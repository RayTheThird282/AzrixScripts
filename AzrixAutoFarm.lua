-- // SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local LocalPlayer = Players.LocalPlayer
local Multiplayer = Workspace:WaitForChild("Multiplayer")

-- // SETTINGS
_G.AutoFarm = true
_G.AutoFarmMethod = "Second Auto Farm Method"
_G.TeleportV3Speed = 60
_G.ShakeIntensity = 2
_G.ShakeFrequency = 0.01
_G.InfiniteAir = true
_G.NoClipEnabled = false
_G.FPSBoostEnabled = false
_G.CurrencyTrackerEnabled = false
_G.DetectChaoticBombs = true
_G.ChaoticBombSpeed = 0.01
_G.BombDetectionRange = 30

-- // VARIABLES
local PressedButtons = {}
local CurrentMap = nil
local LastSafeButtonCFrame = nil
local hasTeleportedToExit = false
local CurrentButton = nil
local ButtonStuckPosition = nil
local ButtonStuckTime = 0
local StartTime = tick()
local ExecutionTimeText = "Time Elapsed: 00:00:00"
local CurrencyTrackerGui = nil
local CurrencyConnections = {}
local currentTween = nil

-- // DEFAULT DELAYS & ATTEMPTS
local RescueDelay = 0.5
local TeleportDelay = 0.03
local ExitTeleportDelay = 0.09
local MaxButtonAttempts = 2
local ExitTeleportAttempts = 25
local RandomizeButtonTeleport = false
local StuckDetectorEnabled = true

-- // FPS BOOSTER SETTINGS
_G.FPSSettings = {
    Players = {
        ["Ignore Me"] = true,
        ["Ignore Others"] = true,
        ["Ignore Tools"] = true
    },
    Other = {
        ["FPS Cap"] = true,
        ["No Camera Effects"] = true,
        ["No Clothes"] = true,
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true,
        ["Low Quality Models"] = false,
        ["Reset Materials"] = true,
        ["Lower Quality MeshParts"] = false
    }
}

-- // FPS BOOSTER FUNCTIONS
local function PartOfCharacter(Inst)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and Inst:IsDescendantOf(v.Character) then
            return true
        end
    end
    return false
end

local function IsGameplayElement(Inst)
    return Inst:IsDescendantOf(CurrentMap) or Inst.Name == "ChaoticBomb" or
           Inst.Name == "_Rescue" or Inst.Name == "Rescue" or
           Inst.Name == "ExitRegion" or Inst:IsDescendantOf(Multiplayer)
end

local function ApplyFPSBoost()
    if not _G.FPSBoostEnabled then return end
    local success, err = pcall(function()
        if _G.FPSSettings.Other["FPS Cap"] then setfpscap(0) end
        if _G.FPSSettings.Other["No Camera Effects"] then
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = false end
            end
        end
        if _G.FPSSettings.Other["No Shadows"] then Lighting.GlobalShadows = false end
        if _G.FPSSettings.Other["Low Rendering"] then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end
        if _G.FPSSettings.Other["Low Water Graphics"] then MaterialService.Use2022Materials = false end
        for _, Inst in pairs(Workspace:GetDescendants()) do
            if not IsGameplayElement(Inst) then
                if Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") then
                    if _G.FPSSettings.Other["No Clothes"] then Inst:Destroy() end
                elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
                    if _G.FPSSettings.Other["Low Quality Parts"] then
                        Inst.Material = Enum.Material.Plastic
                        Inst.Reflectance = 0
                    end
                end
            end
        end
    end)
    if success then
        Fluent:Notify({ Title = "FPS Booster", Content = "Applied optimizations", Duration = 3 })
    else
        warn("FPS Booster Error: " .. tostring(err))
        Fluent:Notify({ Title = "FPS Booster Error", Content = "Failed to apply optimizations: " .. tostring(err), Duration = 5 })
    end
end

