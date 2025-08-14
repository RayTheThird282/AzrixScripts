-- // SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Multiplayer = Workspace:WaitForChild("Multiplayer")

-- // SETTINGS
_G.AutoFarm = true -- AutoFarm ON by default

-- // VARIABLES
local CurrentMap = nil
local PressedButtons = {}
local LastSafeButtonCFrame = nil

-- // DEFAULT DELAYS & ATTEMPTS
local RescueDelay = 2
local TeleportDelay = 0.07
local ExitTeleportDelay = 0.03
local MaxButtonAttempts = 5
local ExitTeleportAttempts = 10
local RandomizeButtonTeleport = false
local StuckDetectorEnabled = true

-- // Fluent UI Library Setup
local Fluent = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if success and result then
    Fluent = result
else
    warn("Failed to load Fluent UI library: " .. tostring(result))
    Fluent = {
        CreateWindow = function(params)
            return {
                AddTab = function() return { AddSection = function() end, AddToggle = function() end, AddSlider = function() end, AddButton = function() end, AddParagraph = function() end } end,
                SelectTab = function() end,
                Notify = function(params) warn(params.Title .. ": " .. params.Content) end,
                ScreenGui = Instance.new("ScreenGui")
            }
        end,
        Options = {}
    }
end

local Options = Fluent.Options

-- Fallback settings storage (in-memory)
local Settings = {
    AutoFarm = _G.AutoFarm,
    RescueDelay = RescueDelay,
    TeleportDelay = TeleportDelay,
    MaxButtonAttempts = MaxButtonAttempts,
    RandomButtonTeleport = RandomizeButtonTeleport,
    ExitTeleportAttempts = ExitTeleportAttempts,
    ExitTeleportDelay = ExitTeleportDelay,
    StuckDetector = StuckDetectorEnabled
}

