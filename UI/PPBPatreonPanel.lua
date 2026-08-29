-- ===========================================================================
-- Patreon Possession Browser - human-facing creator feed and host controls
-- This context intentionally reads only persisted state. Gameplay requests are
-- revalidated by PPBCore.lua and PPBPossession.lua before changing game state.
-- ===========================================================================

include("InstanceManager")
include("PPBPosts.lua")

local SAVE = Modding.OpenSaveData()
local CIV_PPB = GameInfoTypes.CIVILIZATION_PPB_POSSESSION_BROWSERS
local UNIT_REGULAR = GameInfoTypes.UNIT_PPB_PATREON_REGULAR
local BUILDING_PREMIUM = GameInfoTypes.BUILDING_PPB_PREMIUM_SUBSCRIPTION
local PROMO_TEMP = GameInfoTypes.PROMOTION_PPB_TEMP_HOST
local PROMO_MAIN = GameInfoTypes.PROMOTION_PPB_MAIN_HOST
local DOMAIN_AIR = GameInfoTypes.DOMAIN_AIR

local postInstances = InstanceManager:new("PPBPostInstance", "PostCard", Controls.PostStack)
local clipInstances = InstanceManager:new("PPBClipInstance", "ClipCard", Controls.ClipStack)
local targetInstances = InstanceManager:new("PPBTargetInstance", "TargetCard", Controls.TargetStack)

local selectedTab = "FEED"
local selectedClipIndex = nil
local panelOpen = false
local cityScreenOpen = false

local function L(key, ...)
    if Locale ~= nil and Locale.ConvertTextKey ~= nil then
        return Locale.ConvertTextKey(key, ...)
    end
    return tostring(key)
end

local function Key(playerID, suffix)
    return "PPB_" .. tostring(playerID) .. "_" .. tostring(suffix)
end

local function GetNumber(playerID, suffix, defaultValue)
    local value = tonumber(SAVE.GetValue(Key(playerID, suffix)))
    if value == nil then return tonumber(defaultValue) or 0 end
    return value
end

local function GetString(playerID, suffix, defaultValue)
    local value = SAVE.GetValue(Key(playerID, suffix))
    if value == nil then return defaultValue or "" end
    return tostring(value)
end

local function ActivePlayer()
    local playerID = Game.GetActivePlayer()
    return playerID, Players[playerID]
end

local function IsActivePPB()
    local _, player = ActivePlayer()
    return player ~= nil and player:IsAlive() and CIV_PPB ~= nil
        and player:GetCivilizationType() == CIV_PPB
end

local function HasPremium(player)
    if player == nil or BUILDING_PREMIUM == nil then return false end
    for city in player:Cities() do
        if city:GetNumBuilding(BUILDING_PREMIUM) > 0 then return true end
    end
    return false
end

local function ClipCap(player)
    return HasPremium(player) and 4 or 3
end

local function RefreshInterval(player)
    local standardTurns = HasPremium(player) and 9 or 12
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local percent = speed ~= nil and tonumber(speed.TrainPercent) or 100
    return math.max(1, math.floor((standardTurns * percent / 100) + 0.5))
end

local function RefreshStack(stack, scroll)
    stack:CalculateSize()
    stack:ReprocessAnchoring()
    scroll:CalculateInternalSize()
    scroll:ReprocessAnchoring()
end

local function FindRegular(player)
    if player == nil or UNIT_REGULAR == nil then return nil end
    for unit in player:Units() do
        if unit:GetUnitType() == UNIT_REGULAR then return unit end
    end
    return nil
end

local function GetClip(playerID, index)
    local count = GetNumber(playerID, "CLIP_COUNT")
    index = tonumber(index) or 0
    if index < 1 or index > count then return nil end
    return {
        index = index,
        type = GetString(playerID, "CLIP_" .. index .. "_TYPE"),
        post = GetNumber(playerID, "CLIP_" .. index .. "_POST"),
        turn = GetNumber(playerID, "CLIP_" .. index .. "_TURN"),
        serial = GetNumber(playerID, "CLIP_" .. index .. "_SERIAL")
    }
