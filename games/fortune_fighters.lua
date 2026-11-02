--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                           ACQ HUB                                 ║
    ║                   Game Module: Fortune Fighters                   ║
    ║                   PlaceId: 16212191055                            ║
    ║                   UI: Fluent-Modded (StyearX)                     ║
    ╚═══════════════════════════════════════════════════════════════════╝
]]

-- 1. TEARDOWN PREVIOUS INSTANCE (LIVE-RELOAD SAFE)
if getgenv()._ACQ_HUB_CLEANUP then
    pcall(getgenv()._ACQ_HUB_CLEANUP)
    getgenv()._ACQ_HUB_CLEANUP = nil
end

local cleaner = {
    connections = {},
    tasks = {},
    drawings = {},
}

local function addConnection(conn)
    table.insert(cleaner.connections, conn)
    return conn
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- State Tracking
local state = {
    walkSpeed = 16,
    jumpPower = 50,
    speedEnabled = false,
    jumpEnabled = false,
    infJumpEnabled = false,
    noclipEnabled = false,
    fullbrightEnabled = false,
    originalBrightness = Lighting.Brightness,
    originalClockTime = Lighting.ClockTime,
    originalFogEnd = Lighting.FogEnd,
}

-- 2. LOAD FLUENT-MODDED (StyearX)
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/StyearX/Fluent-modded/main/dist/main.lua"))()

-- 3. CREATE WINDOW
local Window = Fluent:CreateWindow({
    Title = "acq hub",
    SubTitle = "Fortune Fighters",
    TabWidth = 150,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = true,
    Theme = "Dark",
    Search = true,
    MinimizeKey = Enum.KeyCode.LeftControl,
})

-- Teardown handler for live reload / hub close
local function fullCleanup()
    for _, conn in ipairs(cleaner.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(cleaner.connections)

    for _, th in ipairs(cleaner.tasks) do
        pcall(function() task.cancel(th) end)
    end
    table.clear(cleaner.tasks)

    for _, drawing in ipairs(cleaner.drawings) do
        pcall(function() drawing:Remove() end)
    end
    table.clear(cleaner.drawings)

    -- Reset player physics & lighting
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        Lighting.Brightness = state.originalBrightness
        Lighting.ClockTime = state.originalClockTime
        Lighting.FogEnd = state.originalFogEnd
    end)

    if Fluent and not Fluent.Unloaded then
        pcall(function() Fluent:Destroy() end)
    end
    print("[acq hub] Closed and cleaned.")
end

getgenv()._ACQ_HUB_CLEANUP = fullCleanup

