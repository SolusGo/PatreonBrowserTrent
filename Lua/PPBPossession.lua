-- ===========================================================================
-- Patreon Possession Browser - temporary hosts, Main Host and Body-Hop
-- ===========================================================================

print("PPB: PPBPossession.lua loading")

local PROMO_TEMP = GameInfoTypes.PROMOTION_PPB_TEMP_HOST
local PROMO_BODY_HOP = GameInfoTypes.PROMOTION_PPB_BODY_HOP_HOST
local PROMO_MAIN = GameInfoTypes.PROMOTION_PPB_MAIN_HOST
local PROMO_DEFEND = GameInfoTypes.PROMOTION_PPB_DEFENDING_POST
local PROMO_EVOLUTION = {
    GameInfoTypes.PROMOTION_PPB_EVOLUTION_1,
    GameInfoTypes.PROMOTION_PPB_EVOLUTION_2,
    GameInfoTypes.PROMOTION_PPB_EVOLUTION_3
}
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR
local possessionTransfer = false
local currentBattle = nil

local CUSTOM_PROMOTIONS = {}
for _, promotionID in ipairs({ PROMO_TEMP, PROMO_BODY_HOP, PROMO_MAIN, PROMO_DEFEND,
    PROMO_EVOLUTION[1], PROMO_EVOLUTION[2], PROMO_EVOLUTION[3] }) do
    if promotionID ~= nil then CUSTOM_PROMOTIONS[promotionID] = true end
end

local function L(key, ...)
    if Locale ~= nil and Locale.ConvertTextKey ~= nil then
        return Locale.ConvertTextKey(key, ...)
    end
    return tostring(key)
end

function PPB_IsPossessionTransfer()
    return possessionTransfer == true
end

local function UnitInfo(unit)
    return unit ~= nil and GameInfo.Units[unit:GetUnitType()] or nil
end

local function SerializePromotions(promotions)
    local values = {}
    for _, promotionID in ipairs(promotions or {}) do
        if not CUSTOM_PROMOTIONS[promotionID] then values[#values + 1] = tostring(promotionID) end
    end
    return table.concat(values, ",")
end

local function ParsePromotions(value)
    local promotions = {}
    for token in string.gmatch(tostring(value or ""), "[^,]+") do
        local promotionID = tonumber(token)
        if promotionID ~= nil and not CUSTOM_PROMOTIONS[promotionID] then
            promotions[#promotions + 1] = promotionID
        end
    end
    return promotions
end

local function CaptureUnit(unit)
    local state = {
        type = unit:GetUnitType(), ai = unit:GetUnitAIType(),
        x = unit:GetX(), y = unit:GetY(), damage = unit:GetDamage(),
        experience = unit:GetExperience(), level = unit:GetLevel(),
        moves = unit:GetMoves(), promotions = {}
    }
    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    if unit.GetFacingDirection ~= nil then state.direction = unit:GetFacingDirection() end
    if unit.IsEmbarked ~= nil then state.embarked = unit:IsEmbarked() end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) and not CUSTOM_PROMOTIONS[promotion.ID] then
            state.promotions[#state.promotions + 1] = promotion.ID
        end
    end
    return state
end

local function SetExactPromotions(unit, promotions)
    local wanted = {}
    for _, promotionID in ipairs(promotions or {}) do wanted[promotionID] = true end
    for promotion in GameInfo.UnitPromotions() do
        if not CUSTOM_PROMOTIONS[promotion.ID] then
            unit:SetHasPromotion(promotion.ID, wanted[promotion.ID] == true)
        end
    end
end

local function ApplyBaseState(unit, state)
    if unit == nil or state == nil then return nil end
    SetExactPromotions(unit, state.promotions)
    unit:SetDamage(math.max(0, math.min(99, tonumber(state.damage) or 0)))
    if unit.SetExperience ~= nil then unit:SetExperience(math.max(0, tonumber(state.experience) or 0))
    elseif (tonumber(state.experience) or 0) > 0 then unit:ChangeExperience(state.experience) end
    if unit.SetLevel ~= nil then unit:SetLevel(math.max(1, tonumber(state.level) or 1)) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end
    if unit.SetMoves ~= nil then unit:SetMoves(math.max(0, tonumber(state.moves) or 0)) end
    if state.embarked and unit.SetEmbarked ~= nil then
        pcall(function() unit:SetEmbarked(true) end)
    end
    if unit.JumpToNearestValidPlot ~= nil then pcall(function() unit:JumpToNearestValidPlot() end) end
    return unit
end

local function CreateUnit(owner, state)
    if owner == nil or state == nil or state.type == nil then return nil end
    local unit = owner:InitUnit(state.type, state.x, state.y, state.ai, state.direction)
    if unit == nil then return nil end
    return ApplyBaseState(unit, state)
end

local function ApplyRolePromotions(unit, role, clipType, evolution)
    if unit == nil then return end
    if PROMO_TEMP ~= nil then unit:SetHasPromotion(PROMO_TEMP, role == "TEMP") end
    if PROMO_BODY_HOP ~= nil then
        unit:SetHasPromotion(PROMO_BODY_HOP, role == "TEMP" and clipType == PPB_CLIP_BODY_HOP)
    end
    if PROMO_MAIN ~= nil then unit:SetHasPromotion(PROMO_MAIN, role == "MAIN") end
    if PROMO_DEFEND ~= nil then
        unit:SetHasPromotion(PROMO_DEFEND, role == "TEMP" and clipType == PPB_CLIP_LOYAL)
    end
    for index, promotionID in ipairs(PROMO_EVOLUTION) do
        if promotionID ~= nil then
            unit:SetHasPromotion(promotionID, role == "MAIN" and evolution == index)
        end
    end
end

local function SaveOriginal(playerID, prefix, state, originalOwnerID, originalUnitID)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_OWNER", originalOwnerID)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_UNIT_ID", originalUnitID)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_TYPE", state.type)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_AI", state.ai)
    PPB_SetString(playerID, prefix .. "_ORIGINAL_NAME", state.name or "")
    PPB_SetString(playerID, prefix .. "_ORIGINAL_PROMOTIONS", SerializePromotions(state.promotions))
