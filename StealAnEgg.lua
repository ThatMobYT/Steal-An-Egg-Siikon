local genv = (type(getgenv) == "function" and getgenv()) or _G or shared or {}
if type(genv.EggStealerCleanup) == "function" then
    pcall(function() genv.EggStealerCleanup() end)
end

local Connections = {}
genv.EggStealerCleanup = function()
    for _, conn in ipairs(Connections) do
        pcall(function()
            if conn.Disconnect then conn:Disconnect()
            elseif conn.disconnect then conn:disconnect() end
        end)
    end
    Connections = {}
end

local function SafeConnect(obj, signalName, callback)
    if not obj then return end
    pcall(function()
        local sig = obj[signalName]
        if sig then
            local conn = sig:Connect(callback)
            table.insert(Connections, conn)
        end
    end)
end

local function SafeSpawn(fn, ...)
    local args = { ... }
    task.spawn(function()
        pcall(fn, unpack(args))
    end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local SafeZoneCFrame = nil
local SpamCount = 5
local SpamDelay = 0.005

local function TeleportCharacter(cf)
    if not cf then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if hrp then
        hrp.CFrame = cf
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    elseif char:IsA("Model") and char.PrimaryPart then
        char:SetPrimaryPartCFrame(cf)
    end
end

local function Notify(title, text)
    SafeSpawn(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "Boss",
            Text = text or "",
            Duration = 2.5
        })
    end)
end

local function GotoSafeZoneSpam()
    if not SafeZoneCFrame then
        Notify("Warning", "Set Safe Zone first")
        return
    end
    SafeSpawn(function()
        for i = 1, SpamCount do
            TeleportCharacter(SafeZoneCFrame)
            task.wait(SpamDelay)
        end
    end)
    Notify("Safe Zone", "Teleported")
end

if UserInputService then
    SafeConnect(UserInputService, "InputBegan", function(input, gpe)
        if not gpe then
            if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.V then
                GotoSafeZoneSpam()
            end
        end
    end)
end

-- INSui UI Integration
local INSuiLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/NonUI/main/NonUI.lua"))()
if not INSuiLib then
    warn("[EggStealer] Failed to load UI library")
    return
end

local Window = INSuiLib:CreateWindow({
    Title = "Steal an Egg",
    Author = "Boss Mode",
    Folder = "",
    Theme = "Dark",
    Size = { 500, 220 },
    OpenButton = { Title = "1", Draggable = true }
})

local MainSection = Window:Section({ Title = "Controls" })
local MainTab = MainSection:Tab({ Title = "Bosses Ignore Player", Icon = "shield" })

MainTab:Button({
    Title = "Set Safe Zone",
    Icon = "map-pin",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if hrp then
            SafeZoneCFrame = hrp.CFrame
            Notify("Saved", "Press your saved key")
        else
            Notify("Error", "Character not found.")
        end
    end
})

MainTab:Keybind({
    Title = "Escape",
    Default = Enum.KeyCode.F,
    Callback = function()
        GotoSafeZoneSpam()
    end
})

-- Speed slider
local SpeedSection = Window:Section({ Title = "Settings" })
local SpeedTab = SpeedSection:Tab({ Title = "Movement", Icon = "sliders" })

SpeedTab:Slider({
    Title = "Flight Speed",
    Min = 50,
    Max = 2000,
    Default = 850,
    Callback = function(value)
        _G.FlightSpeed = value
    end
})

SpeedTab:Slider({
    Title = "Hold Duration",
    Min = 0,
    Max = 100,
    Default = 5,
    Callback = function(value)
        SpamDelay = value / 1000
    end
})

Notify("Ready", "System loaded successfully")