-- // CURRENCY TRACKER FUNCTION
local function ToggleCurrencyTracker(state)
    if state then
        local success, err = pcall(function()
            local currencyFolder = LocalPlayer.PlayerGui:WaitForChild("GameGui"):WaitForChild("HUD")
                :WaitForChild("Main"):WaitForChild("GameStats"):WaitForChild("Stats"):WaitForChild("Currency")
            local labels = {}
            for _, obj in ipairs(currencyFolder:GetDescendants()) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
                    local num = tonumber(obj.Text)
                    if num then table.insert(labels, obj) end
                end
            end
            if #labels < 2 then
                Fluent:Notify({ Title = "Currency Tracker Error", Content = "Could not find coin and gem labels", Duration = 5 })
                return
            end
            table.sort(labels, function(a, b) return tonumber(a.Text) > tonumber(b.Text) end)
            local coinLabel = labels[1]
            local gemLabel = labels[2]
            local prevCoins = tonumber(coinLabel.Text) or 0
            local prevGems = tonumber(gemLabel.Text) or 0
            CurrencyTrackerGui = Instance.new("ScreenGui", CoreGui)
            CurrencyTrackerGui.Name = "FE2CurrencyTracker"
            local Frame = Instance.new("Frame", CurrencyTrackerGui)
            Frame.Size = UDim2.new(0, 220, 0, 60)
            Frame.Position = UDim2.new(1, -230, 0, 10)
            Frame.BackgroundColor3 = Color3.fromRGB(106, 13, 173)
            Frame.BorderSizePixel = 0
            Frame.BackgroundTransparency = 0.2
            Frame.Active = true
            Frame.Draggable = true
            local Corner = Instance.new("UICorner", Frame)
            Corner.CornerRadius = UDim.new(0, 8)
            local Stroke = Instance.new("UIStroke", Frame)
            Stroke.Thickness = 1
            Stroke.Transparency = 0.5
            Stroke.Color = Color3.fromRGB(255, 255, 255)
            local Label = Instance.new("TextLabel", Frame)
            Label.Size = UDim2.new(1, -10, 1, -10)
            Label.Position = UDim2.new(0, 5, 0, 5)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.Font = Enum.Font.GothamBold
            Label.TextSize = 18
            Label.Text = ""
            local function updateUI()
                local currCoins = tonumber(coinLabel.Text) or 0
                local currGems = tonumber(gemLabel.Text) or 0
                local coinsDiff = currCoins - prevCoins
                local gemsDiff = currGems - prevGems
                Label.Text = string.format("Coins: %d (%+d)\nGems: %d (%+d)", currCoins, coinsDiff, currGems, gemsDiff)
                Label.TextColor3 = (coinsDiff < 0 or gemsDiff < 0) and Color3.fromRGB(255, 50, 50) or
                                   (coinsDiff > 0 or gemsDiff > 0) and Color3.fromRGB(50, 255, 50) or
                                   Color3.fromRGB(255, 255, 255)
                prevCoins = currCoins
                prevGems = currGems
            end
            CurrencyConnections = {
                coinLabel:GetPropertyChangedSignal("Text"):Connect(updateUI),
                gemLabel:GetPropertyChangedSignal("Text"):Connect(updateUI)
            }
            updateUI()
            Fluent:Notify({ Title = "Currency Tracker", Content = "Coin and Gem tracker activated!", Duration = 3 })
        end)
        if not success then
            Fluent:Notify({ Title = "Currency Tracker Error", Content = "Failed to activate tracker: " .. tostring(err), Duration = 5 })
            _G.CurrencyTrackerEnabled = false
            Settings.CurrencyTrackerEnabled = false
            if Fluent.SaveManager then Fluent.SaveManager:Save("CurrencyTrackerEnabled", false) end
        end
    else
        for _, connection in ipairs(CurrencyConnections) do
            if connection then connection:Disconnect() end
        end
        CurrencyConnections = {}
        if CurrencyTrackerGui then
            CurrencyTrackerGui:Destroy()
            CurrencyTrackerGui = nil
        end
        Fluent:Notify({ Title = "Currency Tracker", Content = "Coin and Gem tracker deactivated", Duration = 3 })
    end
end

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
                AddTab = function() 
                    return {
                        AddSection = function() end,
                        AddToggle = function() end,
                        AddSlider = function() end,
                        AddButton = function() end,
                        AddParagraph = function(params)
                            return {
                                Title = params.Title or "",
                                Content = params.Content or "",
                                Set = function(self, newParams)
                                    self.Title = newParams.Title or self.Title
                                    self.Content = newParams.Content or self.Content
                                end
                            }
                        end,
                        AddDropdown = function() end
                    }
                end,
                SelectTab = function() end,
                Notify = function(params) warn(params.Title .. ": " .. params.Content) end,
                ScreenGui = Instance.new("ScreenGui")
            }
        end,
        Options = {}
    }
end
local Options = Fluent.Options