end

local function OriginalReturnState(playerID, prefix, current)
    current.type = PPB_GetNumber(playerID, prefix .. "_ORIGINAL_TYPE", current.type)
    current.ai = PPB_GetNumber(playerID, prefix .. "_ORIGINAL_AI", current.ai)
    current.name = PPB_GetString(playerID, prefix .. "_ORIGINAL_NAME", current.name or "")
    current.promotions = ParsePromotions(PPB_GetString(playerID, prefix .. "_ORIGINAL_PROMOTIONS"))
    current.moves = 0
    return current
end

local function ClearOriginal(playerID, prefix)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_OWNER", -1)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_UNIT_ID", -1)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_TYPE", -1)
    PPB_SetNumber(playerID, prefix .. "_ORIGINAL_AI", -1)
    PPB_SetString(playerID, prefix .. "_ORIGINAL_NAME", "")
    PPB_SetString(playerID, prefix .. "_ORIGINAL_PROMOTIONS", "")
end

local function IsCombatUnit(unit)
    if unit == nil or unit:IsDead() then return false end
    if unit.IsCombatUnit ~= nil and not unit:IsCombatUnit() then return false end
    return unit:GetBaseCombatStrength() > 0 or unit:GetBaseRangedCombatStrength() > 0
end

local function IsExcludedUnit(unit)
    if not IsCombatUnit(unit) then return true end
    local info = UnitInfo(unit)
    if info == nil or unit:GetDomainType() == DOMAIN_AIR then return true end
    if tonumber(info.Trade or 0) ~= 0 or tonumber(info.NukeDamageLevel or -1) >= 0
        or tonumber(info.Suicide or 0) ~= 0 or info.Special == "SPECIALUNIT_MISSILE" then return true end
    if unit.GetCargo ~= nil and unit:GetCargo() > 0 then return true end
    if PROMO_TEMP ~= nil and unit:IsHasPromotion(PROMO_TEMP) then return true end
    if PROMO_MAIN ~= nil and unit:IsHasPromotion(PROMO_MAIN) then return true end
    return false
end

local function PlotHasStackedUnit(target)
    local plot = target:GetPlot()
    if plot == nil then return true end
    for index = 0, plot:GetNumUnits() - 1 do
        local other = plot:GetUnit(index)
        if other ~= nil and not (other:GetOwner() == target:GetOwner() and other:GetID() == target:GetID()) then
            return true
        end
    end
    return false
end

local function TargetVisibleTo(player, target)
    local plot = target:GetPlot()
    if plot == nil or not plot:IsVisible(player:GetTeam(), false) then return false end
    if target.IsInvisible ~= nil then
        local ok, invisible = pcall(function() return target:IsInvisible(player:GetTeam(), false) end)
        if ok and invisible then return false end
    end
    return true
end

function PPB_TargetDistance(playerID, target)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) or target == nil or target:GetPlot() == nil then return 999 end
    local targetX, targetY = target:GetX(), target:GetY()
    local best = 999
    for city in player:Cities() do
        best = math.min(best, Map.PlotDistance(city:GetX(), city:GetY(), targetX, targetY))
    end
    for unit in player:Units() do
        if IsCombatUnit(unit) and unit:GetPlot() ~= nil then
            best = math.min(best, Map.PlotDistance(unit:GetX(), unit:GetY(), targetX, targetY))
        end
    end
    return best
end

