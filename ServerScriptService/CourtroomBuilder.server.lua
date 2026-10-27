-- Script in ServerScriptService. Only creates objects inside TrialCourtroom.
local Players = game:GetService("Players")
local room = Instance.new("Model")
room.Name = "TrialCourtroom"
local origin = Vector3.new(0, 100, 0)
local function part(name, size, cf, color, material, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent or room
    return p
end
local dark = Color3.fromRGB(24, 22, 35)
local pink = Color3.fromRGB(255, 55, 150)
part("Floor", Vector3.new(100, 2, 100), CFrame.new(origin), dark, Enum.Material.Marble)
local slots = Instance.new("Folder")
slots.Name, slots.Parent = "Slots", room
local names = {"YOU", "REI", "AKIRA", "MORGAN", "SORA", "JUNE", "KAI", "NOVA"}
for i = 1, 8 do
    local angle = (i - 1) * math.pi / 4
    local position = origin + Vector3.new(math.sin(angle) * 27, 1, math.cos(angle) * 27)
    local facing = CFrame.lookAt(position, origin + Vector3.new(0, 1, 0))
    local slot = Instance.new("Model")
    slot.Name, slot.Parent = tostring(i), slots
    slot:SetAttribute("SpeakerName", names[i])
    part("Base", Vector3.new(9, 0.4, 7), facing * CFrame.new(0, 0.2, 0), pink, Enum.Material.Neon, slot)
    part("Podium", Vector3.new(6, 3, 3), facing * CFrame.new(0, 1.8, -1.8), dark, nil, slot)
    part("Top", Vector3.new(7, 0.4, 3.8), facing * CFrame.new(0, 3.5, -1.8), Color3.fromRGB(80, 65, 95), nil, slot)
    local marker = part("Stand", Vector3.new(1, 1, 1), facing * CFrame.new(0, 3, 1), dark, nil, slot)
    marker.Transparency, marker.CanCollide = 1, false
    if i > 1 then
        local rig = Instance.new("Model")
        rig.Name, rig.Parent = "Speaker", slot
        local color = Color3.fromHSV(i / 8, 0.45, 0.8)
        part("Torso", Vector3.new(2, 2, 1), facing * CFrame.new(0, 3.2, 1), color, nil, rig)
        local head = part("Head", Vector3.new(2, 1, 1), facing * CFrame.new(0, 4.7, 1), Color3.fromRGB(232, 198, 170), nil, rig)
        local face = Instance.new("Decal")
        face.Face, face.Texture, face.Parent = Enum.NormalId.Front, "rbxasset://textures/face.png", head
        for _, side in ipairs({-1, 1}) do
            part("Arm", Vector3.new(1, 2, 1), facing * CFrame.new(side * 1.5, 3.2, 1), color, nil, rig)
            part("Leg", Vector3.new(1, 2, 1), facing * CFrame.new(side * 0.5, 1.2, 1), dark, nil, rig)
        end
    end
end
for i = 1, 16 do
    local a = i * math.pi / 8
    local cf = CFrame.new(origin + Vector3.new(math.sin(a) * 43, 12, math.cos(a) * 43)) * CFrame.Angles(0, a, 0)
    part("Wall", Vector3.new(18, 25, 2), cf, dark)
    local strip = part("LightStrip", Vector3.new(0.5, 22, 0.5), cf * CFrame.new(7, 0, -1.2), pink, Enum.Material.Neon)
    local light = Instance.new("PointLight")
    light.Color, light.Brightness, light.Range, light.Parent = pink, 0.7, 24, strip
end
local ceilingLight = part("Overhead", Vector3.new(18, 0.5, 18), CFrame.new(origin + Vector3.new(0, 22, 0)), Color3.new(1, 1, 1), Enum.Material.Neon)
local light = Instance.new("PointLight")
light.Range, light.Brightness, light.Parent = 60, 3, ceilingLight
room.Parent = workspace
-- A shared room with a separate presentation on each client; multiplayer roles come later.
local function placeCharacter(character)
    local root = character:WaitForChild("HumanoidRootPart", 15)
    if not root or not character.Parent then return end
    character:PivotTo(slots["1"].Stand.CFrame)
    root.Anchored = true
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
end
local function playerAdded(player)
    player.CharacterAdded:Connect(placeCharacter)
    if player.Character then task.spawn(placeCharacter, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
