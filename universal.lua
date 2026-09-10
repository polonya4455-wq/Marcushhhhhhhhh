--[[
    ███╗   ███╗ █████╗ ██████╗  ██████╗██╗   ██╗███████╗██╗  ██╗
    ████╗ ████║██╔══██╗██╔══██╗██╔════╝██║   ██║██╔════╝███████║
    ██╔████╔██║███████║██████╔╝██║     ██║   ██║███████╗██╔══██║
    ██║╚██╔╝██║██╔══██║██╔══██╗██║     ██║   ██║╚════██║██║  ██║
    ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗╚██████╔╝███████║██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚═╝  ╚═╝
    Marcush Hub v3.0 — Bypassed Edition
    CFrame Speed/Fly | Fixed NoClip | Fixed Aimbot | Silent Aim
    __namecall hook | RenderStep priority override
--]]

----------------------------------------------------------------
--  EXECUTOR COMPAT CHECK
----------------------------------------------------------------
local hookmetamethod  = hookmetamethod or (getgenv and getgenv().hookmetamethod)
local getnamecallmethod = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
local newcclosure     = newcclosure or function(f) return f end
local checkcaller     = checkcaller or function() return false end
local getrawmetatable = getrawmetatable or debug.getmetatable
local setreadonly     = setreadonly or function() end

----------------------------------------------------------------
--  SERVICES
----------------------------------------------------------------
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInput      = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

----------------------------------------------------------------
--  STATE
----------------------------------------------------------------
local State = {
    NoClip       = false,
    ESP          = false,
    Aimbot       = false,
    SilentAim    = false,
    Speed        = false,
    Fly          = false,
    InfJump      = false,
    Fullbright   = false,
    GodMode      = false,
    AntiAFK      = false,
    -- tunables
    SpeedValue   = 3,     -- CFrame multiplier (1 = normal)
    FlySpeed     = 80,
    AimbotFOV    = 250,
    AimbotSmooth = 0.25,
}

local Connections = {}
local ESPObjects  = {}
local GuiOpen     = true

----------------------------------------------------------------
--  UTILITY
----------------------------------------------------------------
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

local function GetClosestPlayerToScreen()
    local closest = nil
    local shortDist = State.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if IsAlive(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortDist then
                        shortDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function GetClosestPlayerToChar()
    local myHRP = GetHRP()
    if not myHRP then return nil end
    local closest, shortDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if IsAlive(player) then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude
                if dist < shortDist then
                    shortDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

----------------------------------------------------------------
--  GUI CLEANUP
----------------------------------------------------------------
if game.CoreGui:FindFirstChild("MarcushHub") then
    game.CoreGui:FindFirstChild("MarcushHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MarcushHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

----------------------------------------------------------------
--  MAIN FRAME
----------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 440, 0, 520)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(138, 43, 226)
Stroke.Thickness = 2
Stroke.Transparency = 0.2
Stroke.Parent = MainFrame

-- Gradient glow effect
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 60, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 200))
}
Gradient.Rotation = 45
Gradient.Parent = Stroke

-- animate gradient
spawn(function()
    local rot = 0
    while ScreenGui and ScreenGui.Parent do
        rot = (rot + 1) % 360
        Gradient.Rotation = rot
        RunService.Heartbeat:Wait()
    end
end)