end

local function SetTab(tab)
    selectedTab = tab
    Controls.FeedPanel:SetHide(tab ~= "FEED")
    Controls.ClipsPanel:SetHide(tab ~= "CLIPS")
    Controls.HostPanel:SetHide(tab ~= "HOST")
end

local function RebuildFeed(playerID, player)
    postInstances:ResetInstances()
    local postCount = GetNumber(playerID, "POST_COUNT")
    local clipCount = GetNumber(playerID, "CLIP_COUNT")
    local cap = ClipCap(player)

    for postIndex = postCount, 1, -1 do
        local template = PPB_GetPostTemplate(GetNumber(playerID, "POST_" .. postIndex .. "_TEMPLATE"))
        if template ~= nil then
            local card = postInstances:GetInstance()
            local postTurn = GetNumber(playerID, "POST_" .. postIndex .. "_TURN")
            local commentIndex = GetNumber(playerID, "POST_" .. postIndex .. "_COMMENT")
            local essay = GetNumber(playerID, "POST_" .. postIndex .. "_ESSAY") == 1
            local requiredSpace = essay and 2 or 1

            card.PostTitle:SetText(L(template.titleKey))
            card.PostMeta:SetText(L("TXT_KEY_PPB_UI_POST_META", postTurn,
                template.likes or 0, template.comments or 0))
            card.PostText:SetText(L(template.textKey))
            card.NegativeText:SetHide(template.negativeKey == nil)
            if template.negativeKey ~= nil then card.NegativeText:SetText(L(template.negativeKey)) end

            card.CommentedText:SetHide(commentIndex == 0)
            if commentIndex > 0 and template.choices[commentIndex] ~= nil then
                card.CommentedText:SetText(L("TXT_KEY_PPB_UI_COMMENTED",
                    L(template.choices[commentIndex].quoteKey)))
            end

            for choiceIndex = 1, 3 do
                local button = card["Comment" .. choiceIndex]
                local choice = template.choices[choiceIndex]
                button:SetHide(commentIndex > 0 or choice == nil)
                if choice ~= nil then
                    local clip = PPB_GetClipData(choice.clipType)
                    local full = clipCount + requiredSpace > cap
                    button:SetDisabled(full)
                    button:SetText(L(choice.labelKey))
                    button:SetToolTipString(L(choice.quoteKey) .. "[NEWLINE][NEWLINE]" ..
                        (clip ~= nil and L(clip.helpKey) or ""))
                    local capturedPost = postIndex
                    local capturedChoice = choiceIndex
                    button:RegisterCallback(Mouse.eLClick, function()
                        LuaEvents.PPB_CommentRequest(playerID, capturedPost, capturedChoice)
                    end)
                end
            end
        end
    end

    RefreshStack(Controls.PostStack, Controls.PostScroll)
    if clipCount >= cap then
        Controls.FeedStatus:SetText(L("TXT_KEY_PPB_UI_CLIP_FULL"))
    else
        Controls.FeedStatus:SetText("")
    end

    local regular = FindRegular(player)
    local essayDisabled = regular == nil or clipCount + 2 > cap
    Controls.EssayButton:SetDisabled(essayDisabled)
    Controls.EssayButton:SetText(L("TXT_KEY_PPB_UI_ESSAY"))
    if regular == nil then
        Controls.EssayButton:SetToolTipString(L("TXT_KEY_PPB_UI_ESSAY_NONE"))
    elseif clipCount + 2 > cap then
        Controls.EssayButton:SetToolTipString(L("TXT_KEY_PPB_UI_ESSAY_NEEDS_SPACE"))
    else
        Controls.EssayButton:SetToolTipString(L("TXT_KEY_UNIT_PPB_PATREON_REGULAR_HELP"))
    end
end

local function UnitInfo(unit)
    return unit ~= nil and GameInfo.Units[unit:GetUnitType()] or nil
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

