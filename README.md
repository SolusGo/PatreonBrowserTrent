# Trent — The Patreon Possession Browser

A single-player Civilization V civilization for the Community Patch, led by Trentrouls. Browse an entirely fictional, offline creator feed; leave one comment on each post; save the moment as a Clip; and spend those Clips to seize enemy combat units as temporary Side Hosts or a permanent, evolving Main Host.

The civilization is named **The Possession Browsers**. Its fictional creator account is **ParasiteLovers**. The mod does not connect to Patreon, a browser, or any external service.

## Requirements and installation

- Sid Meier's Civilization V with Brave New World.
- `(1) Community Patch` is required. Vox Populi is not required.
- Single-player only. Multiplayer and Hot Seat are intentionally disabled because the mechanic performs scripted ownership transfers.

To install the source directly, place the repository in its own folder under `Documents/My Games/Sid Meier's Civilization 5/MODS`, keep the included `.modinfo`, SQL, Lua, UI, and Art folders together, then enable **Trent — The Patreon Possession Browser** and **(1) Community Patch** in the Mods menu. The project can also be opened and built with ModBuddy using `PatreonPossessionBrowser.civ5sln`.

## Civilization overview

### Leader: Trentrouls

Trentrouls is an obsessive viewer, prolific commenter, and opportunistic military theorist. His AI emphasizes offense, mobility, culture, Great People, and espionage. It understands the custom feed: it comments, produces bonus posts with Patreon Regulars, evaluates possible hosts, establishes a Main Host, and spends further Main Host Clips on Evolution.

### Unique ability: I'm a Fan of More Baby Content!

- ParasiteLovers publishes a regular post every **12 turns on Standard Speed**.
- Trentrouls may comment once on each post, choosing one of three responses. The response determines the Saved Clip type.
- Store up to **3 Saved Clips**.
- Spend one Clip to possess an eligible visible enemy combat unit at war within range of any Possession Browser City or combat unit.
- Maintain one temporary **Side Host** and one permanent **Main Host** at the same time.
- Combining a Main Host Clip with any second Clip establishes or replaces a Main Host. Further Main Host Clips evolve it up to three times.

The feed and all ownership state persist across saves through Civ V's mod save-data store.

### Saved Clips

| Clip | Effect |
|---|---|
| More Baby Clip | Temporary possession lasts one extra turn. |
| Possession Theory Clip | Target range increases from 4 to 7, and the target browser shows HP, movement, XP, and promotion count. |
| Body-Hop Clip | Once, after the Side Host kills an eligible enemy in combat, Trentrouls may change into that defeated unit type and gain extra possession time. |
| Main Host Clip | Works as a normal Clip; combine it with another Clip to establish a Main Host; or consume it to evolve the current Main Host. |
| Loyal Patron Clip | The Side Host gains **+15% defense** and heals **10 HP after a kill**. The supportive comment also grants a small era-scaled Culture and Golden Age reward. |

Temporary possession lasts 2/3 turns on Quick, 3/4 on Standard, 5/6 on Epic, and 9/12 on Marathon; the second value is for More Baby. Body-Hop adds 1/1/2/3 turns at those speeds.

### Unique unit: Patreon Regular

Replaces the Great Writer.

- Retains **Create Great Work**, including the normal Great Writer identities and works.
- Cannot write a Political Treatise.
- May instead use **Leave an Essay-Length Comment** in the Patreon interface. This consumes the unit, grants era- and speed-scaled Culture, and publishes a bonus post. The selected response on that bonus post awards **two matching Clips**, so two free storage slots are required.

### Unique building: Premium Subscription

Replaces the National Epic and retains its normal cost, prerequisites, Culture, Great Person modifier, and Great Work slot.

- Feed interval improves from **12 to 9 Standard-Speed turns**.
- Saved Clip capacity increases from **3 to 4**.
- Produces **+2 Great Writer Points per turn** in its City.

## Possession rules

The target must be a visible combat unit owned by a civilization or City-State currently at war with Trentrouls. It must be within 4 tiles of any Browser City or combat unit, or 7 tiles when using Possession Theory.

Air units, missiles, nuclear units, trade units, Barbarians, cargo-bearing units, units standing in Cities, stacked units, and existing hosts are excluded. These boundaries avoid transfers for which Civ V cannot safely preserve cargo, stacking, or city state.

The transfer preserves the unit type, custom name, damage, XP, level, movement, AI role, and non-PPB promotions. Host markers are added separately and removed when the unit returns.