----------------------------------------------------------------
--  HEADER
----------------------------------------------------------------
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ MARCUSH HUB v3.0"
Title.TextColor3 = Color3.fromRGB(160, 80, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Version tag
local VersionTag = Instance.new("TextLabel")
VersionTag.Size = UDim2.new(0, 80, 0, 18)
VersionTag.Position = UDim2.new(0, 220, 0, 16)
VersionTag.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
VersionTag.Text = "BYPASSED"
VersionTag.TextColor3 = Color3.fromRGB(255, 255, 255)
VersionTag.TextSize = 10
VersionTag.Font = Enum.Font.GothamBold
VersionTag.Parent = Header
Instance.new("UICorner", VersionTag).CornerRadius = UDim.new(1, 0)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -75, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

----------------------------------------------------------------
--  SCROLL FRAME
----------------------------------------------------------------
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "Toggles"
ScrollFrame.Size = UDim2.new(1, -20, 1, -65)
ScrollFrame.Position = UDim2.new(0, 10, 0, 55)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = ScrollFrame

----------------------------------------------------------------
--  SECTION HEADER FACTORY
----------------------------------------------------------------
local function CreateSection(text, layoutOrder)
    local Section = Instance.new("TextLabel")
    Section.Size = UDim2.new(1, -10, 0, 25)
    Section.BackgroundTransparency = 1
    Section.Text = "  " .. text
    Section.TextColor3 = Color3.fromRGB(138, 43, 226)
    Section.TextSize = 13
    Section.Font = Enum.Font.GothamBold
    Section.TextXAlignment = Enum.TextXAlignment.Left
    Section.LayoutOrder = layoutOrder
    Section.Parent = ScrollFrame
end

----------------------------------------------------------------
--  TOGGLE FACTORY
----------------------------------------------------------------
local function CreateToggle(name, desc, layoutOrder, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 46)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    Frame.BorderSizePixel = 0
    Frame.LayoutOrder = layoutOrder
    Frame.Parent = ScrollFrame
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 0, 20)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(240, 240, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(0.7, 0, 0, 14)
    Desc.Position = UDim2.new(0, 12, 0, 26)
    Desc.BackgroundTransparency = 1
    Desc.Text = desc
    Desc.TextColor3 = Color3.fromRGB(100, 100, 120)
    Desc.TextSize = 10
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Frame

    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 44, 0, 22)
    SwitchBG.Position = UDim2.new(1, -58, 0.5, -11)
    SwitchBG.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    SwitchBG.BorderSizePixel = 0
    SwitchBG.Parent = Frame
    Instance.new("UICorner", SwitchBG).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = UDim2.new(0, 3, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(160, 160, 170)
    Circle.BorderSizePixel = 0
    Circle.Parent = SwitchBG
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    local toggled = false
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = Frame

    Btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        if toggled then
            TweenService:Create(Circle, ti, {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
            TweenService:Create(SwitchBG, ti, {BackgroundColor3 = Color3.fromRGB(138, 43, 226)}):Play()
        else
            TweenService:Create(Circle, ti, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(160,160,170)}):Play()
            TweenService:Create(SwitchBG, ti, {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
        end
        callback(toggled)
    end)
end

----------------------------------------------------------------
--  SLIDER FACTORY
----------------------------------------------------------------
local function CreateSlider(name, min, max, default, layoutOrder, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 46)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    Frame.BorderSizePixel = 0
    Frame.LayoutOrder = layoutOrder
    Frame.Parent = ScrollFrame
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, -20, 0, 18)
    ValLabel.Position = UDim2.new(0, 12, 0, 3)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = name .. ": " .. default
    ValLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    ValLabel.TextSize = 12
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValLabel.Parent = Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 28)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    Track.BorderSizePixel = 0
    Track.Parent = Frame
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local pct = (default - min) / (max - min)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(pct, -6, 0.5, -6)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 3
    Knob.Parent = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local DragBtn = Instance.new("TextButton")
    DragBtn.Size = UDim2.new(1, 10, 1, 16)
    DragBtn.Position = UDim2.new(0, -5, 0, -8)
    DragBtn.BackgroundTransparency = 1
    DragBtn.Text = ""
    DragBtn.ZIndex = 4
    DragBtn.Parent = Track

    DragBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local ratio = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * ratio)
            Fill.Size = UDim2.new(ratio, 0, 1, 0)
            Knob.Position = UDim2.new(ratio, -6, 0.5, -6)
            ValLabel.Text = name .. ": " .. value
            callback(value)
        end
    end)
end

