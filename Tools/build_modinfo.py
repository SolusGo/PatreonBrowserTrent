"""Generate directly loadable Civ V runtime metadata with current MD5 hashes."""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Trent - The Patreon Possession Browser (v 1).modinfo"


def md5(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def main() -> None:
    imports: dict[str, int] = {
        "Art/PPB_IconAtlases.xml": 0,
        "SQL/00_PPB_Core.sql": 0,
        "SQL/10_PPB_Text.sql": 0,
        "Lua/PPBLoader.lua": 0,
        "Lua/PPBPosts.lua": 1,
        "Lua/PPBCore.lua": 1,
        "Lua/PPBPossession.lua": 1,
        "UI/PPBPatreonPanel.xml": 0,
        "UI/PPBPatreonPanel.lua": 0,
    }
    for path in sorted((ROOT / "Art" / "Icons").glob("*.dds")):
        imports[path.relative_to(ROOT).as_posix()] = 1
    for path in sorted((ROOT / "Art" / "DawnOfMan").glob("*.dds")):
        imports[path.relative_to(ROOT).as_posix()] = 1

    file_rows = "\n".join(
        f'    <File md5="{md5(ROOT / relative)}" import="{flag}">{relative}</File>'
        for relative, flag in imports.items()
    )
    document = f'''<?xml version="1.0" encoding="utf-8"?>
<Mod id="ad32607d-c122-4f6d-a1e1-b18044366f71" version="1">
  <Properties>
    <Name>Trent - The Patreon Possession Browser</Name>
    <Teaser>Save fictional creator clips and possess enemy units as temporary or permanent hosts.</Teaser>
    <Description>Adds the Possession Browsers, led by Trentrouls. An entirely offline creator feed supplies Clips used to possess visible wartime enemies, Body-Hop after kills, and evolve a permanent Main Host.</Description>
    <Authors>ThatOneYi</Authors>
    <HideSetupGame>0</HideSetupGame>
    <AffectsSavedGames>1</AffectsSavedGames>
    <MinCompatibleSaveVersion>0</MinCompatibleSaveVersion>
    <SupportsSinglePlayer>1</SupportsSinglePlayer>
    <SupportsMultiplayer>0</SupportsMultiplayer>
    <SupportsHotSeat>0</SupportsHotSeat>
    <SupportsMac>0</SupportsMac>
    <ReloadAudioSystem>0</ReloadAudioSystem>
    <ReloadLandmarkSystem>0</ReloadLandmarkSystem>
    <ReloadStrategicViewSystem>0</ReloadStrategicViewSystem>
    <ReloadUnitSystem>0</ReloadUnitSystem>
  </Properties>
  <Dependencies>
    <Mod id="d1b6328c-ff44-4b0d-aad7-c657f83610cd" minversion="1" maxversion="999" title="(1) Community Patch" />
  </Dependencies>
  <References />
  <Blocks />
  <Files>
{file_rows}
  </Files>
  <Actions>
    <OnModActivated>
      <UpdateDatabase>Art/PPB_IconAtlases.xml</UpdateDatabase>
      <UpdateDatabase>SQL/00_PPB_Core.sql</UpdateDatabase>
      <UpdateDatabase>SQL/10_PPB_Text.sql</UpdateDatabase>
    </OnModActivated>
  </Actions>
  <EntryPoints>
    <EntryPoint type="InGameUIAddin" file="Lua/PPBLoader.lua">
      <Name>Patreon Possession Browser Gameplay</Name>
      <Description>Persistent feed, Clips, AI, and possession systems.</Description>
    </EntryPoint>
    <EntryPoint type="InGameUIAddin" file="UI/PPBPatreonPanel.xml">
      <Name>Patreon Possession Browser Interface</Name>
      <Description>Creator feed, Saved Clips, targets, hosts, and Body-Hop decisions.</Description>
    </EntryPoint>
  </EntryPoints>
</Mod>
'''
    OUTPUT.write_text(document, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.name} with {len(imports)} runtime files.")


if __name__ == "__main__":
    main()

