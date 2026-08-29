-- ===========================================================================
-- Patreon Possession Browser - persistent feed, clips, writers and AI comments
-- ===========================================================================

print("PPB: PPBCore.lua loading")

PPB_SAVE = Modding.OpenSaveData()
PPB_CIV = GameInfoTypes.CIVILIZATION_PPB_POSSESSION_BROWSERS
PPB_UNIT_REGULAR = GameInfoTypes.UNIT_PPB_PATREON_REGULAR
PPB_UNIT_WRITER = GameInfoTypes.UNIT_WRITER
PPB_BUILDING_PREMIUM = GameInfoTypes.BUILDING_PPB_PREMIUM_SUBSCRIPTION

local writerTransfer = false

local function L(key, ...)
    if Locale ~= nil and Locale.ConvertTextKey ~= nil then
        return Locale.ConvertTextKey(key, ...)
    end
    return tostring(key)
end

function PPB_Key(playerID, suffix)
    return "PPB_" .. tostring(playerID) .. "_" .. tostring(suffix)
end

function PPB_GetNumber(playerID, suffix, defaultValue)
    local value = tonumber(PPB_SAVE.GetValue(PPB_Key(playerID, suffix)))
    if value == nil then return tonumber(defaultValue) or 0 end
    return value
end

function PPB_SetNumber(playerID, suffix, value)
    PPB_SAVE.SetValue(PPB_Key(playerID, suffix), tonumber(value) or 0)
end

function PPB_GetString(playerID, suffix, defaultValue)
    local value = PPB_SAVE.GetValue(PPB_Key(playerID, suffix))
    if value == nil then return defaultValue or "" end
    return tostring(value)
end

function PPB_SetString(playerID, suffix, value)
    PPB_SAVE.SetValue(PPB_Key(playerID, suffix), tostring(value or ""))
end

function PPB_IsPlayer(player)
    return player ~= nil and player:IsAlive() and PPB_CIV ~= nil
        and player:GetCivilizationType() == PPB_CIV
end

function PPB_IsTransferActive()
    return writerTransfer == true or (PPB_IsPossessionTransfer ~= nil and PPB_IsPossessionTransfer())
end

function PPB_HasPremium(player)
    if not PPB_IsPlayer(player) or PPB_BUILDING_PREMIUM == nil then return false end
    for city in player:Cities() do
        if city:GetNumBuilding(PPB_BUILDING_PREMIUM) > 0 then return true end
    end
    return false
end

function PPB_GetClipCap(player)
    return PPB_HasPremium(player) and 4 or 3
end

function PPB_GetRefreshInterval(player)
    local standardTurns = PPB_HasPremium(player) and 9 or 12
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local percent = speed ~= nil and tonumber(speed.TrainPercent) or 100
    return math.max(1, math.floor((standardTurns * percent / 100) + 0.5))
end

local function ScaledCulture(player, base)
    local speed = GameInfo.GameSpeeds[Game.GetGameSpeedType()]
    local percent = speed ~= nil and tonumber(speed.CulturePercent) or 100
    local era = math.max(0, math.min(7, player:GetCurrentEra()))
    return math.max(1, math.floor(((base + era * 5) * percent / 100) + 0.5))
end

local function Notify(player, titleKey, bodyKey, ...)
    if player == nil or not player:IsHuman() then return end
    local title = L(titleKey)
    local body = L(bodyKey, ...)
    if player.AddNotification ~= nil and NotificationTypes ~= nil
        and NotificationTypes.NOTIFICATION_GENERIC ~= nil then
        local ok = pcall(function()
            player:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, body, title, -1, -1)
        end)
        if ok then return end
    end
    if Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage(title .. ": " .. body)
    end
end

function PPB_FireStateChanged(playerID)
    if LuaEvents ~= nil and LuaEvents.PPB_StateChanged ~= nil then
        LuaEvents.PPB_StateChanged(playerID)
    end
end

