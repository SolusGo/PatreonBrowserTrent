# Implementation Notes

## Scope

This is a Community Patch civilization implementation, not a Vox Populi civilization. It uses CP event hooks for battle correlation and host protection but supplies its own balance, AI rules, persistent state, and UI. The creator feed is deterministic local content defined in `Lua/PPBPosts.lua`; there are no network requests or external accounts.

## Runtime architecture

The project loads two `InGameUIAddin` contexts.

1. `Lua/PPBLoader.lua` defers initialization by one frame, then includes the post catalogue, gameplay core, and possession systems. This is the authoritative context for rewards, Clip spending, ownership changes, turn processing, and AI.
2. `UI/PPBPatreonPanel.xml` and `.lua` display persisted state and send requests through `LuaEvents`. The UI duplicates eligibility logic only to construct a responsive preview; gameplay revalidates every request.

This boundary prevents stale interface rows, unit movement between click and execution, or UI-context tampering from bypassing mechanic rules.

## Database model

All custom database identifiers use the `PPB` prefix.

- Civilization: `CIVILIZATION_PPB_POSSESSION_BROWSERS`
- Leader: `LEADER_PPB_TRENTROULS`
- Trait: `TRAIT_PPB_FAN_OF_MORE_BABY_CONTENT`
- Unique unit: `UNIT_PPB_PATREON_REGULAR` in `UNITCLASS_WRITER`
- Unique building: `BUILDING_PPB_PREMIUM_SUBSCRIPTION` in `BUILDINGCLASS_NATIONAL_EPIC`
- Promotions: temporary/body-hop markers, Main Host base modifier, three mutually exclusive Evolution modifiers, and Loyal Patron defense/heal.

The civilization copies America's starting units, free techs, base art style, soundtrack tag, and engine-safe leader scene reference. All visible static PPB assets have their own atlases or DDS files. No Dawn of Man narration file is referenced.

The Patreon Regular copies the Great Writer's AI roles, flavors, selection scripts, and unique Great Work names. `BaseCultureTurnsToCount = 0` removes Political Treatise while preserving Great Work creation. Captured or otherwise generated Writers are normalized after creation/conversion so only the Possession Browsers retain the replacement.

The Premium Subscription copies National Epic requirements, prerequisite-building rows, flavors, and yield rows. `SpecialistType = SPECIALIST_WRITER` plus `GreatPeopleRateChange = 2` supplies the requested direct Great Writer Points.

## Persistent state

State is stored with `Modding.OpenSaveData` using keys of the form `PPB_<playerID>_<suffix>`.

### Feed and Clips

- `INITIALIZED`, `NEXT_POST_TURN`, `POST_COUNT`
- `PREMIUM_STATE`, used to shorten an already scheduled wait when Premium is first gained without delaying a post when Premium is later lost
- Per post: template, publication turn, chosen comment, and essay-bonus flag
- `CLIP_COUNT`, `CLIP_SERIAL`
- Per Clip slot: type, source post, saved turn, and stable serial

Clip slots are compacted after consumption. Gameplay requests use the current slot index and then immediately re-read the stored type before applying an effect.

### Side Host

- Active flag, current unit ID, remaining turns, source Clip type, Body-Hop-used flag
- Original owner, unit ID, type, AI role, custom name, and serialized non-PPB promotions

### Main Host

- Active flag, current unit ID, Evolution level
- Original owner, unit ID, type, AI role, custom name, and serialized non-PPB promotions

### Pending Body-Hop

- Pending flag, defeated owner/unit identity, defeated unit type and AI role
- Plot, XP, level, facing, custom name, display name, and serialized promotions

Pending Body-Hop state is persisted before the killed unit disappears. A save made around the decision can therefore reconstruct the prompt and target state.

## Ownership-transfer model

Civ V provides no safe general unit-owner setter. A possession therefore follows this sequence:

1. Validate target, war, visibility, range, Clip inventory, unit category, plot, and host limits.
2. Capture standard state: type, AI role, plot, damage, experience, level, moves, facing, embarkation, name, and promotions.
3. Set an internal transfer guard.
4. Kill the original unit without attributing a combat kill.
5. Initialize the same unit type for the new owner and restore captured state.
6. Apply exactly one PPB role and its applicable mechanic promotion.
7. Persist original-owner data and consume Clips only after the new unit exists.

If creation fails, the code attempts to reconstruct the original unit and does not consume the requested Clip. Returning a host uses its current damage/XP/level/position but restores the original unit type, AI role, name, and non-PPB promotion set. Moves are set to zero to prevent a same-turn double move.

PPB marker promotions are explicitly excluded from serialized promotion lists. This prevents a returned unit from remaining a host or accumulating Evolution through repeated transfers.

## Target and duration rules

Eligible hosts are visible, non-Barbarian, non-air combat units owned by a player at war. Range is measured to the nearest Browser City or combat unit. City plots, stacks, transports carrying cargo, trade units, missiles, nuclear units, suicide units, and existing hosts are excluded.

City-State combat units are eligible when the City-State is at war with Trentrouls. Civilian units, embarked cargo relationships, and City ownership are never transferred.

Durations are explicit rather than proportional rounding so each game speed has reviewed values:

| Speed | Normal | More Baby | Body-Hop extension |
|---|---:|---:|---:|
| Quick | 2 | 3 | 1 |
| Standard | 3 | 4 | 1 |
| Epic | 5 | 6 | 2 |
| Marathon | 9 | 12 | 3 |