----------------------------------------------------------------
--  ██████  NOCLIP — FIXED  ██████
--  Stepped + humanoid state override
----------------------------------------------------------------
local function StartNoClip()
    -- Disable fall/physics states that re-enable collision
    local hum = GetHumanoid()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end

    Connections["NoClip"] = RunService.Stepped:Connect(function(_, dt)
        if not State.NoClip then return end
        local char = GetCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    -- Backup: also on Heartbeat (bazı oyunlar Stepped'den sonra collision reset ediyor)
    Connections["NoClip2"] = RunService.Heartbeat:Connect(function()
        if not State.NoClip then return end
        local char = GetCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function StopNoClip()
    if Connections["NoClip"] then Connections["NoClip"]:Disconnect(); Connections["NoClip"] = nil end
    if Connections["NoClip2"] then Connections["NoClip2"]:Disconnect(); Connections["NoClip2"] = nil end
    local hum = GetHumanoid()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
end

----------------------------------------------------------------
--  ██████  ESP MODULE  ██████
----------------------------------------------------------------
local function CreateESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hrp or not hum or not head then return end

    if ESPObjects[player.Name] then
        for _, obj in pairs(ESPObjects[player.Name]) do pcall(function() obj:Destroy() end) end
    end
    ESPObjects[player.Name] = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "MarcushESP"
    highlight.FillColor = Color3.fromRGB(138, 43, 226)
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(200, 100, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = char
    highlight.Parent = char
    table.insert(ESPObjects[player.Name], highlight)

    local bb = Instance.new("BillboardGui")
    bb.Name = "MarcushInfo"
    bb.Size = UDim2.new(0, 200, 0, 55)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Parent = char
    table.insert(ESPObjects[player.Name], bb)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName .. " [@" .. player.Name .. "]"
    nameLabel.TextColor3 = Color3.fromRGB(200, 130, 255)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = bb

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0.3, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.45, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = ""
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextStrokeTransparency = 0.3
    infoLabel.Parent = bb

    local hpBG = Instance.new("Frame")
    hpBG.Size = UDim2.new(0.6, 0, 0, 4)
    hpBG.Position = UDim2.new(0.2, 0, 0.82, 0)
    hpBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBG.BorderSizePixel = 0
    hpBG.Parent = bb
    Instance.new("UICorner", hpBG).CornerRadius = UDim.new(1, 0)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBG
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

    spawn(function()
        while State.ESP and char and char.Parent do
            local myHRP = GetHRP()
            if myHRP and hrp and hrp.Parent and hum and hum.Parent then
                local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                local hp = math.floor(hum.Health)
                local maxHp = math.floor(hum.MaxHealth)
                infoLabel.Text = "❤ " .. hp .. "/" .. maxHp .. "  📏 " .. dist .. "m"
                local ratio = math.clamp(hp / maxHp, 0, 1)
                hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                hpFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(0,255,100) or ratio > 0.25 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,50,50)
            end
            task.wait(0.15)
        end
    end)
end

local function ClearESP()
    for name, objects in pairs(ESPObjects) do
        for _, obj in pairs(objects) do pcall(function() obj:Destroy() end) end
    end
    ESPObjects = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local h = player.Character:FindFirstChild("MarcushESP")
            if h then h:Destroy() end
            local b = player.Character:FindFirstChild("MarcushInfo")
            if b then b:Destroy() end
        end
    end
end

local function RefreshESP()
    ClearESP()
    if State.ESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if IsAlive(player) then CreateESP(player) end
        end
    end
end

----------------------------------------------------------------
--  ██████  AIMBOT — FIXED (BindToRenderStep priority > Camera)  ██████
--  Roblox camera controller priority = 200
--  We bind at 201 so our CFrame write happens AFTER the engine camera
----------------------------------------------------------------
local AIMBOT_BIND_NAME = "MarcushAimbot"

local function StartAimbot()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND_NAME) end)

    RunService:BindToRenderStep(AIMBOT_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Aimbot then return end
        if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

        local target = GetClosestPlayerToScreen()
        if not target or not target.Character then return end
        local head = target.Character:FindFirstChild("Head")
        if not head then return end

        local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, State.AimbotSmooth)
    end)
end

local function StopAimbot()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND_NAME) end)
end

----------------------------------------------------------------
--  ██████  SILENT AIM — __namecall + Mouse.Hit HOOK  ██████
--  Intercepts RemoteEvent:FireServer / RemoteFunction:InvokeServer
--  Replaces position/CFrame args with nearest enemy head position
--  Also hooks Mouse.Hit and Mouse.Target for games that read those
----------------------------------------------------------------
local SilentAimOldNamecall = nil
local SilentAimOldIndex    = nil
local SilentAimTarget      = nil

local function UpdateSilentTarget()
    Connections["SilentUpdate"] = RunService.Heartbeat:Connect(function()
        if State.SilentAim then
            SilentAimTarget = GetClosestPlayerToScreen()
        else
            SilentAimTarget = nil
        end
    end)
