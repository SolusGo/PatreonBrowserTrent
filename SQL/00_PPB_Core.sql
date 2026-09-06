-- ===========================================================================
-- Trent - The Patreon Possession Browser
-- Core database definitions. Requires the Community Patch, not Vox Populi.
-- Prefix: PPB
-- ===========================================================================

-- Enable only the documented Community Patch hooks used by the mod.
UPDATE CustomModOptions
SET Value = 1
WHERE Name IN (
    'EVENTS_BATTLES',
    'EVENTS_COMMAND',
    'EVENTS_UNIT_CONVERTS',
    'EVENTS_UNIT_CREATED',
    'EVENTS_UNIT_PREKILL',
    'EVENTS_UNIT_UPGRADES'
);

-- Player colours.
INSERT OR REPLACE INTO Colors (Type, Red, Green, Blue, Alpha) VALUES
('COLOR_PPB_PRIMARY',   0.035, 0.090, 0.145, 1.0),
('COLOR_PPB_SECONDARY', 0.835, 0.610, 0.190, 1.0);

INSERT OR REPLACE INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor)
VALUES ('PLAYERCOLOR_PPB', 'COLOR_PPB_PRIMARY', 'COLOR_PPB_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');

-- Trait and leader.
INSERT INTO Traits (Type, Description, ShortDescription)
VALUES (
    'TRAIT_PPB_FAN_OF_MORE_BABY_CONTENT',
    'TXT_KEY_TRAIT_PPB_FAN_HELP',
    'TXT_KEY_TRAIT_PPB_FAN_SHORT'
);

INSERT INTO Leaders
    (Type, Description, Civilopedia, CivilopediaTag, ArtDefineTag,
     PrimaryVictoryPursuit, SecondaryVictoryPursuit,
     VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness,
     Boldness, DiploBalance, WarmongerHate, DoFWillingness, DenounceWillingness,
     WorkWithWillingness, WorkAgainstWillingness, Loyalty, Forgiveness, Neediness,
     Meanness, Chattiness, PortraitIndex, IconAtlas)
SELECT
    'LEADER_PPB_TRENTROULS',
    'TXT_KEY_LEADER_PPB_TRENTROULS',
    'TXT_KEY_LEADER_PPB_TRENTROULS_PEDIA',
    'TXT_KEY_CIVILOPEDIA_LEADERS_PPB_TRENTROULS',
    ArtDefineTag,
    'VICTORY_PURSUIT_DOMINATION',
    'VICTORY_PURSUIT_CULTURE',
    7, 4, 4, 7, 5, 5, 5, 5, 5, 5, 7, 4, 5, 5, 6,
    0, 'PPB_LEADER_ATLAS'
FROM Leaders
WHERE Type = 'LEADER_WASHINGTON';

INSERT INTO Leader_Traits (LeaderType, TraitType)
VALUES ('LEADER_PPB_TRENTROULS', 'TRAIT_PPB_FAN_OF_MORE_BABY_CONTENT');

INSERT INTO Leader_MajorCivApproachBiases (LeaderType, MajorCivApproachType, Bias)
SELECT 'LEADER_PPB_TRENTROULS', MajorCivApproachType, Bias
FROM Leader_MajorCivApproachBiases
WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_MinorCivApproachBiases (LeaderType, MinorCivApproachType, Bias)
SELECT 'LEADER_PPB_TRENTROULS', MinorCivApproachType, Bias
FROM Leader_MinorCivApproachBiases
WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_Flavors (LeaderType, FlavorType, Flavor)
SELECT 'LEADER_PPB_TRENTROULS', FlavorType, Flavor
FROM Leader_Flavors
WHERE LeaderType = 'LEADER_WASHINGTON';

UPDATE Leader_Flavors SET Flavor = 7
WHERE LeaderType = 'LEADER_PPB_TRENTROULS'
  AND FlavorType IN ('FLAVOR_OFFENSE', 'FLAVOR_CULTURE', 'FLAVOR_ESPIONAGE');
UPDATE Leader_Flavors SET Flavor = 6
WHERE LeaderType = 'LEADER_PPB_TRENTROULS'
  AND FlavorType IN ('FLAVOR_DEFENSE', 'FLAVOR_CITY_DEFENSE');
UPDATE Leader_Flavors SET Flavor = 8
WHERE LeaderType = 'LEADER_PPB_TRENTROULS'
  AND FlavorType IN ('FLAVOR_GREAT_PEOPLE', 'FLAVOR_MOBILE');