-- Fallback settings storage
local Settings = {
    AutoFarm = _G.AutoFarm,
    AutoFarmMethod = _G.AutoFarmMethod,
    TeleportV3Speed = _G.TeleportV3Speed,
    ShakeIntensity = _G.ShakeIntensity,
    ShakeFrequency = _G.ShakeFrequency,
    InfiniteAir = _G.InfiniteAir,
    NoClipEnabled = _G.NoClipEnabled,
    FPSBoostEnabled = _G.FPSBoostEnabled,
    CurrencyTrackerEnabled = _G.CurrencyTrackerEnabled,
    RescueDelay = RescueDelay,
    TeleportDelay = TeleportDelay,
    MaxButtonAttempts = MaxButtonAttempts,
    RandomizeButtonTeleport = RandomizeButtonTeleport,
    ExitTeleportAttempts = ExitTeleportAttempts,
    ExitTeleportDelay = ExitTeleportDelay,
    StuckDetector = StuckDetectorEnabled,
    DetectChaoticBombs = _G.DetectChaoticBombs,
    ChaoticBombSpeed = _G.ChaoticBombSpeed
}

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Azrix | Flood Escape 2",
    SubTitle = "AutoFarm",
    TabWidth = 160,
    Size = UDim2.new(0, 850, 0, 650),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.Insert
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    AutoFarmConfig = Window:AddTab({ Title = "AutoFarm Config", Icon = "sliders" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Beta = Window:AddTab({ Title = "Beta", Icon = "info" })
}

-- General Settings Section (Main Tab)
Tabs.Main:AddSection("General Settings")

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Enable AutoFarm",
    Description = "Toggles the AutoFarm functionality",
    Default = Settings.AutoFarm,
    Callback = function(state)
        local success, err = pcall(function()
            _G.AutoFarm = state
            Settings.AutoFarm = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("AutoFarm", state) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update AutoFarm setting: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.Main:AddToggle("InfiniteAirToggle", {
    Title = "Enable Infinite Air",
    Description = "Toggles infinite air (health) functionality",
    Default = Settings.InfiniteAir,
    Callback = function(state)
        local success, err = pcall(function()
            _G.InfiniteAir = state
            Settings.InfiniteAir = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("InfiniteAir", state) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Infinite Air setting: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.Main:AddToggle("NoClipToggle", {
    Title = "Enable NoClip",
    Description = "Toggles ability to pass through objects",
    Default = Settings.NoClipEnabled,
    Callback = function(state)
        local success, err = pcall(function()
            _G.NoClipEnabled = state
            Settings.NoClipEnabled = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("NoClipEnabled", state) end
            local Character = LocalPlayer.Character
            if Character then
                task.wait(0.1)
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part:IsDescendantOf(Character) then
                        part.CanCollide = not state
                    end
                end
            end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update NoClip setting: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Chaotic Bomb Settings Section (Main Tab)
Tabs.Main:AddSection("Chaotic Bomb Settings")

Tabs.Main:AddToggle("DetectChaoticBombsToggle", {
    Title = "Detect Chaotic Bombs",
    Description = "Speed up when chaotic bombs are detected",
    Default = Settings.DetectChaoticBombs,
    Callback = function(state)
        local success, err = pcall(function()
            _G.DetectChaoticBombs = state
            Settings.DetectChaoticBombs = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("DetectChaoticBombs", state) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Detect Chaotic Bombs: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.Main:AddSlider("ChaoticBombSpeedSlider", {
    Title = "Bomb Reaction Speed",
    Description = "Teleport speed when chaotic bombs are nearby",
    Default = Settings.ChaoticBombSpeed,
    Min = 0.001,
    Max = 0.05,
    Rounding = 3,
    Callback = function(value)
        local success, err = pcall(function()
            _G.ChaoticBombSpeed = value
            Settings.ChaoticBombSpeed = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("ChaoticBombSpeed", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Bomb Reaction Speed: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Exit Teleport Section (Main Tab)
Tabs.Main:AddSection("Exit Teleport")

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
            if Fluent.SaveManager then Fluent.SaveManager:Save("ExitTeleportAttempts", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Exit Teleport Attempts: " .. tostring(err), Duration = 5 })
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
            if Fluent.SaveManager then Fluent.SaveManager:Save("ExitTeleportDelay", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Exit Teleport Delay: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.Main:AddToggle("StuckDetectorToggle", {
    Title = "Enable Stuck Detectors",
    Description = "Detect and resolve stuck situations (15s for buttons, 30s for exit)",
    Default = Settings.StuckDetector,
    Callback = function(state)
        local success, err = pcall(function()
            StuckDetectorEnabled = state
            Settings.StuckDetector = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("StuckDetector", state) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Stuck Detector setting: " .. tostring(err), Duration = 5 })
        end
    end
})

-- AutoFarm Config Tab: Auto Farm Method Selection
Tabs.AutoFarmConfig:AddSection("Auto Farm Method Selection")

Tabs.AutoFarmConfig:AddDropdown("AutoFarmMethodDropdown", {
    Title = "Auto Farm Method",
    Description = "Choose the auto farm method",
    Values = {"Auto Farm Main", "Second Auto Farm Method", "Newest auto farm Method"},
    Default = Settings.AutoFarmMethod,
    Callback = function(value)
        local success, err = pcall(function()
            _G.AutoFarmMethod = value
            Settings.AutoFarmMethod = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("AutoFarmMethod", value) end
            Fluent:Notify({ Title = "Auto Farm Method Updated", Content = "Auto farm method set to " .. value, Duration = 3 })
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Auto Farm Method: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Auto Farm Main Configuration
Tabs.AutoFarmConfig:AddSection("Auto Farm Main Configuration")

Tabs.AutoFarmConfig:AddSlider("TeleportDelaySlider", {
    Title = "Teleport Delay",
    Description = "Delay between button teleports (seconds)",
    Default = Settings.TeleportDelay,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        local success, err = pcall(function()
            TeleportDelay = value
            Settings.TeleportDelay = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("TeleportDelay", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Teleport Delay: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.AutoFarmConfig:AddSlider("MaxButtonAttemptsSlider", {
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
            if Fluent.SaveManager then Fluent.SaveManager:Save("MaxButtonAttempts", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Max Button Attempts: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.AutoFarmConfig:AddToggle("RandomButtonTeleportToggle", {
    Title = "Randomize Button Teleport",
    Description = "Randomize teleport delay for buttons",
    Default = Settings.RandomizeButtonTeleport,
    Callback = function(state)
        local success, err = pcall(function()
            RandomizeButtonTeleport = state
            Settings.RandomButtonTeleport = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("RandomButtonTeleport", state) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Random Button Teleport: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Second Auto Farm Method Configuration
Tabs.AutoFarmConfig:AddSection("Second Auto Farm Method Configuration")

Tabs.AutoFarmConfig:AddSlider("ShakeIntensitySlider", {
    Title = "Shake Intensity",
    Description = "Shake distance in studs for Second Auto Farm Method",
    Default = Settings.ShakeIntensity,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        local success, err = pcall(function()
            _G.ShakeIntensity = value
            Settings.ShakeIntensity = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("ShakeIntensity", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Shake Intensity: " .. tostring(err), Duration = 5 })
        end
    end
})

Tabs.AutoFarmConfig:AddSlider("ShakeFrequencySlider", {
    Title = "Shake Frequency",
    Description = "Time between shake movements (seconds)",
    Default = Settings.ShakeFrequency,
    Min = 0.01,
    Max = 0.1,
    Rounding = 2,
    Callback = function(value)
        local success, err = pcall(function()
            _G.ShakeFrequency = value
            Settings.ShakeFrequency = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("ShakeFrequency", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Shake Frequency: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Newest auto farm Configuration
Tabs.AutoFarmConfig:AddSection("Newest auto farm Configuration")

Tabs.AutoFarmConfig:AddSlider("TeleportV3SpeedSlider", {
    Title = "TeleportV3 Speed",
    Description = "Speed for Newest auto farm Method tweening (higher = faster)",
    Default = Settings.TeleportV3Speed,
    Min = 25,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        local success, err = pcall(function()
            _G.TeleportV3Speed = value
            Settings.TeleportV3Speed = value
            if Fluent.SaveManager then Fluent.SaveManager:Save("TeleportV3Speed", value) end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update TeleportV3 Speed: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Misc Tab: FPS Booster Section
Tabs.Misc:AddSection("FPS Booster")

Tabs.Misc:AddToggle("FPSBoostToggle", {
    Title = "Enable FPS Booster",
    Description = "Optimizes game visuals for better performance",
    Default = Settings.FPSBoostEnabled,
    Callback = function(state)
        local success, err = pcall(function()
            _G.FPSBoostEnabled = state
            Settings.FPSBoostEnabled = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("FPSBoostEnabled", state) end
            if state then
                ApplyFPSBoost()
                Fluent:Notify({ Title = "FPS Booster", Content = "FPS optimizations applied", Duration = 3 })
            else
                Fluent:Notify({ Title = "FPS Booster", Content = "FPS optimizations disabled", Duration = 3 })
            end
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update FPS Booster setting: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Misc Tab: Currency Tracker Section
Tabs.Misc:AddSection("Currency Tracker")

Tabs.Misc:AddToggle("CurrencyTrackerToggle", {
    Title = "Enable Currency Tracker",
    Description = "Shows a draggable UI tracking Coins and Gems",
    Default = Settings.CurrencyTrackerEnabled,
    Callback = function(state)
        local success, err = pcall(function()
            _G.CurrencyTrackerEnabled = state
            Settings.CurrencyTrackerEnabled = state
            if Fluent.SaveManager then Fluent.SaveManager:Save("CurrencyTrackerEnabled", state) end
            ToggleCurrencyTracker(state)
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to update Currency Tracker setting: " .. tostring(err), Duration = 5 })
            _G.CurrencyTrackerEnabled = false
            Settings.CurrencyTrackerEnabled = false
            if Fluent.SaveManager then Fluent.SaveManager:Save("CurrencyTrackerEnabled", false) end
        end
    end
})

-- Misc Tab: Script Information Section
Tabs.Misc:AddSection("Script Information")

local ExecutionTimeParagraph = Tabs.Misc:AddParagraph({
    Title = "Script Execution Time",
    Content = "Time Elapsed: 00:00:00"
})

-- Misc Tab: Discord Server Section
Tabs.Misc:AddSection("Discord Server")

Tabs.Misc:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy the Discord invite link to clipboard",
    Callback = function()
        local success, err = pcall(function()
            setclipboard("https://discord.gg/Efx27AMSeX")
            Fluent:Notify({ Title = "Success", Content = "Discord link copied to clipboard!", Duration = 3 })
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to copy Discord link: " .. tostring(err), Duration = 5 })
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
            Fluent:Notify({ Title = "Success", Content = "Discord link copied to clipboard!", Duration = 3 })
        end)
        if not success then
            Fluent:Notify({ Title = "Error", Content = "Failed to copy Discord link: " .. tostring(err), Duration = 5 })
        end
    end
})

-- Execution Timer Update Loop
task.spawn(function()
    while true do
        local success, err = pcall(function()
            local elapsedTime = math.floor(tick() - StartTime)
            local hours = math.floor(elapsedTime / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = elapsedTime % 60
            ExecutionTimeText = string.format("Time Elapsed: %02d:%02d:%02d", hours, minutes, seconds)
            if ExecutionTimeParagraph and ExecutionTimeParagraph.Set then
                ExecutionTimeParagraph:Set({ Title = "Script Execution Time", Content = ExecutionTimeText })
            end
        end)
        if not success then
            Fluent:Notify({ Title = "Execution Timer Error", Content = "Failed to update timer: " .. tostring(err) .. ". Using fallback: " .. ExecutionTimeText, Duration = 5 })
        end
        task.wait(1)
    end
end)

-- Load saved settings
if Fluent.SaveManager then
    local success, err = pcall(function()
        Fluent.SaveManager:SetLibrary(Fluent)
        Fluent.SaveManager:SetFolder("FloodEscape2_AutoFarm")
        Fluent.SaveManager:IgnoreThemeSettings()
        Fluent.SaveManager:SetIgnoreIndexes({})
        Fluent.SaveManager:BuildConfigSection(Tabs.Main)
        Fluent.SaveManager:LoadAutoloadConfig()
        Settings.AutoFarm = Fluent.SaveManager:Get("AutoFarm") or Settings.AutoFarm
        Settings.AutoFarmMethod = Fluent.SaveManager:Get("AutoFarmMethod") or Settings.AutoFarmMethod
        Settings.TeleportV3Speed = Fluent.SaveManager:Get("TeleportV3Speed") or Settings.TeleportV3Speed
        Settings.ShakeIntensity = Fluent.SaveManager:Get("ShakeIntensity") or Settings.ShakeIntensity
        Settings.ShakeFrequency = Fluent.SaveManager:Get("ShakeFrequency") or Settings.ShakeFrequency
        Settings.InfiniteAir = Fluent.SaveManager:Get("InfiniteAir") or Settings.InfiniteAir
        Settings.NoClipEnabled = Fluent.SaveManager:Get("NoClipEnabled") or Settings.NoClipEnabled
        Settings.FPSBoostEnabled = Fluent.SaveManager:Get("FPSBoostEnabled") or Settings.FPSBoostEnabled
        Settings.CurrencyTrackerEnabled = Fluent.SaveManager:Get("CurrencyTrackerEnabled") or Settings.CurrencyTrackerEnabled
        Settings.RescueDelay = Fluent.SaveManager:Get("RescueDelay") or Settings.RescueDelay
        Settings.TeleportDelay = Fluent.SaveManager:Get("TeleportDelay") or Settings.TeleportDelay
        Settings.MaxButtonAttempts = Fluent.SaveManager:Get("MaxButtonAttempts") or Settings.MaxButtonAttempts
        Settings.RandomizeButtonTeleport = Fluent.SaveManager:Get("RandomButtonTeleport") or Settings.RandomButtonTeleport
        Settings.ExitTeleportAttempts = Fluent.SaveManager:Get("ExitTeleportAttempts") or Settings.ExitTeleportAttempts
        Settings.ExitTeleportDelay = Fluent.SaveManager:Get("ExitTeleportDelay") or Settings.ExitTeleportDelay
        Settings.StuckDetector = Fluent.SaveManager:Get("StuckDetector") or Settings.StuckDetector
        Settings.DetectChaoticBombs = Fluent.SaveManager:Get("DetectChaoticBombs") or Settings.DetectChaoticBombs
        Settings.ChaoticBombSpeed = Fluent.SaveManager:Get("ChaoticBombSpeed") or Settings.ChaoticBombSpeed
        _G.AutoFarm = Settings.AutoFarm
        _G.AutoFarmMethod = Settings.AutoFarmMethod
        _G.TeleportV3Speed = Settings.TeleportV3Speed
        _G.ShakeIntensity = Settings.ShakeIntensity
        _G.ShakeFrequency = Settings.ShakeFrequency
        _G.InfiniteAir = Settings.InfiniteAir
        _G.NoClipEnabled = Settings.NoClipEnabled
        _G.FPSBoostEnabled = Settings.FPSBoostEnabled
        _G.CurrencyTrackerEnabled = Settings.CurrencyTrackerEnabled
        RescueDelay = Settings.RescueDelay
        TeleportDelay = Settings.TeleportDelay
        MaxButtonAttempts = Settings.MaxButtonAttempts
        RandomizeButtonTeleport = Settings.RandomizeButtonTeleport
        ExitTeleportAttempts = Settings.ExitTeleportAttempts
        ExitTeleportDelay = Settings.ExitTeleportDelay
        StuckDetectorEnabled = Settings.StuckDetector
        _G.DetectChaoticBombs = Settings.DetectChaoticBombs
        _G.ChaoticBombSpeed = Settings.ChaoticBombSpeed
        if _G.CurrencyTrackerEnabled then ToggleCurrencyTracker(true) end
    end)
    if not success then
        Fluent:Notify({ Title = "Load Error", Content = "Failed to load saved settings: " .. tostring(err) .. ". Using default settings.", Duration = 5 })
    end
else
    Fluent:Notify({ Title = "Warning", Content = "SaveManager not available. Settings will not persist.", Duration = 5 })
end

-- Select Main tab
Window:SelectTab(1)

-- // HELPERS
local function isRandomString(str)
    for i = 1, #str do
        local ltr = str:sub(i, i)
        if ltr:lower() == ltr then return false end
    end
    return true
end

local function FindHitboxInButton(button)
    for _, v in pairs(button:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency == 1 then return v end
    end
end

local function GetButtons(Map)
    local Buttons = {}
    for _, v in pairs(Map:GetDescendants()) do
        if v:IsA("Model") and isRandomString(tostring(v.Name)) and v.Name ~= "NPC" and not PressedButtons[v] then
            local Touch = v:FindFirstChildWhichIsA("TouchTransmitter", true)
            if Touch then table.insert(Buttons, v) end
        end
    end
    return Buttons
end

local function FindFirstDescendant(p, name)
    for _, descendant in pairs(p:GetDescendants()) do
        if descendant.Name == name then return descendant end
    end
    return nil
end

local function HasNearbyChaoticBombs(character)
    if not _G.DetectChaoticBombs or not character or not character.PrimaryPart then return false end
    for _, bomb in pairs(Workspace:GetChildren()) do
        if bomb.Name == "ChaoticBomb" and bomb:FindFirstChild("Explosion") then
            if (bomb.Position - character.PrimaryPart.Position).Magnitude < _G.BombDetectionRange then
                return true
            end
        end
    end
    return false
end

local function cancel()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

-- // AUTO FARM METHODS
local function AutoFarmMain(Button) -- Direct CFrame setting
    local Character = LocalPlayer.Character
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local Hitbox = FindHitboxInButton(Button)
    if not Hitbox then return end

    CurrentButton = Button
    LastSafeButtonCFrame = HRP.CFrame
    ButtonStuckPosition = HRP.Position
    ButtonStuckTime = 0

    local attempts = 0
    local success, err = pcall(function()
        while _G.AutoFarm and Button.Parent and not PressedButtons[Button] and attempts < MaxButtonAttempts do
            local currentDelay = HasNearbyChaoticBombs(Character) and _G.ChaoticBombSpeed or TeleportDelay
            local targetPos = Hitbox.Position - Vector3.new(0, Hitbox.Size.Y/2 - 1, 0)
            HRP.CFrame = CFrame.new(targetPos, Hitbox.Position)
            for i = 1, 3 do
                firetouchinterest(HRP, Hitbox, 0)
                firetouchinterest(HRP, Hitbox, 1)
                task.wait(0.05)
            end
            attempts = attempts + 1
            task.wait(currentDelay)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "AutoFarmMain Error", Content = "Failed to press button: " .. tostring(err), Duration = 5 })
    end
    PressedButtons[Button] = true
    CurrentButton = nil
    ButtonStuckPosition = nil
    ButtonStuckTime = 0
end

local function SecondAutoFarmMethod(Button) -- Shaky method
    local Character = LocalPlayer.Character
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local Hitbox = FindHitboxInButton(Button)
    if not Hitbox then return end

    CurrentButton = Button
    LastSafeButtonCFrame = HRP.CFrame
    ButtonStuckPosition = HRP.Position
    ButtonStuckTime = 0

    local attempts = 0
    local success, err = pcall(function()
        while _G.AutoFarm and Button.Parent and not PressedButtons[Button] and attempts < MaxButtonAttempts do
            local currentDelay = HasNearbyChaoticBombs(Character) and _G.ChaoticBombSpeed or TeleportDelay
            local targetPos = Hitbox.Position - Vector3.new(0, Hitbox.Size.Y/2 - 1, 0)
            local targetCFrame = CFrame.new(targetPos, Hitbox.Position)
            local shakeTime = 0
            while shakeTime < 0.3 do
                local shakeOffset = Vector3.new(
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity)
                )
                HRP.CFrame = targetCFrame + shakeOffset
                task.wait(_G.ShakeFrequency)
                shakeTime = shakeTime + _G.ShakeFrequency
            end
            HRP.CFrame = targetCFrame
            for i = 1, 3 do
                firetouchinterest(HRP, Hitbox, 0)
                firetouchinterest(HRP, Hitbox, 1)
                task.wait(0.05)
            end
            attempts = attempts + 1
            task.wait(currentDelay)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "SecondAutoFarmMethod Error", Content = "Failed to press button: " .. tostring(err), Duration = 5 })
    end
    PressedButtons[Button] = true
    CurrentButton = nil
    ButtonStuckPosition = nil
    ButtonStuckTime = 0
end

local function NewestAutoFarmMethod(Button) -- Original TeleportV3
    local Character = LocalPlayer.Character
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local Hitbox = FindHitboxInButton(Button)
    if not Hitbox then return end

    CurrentButton = Button
    LastSafeButtonCFrame = HRP.CFrame
    ButtonStuckPosition = HRP.Position
    ButtonStuckTime = 0

    local success, err = pcall(function()
        local targetPos = Hitbox.Position - Vector3.new(0, Hitbox.Size.Y/2 - 1, 0)
        local targetCFrame = CFrame.new(targetPos, Hitbox.Position)
        local distance = (HRP.Position - targetPos).Magnitude
        local tspeed = math.clamp(distance / _G.TeleportV3Speed, 0.15, math.huge)
        local ts = TweenService:Create(HRP, TweenInfo.new(tspeed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        cancel()
        currentTween = ts
        ts:Play()
        ts.Completed:Wait()
        for i = 1, 3 do
            firetouchinterest(HRP, Hitbox, 0)
            firetouchinterest(HRP, Hitbox, 1)
            task.wait(0.05)
        end
        task.wait(0.5)
    end)
    if not success then
        Fluent:Notify({ Title = "NewestAutoFarmMethod Error", Content = "Failed to press button: " .. tostring(err), Duration = 5 })
    end
    PressedButtons[Button] = true
    CurrentButton = nil
    ButtonStuckPosition = nil
    ButtonStuckTime = 0
end

-- // AUTO RESCUE
local function AutoRescue(Map)
    local success, err = pcall(function()
        local Rescue = Map:FindFirstChild("_Rescue") or Map:FindFirstChild("Rescue")
        if not Rescue then return end
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local target = Rescue.PrimaryPart and Rescue.PrimaryPart.CFrame or (Rescue:FindFirstChild("Visual") and Rescue.Visual.CFrame)
        if target then
            HRP.CFrame = target + Vector3.new(0, 3, 0)
            task.wait(RescueDelay)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "AutoRescue Error", Content = "Failed to rescue: " .. tostring(err), Duration = 5 })
    end
end

-- // TELEPORT TO EXIT
local function TeleportToExit(ExitRegion)
    if not (LocalPlayer.Character and ExitRegion) then return end
    local Character = LocalPlayer.Character
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local exitCFrame = CFrame.new(ExitRegion.Position + Vector3.new(0, 3, 0))

    for i = 1, ExitTeleportAttempts do
        if _G.AutoFarmMethod == "Second Auto Farm Method" then
            local shakeTime = 0
            while shakeTime < 0.3 do
                local shakeOffset = Vector3.new(
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity)
                )
                HRP.CFrame = exitCFrame + shakeOffset
                task.wait(_G.ShakeFrequency)
                shakeTime = shakeTime + _G.ShakeFrequency
            end
            HRP.CFrame = exitCFrame
        elseif _G.AutoFarmMethod == "Newest auto farm Method" then
            cancel()
            local distance = (HRP.Position - exitCFrame.Position).Magnitude
            local tspeed = math.clamp(distance / _G.TeleportV3Speed, 0.15, math.huge)
            local ts = TweenService:Create(HRP, TweenInfo.new(tspeed, Enum.EasingStyle.Linear), {CFrame = exitCFrame})
            currentTween = ts
            ts:Play()
            ts.Completed:Wait()
        else
            HRP.CFrame = exitCFrame
        end
        task.wait(ExitTeleportDelay)
    end
    hasTeleportedToExit = true
end

-- // INFINITE HEALTH, NOCLIP, STUCK DETECTORS
local ExitStuckPosition = nil
local ExitStuckTime = 0

RunService.RenderStepped:Connect(function(deltaTime)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if _G.InfiniteAir and Humanoid then
            Humanoid.Health = 99999
        end

        if _G.NoClipEnabled then
            local success, err = pcall(function()
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part:IsDescendantOf(Character) then
                        part.CanCollide = false
                    end
                end
            end)
            if not success then
                Fluent:Notify({ Title = "NoClip Error", Content = "Failed to apply NoClip: " .. tostring(err), Duration = 5 })
            end
        end

        if StuckDetectorEnabled and CurrentButton and ButtonStuckPosition then
            if (HRP.Position - ButtonStuckPosition).Magnitude < 1 and not PressedButtons[CurrentButton] then
                ButtonStuckTime = ButtonStuckTime + deltaTime
                if ButtonStuckTime >= 15 then
                    local Hitbox = FindHitboxInButton(CurrentButton)
                    if Hitbox then
                        HRP.CFrame = Hitbox.CFrame
                        Fluent:Notify({ Title = "Button Stuck Detector", Content = "Teleported back to button due to being stuck for 15 seconds", Duration = 3 })
                    end
                    ButtonStuckTime = 0
                    ButtonStuckPosition = HRP.Position
                end
            else
                ButtonStuckTime = 0
                ButtonStuckPosition = HRP.Position
            end
        end

        if StuckDetectorEnabled and hasTeleportedToExit then
            local ExitRegion = CurrentMap and FindFirstDescendant(CurrentMap, "ExitRegion")
            local InExit = ExitRegion and (HRP.Position - ExitRegion.Position).Magnitude < 5
            if ExitStuckPosition then
                if (HRP.Position - ExitStuckPosition).Magnitude < 1 and not InExit then
                    ExitStuckTime = ExitStuckTime + deltaTime
                    if ExitStuckTime >= 30 and LastSafeButtonCFrame then
                        HRP.CFrame = LastSafeButtonCFrame
                        ExitStuckTime = 0
                        Fluent:Notify({ Title = "Exit Stuck Detector", Content = "Teleported back to last safe button due to being stuck for 30 seconds", Duration = 3 })
                    end
                else
                    ExitStuckTime = 0
                end
            end
            ExitStuckPosition = HRP.Position
        end
    end
end)

-- Update NoClip and FPS Boost on respawn
LocalPlayer.CharacterAdded:Connect(function(Character)
    if _G.NoClipEnabled then
        local success, err = pcall(function()
            task.wait(0.1)
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") and part:IsDescendantOf(Character) then
                    part.CanCollide = false
                end
            end
        end)
        if not success then
            Fluent:Notify({ Title = "NoClip Error", Content = "Failed to apply NoClip on respawn: " .. tostring(err), Duration = 5 })
        end
    end
    if _G.FPSBoostEnabled then
        task.wait()
        ApplyFPSBoost()
    end
end)

-- // FPS BOOSTER LOOP
task.spawn(function()
    if not game:IsLoaded() then
        repeat task.wait() until game:IsLoaded()
    end
    ApplyFPSBoost()
    local lastUpdate = tick()
    Workspace.DescendantAdded:Connect(function(Inst)
        if _G.FPSBoostEnabled and (tick() - lastUpdate) >= 1 then
            task.spawn(function()
                ApplyFPSBoost()
                lastUpdate = tick()
            end)
        end
    end)
end)

-- // MAIN LOOP
task.spawn(function()
    Fluent:Notify({ Title = "AutoFarm Started", Content = "Azrix AutoFarm enabled. Waiting for new map...", Duration = 5 })
    StarterGui:SetCore("SendNotification", { Title = "Welcome!", Text = "Enjoy farming! Current Status: " .. tostring(_G.AutoFarm) })
    while task.wait(1) do
        if not _G.AutoFarm then continue end
        Multiplayer:WaitForChild("NewMap", math.huge)
        CurrentMap = Multiplayer:WaitForChild("Map", math.huge)
        Fluent:Notify({ Title = "New Map", Content = "New map detected: " .. CurrentMap.Name, Duration = 3 })

        PressedButtons = {}
        hasTeleportedToExit = false
        ExitStuckTime = 0
        ExitStuckPosition = nil
        CurrentButton = nil
        ButtonStuckTime = 0
        ButtonStuckPosition = nil

        AutoRescue(CurrentMap)

        while CurrentMap and CurrentMap.Parent == Multiplayer and _G.AutoFarm do
            local Buttons = GetButtons(CurrentMap)
            local ExitRegion = FindFirstDescendant(CurrentMap, "ExitRegion")
            if #Buttons == 0 then
                if ExitRegion then TeleportToExit(ExitRegion) end
                break
            else
                for _, Button in pairs(Buttons) do
                    if _G.AutoFarm and Button.Parent and not PressedButtons[Button] then
                        if _G.AutoFarmMethod == "Auto Farm Main" then
                            AutoFarmMain(Button)
                        elseif _G.AutoFarmMethod == "Second Auto Farm Method" then
                            SecondAutoFarmMethod(Button)
                        else
                            NewestAutoFarmMethod(Button)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end
end)
