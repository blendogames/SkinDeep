# ST. BRIELLE: THE INTERVAL

## Project identity

**Working title:** ST. BRIELLE: THE INTERVAL  
**Genre:** first-person horror / immersive sim / systemic FPS  
**Setting:** St. Brielle, in a story adjacent to the existing novel rather than a direct adaptation  
**Engine base:** Skin Deep source / idTech 4 / dhewm3

## Core premise

A municipal continuity inspector is sent to verify essential facilities after a communications outage affecting part of St. Brielle.

The city says the affected district is functioning.

Streetlights are on. Phones ring. WSTB continues broadcasting. Hospital systems report normal operation. Police dispatch still receives calls.

The physical city no longer agrees with its own records.

Rooms appear that are absent from blueprints. Dead residents answer phones. Municipal databases rewrite themselves. Different historical versions of the same location overlap. The player's employee credentials open doors for a department that current city records say never existed.

The player gradually discovers that the systems responsible for maintaining St. Brielle's continuity are attempting to reconcile incompatible versions of the city.

## Design pillars

### 1. Horror from systems, not only scripted scares

The game should be able to change a location because of persistent state, not only because the player crossed a one-use trigger.

Examples:

- a hallway gains a door after a later visit;
- an NPC no longer recognizes a conversation that the player remembers;
- a corpse disappears but its evidence remains in the Record;
- a terminal shows a different employee roster after a Cycle shift;
- a radio broadcast describes an action the player has not performed yet.

### 2. FPS combat is dangerous and expressive

Combat exists, but St. Brielle is not an arena shooter.

The player may use firearms, improvised objects, environmental hazards, security systems, traps, stealth, doors, vents, power systems, and distractions.

Some threats can be killed.
Some can be driven away.
Some cannot be meaningfully harmed.
Some should become more dangerous when attacked.

### 3. The Record is the campaign's memory

The engine stores important facts as persistent `sb_*` keys.

Examples:

- `sb_black_madonna_awareness`
- `sb_room_214_exists`
- `sb_vargas_alive`
- `sb_wstb_knows_player`
- `sb_interval_open`
- `sb_cycle`
- `sb_record_stability`

Later maps can branch on those facts.

### 4. The four Cycles are playable state layers

- **Ink** — ecclesiastical, handwritten, archival, candlelit.
- **Brass** — mechanical, civic-industrial, switches, relays, machinery.
- **Water** — the contemporary St. Brielle baseline.
- **Code** — predictive infrastructure, glass, simulation, civic computation.

A location can contain more than one valid version of itself. Cycle changes are not conventional time travel; they are competing historical states becoming physically authoritative.

### 5. The Black Madonna remains above normal combat logic

The Black Madonna is not a boss with a health bar.

Her influence changes rules, records, geometry, identity, memory, UI, and causality. Direct appearances should be rare and consequential.

## Player fantasy

The player is not a chosen superhero.

They are a municipal employee with legitimate access, procedural knowledge, and a job that becomes cosmologically impossible.

The fantasy is:

**investigate → improvise → survive → decide what becomes true**

## Campaign shape

### Prologue — Municipal Annex
Tutorial and first impossible work order.

### Chapter 1 — St. Mercuria Memorial Hospital
Medical systems, quarantine architecture, power routing, impossible treatment records.

### Chapter 2 — WSTB 1310 AM
Broadcast horror. The station begins reporting the player's actions and possible futures.

### Chapter 3 — The Last Token
Arcade machines and missing-person records produce playable contradictions.

### Chapter 4 — St. Verena / Archivum Briellae
Archive stealth, the Sisters of Perpetual Ink, and direct manipulation of civic records.

### Chapter 5 — Miramar Theatre
Sound, performance, identity, mirrors, and the Producer / Echo Saint.

### Chapter 6 — The Interval
Valentina Ward's gallery becomes an unstable spatial anchor.

### Chapter 7 — Municipal Foresight Center
The Code Cycle begins bleeding backward into the city.

### Chapter 8 — The Unfinished City
Several versions of St. Brielle occupy the same geography.

### Finale — The Record Below
The player reaches the infrastructure or ritual architecture responsible for maintaining civic continuity.

## Relationship to existing canon

The game should expand the universe rather than turn existing major characters into ordinary videogame quest-givers.

Established characters can appear through records, broadcasts, photographs, environmental traces, optional encounters, or limited direct scenes when appropriate.

The game's protagonist and central incident should be original to the game.
