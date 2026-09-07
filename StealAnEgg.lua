-- Siikon Bypass - Potassium Optimized
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
    spawn(function()
        pcall(fn, unpack(args))
    end)
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- Variables
local safeZoneCFrame = nil
local teleportKey = Enum.KeyCode.F
local minimizeKey = Enum.KeyCode.RightControl
local minimized = false
local spamCount = 8
local spamDelay = 0.003
local tpCooldown = 0
local lastTpTime = 0

-- Anti-ragdoll
local function preventRagdoll()
    local char = LP.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("Motor6D") then
                v.Enabled = true
            end
        end
    end
end

-- Anti-reset via constant velocity monitoring
local function preventReset()
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end
end

-- Teleport function with anti-reset
local function TeleportToSafe()
    if not safeZoneCFrame then
        NonUI:Notify("Warning", "Set Safe Zone first")
        return
    end
    
    local now = tick()
    if now - lastTpTime < 0.1 then return end
    lastTpTime = now
    
    SafeSpawn(function()
        for i = 1, spamCount do
            local char = LP.Character
            if not char then break end
            
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if hrp then
                hrp.CFrame = safeZoneCFrame
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                
                -- Prevent ragdoll
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end
            
            task.wait(spamDelay)
        end
        
        -- Final position lock
        local char = LP.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = safeZoneCFrame
            end
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end)
end

-- Notification system
local NonUI = {}
do
    function NonUI:Notify(title, text)
        SafeSpawn(function()
            local gui = Instance.new("ScreenGui")
            gui.Parent = CoreGui
            gui.Name = "SiikonNotify"
            gui.ResetOnSpawn = false
            
            local frame = Instance.new("Frame")
            frame.Parent = gui
            frame.Size = UDim2.new(0, 320, 0, 50)
            frame.Position = UDim2.new(0.5, -160, 0.85, 0)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            frame.BorderSizePixel = 0
            frame.BackgroundTransparency = 0.1
            
            local fc = Instance.new("UICorner")
            fc.Parent = frame
            fc.CornerRadius = UDim.new(0, 10)
            
            -- Glow border
            local border = Instance.new("Frame")
            border.Parent = frame
            border.Size = UDim2.new(1, 2, 1, 2)
            border.Position = UDim2.new(0, -1, 0, -1)
            border.BackgroundColor3 = Color3.fromRGB(80, 60, 220)
            border.BackgroundTransparency = 0.7
            border.BorderSizePixel = 0
            local bc = Instance.new("UICorner")
            bc.Parent = border
            bc.CornerRadius = UDim.new(0, 11)
            
            local t = Instance.new("TextLabel")
            t.Parent = frame
            t.Size = UDim2.new(1, -20, 0, 22)
            t.Position = UDim2.new(0, 10, 0, 4)
            t.Text = title or "Siikon"
            t.TextColor3 = Color3.fromRGB(220, 210, 255)
            t.TextSize = 15
            t.Font = Enum.Font.GothamSemibold
            t.BackgroundTransparency = 1
            t.TextXAlignment = Enum.TextXAlignment.Left
            
            local c = Instance.new("TextLabel")
            c.Parent = frame
            c.Size = UDim2.new(1, -20, 0, 20)
            c.Position = UDim2.new(0, 10, 0, 26)
            c.Text = text or ""
            c.TextColor3 = Color3.fromRGB(180, 180, 210)
            c.TextSize = 12
            c.Font = Enum.Font.Gotham
            c.BackgroundTransparency = 1
            c.TextXAlignment = Enum.TextXAlignment.Left
            
            task.wait(2.8)
            gui:Destroy()
        end)
    end
end

-- Create main UI
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = CoreGui
    screenGui.Name = "SiikonBypass"
    screenGui.ResetOnSpawn = false
    
    local mainSize = 420
    local main = Instance.new("Frame")
    main.Parent = screenGui
    main.Size = UDim2.new(0, mainSize, 0, 260)
    main.Position = UDim2.new(0.5, -mainSize/2, 0.5, -130)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    main.BorderSizePixel = 0
    main.BackgroundTransparency = 0.05
    main.ClipsDescendants = true
    
    local mc = Instance.new("UICorner")
    mc.Parent = main
    mc.CornerRadius = UDim.new(0, 14)
    
    -- Glow border
    local glow = Instance.new("Frame")
    glow.Parent = main
    glow.Size = UDim2.new(1, 2, 1, 2)
    glow.Position = UDim2.new(0, -1, 0, -1)
    glow.BackgroundColor3 = Color3.fromRGB(90, 70, 230)
    glow.BackgroundTransparency = 0.6
    glow.BorderSizePixel = 0
    local gc = Instance.new("UICorner")
    gc.Parent = glow
    gc.CornerRadius = UDim.new(0, 15)
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Parent = main
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = Color3.fromRGB(90, 70, 230)
    titleBar.BackgroundTransparency = 0.15
    titleBar.BorderSizePixel = 0
    
    local titleText = Instance.new("TextLabel")
    titleText.Parent = titleBar
    titleText.Size = UDim2.new(0.6, 0, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.Text = "SIIKON BYPASS"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 17
    titleText.Font = Enum.Font.GothamBold
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local verText = Instance.new("TextLabel")
    verText.Parent = titleBar
    verText.Size = UDim2.new(0.3, 0, 1, 0)
    verText.Position = UDim2.new(0.6, 0, 0, 0)
    verText.Text = "v2.0"
    verText.TextColor3 = Color3.fromRGB(180, 180, 220)
    verText.TextSize = 11
    verText.Font = Enum.Font.Gotham
    verText.BackgroundTransparency = 1
    verText.TextXAlignment = Enum.TextXAlignment.Right
    
    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Parent = titleBar
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1,
