--[[
    ███╗   ███╗ █████╗ ██████╗  ██████╗██╗   ██╗███████╗██╗  ██╗
    ████╗ ████║██╔══██╗██╔══██╗██╔════╝██║   ██║██╔════╝███████║
    ██╔████╔██║███████║██████╔╝██║     ██║   ██║███████╗██╔══██║
    ██║╚██╔╝██║██╔══██║██╔══██╗██║     ██║   ██║╚════██║██║  ██║
    ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗╚██████╔╝███████║██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚═╝  ╚═╝

    Marcush Hub v3.0 — Bypassed Edition
    ═══════════════════════════════════════════════════
    Drawing API ESP (BloxStrike + universal compat)
    Fixed Aimbot (BindToRenderStep priority 201)
    Silent Aim (__namecall + Raycast + Mouse.Hit hook)
    CFrame Speed/Fly (no physics objects = bypass)
    NoClip (Stepped + Heartbeat double-bind)
    Team Check — düşmanı vurursun, takım arkadaşını değil
    ═══════════════════════════════════════════════════
    Executor: Synapse X / Fluxus / Wave / Script-Ware
    PoC / Research — From scratch, standard Roblox API only
--]]

----------------------------------------------------------------
--  EXECUTOR COMPAT
----------------------------------------------------------------
local hookmetamethod   = hookmetamethod or (getgenv and getgenv().hookmetamethod)
local getnamecallmethod = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
local newcclosure      = newcclosure or function(f) return f end
local checkcaller      = checkcaller or function() return false end
local getrawmetatable  = getrawmetatable or debug.getmetatable
local setreadonly      = setreadonly or function() end
local isreadonly       = isreadonly or function() return false end

----------------------------------------------------------------
--  SERVICES
----------------------------------------------------------------
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local Workspace     = game:GetService("Workspace")
local Camera        = Workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

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
    TeamCheck    = true,   -- default ON: takım arkadaşını gösterme/vurma
    -- tunables
    SpeedValue   = 3,
    FlySpeed     = 80,
    AimbotFOV    = 250,
    AimbotSmooth = 0.25,
    ESPMaxDist   = 1000,
}

local Connections  = {}
local ESPCache     = {}  -- player.Name -> {drawings}
local GuiOpen      = true

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

-- Robust head finder: bazı oyunlar Head'i rename ediyor
local function FindHead(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head then return head end
    -- Fallback: ilk MeshPart/Part named with "head" (case insensitive)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("head") then
            return part
        end
    end
    -- Last resort: HumanoidRootPart offset
    return char:FindFirstChild("HumanoidRootPart")
end

-- Robust HRP finder
local function FindHRP(char)
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return nil
end

local function IsAlive(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = FindHRP(char)
    return hum and hrp and hum.Health > 0
end

-- Team check: returns true if player is an ENEMY
local function IsEnemy(player)
    if not State.TeamCheck then return true end -- team check off = herkes düşman
    if player == LocalPlayer then return false end
    -- Eğer team yoksa herkes düşman
    if not LocalPlayer.Team or not player.Team then return true end
    return LocalPlayer.Team ~= player.Team
end

-- Sadece düşman + alive olanları döndür
local function GetValidTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if IsAlive(player) and IsEnemy(player) then
            table.insert(targets, player)
        end
    end
    return targets
end

local function GetClosestEnemy()
    local closest = nil
    local shortDist = State.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(GetValidTargets()) do
        local head = FindHead(player.Character)
        if head then
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
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
MainFrame.Size = UDim2.new(0, 440, 0, 540)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(138, 43, 226)
Stroke.Thickness = 2
Stroke.Transparency = 0.1
Stroke.Parent = MainFrame

-- Animated gradient stroke
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 200))
}
Gradient.Rotation = 0
Gradient.Parent = Stroke

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
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ MARCUSH HUB v3.0"
Title.TextColor3 = Color3.fromRGB(160, 80, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Badge = Instance.new("TextLabel")
Badge.Size = UDim2.new(0, 75, 0, 18)
Badge.Position = UDim2.new(0, 218, 0, 16)
Badge.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
Badge.Text = "BYPASSED"
Badge.TextColor3 = Color3.fromRGB(255, 255, 255)
Badge.TextSize = 9
Badge.Font = Enum.Font.GothamBold
Badge.Parent = Header
Instance.new("UICorner", Badge).CornerRadius = UDim.new(1, 0)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0, 11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -72, 0, 11)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 13
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