UPDATE Leader_Flavors SET Flavor = 5
WHERE LeaderType = 'LEADER_PPB_TRENTROULS' AND FlavorType = 'FLAVOR_SCIENCE';
UPDATE Leader_Flavors SET Flavor = 4
WHERE LeaderType = 'LEADER_PPB_TRENTROULS'
  AND FlavorType IN ('FLAVOR_GOLD', 'FLAVOR_EXPANSION', 'FLAVOR_DIPLOMACY');

-- Civilization. America supplies only safe base art/style fields; the visible
-- selection, map, Dawn of Man, leader, unit and building portraits are PPB art.
INSERT INTO Civilizations
    (Type, Description, Civilopedia, CivilopediaTag, Strategy, Playable, AIPlayable,
     ShortDescription, Adjective, DefaultPlayerColor, ArtDefineTag, ArtStyleType,
     ArtStyleSuffix, ArtStylePrefix, PortraitIndex, IconAtlas, AlphaIconAtlas,
     MapImage, DawnOfManQuote, DawnOfManImage, DawnOfManAudio, SoundtrackTag)
SELECT
    'CIVILIZATION_PPB_POSSESSION_BROWSERS',
    'TXT_KEY_CIV_PPB_DESC',
    'TXT_KEY_CIV_PPB_PEDIA',
    'TXT_KEY_CIV5_PPB_POSSESSION_BROWSERS',
    'TXT_KEY_CIV_PPB_STRATEGY',
    1, 0,
    'TXT_KEY_CIV_PPB_SHORT_DESC',
    'TXT_KEY_CIV_PPB_ADJECTIVE',
    'PLAYERCOLOR_PPB',
    ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
    0, 'PPB_CIV_ATLAS', 'PPB_CIV_ALPHA_ATLAS',
    'Art/DawnOfMan/PPB_Map.dds',
    'TXT_KEY_CIV5_DAWN_PPB_TEXT',
    'Art/DawnOfMan/PPB_DawnOfMan.dds',
    '', SoundtrackTag
FROM Civilizations
WHERE Type = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType)
VALUES ('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'LEADER_PPB_TRENTROULS');

INSERT INTO Civilization_FreeBuildingClasses (CivilizationType, BuildingClassType)
SELECT 'CIVILIZATION_PPB_POSSESSION_BROWSERS', BuildingClassType
FROM Civilization_FreeBuildingClasses
WHERE CivilizationType = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_FreeTechs (CivilizationType, TechType)
SELECT 'CIVILIZATION_PPB_POSSESSION_BROWSERS', TechType
FROM Civilization_FreeTechs
WHERE CivilizationType = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count)
SELECT 'CIVILIZATION_PPB_POSSESSION_BROWSERS', UnitClassType, UnitAIType, Count
FROM Civilization_FreeUnits
WHERE CivilizationType = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_CityNames (CivilizationType, CityName) VALUES
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_UNA_COURT'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_CREATOR_HUB'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_SAVED_FOLDER'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_MAIN_HOST'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_GLOWING_EYES'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_COMMENT_CHAIN'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_PART_TWO'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_FEED_REFRESH'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_PARASITE_LOVERS'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_BODY_HOP'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_PREFERRED_BODY'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_PREMIUM_TIER'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_LONG_COMMENT'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_FRAME_BY_FRAME'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_CITY_NAME_PPB_NEW_NOTIFICATION');

INSERT INTO Civilization_SpyNames (CivilizationType, SpyName) VALUES
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_0'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_1'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_2'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_3'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_4'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_5'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_6'),
('CIVILIZATION_PPB_POSSESSION_BROWSERS', 'TXT_KEY_SPY_NAME_PPB_7');

-- Unique Great Writer: no Political Treatise (BaseCultureTurnsToCount = 0),
-- while the copied Unit_UniqueNames retain Create Great Work.
INSERT INTO Units
    (Type, Description, Civilopedia, Strategy, Help, Requirements,
     Cost, FaithCost, RequiresFaithPurchaseEnabled, Moves, Class, Special,
     Capture, Domain, CivilianAttackPriority, DefaultUnitAI, PrereqTech,
     ObsoleteTech, GoodyHutUpgradeUnitClass, WorkRate, BaseCultureTurnsToCount,
     UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
     ShowInPedia, MoveRate, UnitFlagIconOffset, PortraitIndex, IconAtlas,
     UnitFlagAtlas, MaxHitPoints)