Side Host turns decrement on the Browser player's turn. Peace with the original owner returns it immediately. Main Hosts intentionally ignore peace.

## Body-Hop correlation

`GameEvents.BattleStarted`, `BattleJoined`, and `BattleFinished` maintain the exact player/unit participants of the current battle. `GameEvents.UnitPrekill` considers a defeated unit for Body-Hop only when:

- the killing player is Trentrouls;
- the current temporary host and defeated unit both joined that battle;
- the temporary host was created by a Body-Hop Clip;
- Body-Hop has not already been used; and
- the defeated unit is otherwise eligible.

This avoids triggering from an unrelated unit's kill, an attrition death, or a scripted transfer. The pending defeated body starts at 50 HP, receives no moves, preserves its previous XP/promotions, and can be accepted once. Accepting returns the old body immediately. Declining leaves the current host and duration unchanged.

## Main Host rules

Establishment requires one Main Host Clip plus any second Clip. If a Main Host already exists, the selected new host is created first; only after success is the old Main Host returned. Both Clips are then removed from highest to lowest slot index to avoid compaction errors.

The base promotion grants +10% Combat Strength. Evolution uses one mutually exclusive promotion whose modifier is +5%, +10%, or +15%. The total displayed bonus is therefore +15%, +20%, or +25%. Evolution is stored separately and is reset on death, release, or replacement.

## Host protections

The mod vetoes gift, delete, upgrade, and conversion paths through available CP events. A validation pass on each turn reapplies correct role promotions and clears stale host records if a host no longer exists. `UnitPrekill` distinguishes internal transfer kills from real destruction; a real death clears the record and never recreates the unit.

## AI behavior

AI leaders use the same stored feed and action functions as humans.

- Comment weighting: Main Host 30, More Baby 25, Body-Hop 20, Theory 15, Loyal 10, with a strong additional Evolution preference when applicable.
- Patreon Regulars create essay posts only when two Clip slots are free.
- Host score multiplies combat strength by health, XP, and small ranged/range strategic factors.
- AI first evolves an active Main Host when possible, then establishes one when it has two Clips, then spends a remaining Clip on the best temporary target.
- A pending AI Body-Hop is accepted when the new body's score is at least 75% of the current body's score.

The AI deliberately uses deterministic game RNG for comment selection and does not rely on UI contexts.

## Edge-case matrix

| Case | Behavior |
|---|---|
| Target moves or peace occurs after the list is drawn | Gameplay request fails revalidation; no Clip is consumed. |
| Target is killed before the click resolves | Unit lookup returns nil; no transfer occurs. |
| New host creation fails | Original unit is reconstructed when possible; no Clip is consumed. |
| Side Host timer expires | Current host is killed under transfer guard and returned with zero moves. |
| Peace is made | Side Host returns; Main Host remains. |
| Original owner is eliminated | Host record can be cleared or the host destroyed, but no unit is recreated for a dead player. |
| Host dies normally | State is cleared; nothing returns; Main Evolution is lost. |
| Host is gifted/disbanded/upgraded/converted | CP command/upgrade/conversion vetoes reject the action. |
| Body-Hop kill is made by another Browser unit | Participant correlation rejects it. |
| Multiple deaths occur in one battle | Only the first eligible pending body can be recorded. |
| Bonus post is answered without two free slots | Gameplay rejects the comment; the post remains unanswered. |
| Premium Subscription is captured/lost | Feed interval/cap use current ownership. Existing Clips remain stored; no new Clip can exceed the current cap. |
| Writer is captured by another civilization | Unit-created/conversion normalization replaces it with the normal Great Writer. |
| Save/load with hosts active | Persistent IDs and role state are read; the next validation pass reapplies promotions or clears stale records. |

## Community Patch events enabled

The SQL activates exactly the hooks consumed by this implementation:

- `EVENTS_BATTLES`
- `EVENTS_COMMAND`
- `EVENTS_UNIT_CONVERTS`
- `EVENTS_UNIT_CREATED`
- `EVENTS_UNIT_PREKILL`
- `EVENTS_UNIT_UPGRADES`

The loader checks event objects before registration so absent optional hooks do not cause a Lua load error, but the Community Patch dependency is declared in both project and runtime metadata.

## Validation and current test status

`Tools/validate.py` performs:

- XML parsing for the UI, atlas database, project, and mod metadata;
- verification that every project and atlas file exists;
- localization-use and duplicate-tag checks;
- Pillow decoding of every compressed DDS payload;
- execution of core SQL against a Community Patch-populated `Civ5DebugDatabase.db` copy;
- execution of English text SQL against `Localization-Merged.db`;
- semantic checks for the civilization, leader, trait, unique replacements, GPP fields, writer action field, overrides, and enabled CP events.

Repository checks also include `git diff --check`, missing-key scans, project file reconciliation, and Lua parsing when a local parser is available. No automated harness can execute Civ V's native game objects, combat engine, or UI manager. An actual in-game campaign remains required to validate visual anchoring, live event ordering, AI behavior over time, save/load around Body-Hop, peace returns, and compatibility with the user's full mod stack.

## Known engine-level limitations

- Arbitrary custom per-unit state created by unrelated mods cannot be discovered and copied.
- Transport and stack transfers are disabled.
- Main/Side Host ownership changes can interact with other mods listening to unit death/creation; the transfer guard only scopes this mod's handlers.
- The built-in American diplomacy scene is an engine-safe placeholder for a custom 3D leader scene.
- Dawn of Man narration is silent; no missing audio identifier is referenced.
- Multiplayer synchronization is out of scope and explicitly disabled.