----------------------------------------------------------------
--  SCROLL FRAME
----------------------------------------------------------------
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "Content"
ScrollFrame.Size = UDim2.new(1, -16, 1, -62)
ScrollFrame.Position = UDim2.new(0, 8, 0, 55)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 4)
Layout.Parent = ScrollFrame

----------------------------------------------------------------
--  UI FACTORIES
----------------------------------------------------------------
local function Section(text, order)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 22)
    L.BackgroundTransparency = 1
    L.Text = "  " .. text
    L.TextColor3 = Color3.fromRGB(138, 43, 226)
    L.TextSize = 12
    L.Font = Enum.Font.GothamBold
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.LayoutOrder = order
    L.Parent = ScrollFrame
end

local function Toggle(name, desc, order, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -6, 0, 44)
    F.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
    F.BorderSizePixel = 0
    F.LayoutOrder = order
    F.Parent = ScrollFrame
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 8)

    local N = Instance.new("TextLabel")
    N.Size = UDim2.new(0.65, 0, 0, 18)
    N.Position = UDim2.new(0, 10, 0, 4)
    N.BackgroundTransparency = 1
    N.Text = name
    N.TextColor3 = Color3.fromRGB(235, 235, 250)
    N.TextSize = 13
    N.Font = Enum.Font.GothamBold
    N.TextXAlignment = Enum.TextXAlignment.Left
    N.Parent = F

    local D = Instance.new("TextLabel")
    D.Size = UDim2.new(0.72, 0, 0, 13)
    D.Position = UDim2.new(0, 10, 0, 24)
    D.BackgroundTransparency = 1
    D.Text = desc
    D.TextColor3 = Color3.fromRGB(90, 90, 110)
    D.TextSize = 10
    D.Font = Enum.Font.Gotham
    D.TextXAlignment = Enum.TextXAlignment.Left
    D.Parent = F

    local SBG = Instance.new("Frame")
    SBG.Size = UDim2.new(0, 42, 0, 20)
    SBG.Position = UDim2.new(1, -54, 0.5, -10)
    SBG.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    SBG.BorderSizePixel = 0
    SBG.Parent = F
    Instance.new("UICorner", SBG).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = UDim2.new(0, 3, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    Dot.BorderSizePixel = 0
    Dot.Parent = SBG
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local on = false
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 1, 0)
    B.BackgroundTransparency = 1
    B.Text = ""
    B.Parent = F

    B.MouseButton1Click:Connect(function()
        on = not on
        local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
        if on then
            TweenService:Create(Dot, ti, {Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
            TweenService:Create(SBG, ti, {BackgroundColor3 = Color3.fromRGB(138, 43, 226)}):Play()
        else
            TweenService:Create(Dot, ti, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = Color3.fromRGB(150,150,160)}):Play()
            TweenService:Create(SBG, ti, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
        end
        callback(on)
    end)
end

local function Slider(name, min, max, default, order, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -6, 0, 44)
    F.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
    F.BorderSizePixel = 0
    F.LayoutOrder = order
    F.Parent = ScrollFrame
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 8)

    local VL = Instance.new("TextLabel")
    VL.Size = UDim2.new(1, -16, 0, 16)
    VL.Position = UDim2.new(0, 10, 0, 3)
    VL.BackgroundTransparency = 1
    VL.Text = name .. ": " .. default
    VL.TextColor3 = Color3.fromRGB(235, 235, 250)
    VL.TextSize = 11
    VL.Font = Enum.Font.GothamBold
    VL.TextXAlignment = Enum.TextXAlignment.Left
    VL.Parent = F

    local T = Instance.new("Frame")
    T.Size = UDim2.new(1, -20, 0, 5)
    T.Position = UDim2.new(0, 10, 0, 27)
    T.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    T.BorderSizePixel = 0
    T.Parent = F
    Instance.new("UICorner", T).CornerRadius = UDim.new(1, 0)

    local pct = (default - min) / (max - min)

    local FL = Instance.new("Frame")
    FL.Size = UDim2.new(pct, 0, 1, 0)
    FL.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    FL.BorderSizePixel = 0
    FL.Parent = T
    Instance.new("UICorner", FL).CornerRadius = UDim.new(1, 0)

    local K = Instance.new("Frame")
    K.Size = UDim2.new(0, 12, 0, 12)
    K.Position = UDim2.new(pct, -6, 0.5, -6)
    K.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    K.BorderSizePixel = 0
    K.ZIndex = 3
    K.Parent = T
    Instance.new("UICorner", K).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local DB = Instance.new("TextButton")
    DB.Size = UDim2.new(1, 10, 1, 18)
    DB.Position = UDim2.new(0, -5, 0, -9)
    DB.BackgroundTransparency = 1
    DB.Text = ""
    DB.ZIndex = 4
    DB.Parent = T

    DB.MouseButton1Down:Connect(function() dragging = true end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - T.AbsolutePosition.X) / T.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * r)
            FL.Size = UDim2.new(r, 0, 1, 0)
            K.Position = UDim2.new(r, -6, 0.5, -6)
            VL.Text = name .. ": " .. v
            callback(v)
        end
    end)