function PPB_IsEligibleHost(playerID, target, range)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) or target == nil or target:GetOwner() == playerID
        or IsExcludedUnit(target) then return false end
    local owner = Players[target:GetOwner()]
    if owner == nil or not owner:IsAlive() or owner:IsBarbarian() then return false end
    local plot = target:GetPlot()
    if plot == nil or plot:IsCity() or PlotHasStackedUnit(target) then return false end
    if not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then return false end
    if not TargetVisibleTo(player, target) then return false end
    return PPB_TargetDistance(playerID, target) <= (tonumber(range) or 4)
end

local function DurationForClip(clipType)
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speedType = speed ~= nil and speed.Type or "GAMESPEED_STANDARD"
    if speedType == "GAMESPEED_QUICK" then return clipType == PPB_CLIP_MORE and 3 or 2 end
    if speedType == "GAMESPEED_EPIC" then return clipType == PPB_CLIP_MORE and 6 or 5 end
    if speedType == "GAMESPEED_MARATHON" then return clipType == PPB_CLIP_MORE and 12 or 9 end
    return clipType == PPB_CLIP_MORE and 4 or 3
end

local function BodyHopExtension()
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local speedType = speed ~= nil and speed.Type or "GAMESPEED_STANDARD"
    if speedType == "GAMESPEED_EPIC" then return 2 end
    if speedType == "GAMESPEED_MARATHON" then return 3 end
    return 1
end

local function ClearBodyHopPending(playerID)
    PPB_SetNumber(playerID, "BH_PENDING", 0)
    PPB_SetNumber(playerID, "BH_OWNER", -1)
    PPB_SetNumber(playerID, "BH_UNIT_ID", -1)
    PPB_SetNumber(playerID, "BH_TYPE", -1)
    PPB_SetNumber(playerID, "BH_AI", -1)
    PPB_SetNumber(playerID, "BH_X", -1)
    PPB_SetNumber(playerID, "BH_Y", -1)
    PPB_SetNumber(playerID, "BH_EXPERIENCE", 0)
    PPB_SetNumber(playerID, "BH_LEVEL", 1)
    PPB_SetNumber(playerID, "BH_DIRECTION", 0)
    PPB_SetString(playerID, "BH_NAME", "")
    PPB_SetString(playerID, "BH_DISPLAY_NAME", "")
    PPB_SetString(playerID, "BH_PROMOTIONS", "")
end

function PPB_ClearTemporary(playerID)
    PPB_SetNumber(playerID, "TEMP_ACTIVE", 0)
    PPB_SetNumber(playerID, "TEMP_UNIT_ID", -1)
    PPB_SetNumber(playerID, "TEMP_TURNS", 0)
    PPB_SetString(playerID, "TEMP_CLIP", "")
    PPB_SetNumber(playerID, "TEMP_BODY_HOP_USED", 0)
    ClearOriginal(playerID, "TEMP")
    ClearBodyHopPending(playerID)
end

function PPB_ClearMain(playerID)
    PPB_SetNumber(playerID, "MAIN_ACTIVE", 0)
    PPB_SetNumber(playerID, "MAIN_UNIT_ID", -1)
    PPB_SetNumber(playerID, "MAIN_EVOLUTION", 0)
    ClearOriginal(playerID, "MAIN")
end

local function NotifyPlayer(player, text)
    if player ~= nil and player:IsHuman() and Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage(text)
    end
end

function PPB_StartTemporary(playerID, clipIndex, targetOwnerID, targetUnitID)
    local player = Players[playerID]
    local clip = PPB_GetClip(playerID, clipIndex)
    local owner = Players[tonumber(targetOwnerID) or -1]
    local target = owner ~= nil and owner:GetUnitByID(tonumber(targetUnitID) or -1) or nil
    if not PPB_IsPlayer(player) or clip == nil or PPB_GetNumber(playerID, "TEMP_ACTIVE") == 1 then return false end
    local range = clip.type == PPB_CLIP_THEORY and 7 or 4
    if not PPB_IsEligibleHost(playerID, target, range) then return false end

    local originalOwnerID, originalUnitID = target:GetOwner(), target:GetID()
    local state = CaptureUnit(target)
    possessionTransfer = true
    target:Kill(false, playerID)
    local host = CreateUnit(player, state)
    possessionTransfer = false
    if host == nil then
        possessionTransfer = true
        if owner:IsAlive() then CreateUnit(owner, state) end
        possessionTransfer = false
        return false
    end

    PPB_SetNumber(playerID, "TEMP_ACTIVE", 1)
    PPB_SetNumber(playerID, "TEMP_UNIT_ID", host:GetID())
    PPB_SetNumber(playerID, "TEMP_TURNS", DurationForClip(clip.type))
    PPB_SetString(playerID, "TEMP_CLIP", clip.type)
    PPB_SetNumber(playerID, "TEMP_BODY_HOP_USED", 0)
    SaveOriginal(playerID, "TEMP", state, originalOwnerID, originalUnitID)
    ApplyRolePromotions(host, "TEMP", clip.type, 0)
    PPB_RemoveClip(playerID, clip.index)
    NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_TEMP_STARTED", host:GetName(), PPB_GetNumber(playerID, "TEMP_TURNS")))
    PPB_FireStateChanged(playerID)
    return true