function PPB_GetClip(playerID, index)
    local count = PPB_GetNumber(playerID, "CLIP_COUNT")
    index = tonumber(index) or 0
    if index < 1 or index > count then return nil end
    return {
        index = index,
        type = PPB_GetString(playerID, "CLIP_" .. index .. "_TYPE"),
        post = PPB_GetNumber(playerID, "CLIP_" .. index .. "_POST"),
        turn = PPB_GetNumber(playerID, "CLIP_" .. index .. "_TURN"),
        serial = PPB_GetNumber(playerID, "CLIP_" .. index .. "_SERIAL")
    }
end

function PPB_AddClip(playerID, clipType, sourcePost)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) or PPB_GetClipData(clipType) == nil then return false end
    local count = PPB_GetNumber(playerID, "CLIP_COUNT")
    if count >= PPB_GetClipCap(player) then return false end

    local index = count + 1
    local serial = PPB_GetNumber(playerID, "CLIP_SERIAL") + 1
    PPB_SetNumber(playerID, "CLIP_SERIAL", serial)
    PPB_SetString(playerID, "CLIP_" .. index .. "_TYPE", clipType)
    PPB_SetNumber(playerID, "CLIP_" .. index .. "_POST", sourcePost)
    PPB_SetNumber(playerID, "CLIP_" .. index .. "_TURN", Game.GetGameTurn())
    PPB_SetNumber(playerID, "CLIP_" .. index .. "_SERIAL", serial)
    PPB_SetNumber(playerID, "CLIP_COUNT", index)
    return true
end

function PPB_RemoveClip(playerID, index)
    local count = PPB_GetNumber(playerID, "CLIP_COUNT")
    index = tonumber(index) or 0
    if index < 1 or index > count then return false end
    for i = index, count - 1 do
        PPB_SetString(playerID, "CLIP_" .. i .. "_TYPE", PPB_GetString(playerID, "CLIP_" .. (i + 1) .. "_TYPE"))
        PPB_SetNumber(playerID, "CLIP_" .. i .. "_POST", PPB_GetNumber(playerID, "CLIP_" .. (i + 1) .. "_POST"))
        PPB_SetNumber(playerID, "CLIP_" .. i .. "_TURN", PPB_GetNumber(playerID, "CLIP_" .. (i + 1) .. "_TURN"))
        PPB_SetNumber(playerID, "CLIP_" .. i .. "_SERIAL", PPB_GetNumber(playerID, "CLIP_" .. (i + 1) .. "_SERIAL"))
    end
    PPB_SetString(playerID, "CLIP_" .. count .. "_TYPE", "")
    PPB_SetNumber(playerID, "CLIP_" .. count .. "_POST", 0)
    PPB_SetNumber(playerID, "CLIP_" .. count .. "_TURN", 0)
    PPB_SetNumber(playerID, "CLIP_" .. count .. "_SERIAL", 0)
    PPB_SetNumber(playerID, "CLIP_COUNT", count - 1)
    return true
end

function PPB_FindClip(playerID, clipType)
    for i = 1, PPB_GetNumber(playerID, "CLIP_COUNT") do
        if PPB_GetString(playerID, "CLIP_" .. i .. "_TYPE") == clipType then return i end
    end
    return nil
end