-- 4. BUILD TABS
local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    World = Window:AddTab({ Title = "World", Icon = "globe" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- ==================== DASHBOARD TAB ====================
do
    Tabs.Main:AddParagraph({
        Title = "acq hub",
        Content = string.format("User: %s (@%s)\nGame: [🤠] Fortune Fighters\nPlace ID: %d", LocalPlayer.DisplayName, LocalPlayer.Name, game.PlaceId),
    })

    Tabs.Main:AddButton({
        Title = "Re-join Server",
        Description = "Quickly reconnect to this experience",
        Callback = function()
            local TeleportService = game:GetService("TeleportService")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end,
    })

    Tabs.Main:AddButton({
        Title = "Copy Place ID",
        Description = "Copy Place ID to clipboard",
        Callback = function()
            if setclipboard then
                setclipboard(tostring(game.PlaceId))
                Fluent:Notify({ Title = "acq hub", Content = "Place ID copied to clipboard!", Duration = 3 })
            end
        end,
    })
end

-- ==================== PLAYER TAB ====================
do
    -- WalkSpeed Slider & Toggle
    Tabs.Player:AddToggle("SpeedToggle", {
        Title = "Enable Custom WalkSpeed",
        Default = false,
        Callback = function(val)
            state.speedEnabled = val
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").WalkSpeed = val and state.walkSpeed or 16
            end
        end,
    })

    Tabs.Player:AddSlider("SpeedSlider", {
        Title = "WalkSpeed",
        Description = "Adjust character movement speed",
        Default = 16,
        Min = 16,
        Max = 150,
        Rounding = 0,
        Callback = function(val)
            state.walkSpeed = val
            if state.speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
            end
        end,
    })

    -- JumpPower Slider & Toggle
    Tabs.Player:AddToggle("JumpToggle", {
        Title = "Enable Custom JumpPower",
        Default = false,
        Callback = function(val)
            state.jumpEnabled = val
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").JumpPower = val and state.jumpPower or 50
            end
        end,
    })

    Tabs.Player:AddSlider("JumpSlider", {
        Title = "JumpPower",
        Description = "Adjust character jump height",
        Default = 50,
        Min = 50,
        Max = 300,
        Rounding = 0,
        Callback = function(val)
            state.jumpPower = val
            if state.jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
            end
        end,
    })

    -- Infinite Jump
    Tabs.Player:AddToggle("InfJump", {
        Title = "Infinite Jump",
        Description = "Allows jumping repeatedly in mid-air",
        Default = false,
        Callback = function(val)
            state.infJumpEnabled = val
        end,
    })

    addConnection(UserInputService.JumpRequest:Connect(function()
        if state.infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))

    -- Noclip
    Tabs.Player:AddToggle("NoclipToggle", {
        Title = "Noclip",
        Description = "Walk through walls and barriers",
        Default = false,
        Callback = function(val)
            state.noclipEnabled = val
        end,
    })

    addConnection(RunService.Stepped:Connect(function()
        if state.noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end))

    -- Reset Character
    Tabs.Player:AddButton({
        Title = "Reset Character",
        Description = "Respawn character",
        Callback = function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").Health = 0
            end
        end,
    })
end

-- ==================== VISUALS TAB ====================
do
    -- Fullbright
    Tabs.Visuals:AddToggle("Fullbright", {
        Title = "Fullbright",
        Description = "Illuminate the environment and remove shadows",
        Default = false,
        Callback = function(val)
            state.fullbrightEnabled = val
            if val then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = state.originalBrightness
                Lighting.ClockTime = state.originalClockTime
                Lighting.FogEnd = state.originalFogEnd
                Lighting.GlobalShadows = true
            end
        end,
    })

    -- FOV Slider
    Tabs.Visuals:AddSlider("FovSlider", {
        Title = "Field Of View (FOV)",
        Description = "Adjust camera view width",
        Default = 70,
        Min = 60,
        Max = 120,
        Rounding = 0,
        Callback = function(val)
            if Workspace.CurrentCamera then
                Workspace.CurrentCamera.FieldOfView = val
            end
        end,
    })
end

-- ==================== WORLD TAB ====================
do
    Tabs.World:AddParagraph({
        Title = "Navigation & Teleports",
        Content = "Quick travel points within the current game map.",
    })

    Tabs.World:AddButton({
        Title = "Teleport to Lobby Spawn",
        Description = "Instantly travel to the main Lobby",
        Callback = function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local lobby = Workspace:FindFirstChild("Lobby")
            if root and lobby then
                local target = lobby:FindFirstChild("Building") or lobby:FindFirstChildWhichIsA("BasePart")
                if target then
                    root.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                    Fluent:Notify({ Title = "acq hub", Content = "Teleported to Lobby!", Duration = 3 })
                end
            end
        end,
    })
end

-- ==================== SETTINGS TAB ====================
do
    -- Acrylic Blur Toggle
    Tabs.Settings:AddToggle("AcrylicToggle", {
        Title = "Acrylic Blur",
        Description = "Enable or disable background blur effect",
        Default = true,
        Callback = function(val)
            pcall(function() Fluent:ToggleAcrylic(val) end)
        end,
    })

    -- Transparency Toggle
    Tabs.Settings:AddToggle("TransparencyToggle", {
        Title = "Window Transparency",
        Description = "Enable translucent window backdrop",
        Default = true,
        Callback = function(val)
            pcall(function() Fluent:ToggleTransparency(val) end)
        end,
    })

    -- Theme Selector
    Tabs.Settings:AddDropdown("ThemeDropdown", {
        Title = "UI Theme",
        Description = "Choose a color scheme for the interface",
        Values = { "Dark", "Darker", "Aqua", "Amethyst", "Rose", "Light" },
        Default = "Dark",
        Callback = function(themeName)
            pcall(function() Fluent:SetTheme(themeName) end)
        end,
    })

    -- Minimize Keybind
    Tabs.Settings:AddKeybind("MinimizeKeybind", {
        Title = "Minimize Hub Keybind",
        Description = "Key used to show/hide the hub",
        Default = "LeftControl",
        Mode = "Toggle",
        Callback = function() end,
    })

    -- Hub Unload Button
    Tabs.Settings:AddButton({
        Title = "Unload acq hub",
        Description = "Safely close the hub and disconnect all listeners",
        Callback = function()
            fullCleanup()
        end,
    })
end

-- Select default tab & show load notification
Window:SelectTab(1)

Fluent:Notify({
    Title = "acq hub",
    Content = "Loaded successfully! Press LeftControl to toggle.",
    Duration = 5,
})

print("[acq hub] Fortune Fighters module loaded successfully with Fluent-modded.")