-- Create Window with Amethyst (violet) theme
local Window = Fluent:CreateWindow({
    Title = "Azrix | Flood Escape 2",
    SubTitle = "AutoFarm",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Amethyst", -- Violet/purple theme
    MinimizeKey = Enum.KeyCode.Insert
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Beta = Window:AddTab({ Title = "Beta", Icon = "info" })
}

-- AutoFarm Settings Section (Main Tab)
Tabs.Main:AddSection("AutoFarm Settings")

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Enable AutoFarm",
    Description = "Toggles the AutoFarm functionality",
    Default = Settings.AutoFarm,
    Callback = function(state)
        local success, err = pcall(function()
            _G.AutoFarm = state
            Settings.AutoFarm = state
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("AutoFarm", state)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update AutoFarm setting: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddSlider("RescueDelaySlider", {
    Title = "Rescue Delay",
    Description = "Time to wait after rescuing (seconds)",
    Default = Settings.RescueDelay,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        local success, err = pcall(function()
            RescueDelay = value
            Settings.RescueDelay = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("RescueDelay", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Rescue Delay: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddSlider("TeleportDelaySlider", {
    Title = "Button Teleport Delay",
    Description = "Delay between button teleports (seconds)",
    Default = Settings.TeleportDelay,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        local success, err = pcall(function()
            TeleportDelay = value
            Settings.TeleportDelay = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("TeleportDelay", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Teleport Delay: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddSlider("MaxButtonAttemptsSlider", {
    Title = "Max Button Teleports",
    Description = "Maximum teleport attempts per button",
    Default = Settings.MaxButtonAttempts,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(value)
        local success, err = pcall(function()
            MaxButtonAttempts = value
            Settings.MaxButtonAttempts = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("MaxButtonAttempts", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Max Button Attempts: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddToggle("RandomButtonTeleportToggle", {
    Title = "Randomize Button Teleport",
    Description = "Randomize teleport delay for buttons",
    Default = Settings.RandomButtonTeleport,
    Callback = function(state)
        local success, err = pcall(function()
            RandomizeButtonTeleport = state
            Settings.RandomButtonTeleport = state
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("RandomButtonTeleport", state)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Random Button Teleport: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- Map & Exit Enhancements Section (Main Tab)
Tabs.Main:AddSection("Map & Exit Enhancements")

Tabs.Main:AddSlider("ExitTeleportAttemptsSlider", {
    Title = "Exit Teleport Attempts",
    Description = "Number of teleport attempts to exit",
    Default = Settings.ExitTeleportAttempts,
    Min = 1,
    Max = 25,
    Rounding = 0,
    Callback = function(value)
        local success, err = pcall(function()
            ExitTeleportAttempts = value
            Settings.ExitTeleportAttempts = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("ExitTeleportAttempts", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Exit Teleport Attempts: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddSlider("ExitTeleportDelaySlider", {
    Title = "Exit Teleport Delay",
    Description = "Delay between exit teleports (seconds)",
    Default = Settings.ExitTeleportDelay,
    Min = 0.01,
    Max = 0.1,
    Rounding = 2,
    Callback = function(value)
        local success, err = pcall(function()
            ExitTeleportDelay = value
            Settings.ExitTeleportDelay = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("ExitTeleportDelay", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Exit Teleport Delay: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddToggle("StuckDetectorToggle", {
    Title = "Enable Stuck Detector",
    Description = "Detect and resolve stuck situations after 1 minute",
    Default = Settings.StuckDetector,
    Callback = function(state)
        local success, err = pcall(function()
            StuckDetectorEnabled = state
            Settings.StuckDetector = state
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("StuckDetector", state)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Stuck Detector setting: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- Discord Server Section (Main Tab)
Tabs.Main:AddSection("Discord Server")

Tabs.Main:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy the Discord invite link to clipboard",
    Callback = function()
        local success, err = pcall(function()
            setclipboard("https://discord.gg/Efx27AMSeX")
            Fluent:Notify({
                Title = "Success",
                Content = "Discord link copied to clipboard!",
                Duration = 3
            })
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to copy Discord link: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- Beta Information Section (Beta Tab)
Tabs.Beta:AddSection("Beta Information")

Tabs.Beta:AddParagraph({
    Title = "Beta Version",
    Content = "This is in beta version join the server to see the progress and more fixes along the way - Azrix"
})

Tabs.Beta:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy the Discord invite link to clipboard",
    Callback = function()
        local success, err = pcall(function()
            setclipboard("https://discord.gg/Efx27AMSeX")
            Fluent:Notify({
                Title = "Success",
                Content = "Discord link copied to clipboard!",
                Duration = 3
            })
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to copy Discord link: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- Load saved settings with error handling
if Fluent.SaveManager then
    local success, err = pcall(function()
        Fluent.SaveManager:SetLibrary(Fluent)
        Fluent.SaveManager:SetFolder("FloodEscape2_AutoFarm")
        Fluent.SaveManager:IgnoreThemeSettings()
        Fluent.SaveManager:SetIgnoreIndexes({})
        Fluent.SaveManager:BuildConfigSection(Tabs.Main)
        Fluent.SaveManager:LoadAutoloadConfig()
        -- Update settings from loaded config
        Settings.AutoFarm = Fluent.SaveManager:Get("AutoFarm") or Settings.AutoFarm
        Settings.RescueDelay = Fluent.SaveManager:Get("RescueDelay") or Settings.RescueDelay
        Settings.TeleportDelay = Fluent.SaveManager:Get("TeleportDelay") or Settings.TeleportDelay
        Settings.MaxButtonAttempts = Fluent.SaveManager:Get("MaxButtonAttempts") or Settings.MaxButtonAttempts
        Settings.RandomButtonTeleport = Fluent.SaveManager:Get("RandomButtonTeleport") or Settings.RandomButtonTeleport
        Settings.ExitTeleportAttempts = Fluent.SaveManager:Get("ExitTeleportAttempts") or Settings.ExitTeleportAttempts
        Settings.ExitTeleportDelay = Fluent.SaveManager:Get("ExitTeleportDelay") or Settings.ExitTeleportDelay
        Settings.StuckDetector = Fluent.SaveManager:Get("StuckDetector") or Settings.StuckDetector
        _G.AutoFarm = Settings.AutoFarm
        RescueDelay = Settings.RescueDelay
        TeleportDelay = Settings.TeleportDelay
        MaxButtonAttempts = Settings.MaxButtonAttempts
        RandomizeButtonTeleport = Settings.RandomButtonTeleport
        ExitTeleportAttempts = Settings.ExitTeleportAttempts
        ExitTeleportDelay = Settings.ExitTeleportDelay
        StuckDetectorEnabled = Settings.StuckDetector
    end)
    if not success then
        Fluent:Notify({
            Title = "Load Error",
            Content = "Failed to load saved settings: " .. tostring(err) .. ". Using default settings.",
            Duration = 5
        })
    end
else
    Fluent:Notify({
        Title = "Warning",
        Content = "SaveManager not available. Settings will not persist between sessions.",
        Duration = 5
    })
end

-- Select the Main tab by default
Window:SelectTab(1)

-- =========================
-- HELPER FUNCTIONS
-- =========================
local function isRandomString(str)
    for i = 1, #str do
        local ltr = str:sub(i,i)
        if ltr:lower() == ltr then
            return false
        end
    end
    return true
end

local function AutoRescue(Map)
    local Rescue = Map:FindFirstChild("_Rescue") or Map:FindFirstChild("Rescue")
    if Rescue then
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local RescuePos = Rescue.PrimaryPart and Rescue.PrimaryPart.CFrame or
                         (Rescue:FindFirstChild("Visual") and Rescue.Visual.CFrame)
        if RescuePos then
            local originalCFrame = HRP.CFrame
            HRP.CFrame = RescuePos + Vector3.new(0,3,0)
            task.wait(RescueDelay)
            HRP.CFrame = originalCFrame
        end
        return true
    end
    return false
end

local function GetNewButtons(Map)
    local newButtons = {}
    for _, v in pairs(Map:GetDescendants()) do
        if v:IsA("Model") and isRandomString(tostring(v)) and tostring(v) ~= "NPC" then
            if not PressedButtons[v] then
                local Touch = v:FindFirstChildWhichIsA("TouchTransmitter", true)
                if Touch then
                    local Hitbox = Touch.Parent
                    Hitbox.Name = "Hitbox"
                    table.insert(newButtons, v)
                end
            end
        end
    end
    return newButtons
end

local function JumpPress(Button)
    if not Button or not Button.Parent or PressedButtons[Button] then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    local Hitbox = Button:FindFirstChild("Hitbox")
    if not Hitbox then return end

    LastSafeButtonCFrame = HRP.CFrame
    local attempts = 0
    while _G.AutoFarm and Button.Parent and not PressedButtons[Button] and attempts < MaxButtonAttempts do
        HRP.CFrame = Hitbox.CFrame + Vector3.new(0,2,0)
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        firetouchinterest(HRP, Hitbox, 0)
        task.wait(RandomizeButtonTeleport and math.random(3,10)/100 or TeleportDelay)
        firetouchinterest(HRP, Hitbox, 1)
        attempts = attempts + 1
        task.wait(RandomizeButtonTeleport and math.random(3,10)/100 or TeleportDelay)
    end
    PressedButtons[Button] = true
end

local function TeleportToExit(ExitRegion)
    if not (LocalPlayer.Character and ExitRegion) then return end
    local Character = LocalPlayer.Character
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    for i = 1, ExitTeleportAttempts do
        if (HRP.Position - ExitRegion.Position).Magnitude < 3 then break end
        HRP.CFrame = CFrame.new(ExitRegion.Position + Vector3.new(0,3,0))
        task.wait(ExitTeleportDelay)
    end
end

-- =========================
-- INFINITE HEALTH & STUCK DETECTOR
-- =========================
local StuckPosition = nil
local StuckTime = 0

RunService.RenderStepped:Connect(function(deltaTime)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local HRP = Character:WaitForChild("HumanoidRootPart")

        -- Infinite health
        if Character:FindFirstChild("Humanoid") then
            Character.Humanoid.Health = 99999
        end

        -- Stuck detector (triggers after 1 minute)
        if StuckDetectorEnabled then
            local ExitRegion = CurrentMap and CurrentMap:FindFirstChild("ExitRegion", true)
            local InExit = ExitRegion and (HRP.Position - ExitRegion.Position).Magnitude < 5

            if StuckPosition then
                if (HRP.Position - StuckPosition).Magnitude < 1 and not InExit then
                    StuckTime = StuckTime + deltaTime
                    if StuckTime >= 60 and LastSafeButtonCFrame then -- 1 minute (60 seconds)
                        HRP.CFrame = LastSafeButtonCFrame
                        StuckTime = 0
                        Fluent:Notify({
                            Title = "Stuck Detector",
                            Content = "Teleported back to last safe button due to being stuck for 1 minute",
                            Duration = 3
                        })
                    end
                else
                    StuckTime = 0
                end
            end
            StuckPosition = HRP.Position
        end
    end
end)

-- =========================
-- MAIN LOOP
-- =========================
task.spawn(function()
    Fluent:Notify({
        Title = "AutoFarm Started",
        Content = "Azrix AutoFarm enabled. Waiting for new map...",
        Duration = 5
    })
    while task.wait(1) do
        if not _G.AutoFarm then continue end
        Multiplayer:WaitForChild("NewMap", math.huge)
        CurrentMap = Multiplayer:WaitForChild("Map", math.huge)
        Fluent:Notify({
            Title = "New Map",
            Content = "New map detected: " .. CurrentMap.Name,
            Duration = 3
        })

        PressedButtons = {}
        local hasRescue = AutoRescue(CurrentMap)

        -- Auto skip broken maps
        local Buttons = GetNewButtons(CurrentMap)
        local ExitRegion = CurrentMap:FindFirstChild("ExitRegion", true)
        if not hasRescue and #Buttons == 0 and not ExitRegion then
            Fluent:Notify({
                Title = "Map Issue",
                Content = "Map broken, skipping...",
                Duration = 3
            })
            continue
        end

        while CurrentMap and CurrentMap.Parent == Multiplayer and _G.AutoFarm do
            Buttons = GetNewButtons(CurrentMap)
            ExitRegion = CurrentMap:FindFirstChild("ExitRegion", true)

            if #Buttons == 0 then
                if ExitRegion then
                    TeleportToExit(ExitRegion)
                end
                break
            else
                for _, Button in pairs(Buttons) do
                    if _G.AutoFarm and Button.Parent and not PressedButtons[Button] then
                        JumpPress(Button)
                    end
                end
            end
            task.wait(0.5)
        end
    end

end)