function PPB_AddPost(playerID, essayPost)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) or #PPBPosts == 0 then return false end
    local count = PPB_GetNumber(playerID, "POST_COUNT") + 1
    local templateID = ((count - 1) % #PPBPosts) + 1
    PPB_SetNumber(playerID, "POST_COUNT", count)
    PPB_SetNumber(playerID, "POST_" .. count .. "_TEMPLATE", templateID)
    PPB_SetNumber(playerID, "POST_" .. count .. "_TURN", Game.GetGameTurn())
    PPB_SetNumber(playerID, "POST_" .. count .. "_COMMENT", 0)
    PPB_SetNumber(playerID, "POST_" .. count .. "_ESSAY", essayPost and 1 or 0)
    if not essayPost then
        PPB_SetNumber(playerID, "NEXT_POST_TURN", Game.GetGameTurn() + PPB_GetRefreshInterval(player))
    end

    local template = PPB_GetPostTemplate(templateID)
    if template ~= nil then
        Notify(player, "TXT_KEY_PPB_NOTIFICATION_NEW_POST_TITLE",
            "TXT_KEY_PPB_NOTIFICATION_NEW_POST_BODY", L(template.titleKey))
    end
    PPB_FireStateChanged(playerID)
    return true
end

function PPB_EnsureInitialized(playerID)
    local player = Players[playerID]
    if not PPB_IsPlayer(player) or PPB_GetNumber(playerID, "INITIALIZED") == 1 then return end
    PPB_SetNumber(playerID, "INITIALIZED", 1)
    PPB_SetNumber(playerID, "CLIP_COUNT", 0)
    PPB_SetNumber(playerID, "POST_COUNT", 0)
    PPB_SetNumber(playerID, "PREMIUM_STATE", PPB_HasPremium(player) and 1 or 0)
    PPB_AddPost(playerID, false)
    print("PPB: initialized player " .. tostring(playerID))
end

local function RewardLoyalComment(player)
    local culture = ScaledCulture(player, 15)
    local goldenAge = math.max(2, 2 + math.max(0, math.min(7, player:GetCurrentEra())))
    if player.ChangeJONSCulture ~= nil then player:ChangeJONSCulture(culture) end
    if player.ChangeGoldenAgeProgressMeter ~= nil then player:ChangeGoldenAgeProgressMeter(goldenAge) end
    if player:IsHuman() and Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage(L("TXT_KEY_PPB_LOYAL_REWARD", culture, goldenAge))
    end
end

function PPB_CommentOnPost(playerID, postIndex, choiceIndex)
    local player = Players[playerID]
    postIndex, choiceIndex = tonumber(postIndex) or 0, tonumber(choiceIndex) or 0
    if not PPB_IsPlayer(player) or postIndex < 1
        or postIndex > PPB_GetNumber(playerID, "POST_COUNT")
        or PPB_GetNumber(playerID, "POST_" .. postIndex .. "_COMMENT") ~= 0 then return false end

    local templateID = PPB_GetNumber(playerID, "POST_" .. postIndex .. "_TEMPLATE")
    local template = PPB_GetPostTemplate(templateID)
    local choice = template ~= nil and template.choices[choiceIndex] or nil
    if choice == nil or PPB_GetClipData(choice.clipType) == nil then return false end

    local bonus = PPB_GetNumber(playerID, "POST_" .. postIndex .. "_ESSAY") == 1 and 1 or 0
    local requiredSpace = 1 + bonus
    local count = PPB_GetNumber(playerID, "CLIP_COUNT")
    if count + requiredSpace > PPB_GetClipCap(player) then return false end

    PPB_SetNumber(playerID, "POST_" .. postIndex .. "_COMMENT", choiceIndex)
    if not PPB_AddClip(playerID, choice.clipType, postIndex) then
        PPB_SetNumber(playerID, "POST_" .. postIndex .. "_COMMENT", 0)
        return false
    end
    if bonus == 1 then PPB_AddClip(playerID, choice.clipType, postIndex) end
    if choice.clipType == PPB_CLIP_LOYAL then RewardLoyalComment(player) end
    PPB_FireStateChanged(playerID)
    return true
end

local function CaptureWriter(unit)
    local state = {
        x = unit:GetX(), y = unit:GetY(), ai = unit:GetUnitAIType(),
        damage = unit:GetDamage(), experience = unit:GetExperience(),
        level = unit:GetLevel(), moves = unit:GetMoves(), promotions = {}
    }
    if unit.HasName ~= nil and unit:HasName() then state.name = unit:GetNameNoDesc() end
    if unit.GetFacingDirection ~= nil then state.direction = unit:GetFacingDirection() end
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then
            state.promotions[#state.promotions + 1] = promotion.ID
        end
    end
    return state
end

local function RestoreWriter(unit, state)
    if unit == nil then return nil end
    local wanted = {}
    for _, promotionID in ipairs(state.promotions or {}) do wanted[promotionID] = true end
    for promotion in GameInfo.UnitPromotions() do
        unit:SetHasPromotion(promotion.ID, wanted[promotion.ID] == true)
    end
    unit:SetDamage(state.damage or 0)
    if unit.SetExperience ~= nil then unit:SetExperience(state.experience or 0)
    elseif (state.experience or 0) > 0 then unit:ChangeExperience(state.experience) end
    if unit.SetLevel ~= nil then unit:SetLevel(math.max(1, state.level or 1)) end
    if state.name ~= nil and state.name ~= "" then unit:SetName(state.name) end
    if unit.SetMoves ~= nil then unit:SetMoves(state.moves or 0) end
    if unit.JumpToNearestValidPlot ~= nil then pcall(function() unit:JumpToNearestValidPlot() end) end
    return unit
end

local function ReplaceWriter(player, unit, newType)
    if player == nil or unit == nil or newType == nil then return nil end
    local state = CaptureWriter(unit)
    writerTransfer = true
    unit:Kill(false, -1)
    local replacement = player:InitUnit(newType, state.x, state.y, state.ai, state.direction)
    writerTransfer = false
    if replacement == nil then return nil end
    return RestoreWriter(replacement, state)
end

function PPB_NormalizeWriters(playerID, onlyUnitID)
    if writerTransfer then return end
    local player = Players[playerID]
    if player == nil or not player:IsAlive() then return end
    local wantsRegular = PPB_IsPlayer(player)
    local pending = {}
    for unit in player:Units() do
        if onlyUnitID == nil or unit:GetID() == onlyUnitID then
            if wantsRegular and unit:GetUnitType() == PPB_UNIT_WRITER then
                pending[#pending + 1] = { unit = unit, newType = PPB_UNIT_REGULAR }
            elseif not wantsRegular and unit:GetUnitType() == PPB_UNIT_REGULAR then
                pending[#pending + 1] = { unit = unit, newType = PPB_UNIT_WRITER }
            end
        end
    end
    for _, change in ipairs(pending) do ReplaceWriter(player, change.unit, change.newType) end
end

function PPB_UseEssay(playerID, unitID)
    local player = Players[playerID]
    local unit = player ~= nil and player:GetUnitByID(tonumber(unitID) or -1) or nil
    if not PPB_IsPlayer(player) or unit == nil or unit:GetUnitType() ~= PPB_UNIT_REGULAR then return false end
    if PPB_GetNumber(playerID, "CLIP_COUNT") + 2 > PPB_GetClipCap(player) then return false end
    writerTransfer = true
    unit:Kill(false, playerID)
    writerTransfer = false
    local culture = ScaledCulture(player, 20)
    if player.ChangeJONSCulture ~= nil then player:ChangeJONSCulture(culture) end
    PPB_AddPost(playerID, true)
    if player:IsHuman() and Events.GameplayAlertMessage ~= nil then
        Events.GameplayAlertMessage(L("TXT_KEY_PPB_ESSAY_REWARD", culture))
    end
    return true
end

local function AICommentWeight(playerID, clipType)
    local weights = {
        [PPB_CLIP_MAIN_HOST] = 30,
        [PPB_CLIP_MORE] = 25,
        [PPB_CLIP_BODY_HOP] = 20,
        [PPB_CLIP_THEORY] = 15,
        [PPB_CLIP_LOYAL] = 10
    }
    local weight = weights[clipType] or 1
    if clipType == PPB_CLIP_MAIN_HOST and PPB_GetNumber(playerID, "MAIN_ACTIVE") == 1 then
        if PPB_GetNumber(playerID, "MAIN_EVOLUTION") < 3 then weight = weight + 70
        else weight = math.max(5, weight - 20) end
    end
    return weight
end

local function ProcessAIComments(playerID)
    local player = Players[playerID]
    if player == nil or player:IsHuman() then return end
    local postCount = PPB_GetNumber(playerID, "POST_COUNT")
    for postIndex = 1, postCount do
        if PPB_GetNumber(playerID, "POST_" .. postIndex .. "_COMMENT") == 0 then
            local bonus = PPB_GetNumber(playerID, "POST_" .. postIndex .. "_ESSAY") == 1 and 1 or 0
            if PPB_GetNumber(playerID, "CLIP_COUNT") + 1 + bonus <= PPB_GetClipCap(player) then
                local template = PPB_GetPostTemplate(PPB_GetNumber(playerID, "POST_" .. postIndex .. "_TEMPLATE"))
                if template ~= nil then
                    local total = 0
                    local choiceWeights = {}
                    for i, choice in ipairs(template.choices) do
                        local weight = AICommentWeight(playerID, choice.clipType)
                        choiceWeights[i] = weight
                        total = total + weight
                    end
                    local roll = Game.Rand(math.max(1, total), "PPB AI comment")
                    local selected = 1
                    for i, weight in ipairs(choiceWeights) do
                        if roll < weight then selected = i break end
                        roll = roll - weight
                    end
                    PPB_CommentOnPost(playerID, postIndex, selected)
                end
            end
        end
    end
end

local function ProcessAIRegular(playerID)
    local player = Players[playerID]
    if player == nil or player:IsHuman()
        or PPB_GetNumber(playerID, "CLIP_COUNT") + 2 > PPB_GetClipCap(player) then return end
    for unit in player:Units() do
        if unit:GetUnitType() == PPB_UNIT_REGULAR then
            PPB_UseEssay(playerID, unit:GetID())
            return
        end
    end
end

local function CoreDoTurn(playerID)
    local player = Players[playerID]
    if player == nil or not player:IsAlive() then return end
    PPB_NormalizeWriters(playerID)
    if not PPB_IsPlayer(player) then return end
    PPB_EnsureInitialized(playerID)

    local premiumState = PPB_HasPremium(player) and 1 or 0
    local previousPremiumState = PPB_GetNumber(playerID, "PREMIUM_STATE", premiumState)
    if premiumState ~= previousPremiumState then
        -- Gaining Premium should affect the current wait as well as future posts.
        -- Losing it never pushes an already announced post farther away.
        if premiumState == 1 then
            local acceleratedTurn = Game.GetGameTurn() + PPB_GetRefreshInterval(player)
            PPB_SetNumber(playerID, "NEXT_POST_TURN",
                math.min(PPB_GetNumber(playerID, "NEXT_POST_TURN", acceleratedTurn), acceleratedTurn))
        end
        PPB_SetNumber(playerID, "PREMIUM_STATE", premiumState)
    end

    if Game.GetGameTurn() >= PPB_GetNumber(playerID, "NEXT_POST_TURN", Game.GetGameTurn() + 1) then
        PPB_AddPost(playerID, false)
    end
    ProcessAIComments(playerID)
    ProcessAIRegular(playerID)
    ProcessAIComments(playerID)
    if PPB_PossessionDoTurn ~= nil then PPB_PossessionDoTurn(playerID) end
end

GameEvents.PlayerDoTurn.Add(CoreDoTurn)

if GameEvents.UnitCreated ~= nil then
    GameEvents.UnitCreated.Add(function(playerID, unitID)
        if writerTransfer then return end
        if PPB_QueueDeferred ~= nil then
            PPB_QueueDeferred(function() PPB_NormalizeWriters(playerID, unitID) end)
        else
            PPB_NormalizeWriters(playerID, unitID)
        end
    end)
end

if LuaEvents.PPB_CommentRequest ~= nil then
    LuaEvents.PPB_CommentRequest.Add(function(playerID, postIndex, choiceIndex)
        PPB_CommentOnPost(playerID, postIndex, choiceIndex)
    end)
end

if LuaEvents.PPB_EssayRequest ~= nil then
    LuaEvents.PPB_EssayRequest.Add(function(playerID, unitID)
        PPB_UseEssay(playerID, unitID)
    end)
end

for playerID = 0, (GameDefines.MAX_MAJOR_CIVS or 22) - 1 do
    local player = Players[playerID]
    if PPB_IsPlayer(player) then PPB_EnsureInitialized(playerID) end
end

print("PPB: feed, clip and Patreon Regular systems initialized")
