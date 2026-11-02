--[[
    acq hub - Shared Core Library
    Reusable utilities for connection management, safe cleanup, and math/vector helpers.
]]

local Shared = {}

-- Service references
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

Shared.LocalPlayer = Players.LocalPlayer

-- Connection & Task Tracker for clean teardown and live-reload
function Shared.NewCleaner()
    local cleaner = {
        _connections = {},
        _tasks = {},
        _drawings = {},
        _instances = {},
    }

    function cleaner:Add(item)
        if typeof(item) == "RBXScriptConnection" then
            table.insert(self._connections, item)
        elseif typeof(item) == "thread" then
            table.insert(self._tasks, item)
        elseif typeof(item) == "Instance" then
            table.insert(self._instances, item)
        elseif typeof(item) == "table" and item.Remove then
            -- Drawing object
            table.insert(self._drawings, item)
        end
        return item
    end

    function cleaner:Clean()
        for _, conn in ipairs(self._connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self._connections)

        for _, th in ipairs(self._tasks) do
            pcall(function() task.cancel(th) end)
        end
        table.clear(self._tasks)

        for _, drawing in ipairs(self._drawings) do
            pcall(function() drawing:Remove() end)
        end
        table.clear(self._drawings)

        for _, inst in ipairs(self._instances) do
            pcall(function() inst:Destroy() end)
        end
        table.clear(self._instances)
    end

    return cleaner
end

-- Safe Player Character & RootPart Getter
function Shared.GetCharacter(player)
    player = player or Shared.LocalPlayer
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then
        return nil
    end
    return character, rootPart, humanoid
end

return Shared
