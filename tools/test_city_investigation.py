"""Validate the authored city case without requiring the Windows renderer.

Reads the actual map and exercises its target graph. These checks cannot replace
dmap2, a Windows playthrough, or an engine save/load test.
Run: python tools/test_city_investigation.py
"""
from copy import deepcopy
from itertools import permutations
from pathlib import Path
import random
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "stbrielle/maps/sb01_cityglimpse.map"


def read_entities(path):
    entities = []
    depth = 0
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("//"):
            continue
        if line == "{":
            if depth == 0:
                current = {}
            depth += 1
        elif line == "}":
            depth -= 1
            if depth == 0:
                entities.append(current)
        elif depth == 1:
            match = re.fullmatch(r'"([^"]+)"\s+"([^"]*)"', line)
            if match:
                key, value = match.groups()
                if key in current:
                    raise ValueError(f"Duplicate property: {key}")
                current[key] = value
        if depth < 0:
            raise ValueError("Unexpected closing brace")
    if depth:
        raise ValueError("Unclosed map block")
    return entities


class Case:
    """Small target-graph interpreter; Record is the only persistent state."""

    def __init__(self, record=None):
        self.entities = {e["name"]: e for e in read_entities(MAP) if "name" in e}
        self.record = deepcopy(record or {})
        self.notices = []

    def activate(self, name, depth=0):
        if depth > 40:
            raise AssertionError("Cycle in activation graph")
        entity = self.entities[name]
        kind = entity["classname"]
        if kind == "target_stbrielle_recordcheck":
            key = entity["record_key"]
            actual = self.record.get(key, "")
            expected = entity.get("record_value", "1")
            compare = entity.get("record_compare", "equals")
            conditions = {
                "true": bool(int(actual or "0")),
                "false": not int(actual or "0"),
                "equals": actual.lower() == expected.lower(),
                "lte": int(actual or "0") <= int(expected),
                "gt": int(actual or "0") > int(expected),
            }
            if not conditions[compare]:
                if entity.get("record_fail_target"):
                    self.activate(entity["record_fail_target"], depth + 1)
                return
        elif kind == "target_stbrielle_record":
            # The case deliberately uses only repeatable, guarded set targets.
            assert entity["record_mode"] == "set"
            self.record[entity["record_key"]] = entity["record_value"]
        elif kind == "target_stbrielle_notice":
            self.notices.append(name)
        elif kind not in ("func_static", "light", "trigger_once"):
            raise AssertionError(f"Unsupported case entity: {kind}")
        for key, value in entity.items():
            if re.fullmatch(r"target\d*", key):
                self.activate(value, depth + 1)

    def read_both(self):
        self.activate("city_roster")
        self.activate("city_testimony")


