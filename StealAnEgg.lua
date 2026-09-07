-- =====================================================================
-- SIIKON BYPASS | STEAL AN EGG ULTIMATE v4.0
-- FULLY CUSTOM UI - Everything works, drag, minimize, hotkey binding
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
    if _G.SiikonUI then
        pcall(function() _G.SiikonUI:Destroy() end)
        _G.SiikonUI = nil
    end
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

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================================
-- 1. STATE
-- =====================================================================
local State = {
    HomeCFrame = nil,
    SpamCount = 5,
    SpamDelay = 0.005,
    Hotkey = "F",
    Minimized = false,
}

-- =====================================================================
-- 2. QUICK EGG PICKUP (ALWAYS ON)
-- =====================================================================
local function QuickGrab()
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root then return end
    
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "SmartPromptPart" then
            for _, p in ipairs(c:GetChildren()) do
                if p.ClassName == "ProximityPrompt" then
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
    
    for _, c in ipairs(workspace:GetChildren()) do
        if c.Name == "SmartPromptPart" and c.Position then
            if (c.Position - root.Position).Magnitude <= 25 then
                local prompt = c:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
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

-- =====================================================================
-- 3. TP HOME
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
        notify("Siikon", "Set Home first!", 2)
        return
    end
    QuickGrab()
    task.wait(0.05)
    for i = 1, State.SpamCount do
        TeleportCharacter(State.HomeCFrame)
        task.wait(State.SpamDelay)
    end
    task.wait(0.05)
    QuickGrab()
    notify("Siikon", "TP Home + Quick Grab!", 2)
end

-- =====================================================================
-- 4. NOTIFY
-- =====================================================================
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "Siikon",
            Text = text or "",
            Duration = duration or 2.5
        })
    end)
end

-- =====================================================================
-- 5. KEYBIND SYSTEM
-- =====================================================================
local KeyNames = {
    [70] = "F", [86] = "V", [71] = "G", [84] = "T", [82] = "R",
    [69] = "E", [81] = "Q", [88] = "X", [67] = "C", [90] = "Z",
    [72] = "H", [74] = "J", [75] = "K", [76] = "L",
    [49] = "1", [50] = "2", [51] = "3", [52] = "4", [53] = "5",
    [54] = "6", [55] = "7", [56] = "8", [57] = "9", [48] = "0",
    [32] = "SPACE", [13] = "ENTER", [27] = "ESC",
    [112] = "F1", [113] = "F2", [114] = "F3", [115] = "F4",
    [116] = "F5", [117] = "F6", [118] = "F7", [119] = "F8",
    [120] = "F9", [121] = "F10", [122] = "F11", [123] = "F12",
}

local MouseNames = {
    ["MouseButton1"] = "LMB",
    ["MouseButton2"] = "RMB",
    ["MouseButton3"] = "MB3",
    ["MouseButton4"] = "MB4",
    ["MouseButton5"] = "MB5",
}

local function IsHotkeyPressed(input)
    if not input then return false end
    local key = State.Hotkey
    if not key or key == "" then return false end
    
    if key == "LMB" and input.UserInputType == Enum.UserInputType.MouseButton1 then return true end
    if key == "RMB" and input.UserInputType == Enum.UserInputType.MouseButton2 then return true end
    if key == "MB3" and input.UserInputType == Enum.UserInputType.MouseButton3 then return true end
    if key == "MB4" and input.UserInputType == Enum.UserInputType.MouseButton4 then return true end
    if key == "MB5" and input.UserInputType == Enum.UserInputType.MouseButton5 then return true end
    
    for k, v in pairs(KeyNames) do
        if v == key and input.KeyCode and input.KeyCode.Value == k then
            return true
        end
    end
    
    return false
end

