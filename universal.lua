--[[
    ███╗   ███╗ █████╗ ██████╗  ██████╗██╗   ██╗███████╗██╗  ██╗
    ████╗ ████║██╔══██╗██╔══██╗██╔════╝██║   ██║██╔════╝██║  ██║
    ██╔████╔██║███████║██████╔╝██║     ██║   ██║███████╗███████║
    ██║╚██╔╝██║██╔══██║██╔══██╗██║     ██║   ██║╚════██║██╔══██║
    ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗╚██████╔╝███████║██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚═╝  ╚═╝
    Marcush Hub v2.0 — All-in-One Roblox Exploit GUI
    NoClip | ESP | Aimbot | Speed | Fly | InfJump | Fullbright | GodMode
    PoC / Research — From scratch, standard Roblox API only
--]]

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
--  STATE TABLE
----------------------------------------------------------------
local State = {
    NoClip      = false,
    ESP         = false,
    Aimbot      = false,
    Speed       = false,
    Fly         = false,
    InfJump     = false,
    Fullbright  = false,
    GodMode     = false,
    -- tunables
    SpeedValue  = 50,
    FlySpeed    = 80,
    AimbotFOV   = 250,
    AimbotSmooth = 0.15,
}

-- connection storage (cleanup için)
local Connections = {}
local ESPObjects  = {}

----------------------------------------------------------------
--  UTILITY FUNCTIONS
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
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