class CityInvestigationTests(unittest.TestCase):
    def test_all_targets_resolve_and_names_are_unique(self):
        entities = read_entities(MAP)
        names = [e["name"] for e in entities if "name" in e]
        self.assertEqual(len(names), len(set(names)))
        for entity in entities:
            for key, value in entity.items():
                if re.fullmatch(r"target\d*", key) or key == "record_fail_target":
                    self.assertIn(value, names)
                    self.assertNotEqual(value, entity.get("name"))

    def test_brush_budget_and_materials(self):
        source = MAP.read_text(encoding="utf-8")
        self.assertLessEqual(source.count("brushDef3"), 64)
        materials = "\n".join(p.read_text(encoding="utf-8") for p in (ROOT / "stbrielle/materials").glob("*.mtr"))
        for material in set(re.findall(r'"(textures/[^\"]+)"', source)):
            self.assertIn(material, materials)
        # Every brush is an axis-aligned box with six nondegenerate planes.
        for body in re.findall(r"brushDef3\s*\{([^}]+)\}", source):
            planes = re.findall(r"\( (-?\d+) (-?\d+) (-?\d+) (-?\d+) \)", body)
            self.assertEqual(len(planes), 6)
            plane_map = {tuple(map(int, p[:3])): int(p[3]) for p in planes}
            for axis in ((1, 0, 0), (0, 1, 0), (0, 0, 1)):
                lower = plane_map[tuple(-v for v in axis)]
                upper = -plane_map[axis]
                self.assertLess(lower, upper)

    def test_filing_requires_both_evidence_sources(self):
        for evidence in ([], ["city_roster"], ["city_testimony"]):
            for seal in ("city_certify_official", "city_certify_witness"):
                with self.subTest(evidence=evidence, seal=seal):
                    case = Case()
                    for item in evidence:
                        case.activate(item)
                    before = deepcopy(case.record)
                    case.activate(seal)
                    self.assertEqual(case.record, before)
                    self.assertIn(case.notices[-1], ("city_need_roster", "city_need_testimony"))

    def test_evidence_can_be_read_in_either_order_and_reread(self):
        for order in permutations(("city_roster", "city_testimony")):
            case = Case()
            for item in order:
                case.activate(item)
            before = deepcopy(case.record)
            case.read_both()
            self.assertEqual(case.record, before)
            self.assertNotIn("sb_city_certification", case.record)

    def test_both_choices_are_final_and_have_distinct_routes(self):
        for mode, value, retained in (("official", "1", "0"), ("witness", "2", "1")):
            with self.subTest(mode=mode):
                case = Case()
                case.read_both()
                case.activate("city_certify_" + mode)
                self.assertEqual(case.record["sb_city_certification"], value)
                self.assertEqual(case.record["sb_city_witness_retained"], retained)
                self.assertEqual(case.record["sb_mercuria_entry_mode"], value)
                before = deepcopy(case.record)
                # Includes opposite seal immediately, before any director tick.
                for seal in ("city_certify_official", "city_certify_witness") * 4:
                    case.activate(seal)
                    self.assertEqual(case.record, before)
                    self.assertEqual(case.notices[-1], "city_" + mode + "_result")

    def test_dispatch_requires_certification(self):
        case = Case()
        for item in ("city_dispatch", "city_roster", "city_dispatch", "city_testimony", "city_dispatch"):
            case.activate(item)
        self.assertNotIn("sb_city_dispatch_received", case.record)
        self.assertEqual(case.notices[-1], "city_dispatch_hold")

    def test_completion_and_reentry_only_need_persistent_record(self):
        for mode in ("official", "witness"):
            case = Case({"sb_record_stability": "70", "sb_awareness": "9", "sb_annex_complete": "1"})
            case.read_both()
            case.activate("city_certify_" + mode)
            # Recreate all map entities before collecting; no local flags copied.
            case = Case(case.record)
            case.activate("city_dispatch")
            for key in ("sb_city_dispatch_received", "sb_mercuria_assignment_received", "sb_city_investigation_complete"):
                self.assertEqual(case.record[key], "1")
            self.assertEqual(case.notices[-1], "city_dispatch_" + mode)
            before = deepcopy(case.record)
            for _ in range(3):
                case = Case(case.record)
                for item in ("city_roster", "city_testimony", "city_certify_official", "city_certify_witness", "city_dispatch"):
                    case.activate(item)
                self.assertEqual(case.record, before)
            self.assertEqual(case.record["sb_record_stability"], "70")
            self.assertEqual(case.record["sb_awareness"], "9")

    def test_random_interactions_never_bypass_or_overwrite_a_choice(self):
        randomizer = random.Random(214)
        actions = ["city_roster", "city_testimony", "city_certify_official", "city_certify_witness", "city_dispatch"]
        for _ in range(150):
            case = Case()
            committed = None
            for _ in range(50):
                case.activate(randomizer.choice(actions))
                decision = case.record.get("sb_city_certification")
                if decision:
                    self.assertEqual(case.record["sb_city_roster_read"], "1")
                    self.assertEqual(case.record["sb_city_testimony_read"], "1")
                    if committed:
                        self.assertEqual(decision, committed)
                    committed = decision
                if case.record.get("sb_city_dispatch_received"):
                    self.assertIn(decision, ("1", "2"))
                if randomizer.random() < 0.1:
                    case = Case(case.record)


if __name__ == "__main__":
    unittest.main(verbosity=2)