end

--=============================================================
--
--  ██████  DRAWING API ESP (BloxStrike + Universal)  ██████
--
--  Highlight/BillboardGui KULLANMIYOR.
--  Drawing.new ile ekrana 2D box, text, healthbar çiziyor.
--  Oyun scriptleri bunu göremez, silemez, detect edemez.
--  Camera:WorldToViewportPoint ile 3D → 2D projeksiyon.
--
--=============================================================

local function CreateDrawingESP(player)
    if ESPCache[player.Name] then return end -- zaten var

    local objects = {}

    -- Box (outline rectangle)
    objects.BoxOutline = Drawing.new("Square")
    objects.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    objects.BoxOutline.Thickness = 3
    objects.BoxOutline.Filled = false
    objects.BoxOutline.Visible = false

    objects.Box = Drawing.new("Square")
    objects.Box.Color = Color3.fromRGB(138, 43, 226)
    objects.Box.Thickness = 1.5
    objects.Box.Filled = false
    objects.Box.Visible = false

    -- Name text
    objects.Name = Drawing.new("Text")
    objects.Name.Color = Color3.fromRGB(200, 130, 255)
    objects.Name.Size = 13
    objects.Name.Center = true
    objects.Name.Outline = true
    objects.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.Name.Font = Drawing.Fonts and Drawing.Fonts.Plex or 2
    objects.Name.Visible = false

    -- Distance text
    objects.Dist = Drawing.new("Text")
    objects.Dist.Color = Color3.fromRGB(180, 180, 200)
    objects.Dist.Size = 11
    objects.Dist.Center = true
    objects.Dist.Outline = true
    objects.Dist.OutlineColor = Color3.fromRGB(0, 0, 0)
    objects.Dist.Font = Drawing.Fonts and Drawing.Fonts.Plex or 2
    objects.Dist.Visible = false

    -- HP bar background
    objects.HPbg = Drawing.new("Square")
    objects.HPbg.Color = Color3.fromRGB(0, 0, 0)
    objects.HPbg.Thickness = 1
    objects.HPbg.Filled = true
    objects.HPbg.Visible = false

    -- HP bar fill
    objects.HPfill = Drawing.new("Square")
    objects.HPfill.Color = Color3.fromRGB(0, 255, 100)
    objects.HPfill.Thickness = 1
    objects.HPfill.Filled = true
    objects.HPfill.Visible = false

    -- Snap line (ayaktan ekran altına)
    objects.SnapLine = Drawing.new("Line")
    objects.SnapLine.Color = Color3.fromRGB(138, 43, 226)
    objects.SnapLine.Thickness = 1
    objects.SnapLine.Transparency = 0.5
    objects.SnapLine.Visible = false

    ESPCache[player.Name] = objects
end

