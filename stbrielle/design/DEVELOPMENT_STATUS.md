# Development status — 2026-10-29

The subsequent [Municipal Gothic graphics pass](GRAPHICS_PASS.md) upgrades the
materials, lighting, and street facade detail described below. The street is now
56 brushes; the 32-brush figure below describes the original investigation pass.
The new Windows workflow validates actual texture generation, but engine rendering
and playthrough remain separate acceptance checks.

## Where the game is

Repository: `islapharlots/Project-Black-Madonna`.
Foundation branch: `st-brielle-foundation`.

The project has a functioning first-person systems foundation and an authored
Annex horror sequence. It is still a development slice, with simple original
geometry and assets. It is not a finished immersive-sim FPS or an open city.

Before this pass, the route ended with an atmospheric street arrival. The city
now has a short complete investigation, **Departure Count / Case 0214-B**:

1. Read the city roster: one authorized inspector left the Annex.
2. Read the witness slip: two people left, with the same face.
3. At the east desk, certify the city copy or retain the witness account.
4. See the filed roster and street react; collect a corresponding hospital order.

The filing is final. The HUD warns before filing. Both documents and both seals
remain usable for review. Certifying early gives evidence-specific feedback;
dispatch refuses to issue an order until certification. The two orders establish
different conditions for a future St. Mercuria mission. There is no hospital map
or onward transition in this pass.

## Changes in this pass

- Finish the partial city objective/presentation work present in the local checkout.
- Author the actual evidence, certification, review, dispatch, and consequence
  entities. A witness retained in the Record leaves a stationary second presence.
- Derive presentation from persistent facts; never award progress in polling code.
- Add `record_fail_target` for synchronous rejection feedback from Record checks.
- Prevent one document's old timeout from closing a newer document.
- Require line of sight for observing the Filed Person; walls interrupt observation.
- Clear street objective visibility on maps without the street case.
- Give street facades collision and correct three inherited inverted brush extents.
- Keep the city map at 32 brushes, using the existing original material set.

## Verification performed

`python tools/test_city_investigation.py` — eight checks pass against the actual
map: target references, unique names, brush bounds/materials/budget, evidence
order, premature filing, irreversible choices, dispatch gating, repeat/re-entry
behavior, and 7,500 randomized player actions with simulated map reconstruction.

`python tools/test_record_events.py` — compiles and executes the actual Record
check and notice-clear method bodies with a minimal engine adapter. Tests success
versus failure routing, activator forwarding, legacy behavior without a failure
target, invalid failure targets, and document timeout ownership in both read orders.

`git diff --check` passes.

These tests do **not** prove engine save serialization, visibility, collision,
timing, text layout, or gameplay balance. A native build was not available in this
Linux environment. A full-source GCC syntax attempt encounters existing platform
and legacy C++ header incompatibilities (`trigger.h` casing, `LoadingContext`,
template destructor declarations). No native build or engine playthrough is claimed.

## Windows acceptance pass

1. Build `solution/monstergame.sln`, project **stbrielle**, x64, in VS2022.
2. Run `run_stbrielle_annex.bat`. Verify both maps produce `.proc` and `.cm` files
   and inspect the compile logs for discarded brushes, leaks, or missing assets.
3. Play the Annex sequence through to **LEAVE** and confirm the street loads.
4. Try both seals and dispatch before evidence; no certification should occur.
5. Read the evidence in either order, reopening one before the other's 14-second
   timeout. The newly opened card must keep its full duration.
6. Save before filing. Certify the city copy: green response, one departure, no
   retained presence, service-inspection order. Opposite seal must review this choice.
7. Restore the pre-filing save. Retain the witness: red response, amended roster,
   stationary second presence, disputed-admission order. Neither choice is combat.
8. Save/reload before and after collecting dispatch. The objective, roster, light,
   and presence must match the saved Record. Repeated use must not change outcomes.
9. Test Filed Person observation with and without a wall between it and the player.
   Confirm it cannot be resolved by looking toward it through a wall, and that the
   Annex can still be completed normally.
10. Inspect objective/card readability, kiosk reach, and facade collision in-game.

For a direct street check after compiling maps, use `devmap sb01_cityglimpse`.
For a fresh street case in a disposable test session, clear the eight city/Mercuria
keys listed in `RECORD_KEYS.md` and reload the map. Preserve a pre-filing save for
branch testing; do not clear the player's whole campaign Record.

## Next production priorities

1. **Validate and tune this route on Windows.** Fix any map/compiler issues and
   establish a repeatable playtest before adding another large area.
2. **Build Mercuria intake as one connected mission.** Consume the two entry modes,
   open different access routes, introduce a power-routing puzzle and one threat,
   and end with a new Record decision. Start with a compact intake/service wing.
3. **Broaden survival choices.** The Filed Person is a scripted observation threat,
   not full navigation/search/combat AI. Add a defensive or environmental bypass
   before promising the combat and stealth approaches in the game bible.
4. **Polish the playable route.** Distinct civic architecture, readable signs,
   sound, save feedback, accessibility, and atmosphere are still production work.

Keep the Black Madonna above combat logic. Preserve the existing municipal
inspector premise and the loop: investigate, improvise, survive, decide what
becomes true.
