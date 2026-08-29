-- Gameplay loader and one-frame deferred task queue.
print("PPB: loader starting")

local deferred = {}
local updateCallbacks = {}

function PPB_QueueDeferred(callback)
    if type(callback) ~= "function" then return false end
    deferred[#deferred + 1] = { frames = 1, callback = callback }
    return true
end

function PPB_RegisterUpdate(callback)
    if type(callback) ~= "function" then return false end
    updateCallbacks[#updateCallbacks + 1] = callback
    return true
end

if ContextPtr ~= nil and ContextPtr.SetUpdate ~= nil then
    ContextPtr:SetUpdate(function(deltaTime)
        local ready = {}
        for index = #deferred, 1, -1 do
            local task = deferred[index]
            task.frames = task.frames - 1
            if task.frames <= 0 then
                ready[#ready + 1] = task.callback
                table.remove(deferred, index)
            end
        end
        for _, callback in ipairs(ready) do
            local ok, err = pcall(callback)
            if not ok then print("PPB: deferred task failed: " .. tostring(err)) end
        end
        for _, callback in ipairs(updateCallbacks) do
            local ok, err = pcall(callback, deltaTime)
            if not ok then print("PPB: update callback failed: " .. tostring(err)) end
        end
    end)
else
    print("PPB: warning - ContextPtr update queue unavailable")
end

local function SafeInclude(fileName)
    local ok, err = pcall(function() include(fileName) end)
    if ok then print("PPB: included " .. fileName)
    else print("PPB: failed to include " .. fileName .. ": " .. tostring(err)) end
end

SafeInclude("PPBPosts.lua")
SafeInclude("PPBCore.lua")
SafeInclude("PPBPossession.lua")

print("PPB: loader complete")