end

function PPB_EndTemporary(playerID, reason)
    local player = Players[playerID]
    if player == nil or PPB_GetNumber(playerID, "TEMP_ACTIVE") ~= 1 then return false end
    local host = player:GetUnitByID(PPB_GetNumber(playerID, "TEMP_UNIT_ID", -1))
    local originalOwner = Players[PPB_GetNumber(playerID, "TEMP_ORIGINAL_OWNER", -1)]
    local returned = nil
    if host ~= nil then
        local state = OriginalReturnState(playerID, "TEMP", CaptureUnit(host))
        possessionTransfer = true
        host:Kill(false, -1)
        if originalOwner ~= nil and originalOwner:IsAlive() then returned = CreateUnit(originalOwner, state) end
        possessionTransfer = false
    end
    PPB_ClearTemporary(playerID)
    if reason ~= nil then NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_TEMP_ENDED", reason)) end
    PPB_FireStateChanged(playerID)
    return true, returned
end

local function MainClipPair(playerID, requestedIndex)
    local count = PPB_GetNumber(playerID, "CLIP_COUNT")
    if count < 2 then return nil, nil end
    local mainIndex = tonumber(requestedIndex)
    if mainIndex == nil or PPB_GetString(playerID, "CLIP_" .. mainIndex .. "_TYPE") ~= PPB_CLIP_MAIN_HOST then
        mainIndex = PPB_FindClip(playerID, PPB_CLIP_MAIN_HOST)
    end
    if mainIndex == nil then return nil, nil end
    local otherIndex = mainIndex == 1 and 2 or 1
    return mainIndex, otherIndex
end

function PPB_ReleaseMain(playerID, reason)
    local player = Players[playerID]
    if player == nil or PPB_GetNumber(playerID, "MAIN_ACTIVE") ~= 1 then return false end
    local host = player:GetUnitByID(PPB_GetNumber(playerID, "MAIN_UNIT_ID", -1))
    local originalOwner = Players[PPB_GetNumber(playerID, "MAIN_ORIGINAL_OWNER", -1)]
    if host ~= nil then
        local state = OriginalReturnState(playerID, "MAIN", CaptureUnit(host))
        possessionTransfer = true
        host:Kill(false, -1)
        if originalOwner ~= nil and originalOwner:IsAlive() then CreateUnit(originalOwner, state) end
        possessionTransfer = false
    end
    PPB_ClearMain(playerID)
    if reason ~= nil then NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_MAIN_RELEASED", reason)) end
    PPB_FireStateChanged(playerID)
    return true
end

function PPB_StartMain(playerID, mainClipIndex, targetOwnerID, targetUnitID)
    local player = Players[playerID]
    local owner = Players[tonumber(targetOwnerID) or -1]
    local target = owner ~= nil and owner:GetUnitByID(tonumber(targetUnitID) or -1) or nil
    local firstIndex, secondIndex = MainClipPair(playerID, mainClipIndex)
    if not PPB_IsPlayer(player) or firstIndex == nil or not PPB_IsEligibleHost(playerID, target, 4) then return false end

    local originalOwnerID, originalUnitID = target:GetOwner(), target:GetID()
    local state = CaptureUnit(target)
    possessionTransfer = true
    target:Kill(false, playerID)
    local newMain = CreateUnit(player, state)
    possessionTransfer = false
    if newMain == nil then
        possessionTransfer = true
        if owner:IsAlive() then CreateUnit(owner, state) end
        possessionTransfer = false
        return false
    end

    if PPB_GetNumber(playerID, "MAIN_ACTIVE") == 1 then
        PPB_ReleaseMain(playerID, L("TXT_KEY_PPB_REASON_NEW_MAIN"))
    end
    PPB_SetNumber(playerID, "MAIN_ACTIVE", 1)
    PPB_SetNumber(playerID, "MAIN_UNIT_ID", newMain:GetID())
    PPB_SetNumber(playerID, "MAIN_EVOLUTION", 0)
    SaveOriginal(playerID, "MAIN", state, originalOwnerID, originalUnitID)
    ApplyRolePromotions(newMain, "MAIN", nil, 0)

    local high, low = math.max(firstIndex, secondIndex), math.min(firstIndex, secondIndex)
    PPB_RemoveClip(playerID, high)
    PPB_RemoveClip(playerID, low)
    NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_MAIN_ESTABLISHED", newMain:GetName()))
    PPB_FireStateChanged(playerID)
    return true
end

