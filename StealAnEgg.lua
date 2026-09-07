siikon bypass

mod made by siikon

```lua
-- =====================================================================
-- SIIKON BYPASS | STEAL AN EGG ULTIMATE
-- Clean NonUI interface + Quick Egg Pickup + TP Home
-- =====================================================================

local genv = (type(getgenv) == "function" and getgenv()) or _G or shared or {}
if type(genv.SiikonCleanup) == "function" then
    pcall(function() genv.SiikonCleanup() end)
end

local Connections = {}
genv.SiikonCleanup = function()
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

-- =====================================================================
-- 1. LOAD NONUI LIBRARY
-- =====================================================================
local NonUI = nil
pcall(function()
    NonUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/NonUI/main/NonUI.lua"))()
end)

if not NonUI then
    NonUI = genv.NonUI or _G.NonUI or shared.NonUI
end

if not NonUI then
    warn("[Siikon] NonUI library not found.")
    return
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================================
-- 2. STATE
-- =====================================================================
local State = {
    HomeCFrame = nil,
    SpamCount = 5,
    SpamDelay = 0.005,
    Hotkey = "F",
}

-- =====================================================================
-- 3. QUICK EGG PICKUP (ALWAYS ON)
-- =====================================================================
local function QuickGrab()
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root then return end
    
    -- Patch prompts
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "SmartPromptPart" then
            for _, p in ipairs(c:GetChildren()) do
                if p.ClassName == "ProximityPrompt" then
                    local parentName = p.Parent and p.Parent.Name or ""
                    if parentName == "SmartPromptPart" or parentName:find("Egg") then
                        pcall(function()
                            p.HoldDuration = 0.0
                            p.MaxActivationDistance = 25.0
                            p.RequiresLineOfSight = false
                        end)
                        if fireproximityprompt then
                            pcall(fireproximityprompt, p, 0)
                        end
                    end
                end
            end
        end
    end
    
    -- Grab nearby eggs
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "SmartPromptPart" and c.Position then
            if (c.Position - root.Position).Magnitude <= 25 then
                local prompt = c:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    local parentName = prompt.Parent and prompt.Parent.Name or ""
                    if parentName == "SmartPromptPart" or parentName:find("Egg") then
                        pcall(function()
                            fireproximityprompt(prompt, 0)
                            prompt:InputHoldBegin()
                            task.wait(0.01)
                            prompt:InputHoldEnd()
                        end)
                        pcall(function()
                            keypress(0x45)
                            task.wait(0.02)
                            keyrelease(0x45)
                        end)
                    end
                end
            end
        end
    end
end

-- =====================================================================
-- 4. TP HOME
-- =====================================================================
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
        pcall(function() char:SetPrimaryPartCFrame(cf) end)
    end
end

local function TpHome()
    if not State.HomeCFrame then
        Notify("Siikon", "Set Home first!", 2)
        return
    end
    -- Quick grab before TP
    QuickGrab()
    task.wait(0.05)
    -- TP spam
    for i = 1, State.SpamCount do
        TeleportCharacter(State.HomeCFrame)
        task.wait(State.SpamDelay)
    end
    -- Quick grab after TP
    task.wait(0.05)
    QuickGrab()
    Notify("Siikon", "TP Home + Quick Grab!", 2)
end

-- =====================================================================
-- 5. NOTIFY
-- =====================================================================
local function Notify(title, text, duration)
    SafeSpawn(function()
        if NonUI and NonUI.Notify then
            NonUI:Notify({
                Title = title or "Siikon",
                Content = text or "",
                Duration = duration or 2.5
            })
        else
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = title or "Siikon",
                    Text = text or "",
                    Duration = duration or 2.5
                })
            end)
        end
    end)
end

-- =====================================================================
-- 6. KEYBIND SYSTEM
-- =====================================================================
local KeyMap = {
    ["F"] = 70,
    ["V"] = 86,
    ["G"] = 71,
    ["T"] = 84,
    ["R"] = 82,
    ["E"] = 69,
    ["Q"] = 81,
    ["X"] = 88,
    ["C"] = 67,
    ["Z"] = 90,
    ["LMB"] = "MouseButton1",
    ["RMB"] = "MouseButton2",
    ["MB3"] = "MouseButton3",
    ["MB4"] = "MouseButton4",
    ["MB5"] = "MouseButton5",
}

local function IsHotkeyPressed(input)
    if not input then return false end
    local key = State.Hotkey
    if not key or key == "" then return false end
    
    local keyCode = KeyMap[key]
    if keyCode and type(keyCode) == "number" then
        if input.KeyCode and input.KeyCode.Value == keyCode then
            return true
        end
    end
    
    if key == "LMB" and input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
    if key == "RMB" and input.UserInputType == Enum.UserInputType.MouseButton2 then return true end
    if key == "MB3" and input.UserInputType == Enum.UserInputType.MouseButton3 then return true end
    if key == "MB4" and input.UserInputType == Enum.UserInputType.MouseButton4 then return true end
    if key == "MB5" and input.UserInputType == Enum.UserInputType.MouseButton5 then return true end
    
    return false
end

-- =====================================================================
-- 7. CREATE NONUI WINDOW
-- =====================================================================
local Window = NonUI:CreateWindow({
    Title = "Siikon Bypass",
    Author = "v3.0",
    Folder = "SiikonBypass",
    Theme = "Dark",
    Size = { 380, 280 },
    OpenButton = { Title = "Siikon", Draggable = true, Scale = 0.9 }
})

-- =====================================================================
-- 8. MAIN TAB
-- =====================================================================
local MainSection = Window:Section({ Title = "Controls" })
local MainTab = MainSection:Tab({ Title = "Main", Icon = "home" })

-- Set Home Button
MainTab:Button({
    Title = "Set Home (Current Position)",
    Icon = "map-pin",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if hrp then
            State.HomeCFrame = hrp.CFrame
            Notify("Siikon", "Home set! Press " .. State.Hotkey .. " to TP", 2)
        else
            Notify("Siikon", "Character not found!", 2)
        end
    end
})

-- TP Home Button
MainTab:Button({
    Title = "TP Home Now",
    Icon = "target",
    Callback = function()
        TpHome()
    end
})

-- Keybind
MainTab:Keybind({
    Title = "TP Hotkey",
    Default = "F",
    Callback = function(key)
        State.Hotkey = key or "F"
        Notify("Siikon", "Hotkey set to: " .. State.Hotkey, 2)
    end
})

-- Spam Count Slider
MainTab:Slider({
    Title = "TP Spam Count",
    Value = {
        Min = 1,
        Max = 15,
        Default = 5,
        Step = 1
    },
    Callback = function(v)
        State.SpamCount = math.floor(v)
    end
})

-- =====================================================================
-- 9. INFO TAB
-- =====================================================================
local InfoSection = Window:Section({ Title = "Info" })
local InfoTab = InfoSection:Tab({ Title = "Status", Icon = "info" })

InfoTab:Paragraph({
    Title = "Siikon Bypass v3.0",
    Desc = "Quick Egg Pickup is always enabled.\nPress your hotkey to TP Home + Grab eggs."
})

InfoTab:Paragraph({
    Title = "Status",
    Desc = function()
        return "Home: " .. (State.HomeCFrame and "Set ✅" or "Not Set ❌") ..
            "\nHotkey: " .. State.Hotkey ..
            "\nSpam Count: " .. State.SpamCount
    end
})

-- =====================================================================
-- 10. KEYBIND LISTENER
-- =====================================================================
SafeConnect(UserInputService, "InputBegan", function(input, gpe)
    if not gpe and not input.UserInputType then return end
    if gpe then return end
    
    if UserInputService:GetFocusedTextBox() then return end
    
    if IsHotkeyPressed(input) then
        TpHome()
    end
end)

-- =====================================================================
-- 11. AUTO-PATCH PROMPTS LOOP
-- =====================================================================
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            for _, c in ipairs(workspace:GetChildren()) do
                if c.Name == "SmartPromptPart" then
                    for _, p in ipairs(c:GetChildren()) do
                        if p.ClassName == "ProximityPrompt" then
                            local parentName = p.Parent and p.Parent.Name or ""
                            if parentName == "SmartPromptPart" or parentName:find("Egg") then
                                p.HoldDuration = 0.0
                                p.MaxActivationDistance = 25.0
                                p.RequiresLineOfSight = false
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- =====================================================================
-- 12. AUTO-SET HOME ON START
-- =====================================================================
task.spawn(function()
    task.wait(1.5)
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if hrp then
        State.HomeCFrame = hrp.CFrame
        Notify("Siikon", "Home auto-set! Press " .. State.Hotkey .. " to TP", 2)
    end
end)

Notify("Siikon Bypass", "Loaded! Quick Egg Pickup always active.", 3)
```