local function RemoveDrawingESP(playerName)
    local objects = ESPCache[playerName]
    if not objects then return end
    for _, obj in pairs(objects) do
        pcall(function() obj:Remove() end)
    end
    ESPCache[playerName] = nil
end

local function ClearAllESP()
    for name, _ in pairs(ESPCache) do
        RemoveDrawingESP(name)
    end
    ESPCache = {}
end

local function UpdateESPLoop()
    Connections["ESPLoop"] = RunService.RenderStepped:Connect(function()
        if not State.ESP then
            -- Hepsini gizle
            for _, objects in pairs(ESPCache) do
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
            end
            return
        end

        local myHRP = GetHRP()
        if not myHRP then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            -- ESP objelerini oluştur (yoksa)
            if not ESPCache[player.Name] then
                pcall(function() CreateDrawingESP(player) end)
            end

            local objects = ESPCache[player.Name]
            if not objects then continue end

            local char = player.Character
            local alive = IsAlive(player)
            local enemy = IsEnemy(player)

            if not char or not alive or not enemy then
                for _, obj in pairs(objects) do obj.Visible = false end
                continue
            end

            local hrp = FindHRP(char)
            local head = FindHead(char)
            local hum = char:FindFirstChildOfClass("Humanoid")

            if not hrp or not head or not hum then
                for _, obj in pairs(objects) do obj.Visible = false end
                continue
            end

            local dist = (myHRP.Position - hrp.Position).Magnitude
            if dist > State.ESPMaxDist then
                for _, obj in pairs(objects) do obj.Visible = false end
                continue
            end

            -- 3D → 2D: head ve feet pozisyonlarını ekrana çevir
            local headPos3D = head.Position + Vector3.new(0, 1.2, 0)  -- biraz yukarı (isim için)
            local feetPos3D = hrp.Position - Vector3.new(0, 3, 0)     -- ayak altı

            local headScreen, headOnScreen = Camera:WorldToViewportPoint(headPos3D)
            local feetScreen, feetOnScreen = Camera:WorldToViewportPoint(feetPos3D)
            local hrpScreen = Camera:WorldToViewportPoint(hrp.Position)

            if not headOnScreen and not feetOnScreen then
                for _, obj in pairs(objects) do obj.Visible = false end
                continue
            end

            -- Box hesaplama
            local boxHeight = math.abs(feetScreen.Y - headScreen.Y)
            local boxWidth = boxHeight * 0.55  -- insan oranı
            local boxX = hrpScreen.X - boxWidth / 2
            local boxY = headScreen.Y

            -- BOX
            objects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            objects.BoxOutline.Position = Vector2.new(boxX, boxY)
            objects.BoxOutline.Visible = true

            objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            objects.Box.Position = Vector2.new(boxX, boxY)
            objects.Box.Visible = true

            -- Team coloring: düşman = purple, nötr = kırmızı (team check off ise)
            local boxColor = Color3.fromRGB(138, 43, 226)
            objects.Box.Color = boxColor

            -- NAME
            objects.Name.Text = player.DisplayName
            objects.Name.Position = Vector2.new(hrpScreen.X, boxY - 16)
            objects.Name.Visible = true

            -- DISTANCE
            objects.Dist.Text = math.floor(dist) .. "m"
            objects.Dist.Position = Vector2.new(hrpScreen.X, boxY + boxHeight + 2)
            objects.Dist.Visible = true

            -- HP BAR (sol tarafta dikey bar)
            local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barWidth = 3
            local barX = boxX - barWidth - 3

            objects.HPbg.Size = Vector2.new(barWidth, boxHeight)
            objects.HPbg.Position = Vector2.new(barX, boxY)
            objects.HPbg.Visible = true

            local fillHeight = boxHeight * hpRatio
            objects.HPfill.Size = Vector2.new(barWidth, fillHeight)
            objects.HPfill.Position = Vector2.new(barX, boxY + (boxHeight - fillHeight))
            objects.HPfill.Color = hpRatio > 0.5 and Color3.fromRGB(0,255,100)
                                 or hpRatio > 0.25 and Color3.fromRGB(255,200,0)
                                 or Color3.fromRGB(255, 50, 50)
            objects.HPfill.Visible = true

            -- SNAP LINE (ekran altından ayaklara)
            objects.SnapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objects.SnapLine.To = Vector2.new(hrpScreen.X, feetScreen.Y)
            objects.SnapLine.Visible = true
        end
    end)
