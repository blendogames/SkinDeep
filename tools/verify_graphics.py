"""Check the visual pass and, on Windows, its generated TGA assets.

python tools/verify_graphics.py [--generated] [--baseline /path/to/old/checkout]
No image/graphics packages required. Does not replace an engine render test.
"""
import argparse
import math
from pathlib import Path
import re
import statistics

from test_city_investigation import ROOT, read_entities


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def generated_manifest():
    files = {}
    for script, size in (("setup_annex_textures.ps1", 512), ("setup_room214_textures.ps1", 512), ("setup_room214_paper.ps1", 256)):
        source = (ROOT / "tools" / script).read_text(encoding="utf-8")
        declaration = source.split("$Required = @(", 1)[1].split(")", 1)[0]
        for name in re.findall(r'"([^\"]+\.tga)"', declaration):
            files[name] = size
        if size == 512:
            require("const int N = 512;" in source, script + ": resolution mismatch")
            require("v2-2026-10-29" in source, script + ": cache must be invalidated")
    return files


def validate_sources(baseline=None):
    materials = "\n".join(p.read_text(encoding="utf-8") for p in (ROOT / "stbrielle/materials").glob("*.mtr"))
    names = set(re.findall(r"^([^\s/][^\s{}]*)\s*\{", materials, re.M))
    images = set(re.findall(r"(?:map|qer_editorimage)\s+textures/stbrielle/annex/([^\s]+\.tga)", materials))
    manifest = generated_manifest()
    require(images <= manifest.keys(), "Material references an image that is not generated: " + str(images - manifest.keys()))
    for filename, budget, shadow_budget in (("sb00_annex", 244, 7), ("sb01_cityglimpse", 64, 2)):
        path = ROOT / "stbrielle/maps" / (filename + ".map")
        source = path.read_text(encoding="utf-8")
        entities = read_entities(path)
        by_name = {e["name"]: e for e in entities if "name" in e}
        require(source.count("brushDef3") <= budget, filename + ": brush budget exceeded")
        for mat in set(re.findall(r'"(textures/[^\"]+)"', source)):
            require(mat in names, "Unknown material: " + mat)
        lights = [e for e in entities if e.get("classname") == "light"]
        shadow_lights = [e for e in lights if e.get("noshadows") == "0"]
        require(len(shadow_lights) == shadow_budget, filename + ": unexpected shadow cost")
        for light in lights:
            require(light.get("texture") in names, light["name"] + ": missing light shader")
            radius = [float(v) for v in light.get("light_radius", "").split()]
            require(len(radius) == 3 and min(radius) > 0, light["name"] + ": invalid radius")
            if light.get("ambient") == "1":
                require(max(map(float, light["_color"].split())) <= 0.18, "Ambient fill is too strong")
        if baseline:
            old = read_entities(Path(baseline) / "stbrielle/maps" / (filename + ".map"))
            for entity in old:
                name = entity.get("name")
                if not name:
                    continue
                require(name in by_name, "Removed existing entity: " + name)
                if entity.get("classname") != "light":
                    require(entity == by_name[name], "Changed gameplay/spawn properties: " + name)
        print(filename + ": materials, lighting budgets, and entity checks passed")
    return manifest


def validate_tgas(manifest):
    directory = ROOT / "stbrielle/textures/stbrielle/annex"
    total = 0
    for name, size in manifest.items():
        data = (directory / name).read_bytes()
        require(len(data) == 18 + size * size * 3, name + ": incorrect byte count")
        require(data[2] == 2 and data[16] == 24 and data[17] == 0x20, name + ": unsupported TGA layout")
        require(int.from_bytes(data[12:14], "little") == size and int.from_bytes(data[14:16], "little") == size, name + ": incorrect dimensions")
        pixels = data[18:]
        if name.endswith("_local.tga"):
            # BGR disk order; decode Z, Y, X. Quantization permits a small error.
            for offset in range(0, len(pixels), 3 * 97):
                normal = [channel / 127.5 - 1 for channel in pixels[offset:offset + 3]]
                require(abs(math.sqrt(sum(c * c for c in normal)) - 1) < 0.02, name + ": invalid normal")
                require(normal[0] >= 0, name + ": inverted normal")
        elif name.endswith("_d.tga"):
            require(statistics.pstdev(pixels[::11]) > 2, name + ": flat diffuse map")
        elif name == "light_radial.tga":
            require(max(pixels[:size * 3]) == 0 and max(pixels[-size * 3:]) == 0, "Light profile leaks at its border")
            center = ((size // 2) * size + size // 2) * 3
            require(min(pixels[center:center + 3]) >= 254, "Light profile center is too weak")
        total += len(data)
    print(str(len(manifest)) + " generated images passed format, dimensions, surface and normal checks (" + str(round(total / 1048576, 1)) + " MiB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", action="store_true")
    parser.add_argument("--baseline")
    args = parser.parse_args()
    manifest = validate_sources(args.baseline)
    if args.generated:
        validate_tgas(manifest)
