-- ratman4080 universal
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    Noclip = true,
    ESP = true,
    Aimbot = false,
    WalkSpeed = 50,
    JumpPower = 100,
}

-- ===== NOCLIP =====
local function NoclipLoop()
    if not Config.Noclip then return end
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

-- ===== ESP =====
local ESPObjects = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    
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
    if not Config.ESP then
        for _, obj in pairs(ESPObjects) do
            obj.box.Visible = false
            obj.name.Visible = false
            obj.dist.Visible = false
        end
        return
    end
    
    for player, obj in pairs(ESPObjects) do
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
                local mouse = game:GetService("UserInputService"):GetMouseLocation()
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

-- ===== CHARACTER SETUP =====
local function SetupChar(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
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

print("[ratman4080] loaded. squeak.")