end

local function StopESPLoop()
    if Connections["ESPLoop"] then
        Connections["ESPLoop"]:Disconnect()
        Connections["ESPLoop"] = nil
    end
end

----------------------------------------------------------------
--  ██████  NOCLIP — FIXED (double-bind + state disable)  ██████
----------------------------------------------------------------
local function StartNoClip()
    local hum = GetHumanoid()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end

    Connections["NC1"] = RunService.Stepped:Connect(function()
        if not State.NoClip then return end
        local char = GetCharacter()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)

    Connections["NC2"] = RunService.Heartbeat:Connect(function()
        if not State.NoClip then return end
        local char = GetCharacter()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function StopNoClip()
    if Connections["NC1"] then Connections["NC1"]:Disconnect(); Connections["NC1"] = nil end
    if Connections["NC2"] then Connections["NC2"]:Disconnect(); Connections["NC2"] = nil end
    local hum = GetHumanoid()
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
end

----------------------------------------------------------------
--  ██████  AIMBOT — FIXED (priority 201)  ██████
----------------------------------------------------------------
local AIM_BIND = "MarcushAim"

local function StartAimbot()
    pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)

    RunService:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Aimbot then return end
        if not UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

        local target = GetClosestEnemy()
        if not target or not target.Character then return end
        local head = FindHead(target.Character)
        if not head then return end

        local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, State.AimbotSmooth)
    end)
end

local function StopAimbot()
    pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
end

----------------------------------------------------------------
--  ██████  SILENT AIM — __namecall + __index + Raycast hook  ██████
--
--  3 katmanlı hook:
--    1. __namecall: FireServer/InvokeServer args'daki Vector3/CFrame →
--       düşman head'e redirect
--    2. __index: Mouse.Hit → head CFrame, Mouse.Target → head part
--    3. workspace:Raycast hook: Raycast sonucunu head'e yönlendir
--
--  BloxStrike dahil çoğu FPS oyun bunlardan birini kullanır.
----------------------------------------------------------------
local SilentOldNamecall = nil
local SilentOldIndex    = nil
local SilentTarget      = nil

local function UpdateSilentTarget()
    Connections["SilentTick"] = RunService.Heartbeat:Connect(function()
        if State.SilentAim then
            SilentTarget = GetClosestEnemy()
        else
            SilentTarget = nil
        end
    end)
end

local function GetSilentHead()
    if SilentTarget and SilentTarget.Character then
        local head = FindHead(SilentTarget.Character)
        if head then return head.Position, head.CFrame, head end
    end
    return nil, nil, nil
end

