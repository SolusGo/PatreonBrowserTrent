# Patch Notes

## Version 1 — Player-only civilization selection — 2026-09-06

- Set the Possession Browsers civilization to remain human-playable while preventing the AI from selecting it.

## Version 1 — 2026-08-29

### Added

- The Possession Browsers civilization and Trentrouls leader.
- The persistent, fully offline ParasiteLovers creator feed with twelve rotating post templates and three localized comment choices per post.
- Five Saved Clip types: More Baby, Possession Theory, Body-Hop, Main Host, and Loyal Patron.
- Temporary Side Host possession with game-speed duration scaling.
- Permanent Main Host establishment, replacement, voluntary release, and three Evolution levels.
- CP battle-participant tracking for exact Body-Hop kill correlation and a human accept/stay prompt.
- Patreon Regular, a Great Writer replacement that keeps Great Works and exchanges Political Treatise for a bonus-post essay action.
- Premium Subscription, a National Epic replacement with a faster feed, larger Clip cap, and +2 Great Writer Points.
- AI behavior for comments, essays, target scoring, temporary possession, Main Host establishment, and Evolution.
- A custom top-right creator-feed interface with feed, Clips/targets, and Main Host tabs.
- Custom leader, civilization, unit, building, feed-thumbnail, alpha-mask, map, and Dawn of Man art.
- English Civilopedia, strategy, diplomacy, notification, interface, city, and spy localization.

### Changed

- Community Patch options for battles, commands, unit conversion, unit creation, pre-kill, and upgrade events are enabled when the mod activates.
- Host units are protected from disbanding, gifting, upgrading, conversion, and unsafe capture paths.

### Balance

- Feed: 12 Standard-Speed turns; 9 with Premium Subscription.
- Storage: 3 Clips; 4 with Premium Subscription.
- Target range: 4; 7 for Possession Theory.
- Temporary duration, normal/More Baby: Quick 2/3, Standard 3/4, Epic 5/6, Marathon 9/12.
- Main Host: +10% Combat Strength; Evolution adds +5%, +10%, or +15%.
- Loyal Patron host: +15% defense and 10 HP healed after a kill.
- Body-Hop: new body begins at 50 HP and adds 1/1/2/3 turns by game speed.

### Technical

- Persistent state uses namespaced `Modding.OpenSaveData` keys.
- Ownership transfer preserves standard unit identity and progression fields while excluding PPB-only marker promotions.
- Gameplay actions are authoritative and revalidate every UI request.
- Multiplayer and Hot Seat support are disabled by design.

### Known limitations

- Requires an in-game single-player QA pass; repository checks cover SQL, XML, texture payloads, localization references, and static Lua syntax only.
- Nonstandard custom state added to units by unrelated mods cannot be copied generically during an ownership transfer.
- The diplomacy scene uses America's base scene and the custom Dawn of Man has no narration audio.