local function TargetDistance(player, target)
    if player == nil or target == nil or target:GetPlot() == nil then return 999 end
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

local function IsEligibleTarget(playerID, player, target, range)
    if player == nil or target == nil or target:GetOwner() == playerID or IsExcludedUnit(target) then return false end
    local owner = Players[target:GetOwner()]
    if owner == nil or not owner:IsAlive() or owner:IsBarbarian() then return false end
    local plot = target:GetPlot()
    if plot == nil or plot:IsCity() or PlotHasStackedUnit(target) then return false end
    if not Teams[player:GetTeam()]:IsAtWar(owner:GetTeam()) then return false end
    if not TargetVisibleTo(player, target) then return false end
    return TargetDistance(player, target) <= range
end

local function PromotionCount(unit)
    local count = 0
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then count = count + 1 end
    end
    return count
end

local function TargetStrength(unit)
    return math.max(unit:GetBaseCombatStrength(), unit:GetBaseRangedCombatStrength())
end

local function RebuildTargets(playerID, player)
    targetInstances:ResetInstances()
    local clip = selectedClipIndex ~= nil and GetClip(playerID, selectedClipIndex) or nil
    if clip == nil then
        selectedClipIndex = nil
        Controls.NoTargetsLabel:SetHide(false)
        Controls.NoTargetsLabel:SetText(L("TXT_KEY_PPB_UI_SELECT_CLIP_FIRST"))
        RefreshStack(Controls.TargetStack, Controls.TargetScroll)
        return
    end

    local theory = clip.type == PPB_CLIP_THEORY
    local range = theory and 7 or 4
    local targets = {}
    for otherID = 0, (GameDefines.MAX_CIV_PLAYERS or 64) - 1 do
        local other = Players[otherID]
        if other ~= nil and other:IsAlive() and otherID ~= playerID and not other:IsBarbarian() then
            for unit in other:Units() do
                if IsEligibleTarget(playerID, player, unit, range) then
                    targets[#targets + 1] = {
                        unit = unit,
                        ownerID = otherID,
                        unitID = unit:GetID(),
                        distance = TargetDistance(player, unit),
                        strength = TargetStrength(unit)
                    }
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.strength ~= b.strength then return a.strength > b.strength end
        if a.ownerID ~= b.ownerID then return a.ownerID < b.ownerID end
        return a.unitID < b.unitID
    end)

    local clipCount = GetNumber(playerID, "CLIP_COUNT")
    local mainActive = GetNumber(playerID, "MAIN_ACTIVE") == 1
    for _, target in ipairs(targets) do
        local unit = target.unit
        local owner = Players[target.ownerID]
        local card = targetInstances:GetInstance()
        local ownerName = owner ~= nil and owner:GetName() or "?"
        if theory then
            local moves = math.floor((unit:GetMoves() / (GameDefines.MOVE_DENOMINATOR or 60)) * 10 + 0.5) / 10
            card.TargetText:SetText(L("TXT_KEY_PPB_UI_TARGET_THEORY", unit:GetName(), ownerName,
                target.strength, 100 - unit:GetDamage(), moves, unit:GetExperience(),
                PromotionCount(unit), target.distance))
        else
            card.TargetText:SetText(L("TXT_KEY_PPB_UI_TARGET_BASIC", unit:GetName(), ownerName,
                target.strength, target.distance))
        end

        local capturedOwner = target.ownerID
        local capturedUnit = target.unitID
        local capturedClip = clip.index
        card.PossessButton:SetText(L("TXT_KEY_PPB_UI_POSSESS"))
        card.PossessButton:RegisterCallback(Mouse.eLClick, function()
            LuaEvents.PPB_TemporaryRequest(playerID, capturedClip, capturedOwner, capturedUnit)
        end)

        local canMakeMain = clip.type == PPB_CLIP_MAIN_HOST and clipCount >= 2
        card.MainButton:SetHide(not canMakeMain)
        card.MainButton:SetText(L(mainActive and "TXT_KEY_PPB_UI_REPLACE_MAIN" or "TXT_KEY_PPB_UI_MAKE_MAIN"))
        card.MainButton:RegisterCallback(Mouse.eLClick, function()
            LuaEvents.PPB_MainRequest(playerID, capturedClip, capturedOwner, capturedUnit)
        end)
    end

    Controls.NoTargetsLabel:SetHide(#targets > 0)
    if #targets == 0 then Controls.NoTargetsLabel:SetText(L("TXT_KEY_PPB_UI_NO_TARGETS")) end
    RefreshStack(Controls.TargetStack, Controls.TargetScroll)
end

local function RebuildClips(playerID, player)
    clipInstances:ResetInstances()
    local count = GetNumber(playerID, "CLIP_COUNT")
    local cap = ClipCap(player)
    Controls.ClipHeader:SetText(L("TXT_KEY_PPB_UI_CLIP_HEADER", count, cap))
    Controls.NoClipsLabel:SetHide(count > 0)
    Controls.NoClipsLabel:SetText(L("TXT_KEY_PPB_UI_NO_CLIPS"))

    if selectedClipIndex ~= nil and selectedClipIndex > count then selectedClipIndex = nil end
    for index = 1, count do
        local clip = GetClip(playerID, index)
        local data = clip ~= nil and PPB_GetClipData(clip.type) or nil
        if clip ~= nil and data ~= nil then
            local card = clipInstances:GetInstance()
            card.ClipTitle:SetText((data.icon or "") .. " " .. L(data.nameKey))
            card.ClipSource:SetText(L("TXT_KEY_PPB_UI_CLIP_SOURCE", clip.post, clip.turn))
            card.SelectClip:SetText(index == selectedClipIndex and L("TXT_KEY_PPB_UI_SELECTED")
                or L("TXT_KEY_PPB_UI_USE_CLIP"))
            local capturedIndex = index
            card.SelectClip:RegisterCallback(Mouse.eLClick, function()
                selectedClipIndex = capturedIndex
                RebuildClips(playerID, player)
            end)
        end
    end
    RefreshStack(Controls.ClipStack, Controls.ClipScroll)
    RebuildTargets(playerID, player)
end

local function RebuildHost(playerID, player)
    local mainActive = GetNumber(playerID, "MAIN_ACTIVE") == 1
    local main = mainActive and player:GetUnitByID(GetNumber(playerID, "MAIN_UNIT_ID", -1)) or nil
    if main ~= nil then
        local evolution = GetNumber(playerID, "MAIN_EVOLUTION")
        local originalOwner = Players[GetNumber(playerID, "MAIN_ORIGINAL_OWNER", -1)]
        local originalName = originalOwner ~= nil and originalOwner:GetName() or L("TXT_KEY_PPB_UI_UNKNOWN_OWNER")
        Controls.MainHostStatus:SetText(L("TXT_KEY_PPB_UI_MAIN_STATUS", main:GetName(), originalName,
            evolution, 10 + (5 * evolution)))
        Controls.ReleaseButton:SetDisabled(false)

        local mainClip = nil
        for index = 1, GetNumber(playerID, "CLIP_COUNT") do
            if GetString(playerID, "CLIP_" .. index .. "_TYPE") == PPB_CLIP_MAIN_HOST then
                mainClip = index
                break
            end
        end
        Controls.EvolveButton:SetDisabled(mainClip == nil or evolution >= 3)
        if evolution >= 3 then
            Controls.EvolveButton:SetToolTipString(L("TXT_KEY_PPB_UI_EVOLVE_MAX"))
        elseif mainClip == nil then
            Controls.EvolveButton:SetToolTipString(L("TXT_KEY_PPB_UI_EVOLVE_NO_CLIP"))
        else
            Controls.EvolveButton:SetToolTipString("")
        end
        Controls.EvolveButton:RegisterCallback(Mouse.eLClick, function()
            if mainClip ~= nil then LuaEvents.PPB_EvolveRequest(playerID, mainClip) end
        end)
    else
        Controls.MainHostStatus:SetText(L("TXT_KEY_PPB_UI_MAIN_NONE"))
        Controls.EvolveButton:SetDisabled(true)
        Controls.EvolveButton:SetToolTipString(L("TXT_KEY_PPB_UI_MAIN_NONE"))
        Controls.ReleaseButton:SetDisabled(true)
    end

    if GetNumber(playerID, "TEMP_ACTIVE") == 1 then
        local temp = player:GetUnitByID(GetNumber(playerID, "TEMP_UNIT_ID", -1))
        local tempName = temp ~= nil and temp:GetName() or L("TXT_KEY_PPB_UI_UNKNOWN_HOST")
        Controls.TemporaryStatus:SetText(L("TXT_KEY_PPB_UI_TEMP_STATUS", tempName,
            GetNumber(playerID, "TEMP_TURNS")))
    else
        Controls.TemporaryStatus:SetText(L("TXT_KEY_PPB_UI_TEMP_NONE"))
    end
end

local function RebuildBodyHop(playerID, player)
    local pending = GetNumber(playerID, "BH_PENDING") == 1
    Controls.BodyHopPopup:SetHide(not pending)
    if not pending then return end
    local current = player:GetUnitByID(GetNumber(playerID, "TEMP_UNIT_ID", -1))
    local currentName = current ~= nil and current:GetName() or L("TXT_KEY_PPB_UI_UNKNOWN_HOST")
    local newName = GetString(playerID, "BH_DISPLAY_NAME", L("TXT_KEY_PPB_UI_UNKNOWN_HOST"))
    Controls.BodyHopText:SetText(L("TXT_KEY_PPB_UI_BODY_HOP_TEXT", currentName, newName))
end

local function RebuildAll()
    local playerID, player = ActivePlayer()
    local active = IsActivePPB()
    Controls.PatreonButton:SetHide(not active or cityScreenOpen)
    if not active then
        panelOpen = false
        Controls.Panel:SetHide(true)
        Controls.BodyHopPopup:SetHide(true)
        return
    end

    local clipCount = GetNumber(playerID, "CLIP_COUNT")
    local cap = ClipCap(player)
    local unread = 0
    for index = 1, GetNumber(playerID, "POST_COUNT") do
        if GetNumber(playerID, "POST_" .. index .. "_COMMENT") == 0 then unread = unread + 1 end
    end
    Controls.PatreonButton:SetText(L("TXT_KEY_PPB_UI_BUTTON") .. (unread > 0
        and " [COLOR_NEGATIVE_TEXT](" .. tostring(unread) .. ")[ENDCOLOR]" or ""))

    local nextTurn = GetNumber(playerID, "NEXT_POST_TURN", Game.GetGameTurn() + RefreshInterval(player))
    Controls.NextPostLabel:SetText(L("TXT_KEY_PPB_UI_NEXT_POST", math.max(0, nextTurn - Game.GetGameTurn())))
    RebuildFeed(playerID, player)
    RebuildClips(playerID, player)
    RebuildHost(playerID, player)
    RebuildBodyHop(playerID, player)
    SetTab(selectedTab)
    Controls.Panel:SetHide(not panelOpen or cityScreenOpen)
end

local function ClosePanel()
    panelOpen = false
    Controls.Panel:SetHide(true)
end

local function TogglePanel()
    if not IsActivePPB() or cityScreenOpen then return end
    panelOpen = not panelOpen
    RebuildAll()
end

Controls.Title:SetText(L("TXT_KEY_PPB_UI_TITLE"))
Controls.Subtitle:SetText(L("TXT_KEY_PPB_UI_SUBTITLE"))
Controls.FeedTab:SetText(L("TXT_KEY_PPB_UI_FEED_TAB"))
Controls.ClipsTab:SetText(L("TXT_KEY_PPB_UI_CLIPS_TAB"))
Controls.HostTab:SetText(L("TXT_KEY_PPB_UI_HOST_TAB"))
Controls.TargetHeader:SetText(L("TXT_KEY_PPB_UI_TARGET_HEADER"))
Controls.MainHostTitle:SetText(L("TXT_KEY_PPB_UI_HOST_TAB"))
Controls.RefreshButton:SetText(L("TXT_KEY_PPB_UI_REFRESH"))
Controls.CloseButton:SetText(L("TXT_KEY_PPB_UI_CLOSE"))
Controls.EvolveButton:SetText(L("TXT_KEY_PPB_UI_EVOLVE"))
Controls.ReleaseButton:SetText(L("TXT_KEY_PPB_UI_RELEASE"))
Controls.BodyHopTitle:SetText(L("TXT_KEY_PPB_UI_BODY_HOP_TITLE"))
Controls.BodyHopStay:SetText(L("TXT_KEY_PPB_UI_BODY_HOP_STAY"))
Controls.BodyHopAccept:SetText(L("TXT_KEY_PPB_UI_BODY_HOP_ACCEPT"))

Controls.PatreonButton:RegisterCallback(Mouse.eLClick, TogglePanel)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, ClosePanel)
Controls.RefreshButton:RegisterCallback(Mouse.eLClick, RebuildAll)
Controls.FeedTab:RegisterCallback(Mouse.eLClick, function() SetTab("FEED") end)
Controls.ClipsTab:RegisterCallback(Mouse.eLClick, function() SetTab("CLIPS") end)
Controls.HostTab:RegisterCallback(Mouse.eLClick, function() SetTab("HOST") end)
Controls.EssayButton:RegisterCallback(Mouse.eLClick, function()
    local playerID, player = ActivePlayer()
    local regular = FindRegular(player)
    if regular ~= nil then LuaEvents.PPB_EssayRequest(playerID, regular:GetID()) end
end)
Controls.ReleaseButton:RegisterCallback(Mouse.eLClick, function()
    LuaEvents.PPB_ReleaseMainRequest(Game.GetActivePlayer())
end)
Controls.BodyHopStay:RegisterCallback(Mouse.eLClick, function()
    LuaEvents.PPB_BodyHopChoice(Game.GetActivePlayer(), false)
end)
Controls.BodyHopAccept:RegisterCallback(Mouse.eLClick, function()
    LuaEvents.PPB_BodyHopChoice(Game.GetActivePlayer(), true)
end)

