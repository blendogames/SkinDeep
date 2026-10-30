# Vertical Slice — Municipal Annex

## Map

`sb00_annex`

Target playtime for the finished vertical slice: approximately 20–30 minutes.

The goal is not to build a polished chapter immediately. The goal is to prove every system needed to build the rest of the campaign.

## Opening

The player arrives for an ordinary night continuity shift inside a small St. Brielle municipal annex.

A printed work order is waiting at the desk.

Six facilities require physical verification after a communications interruption.

The work order contains tomorrow's date.

The player's department name on the form does not match the department name on the office door.

The game does not comment on either discrepancy.

## Space plan

### A. Employee entrance
Basic movement, interaction and inventory tutorial.

### B. Continuity office
Work order, city map, first terminal, save point.

### C. Records corridor
Locked records room, alternate vent/service route, first environmental puzzle.

### D. Utility basement
Power routing, maintenance systems, physical-object interaction and first hostile encounter.

### E. Room 214
A room that can be made present or absent through the Record.

### F. Street exit
Mission-complete transition to the first large St. Brielle location.

## Systems the slice must prove

1. Original St. Brielle map loads.
2. Player can interact with doors, physics objects and a terminal.
3. At least one hostile AI can search, lose, reacquire and pursue the player.
4. Player has at least one firearm or defensive tool.
5. Save/load works.
6. `target_stbrielle_record` changes persistent state.
7. `target_stbrielle_recordcheck` changes map behavior based on persistent state.
8. A Record value survives a save and a map transition.
9. The level ends through normal map transition infrastructure.
10. The next map reads the previous map's decision.

## First persistent decision

The basement contains a municipal breaker labelled:

**ARCHIVE AUXILIARY / 214**

Turning it on sets:

`sb_room_214_exists = 1`

Leaving it off allows the player to finish the level with that key unset or false.

Later in the level, a Record check determines whether Room 214 exists in the records corridor.

This gives us a clean technical test:

- one player sees a blank wall;
- another sees a door and room;
- both versions are valid;
- the decision persists into later maps.

## First Awareness event

Inspecting the impossible work order sets:

`sb_black_madonna_awareness += 1`

At awareness 1, nothing supernatural attacks the player.

Instead:

- a framed municipal photograph changes;
- the office directory acquires one extra name;
- a radio emits a short burst of speech;
- a previously normal mirror no longer reflects the office clock.

The point is to establish that Awareness changes the world's behavior, not merely enemy difficulty.

## First combat encounter

The basement encounter should support at least three approaches:

- direct firearm combat;
- environmental distraction / object throw and bypass;
- using a powered door or machinery state to isolate the threat.

The encounter is successful if the player understands that the environment is part of the combat vocabulary.

## End state

At the street exit, the game records:

- `sb_annex_complete = 1`
- `sb_annex_room214 = <result>`
- `sb_annex_workorder_read = <result>`
- `sb_black_madonna_awareness = <current value>`

The level then transitions to the first major mission.

## Current playable implementation

The first playable Annex greybox now exists as:

`maps/sb00_annex.map`

Launch from the repository root with:

`run_stbrielle_annex.bat`

Current controls:

- WASD / mouse — movement and look
- **E** — St. Brielle interaction (`_frob`)

Current authored interaction loop:

1. Read the impossible work order and restore Archive Auxiliary / 214.
2. Enter Room 214 and inspect the occupancy ledger naming the player.
3. Experience the corrected room/photograph and answer the disconnected phone.
4. Complete exit continuity, survive the Filed Person, and choose **LEAVE**.
5. Arrive in `sb01_cityglimpse`, compare the roster and witness slip, and certify
   one account. Collect the resulting St. Mercuria order from central dispatch.

The Annex's first hostile is an observation-driven scripted encounter. Full
search/navigation AI, firearms, multiple combat approaches, final architecture,
and a hospital mission remain future work. The street's hospital orders are
persistent hooks, not a built onward level.

See [Development status](DEVELOPMENT_STATUS.md) for current checks, limitations,
and the required Windows playtest. The outline below records the original
production sequence; it is not a list of completed systems.

## Development order

### Pass A — Record laboratory
Before building the Annex, make a tiny greybox dev map that contains:

- button A: set `sb_test_door=1`;
- button B: clear it;
- one Record check;
- one visible door/light response;
- save station;
- end-level target to a second tiny map;
- second map verifies `sb_test_door` survived.

### Pass B — Annex greybox
Brush geometry only. No final art.

### Pass C — Interaction
Doors, terminal, power, vent path, first AI.

### Pass D — Horror state
Room 214 and first Awareness effects.

### Pass E — Combat and balance

### Pass F — Original St. Brielle art/audio pass