function PPB_EvolveMain(playerID, mainClipIndex)
    local player = Players[playerID]
    local clip = PPB_GetClip(playerID, mainClipIndex)
    local evolution = PPB_GetNumber(playerID, "MAIN_EVOLUTION")
    if not PPB_IsPlayer(player) or PPB_GetNumber(playerID, "MAIN_ACTIVE") ~= 1
        or evolution >= 3 or clip == nil or clip.type ~= PPB_CLIP_MAIN_HOST then return false end
    local host = player:GetUnitByID(PPB_GetNumber(playerID, "MAIN_UNIT_ID", -1))
    if host == nil then PPB_ClearMain(playerID) return false end
    evolution = evolution + 1
    PPB_SetNumber(playerID, "MAIN_EVOLUTION", evolution)
    ApplyRolePromotions(host, "MAIN", nil, evolution)
    PPB_RemoveClip(playerID, clip.index)
    NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_MAIN_EVOLVED", host:GetName(), evolution))
    PPB_FireStateChanged(playerID)
    return true
end

local function IsProtectedHost(playerID, unitID)
    if PPB_GetNumber(playerID, "TEMP_ACTIVE") == 1
        and PPB_GetNumber(playerID, "TEMP_UNIT_ID") == unitID then return true end
    if PPB_GetNumber(playerID, "MAIN_ACTIVE") == 1
        and PPB_GetNumber(playerID, "MAIN_UNIT_ID") == unitID then return true end
    return false
end

local function ProtectedAnywhere(ownerID, unitID)
    for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
        if playerID == ownerID and IsProtectedHost(playerID, unitID) then return true end
    end
    return false
end

local function SaveBodyHopPending(playerID, killedOwnerID, killedUnitID, killedUnit)
    local state = CaptureUnit(killedUnit)
    PPB_SetNumber(playerID, "BH_PENDING", 1)
    PPB_SetNumber(playerID, "BH_OWNER", killedOwnerID)
    PPB_SetNumber(playerID, "BH_UNIT_ID", killedUnitID)
    PPB_SetNumber(playerID, "BH_TYPE", state.type)
    PPB_SetNumber(playerID, "BH_AI", state.ai)
    PPB_SetNumber(playerID, "BH_X", state.x)
    PPB_SetNumber(playerID, "BH_Y", state.y)
    PPB_SetNumber(playerID, "BH_EXPERIENCE", state.experience)
    PPB_SetNumber(playerID, "BH_LEVEL", state.level)
    PPB_SetNumber(playerID, "BH_DIRECTION", state.direction or 0)
    PPB_SetString(playerID, "BH_NAME", state.name or "")
    PPB_SetString(playerID, "BH_DISPLAY_NAME", killedUnit:GetName())
    PPB_SetString(playerID, "BH_PROMOTIONS", SerializePromotions(state.promotions))
end

local function ReadBodyHopPending(playerID)
    if PPB_GetNumber(playerID, "BH_PENDING") ~= 1 then return nil end
    return {
        owner = PPB_GetNumber(playerID, "BH_OWNER", -1),
        unitID = PPB_GetNumber(playerID, "BH_UNIT_ID", -1),
        type = PPB_GetNumber(playerID, "BH_TYPE", -1),
        ai = PPB_GetNumber(playerID, "BH_AI", -1),
        x = PPB_GetNumber(playerID, "BH_X", -1),
        y = PPB_GetNumber(playerID, "BH_Y", -1),
        damage = 50,
        experience = PPB_GetNumber(playerID, "BH_EXPERIENCE"),
        level = PPB_GetNumber(playerID, "BH_LEVEL", 1),
        moves = 0,
        direction = PPB_GetNumber(playerID, "BH_DIRECTION", 0),
        name = PPB_GetString(playerID, "BH_NAME"),
        displayName = PPB_GetString(playerID, "BH_DISPLAY_NAME"),
        promotions = ParsePromotions(PPB_GetString(playerID, "BH_PROMOTIONS"))
    }
end

function PPB_DeclineBodyHop(playerID)
    if PPB_GetNumber(playerID, "BH_PENDING") ~= 1 then return false end
    ClearBodyHopPending(playerID)
    PPB_FireStateChanged(playerID)
    return true
end

