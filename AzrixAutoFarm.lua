-- // SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Multiplayer = Workspace:WaitForChild("Multiplayer")

-- // SETTINGS
_G.AutoFarm = true -- AutoFarm ON by default
_G.DetectChaoticBombs = true
_G.ChaoticBombSpeed = 0.01  -- Fast speed when bombs detected
_G.BombDetectionRange = 30  -- Studs range to detect bombs
_G.InfiniteAir = true -- Infinite Air ON by default
_G.ShakeTeleport = true -- Shake teleport ON by default
_G.ShakeIntensity = 0.5 -- Shake intensity in studs
_G.ShakeFrequency = 0.02 -- Time between shake movements (seconds)
_G.NoClipEnabled = false -- NoClip OFF by default
_G.TeleportMethod = "New (Shake)" -- Default teleport method

-- // VARIABLES
local CurrentMap = nil
local PressedButtons = {}
local LastSafeButtonCFrame = nil
local hasTeleportedToExit = false
local CurrentButton = nil
local ButtonStuckPosition = nil
local ButtonStuckTime = 0

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
                AddTab = function() return { AddSection = function() end, AddToggle = function() end, AddSlider = function() end, AddButton = function() end, AddParagraph = function() end, AddDropdown = function() end } end,
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
    StuckDetector = StuckDetectorEnabled,
    DetectChaoticBombs = _G.DetectChaoticBombs,
    ChaoticBombSpeed = _G.ChaoticBombSpeed,
    InfiniteAir = _G.InfiniteAir,
    ShakeTeleport = _G.ShakeTeleport,
    ShakeIntensity = _G.ShakeIntensity,
    ShakeFrequency = _G.ShakeFrequency,
    NoClipEnabled = _G.NoClipEnabled,
    TeleportMethod = _G.TeleportMethod
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

Tabs.Main:AddToggle("InfiniteAirToggle", {
    Title = "Enable Infinite Air",
    Description = "Toggles infinite air (health) functionality",
    Default = Settings.InfiniteAir,
    Callback = function(state)
        local success, err = pcall(function()
            _G.InfiniteAir = state
            Settings.InfiniteAir = state
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("InfiniteAir", state)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Infinite Air setting: " .. tostring(err),
                Duration = 5
            })
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
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("NoClipEnabled", state)
            end
            -- Update NoClip state immediately
            local Character = LocalPlayer.Character
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = not state
                    end
                end
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update NoClip setting: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

-- Settings Section (Main Tab)
Tabs.Main:AddSection("Settings")

Tabs.Main:AddDropdown("TeleportMethodDropdown", {
    Title = "Teleport Method",
    Description = "Choose teleport method for buttons and exit",
    Values = {"New (Shake)", "Old (Smoother)"},
    Default = Settings.TeleportMethod,
    Callback = function(value)
        local success, err = pcall(function()
            _G.TeleportMethod = value
            Settings.TeleportMethod = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("TeleportMethod", value)
            end
            -- Notify user of method change
            Fluent:Notify({
                Title = "Teleport Method Updated",
                Content = "Teleport method set to " .. value .. ". Shake settings are " .. (value == "New (Shake)" and "enabled" or "disabled"),
                Duration = 3
            })
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Teleport Method: " .. tostring(err) .. ". Please try again.",
                Duration = 5
            })
        end
    end
})