local function StartSilentAim()
    UpdateSilentTarget()

    -- ═══ HOOK 1: __namecall ═══
    if hookmetamethod and getnamecallmethod then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldNC = mt.__namecall
            SilentOldNamecall = oldNC

            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()

                if State.SilentAim and not checkcaller() then
                    if method == "FireServer" or method == "InvokeServer" then
                        local headPos, headCF, _ = GetSilentHead()
                        if headPos then
                            local args = {...}
                            local modified = false

                            for i, arg in ipairs(args) do
                                if typeof(arg) == "CFrame" then
                                    args[i] = headCF
                                    modified = true
                                elseif typeof(arg) == "Vector3" then
                                    args[i] = headPos
                                    modified = true
                                elseif typeof(arg) == "table" then
                                    -- Nested table args (bazı oyunlar data table gönderir)
                                    for k, v in pairs(arg) do
                                        if typeof(v) == "CFrame" then
                                            arg[k] = headCF
                                            modified = true
                                        elseif typeof(v) == "Vector3" then
                                            arg[k] = headPos
                                            modified = true
                                        end
                                    end
                                end
                            end

                            if modified then
                                return oldNC(self, unpack(args))
                            end
                        end
                    end

                    -- ═══ Raycast redirect ═══
                    if method == "Raycast" and self == Workspace then
                        local headPos, _, _ = GetSilentHead()
                        if headPos then
                            local args = {...}
                            if #args >= 2 and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                                local origin = args[1]
                                local newDir = (headPos - origin).Unit * args[2].Magnitude
                                args[2] = newDir
                                return oldNC(self, unpack(args))
                            end
                        end
                    end

                    -- ═══ FindPartOnRay redirect ═══
                    if (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and self == Workspace then
                        local headPos, _, _ = GetSilentHead()
                        if headPos then
                            local args = {...}
                            if #args >= 1 and typeof(args[1]) == "Ray" then
                                local origin = args[1].Origin
                                local newDir = (headPos - origin).Unit * args[1].Direction.Magnitude
                                args[1] = Ray.new(origin, newDir)
                                return oldNC(self, unpack(args))
                            end
                        end
                    end
                end

                return oldNC(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end

    -- ═══ HOOK 2: __index (Mouse.Hit / Mouse.Target) ═══
    if hookmetamethod then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldIdx = mt.__index
            SilentOldIndex = oldIdx

            setreadonly(mt, false)
            mt.__index = newcclosure(function(self, key)
                if State.SilentAim and not checkcaller() then
                    if self == Mouse then
                        if key == "Hit" then
                            local _, headCF, _ = GetSilentHead()
                            if headCF then return headCF end
                        elseif key == "Target" then
                            local _, _, headPart = GetSilentHead()
                            if headPart then return headPart end
                        elseif key == "X" or key == "Y" then
                            local headPos, _, _ = GetSilentHead()
                            if headPos then
                                local sp = Camera:WorldToViewportPoint(headPos)
                                if key == "X" then return sp.X end
                                if key == "Y" then return sp.Y end
                            end
                        end
                    end
                end
                return oldIdx(self, key)
            end)
            setreadonly(mt, true)
        end)
    end
end

local function StopSilentAim()
    SilentTarget = nil
    if Connections["SilentTick"] then
        Connections["SilentTick"]:Disconnect()
        Connections["SilentTick"] = nil
    end

    if SilentOldNamecall and hookmetamethod then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = SilentOldNamecall
            setreadonly(mt, true)
        end)
        SilentOldNamecall = nil
    end

    if SilentOldIndex and hookmetamethod then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__index = SilentOldIndex
            setreadonly(mt, true)
        end)
        SilentOldIndex = nil
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
    FOVCircle.Transparency = 0.5
    FOVCircle.Radius = State.AimbotFOV
    FOVCircle.Visible = false
end)

Connections["FOV"] = RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = State.AimbotFOV
        FOVCircle.Visible = State.Aimbot or State.SilentAim
    end
end)

----------------------------------------------------------------
--  ██████  CFRAME SPEED (bypass)  ██████
--  WalkSpeed = 16 (normal), ekstra hız CFrame ile eklenir
--  Server WalkSpeed'i normal görür
----------------------------------------------------------------
local function StartCFrameSpeed()
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 end

    Connections["CSpeed"] = RunService.Heartbeat:Connect(function(dt)
        if not State.Speed then return end
        local hrp = GetHRP()
        local hum2 = GetHumanoid()
        if not hrp or not hum2 then return end
        local dir = hum2.MoveDirection
        if dir.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + dir.Unit * (State.SpeedValue - 1) * 16 * dt
        end
    end)
end

local function StopCFrameSpeed()
    if Connections["CSpeed"] then Connections["CSpeed"]:Disconnect(); Connections["CSpeed"] = nil end
end

----------------------------------------------------------------
--  ██████  CFRAME FLY (bypass — no BodyVelocity)  ██████
--  Saf CFrame manipülasyonu, fizik objesi yok
--  Humanoid state = Swimming → yerçekimi bypass
----------------------------------------------------------------
local function StartCFrameFly()
    Connections["CFly"] = RunService.Heartbeat:Connect(function(dt)
        if not State.Fly then return end
        local hrp = GetHRP()
        local hum = GetHumanoid()
        if not hrp or not hum then return end

        hum:ChangeState(Enum.HumanoidStateType.Swimming)

        local dir = Vector3.new(0, 0, 0)
        local cf = Camera.CFrame

        if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end

        if dir.Magnitude > 0 then dir = dir.Unit end

        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = hrp.CFrame + (dir * State.FlySpeed * dt)
    end)
