--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                           ACQ HUB                                 ║
    ║                Universal Script Hub Loader                        ║
    ║                                                                   ║
    ║  Loadstring:                                                      ║
    ║  loadstring(game:HttpGet("https://raw.githubusercontent.com/      ║
    ║    zay-aan/acqhub/main/loader.lua"))()                            ║
    ╚═══════════════════════════════════════════════════════════════════╝
]]

local HUB_NAME = "acq hub"
local HUB_VERSION = "1.0.0"

-- GitHub Repository Configuration
local REPO_CONFIG = {
    Owner = "zay-aan",
    Repo = "acqhub",
    Branch = "main",
}

local BASE_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    REPO_CONFIG.Owner,
    REPO_CONFIG.Repo,
    REPO_CONFIG.Branch
)

-- Service references
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Central Notification Dispatcher
local function Notify(title, message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = string.format("[%s] %s", HUB_NAME, title),
            Text = message,
            Duration = duration or 5,
        })
    end)
    print(string.format("[%s] %s: %s", HUB_NAME, title, message))
end

-- Supported Games Manifest
-- Key: PlaceId or UniverseId
-- Value: Path to dedicated game script inside /games
local SUPPORTED_GAMES = {
    -- Fortune Fighters
    [16212191055] = "games/fortune_fighters.lua",
    
    -- Universal / Testing fallback or additional PlaceIds
    -- [PLACE_ID] = "games/<game_file>.lua",
}

-- Game identification
local currentPlaceId = game.PlaceId
local currentUniverseId = game.GameId

local scriptPath = SUPPORTED_GAMES[currentPlaceId] or SUPPORTED_GAMES[currentUniverseId]

if not scriptPath then
    local placeName = "Unknown Game"
    pcall(function()
        local MarketplaceService = game:GetService("MarketplaceService")
        local productInfo = MarketplaceService:GetProductInfo(currentPlaceId)
        if productInfo and productInfo.Name then
            placeName = productInfo.Name
        end
    end)

    Notify("Unsupported Game", string.format("%s (ID: %d) is not currently supported.", placeName, currentPlaceId), 8)
    warn(string.format("[%s] Game is unsupported! PlaceId: %d | UniverseId: %d", HUB_NAME, currentPlaceId, currentUniverseId))
    return
end

-- Construct target URL
local scriptUrl = BASE_URL .. scriptPath

Notify("Loading", "Fetching game module...", 3)

local fetchSuccess, scriptContent = pcall(function()
    return game:HttpGet(scriptUrl)
end)

if not fetchSuccess or not scriptContent or #scriptContent == 0 then
    Notify("Load Error", "Failed to download game script from GitHub.", 6)
    warn(string.format("[%s] Failed to fetch script from: %s", HUB_NAME, scriptUrl))
    return
end

local loadSuccess, loadError = pcall(function()
    local executable = loadstring(scriptContent)
    if typeof(executable) == "function" then
        executable()
    else
        error("Downloaded content is not valid Luau executable code")
    end
end)

if not loadSuccess then
    Notify("Execution Error", "An error occurred while launching the game script.", 6)
    warn(string.format("[%s] Script execution failed: %s", HUB_NAME, tostring(loadError)))
else
    Notify("Ready", "Hub loaded successfully!", 3)
end