end

local function GetSilentHeadPos()
    if SilentAimTarget and SilentAimTarget.Character then
        local head = SilentAimTarget.Character:FindFirstChild("Head")
        if head then return head.Position, head.CFrame end
    end
    return nil, nil
end

local function StartSilentAim()
    UpdateSilentTarget()

    -- HOOK __namecall: intercept FireServer / InvokeServer calls
    if hookmetamethod and getnamecallmethod then
        local mt = getrawmetatable(game)
        if mt then
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)

            SilentAimOldNamecall = oldNamecall

            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if State.SilentAim and (method == "FireServer" or method == "InvokeServer") then
                    local args = {...}
                    local headPos, headCF = GetSilentHeadPos()
                    if headPos then
                        -- Walk through args, replace any CFrame or Vector3 that looks like
                        -- a mouse hit / aim position with the target head
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "CFrame" then
                                args[i] = headCF
                            elseif typeof(arg) == "Vector3" then
                                args[i] = headPos
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end
                return oldNamecall(self, ...)
            end)

            setreadonly(mt, true)
        end
    end

    -- HOOK __index: intercept Mouse.Hit and Mouse.Target reads
    if hookmetamethod then
        local mt = getrawmetatable(game)
        if mt then
            local oldIndex = rawget(mt, "__index") or mt.__index
            setreadonly(mt, false)

            SilentAimOldIndex = oldIndex

            mt.__index = newcclosure(function(self, key)
                if State.SilentAim and self == Mouse then
                    if key == "Hit" then
                        local _, headCF = GetSilentHeadPos()
                        if headCF then return headCF end
                    elseif key == "Target" then
                        if SilentAimTarget and SilentAimTarget.Character then
                            local head = SilentAimTarget.Character:FindFirstChild("Head")
                            if head then return head end
                        end
                    end
                end
                return oldIndex(self, key)
            end)

            setreadonly(mt, true)
        end
    end
end

local function StopSilentAim()
    SilentAimTarget = nil
    if Connections["SilentUpdate"] then
        Connections["SilentUpdate"]:Disconnect()
        Connections["SilentUpdate"] = nil
    end

    -- Restore hooks
    if SilentAimOldNamecall and hookmetamethod then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = SilentAimOldNamecall
            setreadonly(mt, true)
        end)
        SilentAimOldNamecall = nil
    end
    if SilentAimOldIndex and hookmetamethod then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__index = SilentAimOldIndex
            setreadonly(mt, true)
        end)
        SilentAimOldIndex = nil
    end
end

----------------------------------------------------------------
--  FOV CIRCLE
----------------------------------------------------------------
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Color3.fromRGB(138, 43, 226)
    FOVCircle.Thickness = 1.5
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.6
    FOVCircle.Radius = State.AimbotFOV
    FOVCircle.Visible = false
end)

Connections["FOVUpdate"] = RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = State.AimbotFOV
        FOVCircle.Visible = State.Aimbot or State.SilentAim
    end
end)

----------------------------------------------------------------
--  ██████  CFRAME SPEED (bypass — no WalkSpeed)  ██████
--  Moves HRP via CFrame every Heartbeat based on Humanoid.MoveDirection
--  WalkSpeed stays at 16 (default) so server sees nothing suspicious
----------------------------------------------------------------
local function StartCFrameSpeed()
    -- keep WalkSpeed normal so server-side check passes
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 end

    Connections["CFrameSpeed"] = RunService.Heartbeat:Connect(function(dt)
        if not State.Speed then return end
        local hrp = GetHRP()
        local hum2 = GetHumanoid()
        if not hrp or not hum2 then return end

        local moveDir = hum2.MoveDirection
        if moveDir.Magnitude > 0 then
            -- State.SpeedValue is a multiplier (1 = normal, 3 = 3x, etc.)
            -- base speed ≈ 16 studs/s, we add extra on top
            local extra = moveDir.Unit * (State.SpeedValue - 1) * 16 * dt
            hrp.CFrame = hrp.CFrame + extra
        end
    end)
end

local function StopCFrameSpeed()
    if Connections["CFrameSpeed"] then
        Connections["CFrameSpeed"]:Disconnect()
        Connections["CFrameSpeed"] = nil
    end
end