SELECT
    'UNIT_PPB_PATREON_REGULAR',
    'TXT_KEY_UNIT_PPB_PATREON_REGULAR',
    'TXT_KEY_UNIT_PPB_PATREON_REGULAR_PEDIA',
    'TXT_KEY_UNIT_PPB_PATREON_REGULAR_STRATEGY',
    'TXT_KEY_UNIT_PPB_PATREON_REGULAR_HELP',
    Requirements,
    Cost, FaithCost, RequiresFaithPurchaseEnabled, Moves, Class, Special,
    Capture, Domain, CivilianAttackPriority, DefaultUnitAI, PrereqTech,
    ObsoleteTech, NULL, WorkRate, 0,
    UnitArtInfo, UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
    1, MoveRate, UnitFlagIconOffset, 0, 'PPB_REGULAR_ATLAS',
    UnitFlagAtlas, MaxHitPoints
FROM Units
WHERE Type = 'UNIT_WRITER';

INSERT INTO Unit_AITypes (UnitType, UnitAIType)
SELECT 'UNIT_PPB_PATREON_REGULAR', UnitAIType
FROM Unit_AITypes WHERE UnitType = 'UNIT_WRITER';

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
SELECT 'UNIT_PPB_PATREON_REGULAR', FlavorType, Flavor
FROM Unit_Flavors WHERE UnitType = 'UNIT_WRITER';

INSERT INTO Unit_UniqueNames (UnitType, UniqueName, GreatWorkType, EraType)
SELECT 'UNIT_PPB_PATREON_REGULAR', UniqueName, GreatWorkType, EraType
FROM Unit_UniqueNames WHERE UnitType = 'UNIT_WRITER';

INSERT INTO UnitGameplay2DScripts (UnitType, SelectionSound, FirstSelectionSound)
SELECT 'UNIT_PPB_PATREON_REGULAR', SelectionSound, FirstSelectionSound
FROM UnitGameplay2DScripts WHERE UnitType = 'UNIT_WRITER';

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType)
VALUES (
    'CIVILIZATION_PPB_POSSESSION_BROWSERS',
    'UNITCLASS_WRITER',
    'UNIT_PPB_PATREON_REGULAR'
);

-- Unique National Epic. All base National Epic requirements/yields are copied;
-- the direct writer GPP are the requested +2 per turn.
INSERT INTO Buildings
    (Type, Description, Civilopedia, Strategy, Help, GoldMaintenance,
     NeverCapture, NukeImmune, Cost, NumCityCostMod, HurryCostModifier, MinAreaSize,
     ConquestProb, GreatPeopleRateModifier, BuildingClass, ArtDefineTag,
     PrereqTech, SpecialistType, GreatPeopleRateChange, GreatWorkSlotType,
     GreatWorkCount, PortraitIndex, IconAtlas)
SELECT
    'BUILDING_PPB_PREMIUM_SUBSCRIPTION',
    'TXT_KEY_BUILDING_PPB_PREMIUM_SUBSCRIPTION',
    'TXT_KEY_BUILDING_PPB_PREMIUM_SUBSCRIPTION_PEDIA',
    'TXT_KEY_BUILDING_PPB_PREMIUM_SUBSCRIPTION_STRATEGY',
    'TXT_KEY_BUILDING_PPB_PREMIUM_SUBSCRIPTION_HELP',
    GoldMaintenance, NeverCapture, NukeImmune, Cost, NumCityCostMod, HurryCostModifier,
    MinAreaSize, ConquestProb, GreatPeopleRateModifier, BuildingClass,
    ArtDefineTag, PrereqTech, 'SPECIALIST_WRITER', 2,
    GreatWorkSlotType, GreatWorkCount, 0, 'PPB_PREMIUM_ATLAS'
FROM Buildings
WHERE Type = 'BUILDING_NATIONAL_EPIC';

INSERT INTO Building_ClassesNeededInCity (BuildingType, BuildingClassType)
SELECT 'BUILDING_PPB_PREMIUM_SUBSCRIPTION', BuildingClassType
FROM Building_ClassesNeededInCity
WHERE BuildingType = 'BUILDING_NATIONAL_EPIC';

INSERT INTO Building_Flavors (BuildingType, FlavorType, Flavor)
SELECT 'BUILDING_PPB_PREMIUM_SUBSCRIPTION', FlavorType, Flavor
FROM Building_Flavors
WHERE BuildingType = 'BUILDING_NATIONAL_EPIC';

INSERT INTO Building_PrereqBuildingClasses (BuildingType, BuildingClassType, NumBuildingNeeded)
SELECT 'BUILDING_PPB_PREMIUM_SUBSCRIPTION', BuildingClassType, NumBuildingNeeded
FROM Building_PrereqBuildingClasses
WHERE BuildingType = 'BUILDING_NATIONAL_EPIC';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, Yield)
SELECT 'BUILDING_PPB_PREMIUM_SUBSCRIPTION', YieldType, Yield
FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_NATIONAL_EPIC';

