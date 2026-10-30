# ST. BRIELLE: THE INTERVAL

This directory is the beginning of the **standalone St. Brielle game data layer**.

The project is being developed as a first-person horror / immersive-sim FPS using the Skin Deep / idTech 4 source foundation. The existing commercial Skin Deep content is not part of this repository's GPL source release, so all distributable St. Brielle maps, art, audio, models, textures, narrative data, and UI must be original.

## Current foundation

The `st-brielle-foundation` branch currently contains:

- St. Brielle runtime branding and `stbrielle.exe` build target.
- A separate `stbrielle/` game directory mounted with `fs_game stbrielle`.
- **The Record** — persistent campaign facts stored as `sb_*` keys.
- Mapper targets for changing and checking Record facts.
- **Awareness** — hidden 0–100 systemic state with Dormant, Noticed, Observing, Correcting, and Rupture tiers.
- **Awareness Director** — lets each map react differently when an Awareness tier becomes active.
- **Cycle Director** — lets each map react to Ink, Brass, Water, or Code becoming the dominant Cycle.
- Developer console commands for inspecting persistent state.
- Two original greybox Record laboratory maps.
- A Windows launcher that compiles and starts the laboratory.
- A playable Municipal Annex sequence: work order, power restoration, Room 214,
  occupancy ledger, corrected photograph, disconnected phone, Filed Person, exit.
- `sb01_cityglimpse` — **Departure Count**, a street investigation with two
  evidence sources, a permanent certification choice, and branching Mercuria orders.
- Persistent street objectives, repeatable evidence, and guarded case completion.

See [Development status](design/DEVELOPMENT_STATUS.md) for the current boundaries,
validation results, Windows playtest steps, and next production priorities.

The [Municipal Gothic graphics pass](design/GRAPHICS_PASS.md) upgrades both maps
with 512-pixel materials, practical lighting, selective shadows, and street detail.
The Annex launcher regenerates textures and compiles maps automatically. Use a
fresh run; launch with `run_stbrielle_annex.bat low` for the lower-cost profile.

## Development content layout

- `def/` — St. Brielle entity declarations
- `maps/` — original St. Brielle map sources and compiled maps
- `guis/` — HUD, terminals, menus, civic interfaces
- `materials/` — original material declarations
- `models/` — original models and animations
- `sound/` — original sound shaders and audio
- `script/` — map/game scripts
- `strings/` — localization and narrative text

Some folders will appear only when the first vertical-slice assets are created.

## The Record

`idStBrielleRecord` stores campaign facts in the engine's persistent level dictionary. One map can permanently alter what later maps believe is true.

Example keys:

- `sb_black_madonna_awareness`
- `sb_room_214_exists`
- `sb_vargas_alive`
- `sb_wstb_knows_player`
- `sb_cycle`
- `sb_record_stability`

Mapper-facing targets:

- `target_stbrielle_record` — set/add/toggle/clear a persistent fact.
- `target_stbrielle_recordcheck` — conditionally fire map targets based on a persistent fact.

## Awareness

The canonical system key is:

`sb_awareness`

Tiers:

- **0 — Dormant:** 0
- **1 — Noticed:** 1–9
- **2 — Observing:** 10–24
- **3 — Correcting:** 25–49
- **4 — Rupture:** 50–100

The player is not intended to see these numbers. Maps interpret them through `stbrielle_awareness_director`.

## Cycles

`sb_cycle` uses:

- **0 — Ink**
- **1 — Brass**
- **2 — Water**
- **3 — Code**

Maps interpret the current Cycle through `stbrielle_cycle_director`.

## Developer commands

- `sb_recordDump`
- `sb_recordGet <key>`
- `sb_recordSet <key> <value>`
- `sb_recordAdd <key> <integer>`
- `sb_recordClear [key]`
- `sb_awareness`
- `sb_cycle [ink|brass|water|code]`

## First runnable proof

See:

`design/RUN_RECORDLAB.md`

and run:

`run_stbrielle_recordlab.bat`

after building the x64 **stbrielle** target in Visual Studio 2022.

## Current playable route

Build the x64 **stbrielle** project in Visual Studio 2022 and run
`run_stbrielle_annex.bat`. It prepares the existing original assets, compiles both
maps, and launches the Annex. Use **E** to interact.

The Annex leads into **Departure Count**. Read the north-side city roster and the
south-side witness slip, choose one of the two seals at the east desk, then collect
the resulting order from central dispatch. Both seals review your filed choice
afterward; neither can overwrite it. Evidence remains readable.

St. Mercuria Memorial Hospital is the next production target. This case stores
its entry conditions; the hospital map and onward transition are not built yet.