----------------------------------------------------------------
--  ██████  CFRAME FLY (bypass — no BodyVelocity/BodyGyro)  ██████
--  Pure CFrame manipulation = no physics objects to detect
--  Anti-fall: constantly set Humanoid state to Physics to prevent gravity
----------------------------------------------------------------
local function StartCFrameFly()
    local hrp = GetHRP()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    Connections["CFrameFly"] = RunService.Heartbeat:Connect(function(dt)
        if not State.Fly then return end
        hrp = GetHRP()
        hum = GetHumanoid()
        if not hrp or not hum then return end

        -- Prevent gravity
        hum:ChangeState(Enum.HumanoidStateType.Swimming)

        local dir = Vector3.new(0, 0, 0)
        local camCF = Camera.CFrame

        if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        if dir.Magnitude > 0 then
            dir = dir.Unit
        end

        -- Zero out velocity so physics doesn't fight us
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = hrp.CFrame + (dir * State.FlySpeed * dt)
    end)
end

local function StopCFrameFly()
    if Connections["CFrameFly"] then
        Connections["CFrameFly"]:Disconnect()
        Connections["CFrameFly"] = nil
    end
    local hum = GetHumanoid()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

----------------------------------------------------------------
--  INFINITE JUMP
----------------------------------------------------------------
local function StartInfJump()
    Connections["InfJump"] = UserInput.JumpRequest:Connect(function()
        if State.InfJump then
            local hum = GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

local function StopInfJump()
    if Connections["InfJump"] then Connections["InfJump"]:Disconnect(); Connections["InfJump"] = nil end
end

----------------------------------------------------------------
--  FULLBRIGHT
----------------------------------------------------------------
local OrigAmbient     = Lighting.Ambient
local OrigBrightness  = Lighting.Brightness
local OrigOutdoor     = Lighting.OutdoorAmbient
local OrigFogEnd      = Lighting.FogEnd

local function ToggleFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 1e9
    else
        Lighting.Ambient = OrigAmbient
        Lighting.Brightness = OrigBrightness
        Lighting.OutdoorAmbient = OrigOutdoor
        Lighting.FogEnd = OrigFogEnd
    end
end

----------------------------------------------------------------
--  GOD MODE (client-side HP loop)
----------------------------------------------------------------
local function StartGodMode()
    Connections["GodMode"] = RunService.Heartbeat:Connect(function()
        if State.GodMode then
            local hum = GetHumanoid()
            if hum then hum.Health = hum.MaxHealth end
        end
    end)
end

local function StopGodMode()
    if Connections["GodMode"] then Connections["GodMode"]:Disconnect(); Connections["GodMode"] = nil end
end

----------------------------------------------------------------
--  ANTI-AFK
----------------------------------------------------------------
local function StartAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    Connections["AntiAFK"] = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function StopAntiAFK()
    if Connections["AntiAFK"] then Connections["AntiAFK"]:Disconnect(); Connections["AntiAFK"] = nil end
end

----------------------------------------------------------------
--  CREATE ALL GUI ELEMENTS
----------------------------------------------------------------
CreateSection("━━━ COMBAT ━━━", 1)

CreateToggle("🎯 Aimbot", "Sağ tık = en yakın kafaya lock (FIXED)", 2, function(on)
    State.Aimbot = on
    if on then StartAimbot() else StopAimbot() end
end)

CreateToggle("🔇 Silent Aim", "Kamera kımıldamaz, mermi hedefe gider (__namecall hook)", 3, function(on)
    State.SilentAim = on
    if on then StartSilentAim() else StopSilentAim() end
end)

CreateSlider("🎯 Aimbot FOV", 50, 500, 250, 4, function(val) State.AimbotFOV = val end)
CreateSlider("🎯 Smooth", 5, 100, 25, 5, function(val) State.AimbotSmooth = val / 100 end)

CreateSection("━━━ MOVEMENT ━━━", 10)

CreateToggle("⛔ NoClip", "Duvardan geç (Stepped+Heartbeat double-bind)", 11, function(on)
    State.NoClip = on
    if on then StartNoClip() else StopNoClip() end
end)

CreateToggle("💨 CFrame Speed", "WalkSpeed dokunulmaz, CFrame ile hız (bypass)", 12, function(on)
    State.Speed = on
    if on then StartCFrameSpeed() else StopCFrameSpeed() end
end)

CreateSlider("💨 Speed Multi", 1, 10, 3, 13, function(val) State.SpeedValue = val end)

CreateToggle("🕊️ CFrame Fly", "BodyVelocity yok, saf CFrame (bypass)", 14, function(on)
    State.Fly = on
    if on then StartCFrameFly() else StopCFrameFly() end
end)

CreateSlider("🕊️ Fly Speed", 20, 300, 80, 15, function(val) State.FlySpeed = val end)

CreateToggle("🦘 Infinite Jump", "Havada sınırsız zıpla", 16, function(on)
    State.InfJump = on
    if on then StartInfJump() else StopInfJump() end
end)

CreateSection("━━━ VISUALS ━━━", 20)

CreateToggle("👁️ ESP", "Highlight + isim + HP + mesafe (duvar arkası)", 21, function(on)
    State.ESP = on
    if on then
        RefreshESP()
        Connections["ESPAdded"] = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function() task.wait(1); if State.ESP then CreateESP(p) end end)
        end)
    else
        ClearESP()
        if Connections["ESPAdded"] then Connections["ESPAdded"]:Disconnect() end
    end
