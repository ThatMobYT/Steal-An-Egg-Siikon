local genv = (type(getgenv) == "function" and getenv()) or _G or shared or {}
if type(genv.EggStealerCleanup) == "function" then
    pcall(genv.EggStealerCleanup)
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

local NonUI = nil
pcall(function()
    NonUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/NonUI/main/NonUI.lua"))()
end)

if not NonUI then
    NonUI = genv.NonUI or _G.NonUI or shared.NonUI
end

if not NonUI then
    warn("[EggStealer] NonUI library not found.")
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Running = true

-- ========== SAFE ZONE (UNCHANGED) ==========
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
        if NonUI and NonUI.Notify then
            NonUI:Notify({ Title = title or "Boss", Content = text or "", Duration = 2.5 })
        end
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

-- ========== ADDED: INSTANT PICKUP ==========

local function PatchAllSmartPrompts()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c.Name == "SmartPromptPart" then
            for _, p in ipairs(c:GetChildren()) do
                if p.ClassName == "ProximityPrompt" then
                    pcall(function()
                        p.HoldDuration = 0.0
                        p.MaxActivationDistance = 25.0
                        p.RequiresLineOfSight = false
                    end)
                    local addr = p.Address
                    if addr and type(addr) == "number" and addr > 0x10000 and memory_write then
                        pcall(function()
                            memory_write("float", addr + 0x120, 0.0)
                            memory_write("float", addr + 0x128, 25.0)
                        end)
                    end
                end
            end
        end
    end
end

local function InstantPickup()
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not hrp then return end
    local pos = hrp.Position
    local bestPrompt = nil
    local bestDist = math.huge

    for _, part in ipairs(Workspace:GetChildren()) do
        if part.Name == "SmartPromptPart" and part.Position then
            local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                local dist = (part.Position - pos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestPrompt = prompt
                end
            end
        end
    end

    if bestPrompt then
        if fireproximityprompt then
            pcall(fireproximityprompt, bestPrompt, 0)
        end
        pcall(function()
            bestPrompt:InputHoldBegin()
            task.wait(0.02)
            bestPrompt:InputHoldEnd()
        end)
        pcall(function()
            keypress(0x45)
            keypress(69)
            task.wait(0.05)
            keyrelease(0x45)
            keyrelease(69)
        end)
    end
end

-- Bind E key to instant pickup (ADDED, does not affect F escape)
if UserInputService then
    SafeConnect(UserInputService, "InputBegan", function(input, gpe)
        if not gpe then
            if input.KeyCode == Enum.KeyCode.E then
                InstantPickup()
            end
            if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.V then
                GotoSafeZoneSpam()
            end
        end
    end)
end

-- Auto‑patch on startup & periodically
SafeSpawn(function()
    task.wait(1)
    PatchAllSmartPrompts()
    Notify("Ready", "Instant pickup (E) + Safe Zone (F)")
end)

task.spawn(function()
    while Running do
        task.wait(60)
        PatchAllSmartPrompts()
    end
end)

-- ========== UI (renamed title & section) ==========
local Window = NonUI:CreateWindow({
    Title = "Siikon Bypass",          -- changed
    Author = "Where is the boss",
    Folder = "",
    Theme = "Dark",
    Size = { 500, 220 },
    OpenButton = { Title = "1", Draggable = true }
})

local MainSection = Window:Section({ Title = "Misc" })  -- renamed
local MainTab = MainSection:Tab({ Title = "General", Icon = "shield" })  -- renamed

MainTab:Button({
    Title = "Set Safe Zone",
    Icon = "map-pin",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if hrp then
            SafeZoneCFrame = hrp.CFrame
            Notify("Saved", "Press F to escape")
        else
            Notify("Error", "Character not found.")
        end
    end
})

MainTab:Keybind({
    Title = "Escape to Safe Zone",
    Default = Enum.KeyCode.F,
    Callback = function()
        GotoSafeZoneSpam()
    end
})

Notify("Ready", "F1 menu | E = instant pickup | F = safe zone")