function PPB_AcceptBodyHop(playerID)
    local player = Players[playerID]
    local pending = ReadBodyHopPending(playerID)
    if not PPB_IsPlayer(player) or pending == nil
        or PPB_GetNumber(playerID, "TEMP_ACTIVE") ~= 1
        or PPB_GetString(playerID, "TEMP_CLIP") ~= PPB_CLIP_BODY_HOP
        or PPB_GetNumber(playerID, "TEMP_BODY_HOP_USED") == 1 then return false end
    local oldHost = player:GetUnitByID(PPB_GetNumber(playerID, "TEMP_UNIT_ID", -1))
    if oldHost == nil then PPB_ClearTemporary(playerID) PPB_FireStateChanged(playerID) return false end

    local turns = PPB_GetNumber(playerID, "TEMP_TURNS")
    local oldOwner = Players[PPB_GetNumber(playerID, "TEMP_ORIGINAL_OWNER", -1)]
    local oldReturn = OriginalReturnState(playerID, "TEMP", CaptureUnit(oldHost))
    possessionTransfer = true
    oldHost:Kill(false, -1)
    if oldOwner ~= nil and oldOwner:IsAlive() then CreateUnit(oldOwner, oldReturn) end
    local newHost = CreateUnit(player, pending)
    possessionTransfer = false

    if newHost == nil then
        PPB_ClearTemporary(playerID)
        PPB_FireStateChanged(playerID)
        return false
    end
    PPB_SetNumber(playerID, "TEMP_UNIT_ID", newHost:GetID())
    PPB_SetNumber(playerID, "TEMP_TURNS", turns + BodyHopExtension())
    PPB_SetNumber(playerID, "TEMP_BODY_HOP_USED", 1)
    SaveOriginal(playerID, "TEMP", pending, pending.owner, pending.unitID)
    ApplyRolePromotions(newHost, "TEMP", PPB_CLIP_BODY_HOP, 0)
    ClearBodyHopPending(playerID)
    NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_BODY_HOP", newHost:GetName(), PPB_GetNumber(playerID, "TEMP_TURNS")))
    PPB_FireStateChanged(playerID)
    return true
end

local function BattleContains(playerID, unitID)
    if currentBattle == nil then return false end
    for _, participant in ipairs(currentBattle.units) do
        if not participant.isCity and participant.playerID == playerID and participant.objectID == unitID then return true end
    end
    return false
end

local function BodyHopKillEligible(playerID, killedOwnerID, killedUnitID, killedUnit, killerPlayerID)
    if killerPlayerID ~= playerID or PPB_GetNumber(playerID, "TEMP_ACTIVE") ~= 1
        or PPB_GetString(playerID, "TEMP_CLIP") ~= PPB_CLIP_BODY_HOP
        or PPB_GetNumber(playerID, "TEMP_BODY_HOP_USED") == 1
        or PPB_GetNumber(playerID, "BH_PENDING") == 1 or IsExcludedUnit(killedUnit) then return false end
    local killedOwner = Players[killedOwnerID]
    if killedOwner == nil or killedOwner:IsBarbarian() then return false end
    local tempID = PPB_GetNumber(playerID, "TEMP_UNIT_ID", -1)
    if currentBattle ~= nil then
        return BattleContains(playerID, tempID) and BattleContains(killedOwnerID, killedUnitID)
    end
    local player = Players[playerID]
    local host = player ~= nil and player:GetUnitByID(tempID) or nil
    if host ~= nil and host.IsFighting ~= nil then
        local ok, fighting = pcall(function() return host:IsFighting() end)
        return ok and fighting
    end
    return false
end

local function HostScore(unit)
    if unit == nil then return 0 end
    local strength = math.max(unit:GetBaseCombatStrength(), unit:GetBaseRangedCombatStrength())
    local healthFactor = math.max(0.1, (100 - unit:GetDamage()) / 100)
    local experienceFactor = 1 + math.min(2, unit:GetExperience() / 100)
    local info = UnitInfo(unit)
    local strategic = 1
    if info ~= nil and tonumber(info.RangedCombat or 0) > 0 then strategic = strategic + 0.15 end
    if info ~= nil and tonumber(info.Range or 0) >= 2 then strategic = strategic + 0.10 end
    return strength * healthFactor * experienceFactor * strategic
end

local function PendingScore(pending)
    if pending == nil then return 0 end
    local info = GameInfo.Units[pending.type]
    if info == nil then return 0 end
    local strength = math.max(tonumber(info.Combat) or 0, tonumber(info.RangedCombat) or 0)
    return strength * 0.5 * (1 + math.min(2, (pending.experience or 0) / 100))
end

local function ProcessBodyHopPending(playerID)
    local player = Players[playerID]
    local pending = ReadBodyHopPending(playerID)
    if not PPB_IsPlayer(player) or pending == nil then return end
    if player:IsHuman() then
        PPB_FireStateChanged(playerID)
    else
        local current = player:GetUnitByID(PPB_GetNumber(playerID, "TEMP_UNIT_ID", -1))
        if PendingScore(pending) >= HostScore(current) * 0.75 then PPB_AcceptBodyHop(playerID)
        else PPB_DeclineBodyHop(playerID) end
    end
end