end)

CreateToggle("☀️ Fullbright", "Karanlıkta her şeyi gör", 22, function(on)
    State.Fullbright = on
    ToggleFullbright(on)
end)

CreateSection("━━━ MISC ━━━", 30)

CreateToggle("🛡️ God Mode", "Client-side HP max loop", 31, function(on)
    State.GodMode = on
    if on then StartGodMode() else StopGodMode() end
end)

CreateToggle("💤 Anti-AFK", "Idle kick bypass (VirtualUser)", 32, function(on)
    State.AntiAFK = on
    if on then StartAntiAFK() else StopAntiAFK() end
end)

----------------------------------------------------------------
--  HEADER BUTTONS
----------------------------------------------------------------
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 440, 0, 50) or UDim2.new(0, 440, 0, 520)
    MinBtn.Text = minimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    for _, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
    end
    StopNoClip(); StopAimbot(); StopSilentAim()
    StopCFrameSpeed(); StopCFrameFly(); StopInfJump()
    StopGodMode(); StopAntiAFK()
    ClearESP(); ToggleFullbright(false)
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    ScreenGui:Destroy()
end)

----------------------------------------------------------------
--  TOGGLE GUI — RightControl
----------------------------------------------------------------
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

----------------------------------------------------------------
--  AUTO-REFRESH ON RESPAWN
----------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Speed then StopCFrameSpeed(); StartCFrameSpeed() end
    if State.Fly then StopCFrameFly(); StartCFrameFly() end
    if State.NoClip then StopNoClip(); StartNoClip() end
    if State.GodMode then StopGodMode(); StartGodMode() end
    if State.ESP then RefreshESP() end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if State.ESP then CreateESP(player) end
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if State.ESP then CreateESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player.Name] then
        for _, obj in pairs(ESPObjects[player.Name]) do pcall(function() obj:Destroy() end) end
        ESPObjects[player.Name] = nil
    end
end)

----------------------------------------------------------------
--  LOADED NOTIFICATION
----------------------------------------------------------------
local Notif = Instance.new("TextLabel")
Notif.Size = UDim2.new(0, 320, 0, 40)
Notif.Position = UDim2.new(0.5, -160, 0, 10)
Notif.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
Notif.TextColor3 = Color3.fromRGB(255, 255, 255)
Notif.Text = "⚡ Marcush Hub v3.0 — Bypassed Edition Loaded!"
Notif.TextSize = 14
Notif.Font = Enum.Font.GothamBold
Notif.BorderSizePixel = 0
Notif.Parent = ScreenGui
Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 8)

spawn(function()
    task.wait(3)
    for i = 0, 1, 0.04 do
        Notif.BackgroundTransparency = i
        Notif.TextTransparency = i
        task.wait(0.02)
    end
    Notif:Destroy()
end)

print("[Marcush Hub v3.0] Loaded! RightCtrl = toggle GUI")
print("[Marcush Hub v3.0] Silent Aim: __namecall + Mouse.Hit hook aktif")
print("[Marcush Hub v3.0] Speed/Fly: CFrame-based bypass (no physics objects)")