- A Side Host returns to its original owner when its timer expires, peace is made, or Body-Hop moves Trentrouls elsewhere.
- A destroyed host stays destroyed; no duplicate is returned.
- A Main Host persists through peace and remains controlled until death, voluntary release, or replacement.
- Main Hosts receive **+10% Combat Strength**, plus **+5% / +10% / +15%** from Evolution I/II/III.
- Hosts cannot be disbanded, gifted, upgraded, or converted while possessed. A Main Host also cannot be captured.

## Core gameplay loop

1. Read a new fictional creator post.
2. Choose a comment and save its Clip.
3. Declare or enter a war, position Cities or combat units near valuable enemy units, and spend a Clip.
4. Use the borrowed body before temporary possession expires, or invest two Clips in a Main Host.
5. Generate more posts with time, Premium Subscription, and Patreon Regular essays; evolve or replace the Main Host as the battlefield changes.

### Early game

Bank Clips, scout possible hosts, and avoid filling storage with no war in sight. A single strong borrowed unit can change an early engagement, but the short timer rewards deliberate positioning.

### Mid game

Premium Subscription becomes the economic center of the kit. Faster posts and four storage slots support a Main Host plus repeated Side Hosts. Body-Hop is strongest during sustained attacks where the first borrowed unit can reliably secure a kill.

### Late game

High-tier enemy units make excellent permanent hosts. An Evolution III Main Host is powerful but still a single mortal unit; rotate temporary bodies around it and protect it from concentrated fire.

## Victory routes

- **Domination — Excellent.** The kit directly converts enemy military quality into your own tactical strength and rewards active wars.
- **Culture — Strong.** The Great Writer replacement, National Epic replacement, bonus posts, and Loyal Patron comments reinforce Culture without deleting normal Great Works.
- **Science — Viable.** Possession can save production otherwise spent matching an opponent's newest units, but there is no direct science yield.
- **Diplomacy — Difficult.** The civilization wants recurring wartime access to valuable targets and has no direct delegate or City-State economy bonus.

## Strengths, weaknesses, and counterplay

**Strengths:** flexible access to enemy unit types, high tactical ceiling, a permanent elite unit, strong Great Writer integration, and meaningful decisions even when no unit is being produced.

**Weaknesses:** requires visible wartime targets and forward positioning; Clips are scarce; temporary turns are short; a dead Main Host loses every Evolution; and the civilization has little direct help for infrastructure, science, gold, or diplomacy.

**Synergies:** vision and mobility reveal better hosts; ranged armies help a Body-Hop host secure a safe kill; culture and Great Person bonuses produce more Patreon Regulars; durable screening units protect the Main Host.

**Counters:** deny vision, keep premium targets farther than the current range, stack or garrison vulnerable units when appropriate, focus-fire the Main Host, end wars to force Side Hosts home, and pressure the Premium Subscription City.

## Interface

The **PATREON** button appears at the upper right for the Possession Browsers outside the City screen. Its three tabs contain the creator feed, Saved Clips and eligible targets, and Main Host controls. A red count shows unanswered posts. Body-Hop decisions use a separate blocking prompt so the choice cannot be lost behind the main panel.

The target list is only a preview. The gameplay layer validates war, visibility, range, stacking, unit category, Clip inventory, and host limits again when a button is pressed.

## Compatibility and known limitations

- Built for the Community Patch database and Lua event surface. It explicitly enables only the CP hooks it uses.
- Not designed for multiplayer, Hot Seat, or Mac builds.
- Best used without another mod that replaces the same civilization, Great Writer class, National Epic class, or top-right UI region.
- Unit ownership is implemented by kill-and-recreate because Civ V exposes no general native owner setter. State is preserved carefully, but mod-added unit properties outside the standard unit/promotion fields cannot be copied generically.
- Transport/cargo and stacked-unit transfers are disabled rather than risking cargo loss or invalid plots.
- The custom Dawn of Man, map, leader, civilization, unit, building, feed, and alpha art are included. The live diplomacy scene uses America's base leader scene as a safe engine fallback, and the Dawn of Man narration is intentionally silent.

## Repository layout and validation

- `SQL/` — civilization, components, promotions, CP options, and English text.
- `Lua/` — persistent feed, clips, writer behavior, possession, Body-Hop, AI, and loader.
- `UI/` — the creator-feed and host-management interface.
- `Art/` — lossless generated sources and compressed Civ V DDS assets.
- `Tools/build_art.py` — deterministic resize/crop/DDS packaging from the source PNGs.
- `Tools/validate.py` — XML, project, localization, DDS, and CP-database validation.
- `Docs/IMPLEMENTATION_NOTES.md` — state model, event wiring, edge cases, and technical rationale.

Run validation with the bundled or any Pillow-enabled Python:

```powershell
python Tools/validate.py --database "Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
```

The reference database should be generated after loading the Community Patch at least once.