function PPB_GetBestTarget(playerID, range)
    local best, bestScore = nil, -1
    for otherID = 0, (GameDefines.MAX_CIV_PLAYERS or 64) - 1 do
        local other = Players[otherID]
        if other ~= nil and other:IsAlive() and otherID ~= playerID and not other:IsBarbarian() then
            for unit in other:Units() do
                if PPB_IsEligibleHost(playerID, unit, range) then
                    local score = HostScore(unit)
                    if score > bestScore then best, bestScore = unit, score end
                end
            end
        end
    end
    return best
end

local function ValidateHosts(playerID)
    local player = Players[playerID]
    if player == nil then return end
    if PPB_GetNumber(playerID, "MAIN_ACTIVE") == 1 then
        local main = player:GetUnitByID(PPB_GetNumber(playerID, "MAIN_UNIT_ID", -1))
        if main == nil then PPB_ClearMain(playerID)
        else ApplyRolePromotions(main, "MAIN", nil, PPB_GetNumber(playerID, "MAIN_EVOLUTION")) end
    end
    if PPB_GetNumber(playerID, "TEMP_ACTIVE") == 1 then
        local temp = player:GetUnitByID(PPB_GetNumber(playerID, "TEMP_UNIT_ID", -1))
        if temp == nil then PPB_ClearTemporary(playerID)
        else ApplyRolePromotions(temp, "TEMP", PPB_GetString(playerID, "TEMP_CLIP"), 0) end
    end
end

local function AIUseClips(playerID)
    local player = Players[playerID]
    if player == nil or player:IsHuman() then return end

    if PPB_GetNumber(playerID, "MAIN_ACTIVE") == 1 and PPB_GetNumber(playerID, "MAIN_EVOLUTION") < 3 then
        local mainClip = PPB_FindClip(playerID, PPB_CLIP_MAIN_HOST)
        if mainClip ~= nil then PPB_EvolveMain(playerID, mainClip) end
    end

    if PPB_GetNumber(playerID, "MAIN_ACTIVE") == 0
        and PPB_GetNumber(playerID, "CLIP_COUNT") >= 2 then
        local mainClip = PPB_FindClip(playerID, PPB_CLIP_MAIN_HOST)
        if mainClip ~= nil then
            local target = PPB_GetBestTarget(playerID, 4)
            if target ~= nil then PPB_StartMain(playerID, mainClip, target:GetOwner(), target:GetID()) end
        end
    end

    if PPB_GetNumber(playerID, "TEMP_ACTIVE") == 0 then
        local clipIndex = nil
        for i = 1, PPB_GetNumber(playerID, "CLIP_COUNT") do
            if PPB_GetString(playerID, "CLIP_" .. i .. "_TYPE") ~= PPB_CLIP_MAIN_HOST then clipIndex = i break end
        end
        if clipIndex == nil and PPB_GetNumber(playerID, "CLIP_COUNT") > 0 then clipIndex = 1 end
        if clipIndex ~= nil then
            local clip = PPB_GetClip(playerID, clipIndex)
            local range = clip ~= nil and clip.type == PPB_CLIP_THEORY and 7 or 4
            local target = PPB_GetBestTarget(playerID, range)
            if target ~= nil then PPB_StartTemporary(playerID, clipIndex, target:GetOwner(), target:GetID()) end
        end
    end
end

function PPB_PossessionDoTurn(playerID)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) then return end
    ValidateHosts(playerID)
    if PPB_GetNumber(playerID, "TEMP_ACTIVE") == 1 then
        local owner = Players[PPB_GetNumber(playerID, "TEMP_ORIGINAL_OWNER", -1)]
        if owner ~= nil and owner:IsAlive() and not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then
            PPB_EndTemporary(playerID, L("TXT_KEY_PPB_REASON_PEACE"))
        elseif PPB_GetNumber(playerID, "BH_PENDING") ~= 1 then
            local turns = PPB_GetNumber(playerID, "TEMP_TURNS") - 1
            PPB_SetNumber(playerID, "TEMP_TURNS", turns)
            if turns <= 0 then PPB_EndTemporary(playerID, L("TXT_KEY_PPB_REASON_EXPIRED")) end
        end
    end
    ProcessBodyHopPending(playerID)
    AIUseClips(playerID)
    PPB_FireStateChanged(playerID)
end

-- CP battle participants correlate a killed unit to the actual temporary host.
if GameEvents.BattleStarted ~= nil then
    GameEvents.BattleStarted.Add(function(battleType, x, y)
        currentBattle = { battleType = battleType, x = x, y = y, units = {} }
    end)
end

if GameEvents.BattleJoined ~= nil then
    GameEvents.BattleJoined.Add(function(playerID, objectID, role, isCity)
        if currentBattle == nil then currentBattle = { units = {} } end
        currentBattle.units[#currentBattle.units + 1] = {
            playerID = playerID, objectID = objectID, role = role, isCity = isCity == true
        }
    end)
end