----------------------------------------------------------------
--  GUI CREATION
----------------------------------------------------------------
-- Eski GUI varsa sil
if game.CoreGui:FindFirstChild("MarcushHub") then
    game.CoreGui:FindFirstChild("MarcushHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MarcushHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- ANA FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 480)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(138, 43, 226)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ MARCUSH HUB v2.0"
Title.TextColor3 = Color3.fromRGB(138, 43, 226)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- MINIMIZE / CLOSE
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -75, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- SCROLL FRAME (toggle'lar buraya)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "Toggles"
ScrollFrame.Size = UDim2.new(1, -20, 1, -65)
ScrollFrame.Position = UDim2.new(0, 10, 0, 55)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)
ListLayout.Parent = ScrollFrame

----------------------------------------------------------------
--  TOGGLE BUTTON FACTORY
----------------------------------------------------------------
local function CreateToggle(name, description, layoutOrder, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name
    ToggleFrame.Size = UDim2.new(1, -10, 0, 50)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = layoutOrder
    ToggleFrame.Parent = ScrollFrame

    local TC = Instance.new("UICorner")
    TC.CornerRadius = UDim.new(0, 8)
    TC.Parent = ToggleFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 15
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(0.7, 0, 0, 16)
    Desc.Position = UDim2.new(0, 12, 0, 28)
    Desc.BackgroundTransparency = 1
    Desc.Text = description
    Desc.TextColor3 = Color3.fromRGB(120, 120, 140)
    Desc.TextSize = 11
    Desc.Font = Enum.Font.Gotham
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = ToggleFrame

    -- TOGGLE SWITCH
    local SwitchBG = Instance.new("Frame")
    SwitchBG.Size = UDim2.new(0, 48, 0, 24)
    SwitchBG.Position = UDim2.new(1, -62, 0.5, -12)
    SwitchBG.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    SwitchBG.BorderSizePixel = 0
    SwitchBG.Parent = ToggleFrame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBG

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, 3, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    Circle.BorderSizePixel = 0
    Circle.Parent = SwitchBG

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local toggled = false

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.Parent = ToggleFrame

    ClickBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if toggled then
            TweenService:Create(Circle, tweenInfo, {
                Position = UDim2.new(1, -21, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            TweenService:Create(SwitchBG, tweenInfo, {
                BackgroundColor3 = Color3.fromRGB(138, 43, 226)
            }):Play()
        else
            TweenService:Create(Circle, tweenInfo, {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            }):Play()
            TweenService:Create(SwitchBG, tweenInfo, {
                BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            }):Play()
        end

        callback(toggled)
    end)

    return ToggleFrame
end

----------------------------------------------------------------
--  SLIDER FACTORY (speed/fov için)
----------------------------------------------------------------
local function CreateSlider(name, min, max, default, layoutOrder, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = name
    SliderFrame.Size = UDim2.new(1, -10, 0, 50)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.LayoutOrder = layoutOrder
    SliderFrame.Parent = ScrollFrame

    local SC = Instance.new("UICorner")
    SC.CornerRadius = UDim.new(0, 8)
    SC.Parent = SliderFrame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, -20, 0, 20)
    ValLabel.Position = UDim2.new(0, 12, 0, 3)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = name .. ": " .. tostring(default)
    ValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValLabel.TextSize = 13
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValLabel.Parent = SliderFrame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 30)
    Track.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    Track.BorderSizePixel = 0
    Track.Parent = SliderFrame

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local pct = (default - min) / (max - min)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(pct, -7, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 3
    Knob.Parent = Track

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local dragging = false

    local DragBtn = Instance.new("TextButton")
    DragBtn.Size = UDim2.new(1, 0, 1, 20)
    DragBtn.Position = UDim2.new(0, 0, 0, -10)
    DragBtn.BackgroundTransparency = 1
    DragBtn.Text = ""
    DragBtn.ZIndex = 4
    DragBtn.Parent = Track

    DragBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local trackAbsPos = Track.AbsolutePosition.X
            local trackAbsSize = Track.AbsoluteSize.X
            local mouseX = input.Position.X
            local ratio = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            local value = math.floor(min + (max - min) * ratio)

            Fill.Size = UDim2.new(ratio, 0, 1, 0)
            Knob.Position = UDim2.new(ratio, -7, 0.5, -7)
            ValLabel.Text = name .. ": " .. tostring(value)

            callback(value)
        end
    end)

    return SliderFrame
end

----------------------------------------------------------------
--  NOCLIP MODULE
----------------------------------------------------------------
local function StartNoClip()
    Connections["NoClip"] = RunService.Stepped:Connect(function()
        if State.NoClip then
            local char = GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function StopNoClip()
    if Connections["NoClip"] then
        Connections["NoClip"]:Disconnect()
        Connections["NoClip"] = nil
    end
end

----------------------------------------------------------------
--  ESP MODULE
----------------------------------------------------------------
local function CreateESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hrp or not hum or not head then return end

    -- varsa eski esp sil
    if ESPObjects[player.Name] then
        for _, obj in pairs(ESPObjects[player.Name]) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    ESPObjects[player.Name] = {}

    -- HIGHLIGHT (wallhack glow)
    local highlight = Instance.new("Highlight")
    highlight.Name = "MarcushESP"
    highlight.FillColor = Color3.fromRGB(138, 43, 226)
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.fromRGB(200, 100, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = char
    highlight.Parent = char
    table.insert(ESPObjects[player.Name], highlight)

    -- BILLBOARD (isim + mesafe + HP)
    local bb = Instance.new("BillboardGui")
    bb.Name = "MarcushInfo"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Parent = char
    table.insert(ESPObjects[player.Name], bb)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(200, 130, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = bb

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "HP: 100 | 0m"
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextStrokeTransparency = 0.3
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.Parent = bb

    -- HP bar
    local hpBG = Instance.new("Frame")
    hpBG.Size = UDim2.new(0, 120, 0, 5)
    hpBG.Position = UDim2.new(0.5, -60, 1, 2)
    hpBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBG.BorderSizePixel = 0
    hpBG.Parent = bb
    table.insert(ESPObjects[player.Name], hpBG)

    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(1, 0)
    hpCorner.Parent = hpBG

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBG

    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(1, 0)
    hpFillCorner.Parent = hpFill

    -- ESP Update loop
    spawn(function()
        while State.ESP and char and char.Parent do
            local myHRP = GetHRP()
            if myHRP and hrp and hrp.Parent and hum and hum.Parent then
                local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                local hp = math.floor(hum.Health)
                local maxHp = math.floor(hum.MaxHealth)
                infoLabel.Text = "HP: " .. hp .. "/" .. maxHp .. " | " .. dist .. "m"

                local ratio = math.clamp(hp / maxHp, 0, 1)
                hpFill.Size = UDim2.new(ratio, 0, 1, 0)

                if ratio > 0.5 then
                    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                elseif ratio > 0.25 then
                    hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                else
                    hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                end
            end
            wait(0.1)
        end
    end)
end

local function ClearESP()
    for name, objects in pairs(ESPObjects) do
        for _, obj in pairs(objects) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    ESPObjects = {}
    -- Highlight'ları da temizle
    for _, player in pairs(Players:GetPlayers()) do
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
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsAlive(player) then
                CreateESP(player)
            end
        end
    end
end

----------------------------------------------------------------
--  AIMBOT MODULE
----------------------------------------------------------------
local AimbotTarget = nil

local function GetClosestPlayer()
    local closest = nil
    local shortDist = State.AimbotFOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
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

local function StartAimbot()
    Connections["Aimbot"] = RunService.RenderStepped:Connect(function()
        if State.Aimbot and UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetClosestPlayer()
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, State.AimbotSmooth)
                end
            end
        end
    end)
end

local function StopAimbot()
    if Connections["Aimbot"] then
        Connections["Aimbot"]:Disconnect()
        Connections["Aimbot"] = nil
    end
end

----------------------------------------------------------------
--  FOV CIRCLE (aimbot visual)
----------------------------------------------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(138, 43, 226)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Radius = State.AimbotFOV
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Visible = false

Connections["FOVUpdate"] = RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = State.AimbotFOV
    FOVCircle.Visible = State.Aimbot
end)

----------------------------------------------------------------
--  SPEED MODULE
----------------------------------------------------------------
local function UpdateSpeed()
    local hum = GetHumanoid()
    if hum then
        if State.Speed then
            hum.WalkSpeed = State.SpeedValue
        else
            hum.WalkSpeed = 16 -- default
        end
    end
end

----------------------------------------------------------------
--  FLY MODULE
----------------------------------------------------------------
local FlyBody = nil
local FlyGyro = nil

local function StartFly()
    local hrp = GetHRP()
    if not hrp then return end

    FlyBody = Instance.new("BodyVelocity")
    FlyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBody.Velocity = Vector3.new(0, 0, 0)
    FlyBody.Parent = hrp

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyGyro.P = 9e4
    FlyGyro.Parent = hrp

    Connections["Fly"] = RunService.RenderStepped:Connect(function()
        if State.Fly and FlyBody and FlyGyro and hrp and hrp.Parent then
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

            FlyBody.Velocity = dir * State.FlySpeed
            FlyGyro.CFrame = camCF
        end
    end)
end

local function StopFly()
    if Connections["Fly"] then
        Connections["Fly"]:Disconnect()
        Connections["Fly"] = nil
    end
    if FlyBody then FlyBody:Destroy() FlyBody = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
end

----------------------------------------------------------------
--  INFINITE JUMP MODULE
----------------------------------------------------------------
local function StartInfJump()
    Connections["InfJump"] = UserInput.JumpRequest:Connect(function()
        if State.InfJump then
            local hum = GetHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function StopInfJump()
    if Connections["InfJump"] then
        Connections["InfJump"]:Disconnect()
        Connections["InfJump"] = nil
    end
end

----------------------------------------------------------------
--  FULLBRIGHT MODULE
----------------------------------------------------------------
local OriginalAmbient = Lighting.Ambient
local OriginalBrightness = Lighting.Brightness
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient

local function ToggleFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 1e9
    else
        Lighting.Ambient = OriginalAmbient
        Lighting.Brightness = OriginalBrightness
        Lighting.OutdoorAmbient = OriginalOutdoorAmbient
    end
end

----------------------------------------------------------------
--  GOD MODE MODULE (client-side HP loop)
----------------------------------------------------------------
local function StartGodMode()
    Connections["GodMode"] = RunService.Heartbeat:Connect(function()
        if State.GodMode then
            local hum = GetHumanoid()
            if hum then
                hum.Health = hum.MaxHealth
            end
        end
    end)
end

local function StopGodMode()
    if Connections["GodMode"] then
        Connections["GodMode"]:Disconnect()
        Connections["GodMode"] = nil
    end
end

----------------------------------------------------------------
--  CREATE ALL TOGGLES
----------------------------------------------------------------
CreateToggle("⛔ NoClip", "Duvarlardan geç (tüm collision kapatılır)", 1, function(on)
    State.NoClip = on
    if on then StartNoClip() else StopNoClip() end
end)

CreateToggle("👁️ ESP", "Oyuncuları duvar arkasından gör", 2, function(on)
    State.ESP = on
    if on then
        RefreshESP()
        -- Yeni oyuncuları da yakala
        Connections["ESPAdded"] = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function()
                wait(1)
                if State.ESP then CreateESP(p) end
            end)
        end)
    else
        ClearESP()
        if Connections["ESPAdded"] then
            Connections["ESPAdded"]:Disconnect()
        end
    end
end)

CreateToggle("🎯 Aimbot", "Sağ tık basılı = en yakın kafaya kilitlen", 3, function(on)
    State.Aimbot = on
    if on then StartAimbot() else StopAimbot() end
end)

CreateSlider("🎯 Aimbot FOV", 50, 500, 250, 4, function(val)
    State.AimbotFOV = val
end)

CreateSlider("🎯 Aimbot Smooth", 1, 100, 15, 5, function(val)
    State.AimbotSmooth = val / 100
end)

CreateToggle("💨 Speed Hack", "Hızlı koşma (slider ile ayarla)", 6, function(on)
    State.Speed = on
    UpdateSpeed()
end)

CreateSlider("💨 Speed Value", 16, 200, 50, 7, function(val)
    State.SpeedValue = val
    if State.Speed then UpdateSpeed() end
end)

CreateToggle("🕊️ Fly", "WASD + Space/Shift ile uç", 8, function(on)
    State.Fly = on
    if on then StartFly() else StopFly() end
end)

CreateSlider("🕊️ Fly Speed", 20, 300, 80, 9, function(val)
    State.FlySpeed = val
end)

CreateToggle("🦘 Infinite Jump", "Havada sınırsız zıpla", 10, function(on)
    State.InfJump = on
    if on then StartInfJump() else StopInfJump() end
end)

CreateToggle("☀️ Fullbright", "Karanlıkta bile her şeyi gör", 11, function(on)
    State.Fullbright = on
    ToggleFullbright(on)
end)

CreateToggle("🛡️ God Mode", "Client-side HP loop (sadece client)", 12, function(on)
    State.GodMode = on
    if on then StartGodMode() else StopGodMode() end
end)

----------------------------------------------------------------
--  HEADER BUTTONS (minimize / close)
----------------------------------------------------------------
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 420, 0, 50)
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 420, 0, 480)
        MinBtn.Text = "—"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- cleanup
    for _, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    ClearESP()
    StopFly()
    ToggleFullbright(false)
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 end
    FOVCircle:Remove()
    ScreenGui:Destroy()
end)

