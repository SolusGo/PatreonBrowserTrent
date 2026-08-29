"""Static and database-backed validation for the Patreon Possession Browser."""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import sqlite3
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "PatreonPossessionBrowser.civ5proj"
TEXT_KEY = re.compile(r"TXT_KEY_[A-Z0-9_]*PPB[A-Z0-9_]*")
TEXT_ROW = re.compile(r"\('([^']+)'\s*,")


def check(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate_xml(errors: list[str]) -> None:
    paths = list(ROOT.rglob("*.xml")) + list(ROOT.rglob("*.modinfo"))
    for path in sorted(paths):
        try:
            ET.parse(path)
        except ET.ParseError as exc:
            errors.append(f"Malformed XML: {path.relative_to(ROOT)}: {exc}")
    try:
        ET.parse(PROJECT)
    except ET.ParseError as exc:
        errors.append(f"Malformed project XML: {exc}")


def validate_project_files(errors: list[str]) -> None:
    tree = ET.parse(PROJECT)
    namespace = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
    for item in tree.findall(".//m:Content", namespace):
        include = item.get("Include")
        if include:
            check((ROOT / include).is_file(), f"Project references missing file: {include}", errors)

    modinfo_path = ROOT / "Trent - The Patreon Possession Browser (v 1).modinfo"
    check(modinfo_path.is_file(), f"Missing runtime metadata: {modinfo_path.name}", errors)
    if modinfo_path.is_file():
        modinfo = ET.parse(modinfo_path)
        for item in modinfo.findall(".//File"):
            relative = item.text or ""
            path = ROOT / relative
            check(path.is_file(), f"Modinfo references missing file: {relative}", errors)
            if path.is_file():
                actual = hashlib.md5(path.read_bytes()).hexdigest().upper()
                check(item.get("md5") == actual,
                      f"Stale modinfo MD5 for {relative}; run Tools/build_modinfo.py", errors)


def validate_localization(errors: list[str]) -> None:
    text_sql = (ROOT / "SQL" / "10_PPB_Text.sql").read_text(encoding="utf-8")
    defined = set(TEXT_ROW.findall(text_sql))
    used: set[str] = set()
    for suffix in ("*.sql", "*.lua", "*.xml"):
        for path in ROOT.rglob(suffix):
            used.update(TEXT_KEY.findall(path.read_text(encoding="utf-8")))
    missing = sorted(
        key for key in used
        if key not in defined
        and not key.endswith("_")
        and not any(candidate.startswith(key + "_") for candidate in defined)
    )
    if missing:
        errors.append("Undefined localization keys: " + ", ".join(missing))
    rows = TEXT_ROW.findall(text_sql)
    duplicates = sorted({key for key in rows if rows.count(key) > 1})
    if duplicates:
        errors.append("Duplicate localization rows: " + ", ".join(duplicates))


def validate_art(errors: list[str]) -> None:
    atlas = ET.parse(ROOT / "Art" / "PPB_IconAtlases.xml")
    for row in atlas.findall(".//Row"):
        filename = row.findtext("Filename")
        if filename:
            check((ROOT / filename).is_file(), f"Atlas references missing texture: {filename}", errors)
    try:
        from PIL import Image
    except ImportError:
        return
    for path in sorted((ROOT / "Art").rglob("*.dds")):
        try:
            with Image.open(path) as image:
                image.load()
                check(image.width > 0 and image.height > 0,
                      f"Texture has invalid size: {path.relative_to(ROOT)}", errors)
        except Exception as exc:  # Pillow validates headers and compressed payloads.
            errors.append(f"Unreadable DDS: {path.relative_to(ROOT)}: {exc}")


def validate_database(database: Path, localization_database: Path, errors: list[str]) -> None:
    if not database.is_file():
        errors.append(f"Reference Civ V database not found: {database}")
        return
    with tempfile.TemporaryDirectory(prefix="ppb-validate-") as temp_dir:
        copy_path = Path(temp_dir) / "Civ5.db"
        shutil.copy2(database, copy_path)
        connection = sqlite3.connect(copy_path)
        try:
            connection.executescript((ROOT / "SQL" / "00_PPB_Core.sql").read_text(encoding="utf-8"))
        except sqlite3.Error as exc:
            errors.append(f"SQL failed against Civ5DebugDatabase.db: {exc}")
            connection.close()
            return

        required_rows = (
            ("Civilizations", "Type", "CIVILIZATION_PPB_POSSESSION_BROWSERS"),
            ("Leaders", "Type", "LEADER_PPB_TRENTROULS"),
            ("Traits", "Type", "TRAIT_PPB_FAN_OF_MORE_BABY_CONTENT"),
            ("Units", "Type", "UNIT_PPB_PATREON_REGULAR"),
            ("Buildings", "Type", "BUILDING_PPB_PREMIUM_SUBSCRIPTION"),
            ("UnitPromotions", "Type", "PROMOTION_PPB_MAIN_HOST"),
        )
        for table, column, value in required_rows:
            count = connection.execute(
                f"SELECT COUNT(*) FROM {table} WHERE {column} = ?", (value,)
            ).fetchone()[0]
            check(count == 1, f"Expected one {table}.{column} row for {value}, found {count}", errors)

        writer = connection.execute(
            "SELECT BaseCultureTurnsToCount, Class, Special, WorkRate FROM Units WHERE Type=?",
            ("UNIT_PPB_PATREON_REGULAR",),
        ).fetchone()
        check(writer == (0, "UNITCLASS_WRITER", "SPECIALUNIT_PEOPLE", 1),
              f"Patreon Regular writer semantics are incorrect: {writer}", errors)

        premium = connection.execute(
            "SELECT GreatPeopleRateModifier, SpecialistType, GreatPeopleRateChange, BuildingClass, NumCityCostMod "
            "FROM Buildings WHERE Type=?", ("BUILDING_PPB_PREMIUM_SUBSCRIPTION",)
        ).fetchone()
        check(premium == (25, "SPECIALIST_WRITER", 2, "BUILDINGCLASS_NATIONAL_EPIC", 30),
              f"Premium Subscription GPP/class semantics are incorrect: {premium}", errors)

        overrides = connection.execute(
            "SELECT UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=? "
            "UNION ALL SELECT BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?",
            ("CIVILIZATION_PPB_POSSESSION_BROWSERS", "CIVILIZATION_PPB_POSSESSION_BROWSERS"),
        ).fetchall()
        check(len(overrides) == 2, f"Expected two civilization overrides, found {len(overrides)}", errors)

        enabled = dict(connection.execute(
            "SELECT Name, Value FROM CustomModOptions WHERE Name IN "
            "('EVENTS_BATTLES','EVENTS_COMMAND','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_CREATED',"
            "'EVENTS_UNIT_PREKILL','EVENTS_UNIT_UPGRADES')"
        ).fetchall())
        disabled = sorted(name for name, value in enabled.items() if int(value) != 1)
        check(len(enabled) == 6 and not disabled,
              f"Required CP events were not all enabled: rows={enabled}", errors)
        connection.close()

    if not localization_database.is_file():
        errors.append(f"Reference localization database not found: {localization_database}")
        return
    with tempfile.TemporaryDirectory(prefix="ppb-localization-") as temp_dir:
        copy_path = Path(temp_dir) / "Localization.db"
        shutil.copy2(localization_database, copy_path)
        connection = sqlite3.connect(copy_path)
        try:
            connection.executescript((ROOT / "SQL" / "10_PPB_Text.sql").read_text(encoding="utf-8"))
        except sqlite3.Error as exc:
            errors.append(f"Localization SQL failed against Localization-Merged.db: {exc}")
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", type=Path, required=True,
                        help="Path to cache/Civ5DebugDatabase.db after loading Community Patch")
    parser.add_argument("--localization-database", type=Path,
                        help="Path to cache/Localization-Merged.db (defaults beside --database)")
    args = parser.parse_args()
    errors: list[str] = []
    validate_xml(errors)
    validate_project_files(errors)
    validate_localization(errors)
    validate_art(errors)
    localization_database = args.localization_database or args.database.with_name("Localization-Merged.db")
    validate_database(args.database, localization_database, errors)
    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("VALIDATION PASSED: XML, project references, localization, DDS assets, and CP-backed SQL.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