-- Conditionally add shake settings based on initial teleport method
if _G.TeleportMethod == "New (Shake)" then
    Tabs.Main:AddToggle("ShakeTeleportToggle", {
        Title = "Enable Shake Teleport",
        Description = "Toggles shaky teleport for reliable button pressing (New method only)",
        Default = Settings.ShakeTeleport,
        Callback = function(state)
            local success, err = pcall(function()
                if _G.TeleportMethod == "New (Shake)" then
                    _G.ShakeTeleport = state
                    Settings.ShakeTeleport = state
                    if Fluent.SaveManager then
                        Fluent.SaveManager:Save("ShakeTeleport", state)
                    end
                else
                    Fluent:Notify({
                        Title = "Warning",
                        Content = "Shake Teleport setting is only applicable for New (Shake) method",
                        Duration = 3
                    })
                end
            end)
            if not success then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to update Shake Teleport setting: " .. tostring(err),
                    Duration = 5
                })
            end
        end
    })

    Tabs.Main:AddSlider("ShakeIntensitySlider", {
        Title = "Shake Intensity",
        Description = "Intensity of teleport shake in studs (New method only)",
        Default = Settings.ShakeIntensity,
        Min = 0.1,
        Max = 2,
        Rounding = 1,
        Callback = function(value)
            local success, err = pcall(function()
                if _G.TeleportMethod == "New (Shake)" then
                    _G.ShakeIntensity = value
                    Settings.ShakeIntensity = value
                    if Fluent.SaveManager then
                        Fluent.SaveManager:Save("ShakeIntensity", value)
                    end
                else
                    Fluent:Notify({
                        Title = "Warning",
                        Content = "Shake Intensity setting is only applicable for New (Shake) method",
                        Duration = 3
                    })
                end
            end)
            if not success then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to update Shake Intensity: " .. tostring(err),
                    Duration = 5
                })
            end
        end
    })

    Tabs.Main:AddSlider("ShakeFrequencySlider", {
        Title = "Shake Frequency",
        Description = "Time between shake movements in seconds (New method only)",
        Default = Settings.ShakeFrequency,
        Min = 0.01,
        Max = 0.1,
        Rounding = 2,
        Callback = function(value)
            local success, err = pcall(function()
                if _G.TeleportMethod == "New (Shake)" then
                    _G.ShakeFrequency = value
                    Settings.ShakeFrequency = value
                    if Fluent.SaveManager then
                        Fluent.SaveManager:Save("ShakeFrequency", value)
                    end
                else
                    Fluent:Notify({
                        Title = "Warning",
                        Content = "Shake Frequency setting is only applicable for New (Shake) method",
                        Duration = 3
                    })
                end
            end)
            if not success then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to update Shake Frequency: " .. tostring(err),
                    Duration = 5
                })
            end
        end
    })
end

-- Other AutoFarm Settings
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

-- Chaotic Bomb Settings Section (Main Tab)
Tabs.Main:AddSection("Chaotic Bomb Settings")

Tabs.Main:AddToggle("DetectChaoticBombsToggle", {
    Title = "Detect Chaotic Bombs",
    Description = "Speed up when chaotic bombs are detected",
    Default = _G.DetectChaoticBombs,
    Callback = function(state)
        local success, err = pcall(function()
            _G.DetectChaoticBombs = state
            Settings.DetectChaoticBombs = state
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("DetectChaoticBombs", state)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Detect Chaotic Bombs: " .. tostring(err),
                Duration = 5
            })
        end
    end
})