----------------------------------------------------------------
--  TOGGLE GUI VISIBILITY (RightControl tuşu)
----------------------------------------------------------------
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

----------------------------------------------------------------
--  AUTO-REFRESH ESP ON RESPAWN
----------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    if State.Speed then UpdateSpeed() end
    if State.Fly then StopFly(); StartFly() end
    if State.NoClip then StopNoClip(); StartNoClip() end
    if State.GodMode then StopGodMode(); StartGodMode() end
    if State.ESP then RefreshESP() end
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(1)
            if State.ESP then CreateESP(player) end
        end)
    end
end

----------------------------------------------------------------
--  NOTIFICATION
----------------------------------------------------------------
local Notif = Instance.new("TextLabel")
Notif.Size = UDim2.new(0, 300, 0, 40)
Notif.Position = UDim2.new(0.5, -150, 0, 10)
Notif.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
Notif.TextColor3 = Color3.fromRGB(255, 255, 255)
Notif.Text = "⚡ Marcush Hub v2.0 Loaded!"
Notif.TextSize = 16
Notif.Font = Enum.Font.GothamBold
Notif.BorderSizePixel = 0
Notif.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 8)
NotifCorner.Parent = Notif

-- 3 sn sonra fade out
spawn(function()
    wait(3)
    for i = 0, 1, 0.05 do
        Notif.BackgroundTransparency = i
        Notif.TextTransparency = i
        wait(0.02)
    end
    Notif:Destroy()
end)

print("[Marcush Hub v2.0] Loaded successfully! RightCtrl to toggle GUI.")