end

local function StopCFrameFly()
    if Connections["CFly"] then Connections["CFly"]:Disconnect(); Connections["CFly"] = nil end
    local hum = GetHumanoid()
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

----------------------------------------------------------------
--  INFINITE JUMP
----------------------------------------------------------------
local function StartInfJump()
    Connections["IJ"] = UserInput.JumpRequest:Connect(function()
        if State.InfJump then
            local hum = GetHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

local function StopInfJump()
    if Connections["IJ"] then Connections["IJ"]:Disconnect(); Connections["IJ"] = nil end
end

----------------------------------------------------------------
--  FULLBRIGHT
----------------------------------------------------------------
local OrigA  = Lighting.Ambient
local OrigB  = Lighting.Brightness
local OrigOA = Lighting.OutdoorAmbient
local OrigFE = Lighting.FogEnd

local function SetFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 1e9
    else
        Lighting.Ambient = OrigA
        Lighting.Brightness = OrigB
        Lighting.OutdoorAmbient = OrigOA
        Lighting.FogEnd = OrigFE
    end
end

----------------------------------------------------------------
--  GOD MODE (client HP loop)
----------------------------------------------------------------
local function StartGodMode()
    Connections["GM"] = RunService.Heartbeat:Connect(function()
        if State.GodMode then
            local hum = GetHumanoid()
            if hum then hum.Health = hum.MaxHealth end
        end
    end)
end

local function StopGodMode()
    if Connections["GM"] then Connections["GM"]:Disconnect(); Connections["GM"] = nil end
end

----------------------------------------------------------------
--  ANTI-AFK
----------------------------------------------------------------
local function StartAntiAFK()
    local VU = game:GetService("VirtualUser")
    Connections["AFK"] = LocalPlayer.Idled:Connect(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end

local function StopAntiAFK()
    if Connections["AFK"] then Connections["AFK"]:Disconnect(); Connections["AFK"] = nil end
end

----------------------------------------------------------------
--  ██████  BUILD GUI  ██████
----------------------------------------------------------------
Section("━━━ COMBAT ━━━", 1)

Toggle("🎯 Aimbot", "Sağ tık = kafa lock (priority 201 fix)", 2, function(on)
    State.Aimbot = on
    if on then StartAimbot() else StopAimbot() end
end)

Toggle("🔇 Silent Aim", "Kamera sabit, mermi kafaya (__namecall+Raycast+Mouse hook)", 3, function(on)
    State.SilentAim = on
    if on then StartSilentAim() else StopSilentAim() end
end)

Slider("🎯 Aimbot FOV", 50, 500, 250, 4, function(v) State.AimbotFOV = v end)
Slider("🎯 Smooth", 5, 100, 25, 5, function(v) State.AimbotSmooth = v / 100 end)

Toggle("🤝 Team Check", "Takım arkadaşını hedefleme (default ON)", 6, function(on)
    State.TeamCheck = on
end)

Section("━━━ MOVEMENT ━━━", 10)

Toggle("⛔ NoClip", "Duvardan geç (Stepped+Heartbeat double-bind)", 11, function(on)
    State.NoClip = on
    if on then StartNoClip() else StopNoClip() end
end)

Toggle("💨 CFrame Speed", "WalkSpeed normal kalır, CFrame hız bypass", 12, function(on)
    State.Speed = on
    if on then StartCFrameSpeed() else StopCFrameSpeed() end
end)

Slider("💨 Speed Multi", 1, 10, 3, 13, function(v) State.SpeedValue = v end)

Toggle("🕊️ CFrame Fly", "Fizik objesi yok, saf CFrame uçuş bypass", 14, function(on)
    State.Fly = on
    if on then StartCFrameFly() else StopCFrameFly() end
end)

Slider("🕊️ Fly Speed", 20, 300, 80, 15, function(v) State.FlySpeed = v end)

Toggle("🦘 Infinite Jump", "Havada sınırsız zıpla", 16, function(on)
    State.InfJump = on
    if on then StartInfJump() else StopInfJump() end
end)

Section("━━━ VISUALS ━━━", 20)

Toggle("👁️ ESP", "Drawing API box ESP (BloxStrike compat, undetectable)", 21, function(on)
    State.ESP = on
    if on then
        -- Create drawings for existing players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                pcall(function() CreateDrawingESP(p) end)
            end
        end
        UpdateESPLoop()
    else
        StopESPLoop()
        ClearAllESP()
    end
end)

Slider("👁️ ESP Max Dist", 100, 2000, 1000, 22, function(v) State.ESPMaxDist = v end)

Toggle("☀️ Fullbright", "Karanlıkta her şeyi gör", 23, function(on)
    State.Fullbright = on
    SetFullbright(on)
end)

Section("━━━ MISC ━━━", 30)

Toggle("🛡️ God Mode", "Client-side HP max loop", 31, function(on)
    State.GodMode = on
    if on then StartGodMode() else StopGodMode() end
end)

Toggle("💤 Anti-AFK", "Idle kick bypass (VirtualUser)", 32, function(on)
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
    MainFrame.Size = minimized and UDim2.new(0, 440, 0, 50) or UDim2.new(0, 440, 0, 540)
    MinBtn.Text = minimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Full cleanup
    StopNoClip(); StopAimbot(); StopSilentAim()
    StopCFrameSpeed(); StopCFrameFly(); StopInfJump()
    StopGodMode(); StopAntiAFK(); StopESPLoop()
    ClearAllESP(); SetFullbright(false)

    for _, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
    end

    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    ScreenGui:Destroy()
end)

----------------------------------------------------------------
--  TOGGLE GUI — RightControl
----------------------------------------------------------------
UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

----------------------------------------------------------------
--  AUTO RECONNECT ON RESPAWN
----------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    Camera = Workspace.CurrentCamera
    if State.Speed then StopCFrameSpeed(); StartCFrameSpeed() end
    if State.Fly then StopCFrameFly(); StartCFrameFly() end
    if State.NoClip then StopNoClip(); StartNoClip() end
    if State.GodMode then StopGodMode(); StartGodMode() end
    if State.Aimbot then StopAimbot(); StartAimbot() end
end)

-- Yeni oyuncu geldiğinde ESP drawing oluştur
Players.PlayerAdded:Connect(function(p)
    if State.ESP then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            pcall(function() CreateDrawingESP(p) end)
        end)
    end
end)