Tabs.Main:AddSlider("ChaoticBombSpeedSlider", {
    Title = "Bomb Reaction Speed",
    Description = "Teleport speed when chaotic bombs are nearby",
    Default = _G.ChaoticBombSpeed,
    Min = 0.001,
    Max = 0.05,
    Rounding = 3,
    Callback = function(value)
        local success, err = pcall(function()
            _G.ChaoticBombSpeed = value
            Settings.ChaoticBombSpeed = value
            if Fluent.SaveManager then
                Fluent.SaveManager:Save("ChaoticBombSpeed", value)
            end
        end)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to update Bomb Reaction Speed: " .. tostring(err),
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
    Title = "Enable Stuck Detectors",
    Description = "Detect and resolve stuck situations (15s for buttons, 30s for exit)",
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
        Settings.DetectChaoticBombs = Fluent.SaveManager:Get("DetectChaoticBombs") or Settings.DetectChaoticBombs
        Settings.ChaoticBombSpeed = Fluent.SaveManager:Get("ChaoticBombSpeed") or Settings.ChaoticBombSpeed
        Settings.InfiniteAir = Fluent.SaveManager:Get("InfiniteAir") or Settings.InfiniteAir
        Settings.ShakeTeleport = Fluent.SaveManager:Get("ShakeTeleport") or Settings.ShakeTeleport
        Settings.ShakeIntensity = Fluent.SaveManager:Get("ShakeIntensity") or Settings.ShakeIntensity
        Settings.ShakeFrequency = Fluent.SaveManager:Get("ShakeFrequency") or Settings.ShakeFrequency
        Settings.NoClipEnabled = Fluent.SaveManager:Get("NoClipEnabled") or Settings.NoClipEnabled
        Settings.TeleportMethod = Fluent.SaveManager:Get("TeleportMethod") or Settings.TeleportMethod
        _G.AutoFarm = Settings.AutoFarm
        RescueDelay = Settings.RescueDelay
        TeleportDelay = Settings.TeleportDelay
        MaxButtonAttempts = Settings.MaxButtonAttempts
        RandomizeButtonTeleport = Settings.RandomButtonTeleport
        ExitTeleportAttempts = Settings.ExitTeleportAttempts
        ExitTeleportDelay = Settings.ExitTeleportDelay
        StuckDetectorEnabled = Settings.StuckDetector
        _G.DetectChaoticBombs = Settings.DetectChaoticBombs
        _G.ChaoticBombSpeed = Settings.ChaoticBombSpeed
        _G.InfiniteAir = Settings.InfiniteAir
        _G.ShakeTeleport = Settings.ShakeTeleport
        _G.ShakeIntensity = Settings.ShakeIntensity
        _G.ShakeFrequency = Settings.ShakeFrequency
        _G.NoClipEnabled = Settings.NoClipEnabled
        _G.TeleportMethod = Settings.TeleportMethod
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

local function HasNearbyChaoticBombs(character)
    if not _G.DetectChaoticBombs or not character or not character.PrimaryPart then 
        return false 
    end
    
    for _, bomb in pairs(Workspace:GetChildren()) do
        if bomb.Name == "ChaoticBomb" and bomb:FindFirstChild("Explosion") then
            if (bomb.Position - character.PrimaryPart.Position).Magnitude < _G.BombDetectionRange then
                return true
            end
        end
    end
    
    return false
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

    CurrentButton = Button
    LastSafeButtonCFrame = HRP.CFrame
    local attempts = 0
    ButtonStuckPosition = HRP.Position
    ButtonStuckTime = 0
    
    while _G.AutoFarm and Button.Parent and not PressedButtons[Button] and attempts < MaxButtonAttempts do
        -- Check for bombs and adjust speed
        local currentDelay = HasNearbyChaoticBombs(Character) and _G.ChaoticBombSpeed or TeleportDelay
        
        -- Position HumanoidRootPart so head is half inside, half outside the button
        local optimalCFrame = Hitbox.CFrame * CFrame.new(0, Hitbox.Size.Y / 2 - 2, 0) -- Head center at hitbox surface, HRP 2 studs below
        
        -- Trigger press
        firetouchinterest(HRP, Hitbox, 0)
        
        -- Apply teleport method
        if _G.TeleportMethod == "New (Shake)" and _G.ShakeTeleport then
            local shakeTime = 0
            while shakeTime < 0.1 do -- Short duration for instant activation
                local shakeOffset = Vector3.new(
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity)
                )
                HRP.CFrame = optimalCFrame + shakeOffset
                task.wait(_G.ShakeFrequency)
                shakeTime = shakeTime + _G.ShakeFrequency
            end
        else
            HRP.CFrame = optimalCFrame
            task.wait(0.1) -- Original smoother method duration
        end
        
        firetouchinterest(HRP, Hitbox, 1)
        
        attempts = attempts + 1
        task.wait(currentDelay)
    end
    
    PressedButtons[Button] = true
    CurrentButton = nil
    ButtonStuckPosition = nil
    ButtonStuckTime = 0
end

local function TeleportToExit(ExitRegion)
    if not (LocalPlayer.Character and ExitRegion) then return end
    local Character = LocalPlayer.Character
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    for i = 1, ExitTeleportAttempts do
        if _G.TeleportMethod == "New (Shake)" and _G.ShakeTeleport then
            local shakeTime = 0
            while shakeTime < 0.1 do -- Short duration for shake
                local shakeOffset = Vector3.new(
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity),
                    math.random(-_G.ShakeIntensity, _G.ShakeIntensity)
                )
                HRP.CFrame = CFrame.new(ExitRegion.Position + Vector3.new(0, 3, 0)) + shakeOffset
                task.wait(_G.ShakeFrequency)
                shakeTime = shakeTime + _G.ShakeFrequency
            end
        else
            HRP.CFrame = CFrame.new(ExitRegion.Position + Vector3.new(0, 3, 0))
        end
        task.wait(ExitTeleportDelay)
    end
    hasTeleportedToExit = true