INSERT INTO Civilization_BuildingClassOverrides
    (CivilizationType, BuildingClassType, BuildingType)
VALUES (
    'CIVILIZATION_PPB_POSSESSION_BROWSERS',
    'BUILDINGCLASS_NATIONAL_EPIC',
    'BUILDING_PPB_PREMIUM_SUBSCRIPTION'
);

-- Script markers and combat modifiers. These promotions are never selectable.
INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade,
     PortraitIndex, IconAtlas, PediaType, PediaEntry, ShowInUnitPanel)
VALUES
('PROMOTION_PPB_TEMP_HOST', 'TXT_KEY_PROMOTION_PPB_TEMP_HOST',
 'TXT_KEY_PROMOTION_PPB_TEMP_HOST_HELP', 1, 1, 59, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_TEMP_HOST', 1),
('PROMOTION_PPB_BODY_HOP_HOST', 'TXT_KEY_PROMOTION_PPB_BODY_HOP_HOST',
 'TXT_KEY_PROMOTION_PPB_BODY_HOP_HOST_HELP', 1, 1, 58, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_BODY_HOP_HOST', 1);

INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade,
     CombatPercent, CannotBeCaptured, PortraitIndex, IconAtlas,
     PediaType, PediaEntry, ShowInUnitPanel)
VALUES
('PROMOTION_PPB_MAIN_HOST', 'TXT_KEY_PROMOTION_PPB_MAIN_HOST',
 'TXT_KEY_PROMOTION_PPB_MAIN_HOST_HELP', 1, 1, 10, 1, 57, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_MAIN_HOST', 1),
('PROMOTION_PPB_EVOLUTION_1', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_1',
 'TXT_KEY_PROMOTION_PPB_EVOLUTION_1_HELP', 1, 1, 5, 1, 56, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_1', 1),
('PROMOTION_PPB_EVOLUTION_2', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_2',
 'TXT_KEY_PROMOTION_PPB_EVOLUTION_2_HELP', 1, 1, 10, 1, 56, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_2', 1),
('PROMOTION_PPB_EVOLUTION_3', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_3',
 'TXT_KEY_PROMOTION_PPB_EVOLUTION_3_HELP', 1, 1, 15, 1, 56, 'ABILITY_ATLAS',
 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_EVOLUTION_3', 1);

INSERT INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade,
     DefenseMod, HPHealedIfDestroyEnemy, PortraitIndex, IconAtlas,
     PediaType, PediaEntry, ShowInUnitPanel)
VALUES
('PROMOTION_PPB_DEFENDING_POST', 'TXT_KEY_PROMOTION_PPB_DEFENDING_POST',
 'TXT_KEY_PROMOTION_PPB_DEFENDING_POST_HELP', 1, 1, 15, 10, 55,
 'ABILITY_ATLAS', 'PEDIA_SHARED', 'TXT_KEY_PROMOTION_PPB_DEFENDING_POST', 1);

-- A compact custom diplomacy set avoids borrowing Washington's dialogue.
INSERT INTO Diplomacy_Responses (LeaderType, ResponseType, Response, Bias) VALUES
('LEADER_PPB_TRENTROULS', 'RESPONSE_FIRST_GREETING', 'TXT_KEY_LEADER_PPB_FIRSTGREETING%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_GREETING_POLITE_HELLO', 'TXT_KEY_LEADER_PPB_GREETING_POLITE%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_GREETING_NEUTRAL_HELLO', 'TXT_KEY_LEADER_PPB_GREETING_NEUTRAL%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_GREETING_HOSTILE_HELLO', 'TXT_KEY_LEADER_PPB_GREETING_HOSTILE%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_LETS_HEAR_IT', 'TXT_KEY_LEADER_PPB_LETSHEARIT%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_DOW_GENERIC', 'TXT_KEY_LEADER_PPB_DECLAREWAR%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_ATTACKED_HOSTILE', 'TXT_KEY_LEADER_PPB_ATTACKED%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_DEFEATED', 'TXT_KEY_LEADER_PPB_DEFEATED%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_TRADE_YES_HAPPY', 'TXT_KEY_LEADER_PPB_TRADE_YES%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_TRADE_NO_NEUTRAL', 'TXT_KEY_LEADER_PPB_TRADE_NO%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS', 'TXT_KEY_LEADER_PPB_PEACE%', 1),
('LEADER_PPB_TRENTROULS', 'RESPONSE_DEMAND', 'TXT_KEY_LEADER_PPB_DEMAND%', 1);