-- Oyuncu çıktığında ESP temizle
Players.PlayerRemoving:Connect(function(p)
    RemoveDrawingESP(p.Name)
end)

-- Mevcut oyuncuların respawn'unu yakala
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if State.ESP then
                pcall(function() CreateDrawingESP(p) end)
            end
        end)
    end
end

----------------------------------------------------------------
--  LOADED NOTIFICATION
----------------------------------------------------------------
local Notif = Instance.new("TextLabel")
Notif.Size = UDim2.new(0, 340, 0, 42)
Notif.Position = UDim2.new(0.5, -170, 0, 10)
Notif.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
Notif.TextColor3 = Color3.fromRGB(255, 255, 255)
Notif.Text = "⚡ Marcush Hub v3.0 — Bypassed Edition"
Notif.TextSize = 14
Notif.Font = Enum.Font.GothamBold
Notif.BorderSizePixel = 0
Notif.Parent = ScreenGui
Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 10)

spawn(function()
    task.wait(3.5)
    for i = 0, 1, 0.03 do
        Notif.BackgroundTransparency = i
        Notif.TextTransparency = i
        task.wait(0.02)
    end
    Notif:Destroy()
end)

----------------------------------------------------------------
--  CONSOLE OUTPUT
----------------------------------------------------------------
print("═══════════════════════════════════════════════")
print("  ⚡ Marcush Hub v3.0 — Bypassed Edition")
print("  RightCtrl = toggle GUI visibility")
print("  ESP: Drawing API (undetectable by game)")
print("  Silent Aim: __namecall + Raycast + Mouse hook")
print("  Speed/Fly: CFrame-based (no physics objects)")
print("═══════════════════════════════════════════════")