end

-- =========================
-- INFINITE HEALTH, NOCLIP & STUCK DETECTORS
-- =========================
local ExitStuckPosition = nil
local ExitStuckTime = 0

RunService.RenderStepped:Connect(function(deltaTime)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        -- Infinite health (air)
        if _G.InfiniteAir and Humanoid then
            Humanoid.Health = 99999
        end

        -- NoClip
        if _G.NoClipEnabled then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end

        -- Button stuck detector (15 seconds, when pressing a button)
        if StuckDetectorEnabled and CurrentButton and ButtonStuckPosition then
            if (HRP.Position - ButtonStuckPosition).Magnitude < 1 and not PressedButtons[CurrentButton] then
                ButtonStuckTime = ButtonStuckTime + deltaTime
                if ButtonStuckTime >= 15 then -- 15 seconds
                    local Hitbox = CurrentButton:FindFirstChild("Hitbox")
                    if Hitbox then
                        local optimalCFrame = Hitbox.CFrame * CFrame.new(0, Hitbox.Size.Y / 2 - 2, 0) -- Same head-based positioning
                        HRP.CFrame = optimalCFrame
                        Fluent:Notify({
                            Title = "Button Stuck Detector",
                            Content = "Teleported back to button due to being stuck for 15 seconds",
                            Duration = 3
                        })
                    end
                    ButtonStuckTime = 0
                    ButtonStuckPosition = HRP.Position
                end
            else
                ButtonStuckTime = 0
                ButtonStuckPosition = HRP.Position
            end
        end

        -- Exit stuck detector (30 seconds, only after TP to exit)
        if StuckDetectorEnabled and hasTeleportedToExit then
            local ExitRegion = CurrentMap and CurrentMap:FindFirstChild("ExitRegion", true)
            local InExit = ExitRegion and (HRP.Position - ExitRegion.Position).Magnitude < 5

            if ExitStuckPosition then
                if (HRP.Position - ExitStuckPosition).Magnitude < 1 and not InExit then
                    ExitStuckTime = ExitStuckTime + deltaTime
                    if ExitStuckTime >= 30 and LastSafeButtonCFrame then -- 30 seconds
                        HRP.CFrame = LastSafeButtonCFrame
                        ExitStuckTime = 0
                        Fluent:Notify({
                            Title = "Exit Stuck Detector",
                            Content = "Teleported back to last safe button due to being stuck for 30 seconds after exit TP",
                            Duration = 3
                        })
                    end
                else
                    ExitStuckTime = 0
                end
            end
            ExitStuckPosition = HRP.Position
        end
    end
end)

-- Update NoClip on character respawn
LocalPlayer.CharacterAdded:Connect(function(Character)
    if _G.NoClipEnabled then
        task.wait() -- Wait for character to fully load
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
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
        hasTeleportedToExit = false
        ExitStuckTime = 0
        ExitStuckPosition = nil
        CurrentButton = nil
        ButtonStuckTime = 0
        ButtonStuckPosition = nil
        local hasRescue = AutoRescue(CurrentMap)

        while CurrentMap and CurrentMap.Parent == Multiplayer and _G.AutoFarm do
            local Buttons = GetNewButtons(CurrentMap)
            local ExitRegion = CurrentMap:FindFirstChild("ExitRegion", true)

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
