--[[
    acq hub - [🤠] Fortune Fighters
    PlaceId: 16212191055
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Teardown of previous instance if re-executed or live-reloaded
if getgenv()._ACQ_HUB_CLEANUP then
    pcall(getgenv()._ACQ_HUB_CLEANUP)
    getgenv()._ACQ_HUB_CLEANUP = nil
end

local cleaner = {
    connections = {},
    tasks = {},
}

local function cleanup()
    for _, conn in ipairs(cleaner.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(cleaner.connections)

    for _, th in ipairs(cleaner.tasks) do
        pcall(function() task.cancel(th) end)
    end
    table.clear(cleaner.tasks)

    if getgenv()._ACQ_HUB_WINDOW and getgenv()._ACQ_HUB_WINDOW.Destroy then
        pcall(function() getgenv()._ACQ_HUB_WINDOW:Destroy() end)
    elseif getgenv()._ACQ_HUB_WINDOW and getgenv()._ACQ_HUB_WINDOW.Unload then
        pcall(function() getgenv()._ACQ_HUB_WINDOW:Unload() end)
    end
end

getgenv()._ACQ_HUB_CLEANUP = cleanup

print("[acq hub] Loaded fortune_fighters module. Awaiting UI library selection to build GUI.")