if GameEvents.BattleFinished ~= nil then
    GameEvents.BattleFinished.Add(function()
        currentBattle = nil
        for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
            if PPB_GetNumber(playerID, "BH_PENDING") == 1 then ProcessBodyHopPending(playerID) end
        end
    end)
end

if GameEvents.UnitPrekill ~= nil then
    GameEvents.UnitPrekill.Add(function(killedPlayerID, killedUnitID, _, _, _, _, killerPlayerID)
        if possessionTransfer then return end
        local killedPlayer = Players[killedPlayerID]
        local killedUnit = killedPlayer ~= nil and killedPlayer:GetUnitByID(killedUnitID) or nil

        if killedUnit ~= nil then
            for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
                if BodyHopKillEligible(playerID, killedPlayerID, killedUnitID, killedUnit, killerPlayerID) then
                    SaveBodyHopPending(playerID, killedPlayerID, killedUnitID, killedUnit)
                    if PPB_QueueDeferred ~= nil then
                        local deferredPlayerID = playerID
                        PPB_QueueDeferred(function() ProcessBodyHopPending(deferredPlayerID) end)
                    end
                    break
                end
            end
        end

        if IsProtectedHost(killedPlayerID, killedUnitID) then
            local player = Players[killedPlayerID]
            if PPB_GetNumber(killedPlayerID, "TEMP_ACTIVE") == 1
                and PPB_GetNumber(killedPlayerID, "TEMP_UNIT_ID") == killedUnitID then
                PPB_ClearTemporary(killedPlayerID)
                NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_TEMP_KILLED"))
            end
            if PPB_GetNumber(killedPlayerID, "MAIN_ACTIVE") == 1
                and PPB_GetNumber(killedPlayerID, "MAIN_UNIT_ID") == killedUnitID then
                PPB_ClearMain(killedPlayerID)
                NotifyPlayer(player, L("TXT_KEY_PPB_ALERT_MAIN_KILLED"))
            end
            PPB_FireStateChanged(killedPlayerID)
        end
    end)
end

if GameEvents.PlayerCanGiftUnit ~= nil then
    GameEvents.PlayerCanGiftUnit.Add(function(playerID, _, unitID)
        return not ProtectedAnywhere(playerID, unitID)
    end)
end

if GameEvents.PlayerCanDoCommand ~= nil then
    GameEvents.PlayerCanDoCommand.Add(function(playerID, unitID, commandID)
        if not ProtectedAnywhere(playerID, unitID) then return true end
        if CommandTypes ~= nil and (commandID == CommandTypes.COMMAND_DELETE
            or commandID == CommandTypes.COMMAND_UPGRADE
            or commandID == CommandTypes.COMMAND_GIFT) then return false end
        return true
    end)
end

if GameEvents.CanHaveAnyUpgrade ~= nil then
    GameEvents.CanHaveAnyUpgrade.Add(function(playerID, unitID)
        return not ProtectedAnywhere(playerID, unitID)
    end)
end

if GameEvents.CanHaveUpgrade ~= nil then
    GameEvents.CanHaveUpgrade.Add(function(playerID, unitID)
        return not ProtectedAnywhere(playerID, unitID)
    end)
end

if GameEvents.UnitConverted ~= nil then
    GameEvents.UnitConverted.Add(function(oldPlayerID, _, oldUnitID)
        return not ProtectedAnywhere(oldPlayerID, oldUnitID)
    end)
end

if LuaEvents.PPB_TemporaryRequest ~= nil then
    LuaEvents.PPB_TemporaryRequest.Add(function(playerID, clipIndex, targetOwnerID, targetUnitID)
        PPB_StartTemporary(playerID, clipIndex, targetOwnerID, targetUnitID)
    end)
end
if LuaEvents.PPB_MainRequest ~= nil then
    LuaEvents.PPB_MainRequest.Add(function(playerID, clipIndex, targetOwnerID, targetUnitID)
        PPB_StartMain(playerID, clipIndex, targetOwnerID, targetUnitID)
    end)
end
if LuaEvents.PPB_EvolveRequest ~= nil then
    LuaEvents.PPB_EvolveRequest.Add(function(playerID, clipIndex) PPB_EvolveMain(playerID, clipIndex) end)
end
if LuaEvents.PPB_ReleaseMainRequest ~= nil then
    LuaEvents.PPB_ReleaseMainRequest.Add(function(playerID)
        PPB_ReleaseMain(playerID, L("TXT_KEY_PPB_REASON_VOLUNTARY"))
    end)
end
if LuaEvents.PPB_BodyHopChoice ~= nil then
    LuaEvents.PPB_BodyHopChoice.Add(function(playerID, accept)
        if accept then PPB_AcceptBodyHop(playerID) else PPB_DeclineBodyHop(playerID) end
    end)
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    if PPB_IsPlayer(Players[playerID]) then ValidateHosts(playerID) end
end

print("PPB: possession, Main Host, Body-Hop and AI host systems initialized")
