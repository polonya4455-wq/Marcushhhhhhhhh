-- ratman4080 universal v2 — GUI edition
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    Noclip = true,
    ESP = true,
    Aimbot = true,
    WalkSpeed = true,
    JumpPower = true,
    SpeedValue = 50,
    JumpValue = 100,
    MenuOpen = true,
}

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ratman4080_gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 340)
Main.Position = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 1
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.BorderSizePixel = 0
Title.Text = "ratman4080"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 60, 0, 24)
ToggleBtn.Position = UDim2.new(1, -66, 0, 4)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "[F]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = Title

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = ToggleBtn

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -48)
Scroll.Position = UDim2.new(0, 8, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- ===== TOGGLE FACTORY =====
local function MakeToggle(name, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 32)
    Btn.BackgroundColor3 = default and Color3.fromRGB(60, 20, 20) or Color3.fromRGB(30, 30, 30)
    Btn.Text = ""
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Parent = Scroll

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 6)
    C.Parent = Btn

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -50, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Btn

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(1, -24, 0.5, -7)
    Dot.BackgroundColor3 = default and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(70, 70, 70)
    Dot.BorderSizePixel = 0
    Dot.Parent = Btn

    local DC = Instance.new("UICorner")
    DC.CornerRadius = UDim.new(1, 0)
    DC.Parent = Dot

    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(60, 20, 20) or Color3.fromRGB(30, 30, 30)
        Dot.BackgroundColor3 = state and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(70, 70, 70)
        callback(state)
    end)
    return Btn
end

-- ===== SLIDER FACTORY =====
local function MakeSlider(name, min, max, default, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -8, 0, 52)
    Holder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Holder.BorderSizePixel = 0
    Holder.Parent = Scroll

    local HC = Instance.new("UICorner")
    HC.CornerRadius = UDim.new(0, 6)
    HC.Parent = Holder

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -20, 0, 20)
    Lbl.Position = UDim2.new(0, 10, 0, 4)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name .. ": " .. default
    Lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 8)
    Bar.Position = UDim2.new(0, 10, 0, 32)
    Bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Bar.BorderSizePixel = 0
    Bar.Parent = Holder

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(1, 0)
    BC.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(1, 0)
    FC.Parent = Fill

    local dragging = false
    local function UpdatePos(input)
        local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        local val = math.floor(min + (max - min) * rel)
        Lbl.Text = name .. ": " .. val
        callback(val)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdatePos(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdatePos(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ===== TOGGLES =====
MakeToggle("Noclip", Config.Noclip, function(v) Config.Noclip = v end)
MakeToggle("ESP", Config.ESP, function(v) Config.ESP = v end)
MakeToggle("Aimbot", Config.Aimbot, function(v) Config.Aimbot = v end)
MakeToggle("WalkSpeed", Config.WalkSpeed, function(v)
    Config.WalkSpeed = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v and Config.SpeedValue or 16 end
end)
MakeToggle("JumpPower", Config.JumpPower, function(v)
    Config.JumpPower = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v and Config.JumpValue or 50 end
end)

MakeSlider("Speed", 16, 200, Config.SpeedValue, function(v)
    Config.SpeedValue = v
    if Config.WalkSpeed then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

MakeSlider("Jump", 50, 300, Config.JumpValue, function(v)
    Config.JumpValue = v
    if Config.JumpPower then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

-- ===== NOCLIP =====
local function NoclipLoop()
    if not Config.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

-- ===== ESP =====
local ESPObjects = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Filled = false
    box.Transparency = 1
    box.Visible = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false

    local distTag = Drawing.new("Text")
    distTag.Size = 12
    distTag.Center = true
    distTag.Outline = true
    distTag.Color = Color3.fromRGB(200, 200, 200)
    distTag.Visible = false

    ESPObjects[player] = {box = box, name = nameTag, dist = distTag}
end

local function UpdateESP()
    for player, obj in pairs(ESPObjects) do
        if not Config.ESP then
            obj.box.Visible = false
            obj.name.Visible = false
            obj.dist.Visible = false
            continue
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local size = Vector2.new(2000 / pos.Z, 3000 / pos.Z)
                obj.box.Size = size
                obj.box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                obj.box.Visible = true
                obj.name.Text = player.Name
                obj.name.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 18)
                obj.name.Visible = true
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                obj.dist.Text = string.format("[%d studs]", math.floor(dist))
                obj.dist.Position = Vector2.new(pos.X, pos.Y + size.Y / 2 + 4)
                obj.dist.Visible = true
            else
                obj.box.Visible = false
                obj.name.Visible = false
                obj.dist.Visible = false
            end
        else
            obj.box.Visible = false
            obj.name.Visible = false
            obj.dist.Visible = false
        end
    end
end

-- ===== AIMBOT =====
local function GetClosestPlayer()
    local closest, shortest = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local mouse = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = hrp
                end
            end
        end
    end
    return closest
end

-- ===== ANA LOOP =====
RunService.RenderStepped:Connect(function()
    NoclipLoop()
    UpdateESP()
    if Config.Aimbot then
        local target = GetClosestPlayer()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- ===== CHARACTER =====
local function SetupChar(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.WalkSpeed then hum.WalkSpeed = Config.SpeedValue end
        if Config.JumpPower then hum.JumpPower = Config.JumpValue end
    end
end

if LocalPlayer.Character then SetupChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SetupChar)

-- ===== PLAYER TRACKING =====
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(p)
    local obj = ESPObjects[p]
    if obj then
        obj.box:Remove()
        obj.name:Remove()
        obj.dist:Remove()
        ESPObjects[p] = nil
    end
end)

for _, p in pairs(Players:GetPlayers()) do
    CreateESP(p)
end

-- ===== MENU TOGGLE (F) =====
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        Config.MenuOpen = not Config.MenuOpen
        Main.Visible = Config.MenuOpen
    end
end)

print("[ratman4080] loaded. squeak.")