-- =====================================================================
-- 6. CREATE CUSTOM UI
-- =====================================================================
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SiikonBypass"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer.PlayerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -180)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 16, 1, 16)
    shadow.Position = UDim2.new(0, -8, 0, -8)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.65
    shadow.BorderSizePixel = 0
    shadow.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(80, 110, 240)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title Text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 14, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "SIIKON BYPASS"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -70, 0, 4)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    minBtn.TextSize = 20
    minBtn.Font = Enum.Font.Gotham
    minBtn.Parent = titleBar
    minBtn.MouseButton1Click:Connect(function()
        State.Minimized = not State.Minimized
        mainFrame.Visible = not State.Minimized
        if State.Minimized then
            minBtn.Text = "+"
        else
            minBtn.Text = "—"
        end
    end)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -36, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        genv.SiikonCleanup()
    end)
    
    -- Drag Logic
    local dragging = false
    local dragOffX, dragOffY = 0, 0
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOffX = input.Position.X - mainFrame.AbsolutePosition.X
            dragOffY = input.Position.Y - mainFrame.AbsolutePosition.Y
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position
            local parent = screenGui
            local newX = math.clamp(pos.X - dragOffX, 0, parent.AbsoluteSize.X - mainFrame.AbsoluteSize.X)
            local newY = math.clamp(pos.Y - dragOffY, 0, parent.AbsoluteSize.Y - mainFrame.AbsoluteSize.Y)
            mainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    -- Content Container
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -16, 1, -54)
    content.Position = UDim2.new(0, 8, 0, 46)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(80, 110, 240)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    -- =====================================================================
    -- 7. UI HELPERS
    -- =====================================================================
    local function AddLabel(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(200, 200, 220)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = content
        return lbl
    end
    
    local function AddButton(text, callback, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.Parent = content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = (color or Color3.fromRGB(45, 45, 55)) + Color3.fromRGB(12, 12, 15)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
        end)
        return btn
    end
    
    local function AddKeybindRow(label, currentKey, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundTransparency = 1
        row.Parent = content
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        
        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0.4, 0, 1, -4)
        keyBtn.Position = UDim2.new(0.5, 5, 0.5, -2)
        keyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        keyBtn.BorderSizePixel = 0
        keyBtn.Text = currentKey or "F"
        keyBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        keyBtn.TextSize = 13
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.Parent = row
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 5)
        keyCorner.Parent = keyBtn
        
        local listening = false
        local listenConn = nil
        local escConn = nil
        
        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = Color3.fromRGB(80, 110, 240)
            
            listenConn = UserInputService.InputBegan:Connect(function(input)
                if not input then return end
                local keyName = nil
                
                -- Check keyboard
                if input.KeyCode then
                    local code = input.KeyCode.Value
                    if KeyNames[code] then
                        keyName = KeyNames[code]
                    end
                end
                
                -- Check mouse
                if input.UserInputType then
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "LMB" end
                    if input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "RMB" end
                    if input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MB3" end
                    if input.UserInputType == Enum.UserInputType.MouseButton4 then keyName = "MB4" end
                    if input.UserInputType == Enum.UserInputType.MouseButton5 then keyName = "MB5" end
                end
                
                if keyName then
                    listening = false
                    keyBtn.Text = keyName
                    keyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    if callback then callback(keyName) end
                    if listenConn then listenConn:Disconnect() end
                    if escConn then escConn:Disconnect() end
                end
            end)
            
            escConn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode and input.KeyCode.Value == 27 then
                    listening = false
                    keyBtn.Text = State.Hotkey or "F"
                    keyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    if listenConn then listenConn:Disconnect() end
                    if escConn then escConn:Disconnect() end
                end
            end)
        end)
        
        return {
            Set = function(v)
                keyBtn.Text = v
            end,
            Get = function()
                return keyBtn.Text
            end
        }
    end
    
    local function AddSlider(label, min, max, default, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundTransparency = 1
        row.Parent = content
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": " .. tostring(default)
        lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 6)
        slider.Position = UDim2.new(0, 0, 0, 26)
        slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        slider.BorderSizePixel = 0
        slider.Parent = row
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 3)
        sliderCorner.Parent = slider
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(80, 110, 240)
        fill.BorderSizePixel = 0
        fill.Parent = slider
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = row
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 7)
        knobCorner.Parent = knob
        
        local value = default
        local draggingSlider = false
        
        local function UpdateSlider(newVal)
            value = math.clamp(newVal, min, max)
            local pct = (value - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -7, 0.5, -7)
            lbl.Text = label .. ": " .. tostring(math.floor(value))
            if callback then callback(value) end
        end
        
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
                local pos = input.Position
                local relX = math.clamp((pos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                UpdateSlider(min + (max - min) * relX)
            end
        end)
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = input.Position
                local relX = math.clamp((pos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                UpdateSlider(min + (max - min) * relX)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = false
            end
        end)
        
        return {
            Set = UpdateSlider,
            Get = function() return value end
        }
    end
    
    -- =====================================================================
    -- 8. BUILD UI
    -- =====================================================================
    AddLabel("SIIKON BYPASS v4.0", Color3.fromRGB(80, 110, 240))
    
    -- Keybind
    local keyRow = AddKeybindRow("TP Hotkey", State.Hotkey, function(key)
        State.Hotkey = key
        notify("Siikon", "Hotkey set to: " .. key, 2)
    end)
    
    -- Buttons
    AddButton("Set Home (Current Position)", function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if hrp then
            State.HomeCFrame = hrp.CFrame
            notify("Siikon", "Home set! Press " .. State.Hotkey .. " to TP", 2)
        else
            notify("Siikon", "Character not found!", 2)
        end
    end, Color3.fromRGB(40, 100, 60))
    
    AddButton("TP Home Now", function()
        TpHome()
    end, Color3.fromRGB(55, 75, 130))
    
    -- Spam Count Slider
    local spamSlider = AddSlider("TP Spam Count", 1, 15, State.SpamCount, function(v)
        State.SpamCount = math.floor(v)
    end)
    
    -- Quick Grab Info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "✅ Quick Egg Pickup: ALWAYS ACTIVE"
    infoLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = content
    
    -- Re-patch Button
    AddButton("Re-Patch Prompts", function()
        pcall(function()
            for _, c in ipairs(workspace:GetChildren()) do
                if c.Name == "SmartPromptPart" then
                    for _, p in ipairs(c:GetChildren()) do
                        if p.ClassName == "ProximityPrompt" then
                            p.HoldDuration = 0.0
                            p.MaxActivationDistance = 25.0
                            p.RequiresLineOfSight = false
                        end
                    end
                end
            end
        end)
        notify("Siikon", "Prompts re-patched!", 2)
    end, Color3.fromRGB(45, 45, 65))
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 24)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Ready | Press " .. State.Hotkey .. " to TP"
    statusLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = content
    
    -- Auto-set home
    task.spawn(function()
        task.wait(0.5)
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if hrp and not State.HomeCFrame then
            State.HomeCFrame = hrp.CFrame
            notify("Siikon", "Home auto-set! Press " .. State.Hotkey .. " to TP", 2)
            statusLabel.Text = "Status: Home set | Press " .. State.Hotkey .. " to TP"
        end
    end)
    
    -- Update status on key change
    local oldSet = keyRow.Set
    keyRow.Set = function(v)
        oldSet(v)
        statusLabel.Text = "Status: Ready | Press " .. v .. " to TP"
    end
    
    return screenGui
end

-- =====================================================================
-- 9. KEYBIND LISTENER
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
-- 10. AUTO-PATCH PROMPTS LOOP
-- =====================================================================
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            for _, c in ipairs(workspace:GetChildren()) do
                if c.Name == "SmartPromptPart" then
                    for _, p in ipairs(c:GetChildren()) do
                        if p.ClassName == "ProximityPrompt" then
                            p.HoldDuration = 0.0
                            p.MaxActivationDistance = 25.0
                            p.RequiresLineOfSight = false
                        end
                    end
                end
            end
        end)
    end
end)

-- =====================================================================
-- 11. INIT
-- =====================================================================
_G.SiikonUI = CreateUI()
notify("Siikon Bypass", "Loaded! Press " .. State.Hotkey .. " to TP Home + Quick Grab", 3)
