# Municipal Gothic — graphics pass 01

## Art direction

A working municipal institution that has outlasted its own records: worn warm
plaster, dark green terrazzo-like tile, cut limestone, aged painted iron, walnut,
tarnished brass, and old ruled paper. The street adds soot-dark brick, wet asphalt,
warm lamps, and cooler ambient light. Red and green remain reserved for the
certification outcome and established gameplay signals.

This is an authored material/lighting pass in the existing renderer. It does not
add ray tracing, screen-space reflections, volumetric fog, new character models,
or a hospital level. Wetness comes from surface-specific normal/specular maps.

## Changes

- Upgrade the Annex's seven generated material families from 256 to 512 pixels.
  Rework diffuse color, surface relief, wear, and specularity rather than only
  increasing resolution. Add brick, asphalt, and ruled paper families.
- Give ordinary papers a lit material instead of a flat unlit color.
- Generate a soft radial light mask and use the engine's quadratic depth falloff
  for practical lights. Explicitly assign every Annex/street light a local shader.
- Reduce broad fills to weak ambient lighting. Use warm/cool practical pools with
  seven authored shadow lights in the Annex (one starts off) and two on the street.
- Author texture density in world units: most surfaces repeat every 128 units;
  street masonry every 256. Higher image resolution no longer means tiny repeats.
- Match Room 214 to the new base materials at 512 pixels while preserving its
  drifting grout, erased marks, crossed wood grain, and corrected surface state.
- Add masonry base/cornice courses, six additional lit windows, and two street
  lamp fixtures. Annex remains at 244 brushes; street rises from 32 to 56.
- Add Balanced and Low renderer profiles. Neither changes resolution, gamma,
  movement, document timing, or campaign logic.

## Pull and run

Pull `st-brielle-foundation`. If the previous gameplay update has not been built,
rebuild the x64 **stbrielle** project first. This graphics pass itself changes data
and asset-generation scripts, not C++ engine code.

Run `run_stbrielle_annex.bat`. The launcher detects the v2 texture cache, regenerates
the original surfaces once, recompiles both maps, applies the Balanced profile,
and launches the Annex. No separate texture download or Python installation is
needed for the game launcher.

Use a fresh run for this pass. Old saves serialize old light states and do not
automatically acquire the newly added street fixtures.

For lower rendering cost:

```bat
run_stbrielle_annex.bat low
```

Low disables shadows, uses 4x anisotropy, and downsamples the surface maps. Balanced
uses shadows, 8x anisotropy, and full-resolution generated textures. Starting the
launcher normally restores Balanced.

## Verification

The Windows Actions workflow executes all three actual PowerShell/C# generators,
validates 46 TGA files (32.8 MiB uncompressed on disk), checks their sizes, dimensions,
surface variation, normal vectors, and light-mask borders, then reruns the generators
to verify cache reuse. It also runs the eight city progression tests and renders
an inspection sheet from the generated diffuse maps.

Local checks compare every pre-existing non-light entity's spawn properties with
the previous checkout, resolve material/light references, enforce brush and shadow
budgets, and rerun the existing Record event tests. Mission targets and Record
conditions remain identical to the prior gameplay update.

The asset inspection sheet is not an in-game screenshot. Final lighting exposure,
shadow performance, material scale, and engine map compilation still require a
Windows game playthrough. The workflow does not build or launch the engine.

Manual checks:

1. Start a fresh Annex run and inspect the reception desk, corridor floor, lamps,
   room labels, breaker, and exit. The route and interactables must remain readable.
2. Enter and leave Room 214. Check that the corrected material swap still occurs
   and that the original phone/light signals remain visible.
3. Resolve the Filed Person and leave. Inspect the new street masonry and lamps.
4. Test both certification branches from a pre-filing save made with this build.
   Green/red choices, the amended roster, and retained witness must remain clear.
5. Compare Balanced and Low on the target PC. Check FPS around corridor lamps and
   both street lamps before increasing the number of shadow-casting lights.

Developer commands:

```text
python tools/verify_graphics.py
python tools/verify_graphics.py --generated
python tools/test_city_investigation.py
python tools/test_record_events.py
powershell -NoProfile -File tools/preview_materials.ps1
```

`--generated` expects the textures to have been generated first. The Record event
test uses a C++ compiler and its small Linux adapter. The game launcher needs none
of these developer tests. The preview script writes
`graphics-validation/municipal-materials.png` from the real generated assets.