ContextPtr:SetInputHandler(function(uiMsg, wParam)
    if uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE then
        if not Controls.BodyHopPopup:IsHidden() then return true end
        if panelOpen then ClosePanel() return true end
    end
    return false
end)

if Events.SerialEventEnterCityScreen ~= nil then
    Events.SerialEventEnterCityScreen.Add(function()
        cityScreenOpen = true
        Controls.PatreonButton:SetHide(true)
        Controls.Panel:SetHide(true)
    end)
end
if Events.SerialEventExitCityScreen ~= nil then
    Events.SerialEventExitCityScreen.Add(function()
        cityScreenOpen = false
        RebuildAll()
    end)
end
if Events.GameplaySetActivePlayer ~= nil then
    Events.GameplaySetActivePlayer.Add(function()
        selectedClipIndex = nil
        panelOpen = false
        RebuildAll()
    end)
end
if Events.ActivePlayerTurnStart ~= nil then Events.ActivePlayerTurnStart.Add(RebuildAll) end
if Events.SerialEventUnitCreated ~= nil then Events.SerialEventUnitCreated.Add(RebuildAll) end
if Events.SerialEventUnitDestroyed ~= nil then Events.SerialEventUnitDestroyed.Add(RebuildAll) end
if LuaEvents.PPB_StateChanged ~= nil then
    LuaEvents.PPB_StateChanged.Add(function(playerID)
        if playerID == Game.GetActivePlayer() then RebuildAll() end
    end)
end

RebuildAll()
