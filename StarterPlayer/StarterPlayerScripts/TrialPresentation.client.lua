-- LocalScript in StarterPlayer > StarterPlayerScripts. Builds its own PlayerGui.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local lines = require(game:GetService("ReplicatedStorage"):WaitForChild("TrialDialogue"))
local room = workspace:WaitForChild("TrialCourtroom")
local slots = room:WaitForChild("Slots")
local camera = workspace.CurrentCamera
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "TrialPresentation", false, 20
gui.Parent = player:WaitForChild("PlayerGui")
local pink = Color3.fromRGB(255, 55, 150)
local function ui(class, properties, parent)
    local item = Instance.new(class)
    for key, value in pairs(properties) do item[key] = value end
    item.Parent = parent or gui
    return item
end
local function label(properties, parent)
    local defaults = {BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextScaled = true, BorderSizePixel = 0}
    for key, value in pairs(properties) do defaults[key] = value end
    local item = ui("TextLabel", defaults, parent)
    ui("UITextSizeConstraint", {MinTextSize = 10, MaxTextSize = 30}, item)
    return item
end
local title = label({Text = "CLASS TRIAL  /  RECONSTRUCTION", Position = UDim2.fromScale(0.035, 0.04), Size = UDim2.fromScale(0.7, 0.05), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = pink})
local panel = ui("Frame", {Position = UDim2.fromScale(0.025, 0.72), Size = UDim2.fromScale(0.95, 0.245), BackgroundColor3 = Color3.fromRGB(17, 16, 26), BackgroundTransparency = 0.08, BorderSizePixel = 0})
ui("UIStroke", {Color = pink, Thickness = 2}, panel)
local viewport = ui("ViewportFrame", {Position = UDim2.fromScale(0.01, -0.45), Size = UDim2.fromScale(0.23, 1.45), BackgroundTransparency = 1, Ambient = Color3.fromRGB(210,210,220), LightColor = Color3.new(1,1,1)}, panel)
local world = ui("WorldModel", {}, viewport)
local portraitCamera = ui("Camera", {FieldOfView = 34}, viewport)
viewport.CurrentCamera = portraitCamera
local speaker = label({Position = UDim2.fromScale(0.26, 0.05), Size = UDim2.fromScale(0.69, 0.19), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = pink}, panel)
local dialogue = label({Position = UDim2.fromScale(0.26, 0.28), Size = UDim2.fromScale(0.69, 0.43), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham}, panel)
local hint = label({Text = "SPACE / TAP NEXT", Position = UDim2.fromScale(0.58, 0.78), Size = UDim2.fromScale(0.38, 0.12), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(180,180,195)}, panel)
local nextButton = ui("TextButton", {Text = "", BackgroundTransparency = 1, Position = UDim2.fromScale(0.25, 0), Size = UDim2.fromScale(0.75, 1)}, panel)
local debateLayer = ui("Frame", {Size = UDim2.fromScale(1, 0.65), Position = UDim2.fromScale(0, 0.1), BackgroundTransparency = 1, ClipsDescendants = true})
local debateHint = label({Text = "CLICK / TAP A STATEMENT TO SHOOT", Position = UDim2.fromScale(0.1, 0.87), Size = UDim2.fromScale(0.8, 0.06), TextColor3 = pink, Visible = false})
local feedback = label({Text = "", Position = UDim2.fromScale(0.2, 0.68), Size = UDim2.fromScale(0.6, 0.1), TextColor3 = pink, Visible = false, ZIndex = 5})
local intro = ui("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 10, 22), BackgroundTransparency = 0.12, Visible = false, ZIndex = 10, Active = true})
local introTitle = label({Text = "NONSTOP DEBATE", Position = UDim2.fromScale(-1, 0.35), Size = UDim2.fromScale(0.9, 0.16), TextColor3 = pink, ZIndex = 11}, intro)
introTitle:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = 68
label({Text = "Aim at the moving statements. Click or tap to fire.", Position = UDim2.fromScale(0.1, 0.55), Size = UDim2.fromScale(0.8, 0.07), ZIndex = 11}, intro)
local index, generation, typing, orbit = 0, 0, false, false
local transitioning, shot = false, false
local fireAt
local activeTween, flyingTween
local orbitTime = 0
local function portrait(slot)
    world:ClearAllChildren()
    local source = slot.Name == "1" and player.Character or slot:FindFirstChild("Speaker")
    if not source then return end
    local previous = source.Archivable
    source.Archivable = true
    local clone = source:Clone()
    source.Archivable = previous
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("Script") or child:IsA("LocalScript") then child:Destroy()
        elseif child:IsA("BasePart") then child.Anchored, child.CanCollide = true, false end
    end
    clone.Parent = world
    local head = clone:FindFirstChild("Head")
    if head then
        local target = head.Position - Vector3.new(0, 0.9, 0)
        portraitCamera.CFrame = CFrame.lookAt(target + head.CFrame.LookVector * 8, target)
    end
end
local function advance()
    if transitioning then return end
    if typing then dialogue.MaxVisibleGraphemes = -1; typing = false; return end
    local wasDebate = orbit
    index = index % #lines + 1
    generation = generation + 1
    local token = generation
    local line = lines[index]
    local slot = slots:WaitForChild(tostring(line.speaker))
    if activeTween then activeTween:Cancel() end
    if flyingTween then flyingTween:Cancel() end
    debateLayer:ClearAllChildren()
    orbit = line.debate == true
    shot = false
    fireAt = nil
    feedback.Visible = false
    panel.Visible = not orbit
    debateHint.Visible = orbit
    if orbit and not wasDebate then
        transitioning = true
        debateHint.Visible = false
        intro.Visible = true
        introTitle.Position = UDim2.fromScale(-1, 0.35)
        local entry = TweenService:Create(introTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.05, 0.35)})
        entry:Play()
        task.wait(2.2)
        intro.Visible = false
        debateHint.Visible = true
        transitioning = false
    end
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = orbit and 65 or 50
    if not orbit then
        local stand = slot:WaitForChild("Stand")
        local target = stand.Position + Vector3.new(0, 1.5, 0)
        local distance = line.shot == "wide" and 17 or 8
        local position = target + stand.CFrame.LookVector * distance + Vector3.new(2, 1, 0)
        activeTween = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {CFrame = CFrame.lookAt(position, target), Focus = CFrame.new(target)})
        activeTween:Play()
    end
    speaker.Text = slot.Name == "1" and player.DisplayName or slot:GetAttribute("SpeakerName")
    title.Text = orbit and "NONSTOP DEBATE  /  TESTIMONY" or "CLASS TRIAL  /  RECONSTRUCTION"
    if not orbit then portrait(slot) end
    dialogue.Text, dialogue.MaxVisibleGraphemes, typing = line.text, 0, not orbit
    hint.Text = index == #lines and "SPACE / TAP TO REPLAY" or "SPACE / TAP NEXT"
    if orbit then
        local words = label({ZIndex = 2, Text = line.text, TextColor3 = pink, TextStrokeTransparency = 0.25, Rotation = -7, Position = UDim2.fromScale(1, 0.30), Size = UDim2.fromScale(0.85, 0.2)}, debateLayer)
        local constraint = words:FindFirstChildOfClass("UITextSizeConstraint")
        constraint.MaxTextSize = 52
        flyingTween = TweenService:Create(words, TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(-0.9, 0.46)})
        flyingTween:Play()
        -- Check the moving target on pointer-down, not after a moving button is released.
        fireAt = function(point)
            if shot or transitioning or token ~= generation then return end
            local center = words.AbsolutePosition + words.AbsoluteSize / 2
            local offset = point - center
            local angle = math.rad(-words.Rotation)
            local x = offset.X * math.cos(angle) - offset.Y * math.sin(angle)
            local y = offset.X * math.sin(angle) + offset.Y * math.cos(angle)
            local layerPoint = point - debateLayer.AbsolutePosition
            local insideLayer = layerPoint.X >= 0 and layerPoint.Y >= 0 and layerPoint.X <= debateLayer.AbsoluteSize.X and layerPoint.Y <= debateLayer.AbsoluteSize.Y
            local hit = insideLayer and math.abs(x) <= words.AbsoluteSize.X / 2 and math.abs(y) <= words.AbsoluteSize.Y / 2
            -- A visible tracer appears on every shot, including misses.
            local start = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.9)
            local delta = point - start
            local tracer = ui("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(start.X, start.Y), Size = UDim2.fromOffset(delta.Magnitude, 5), Rotation = math.deg(math.atan2(delta.Y, delta.X)), BackgroundColor3 = Color3.fromRGB(255, 215, 80), BorderSizePixel = 0, ZIndex = 8})
            -- Rotate around the center while keeping the line endpoints aligned.
            tracer.AnchorPoint = Vector2.new(0.5, 0.5)
            tracer.Position = UDim2.fromOffset((start.X + point.X) / 2, (start.Y + point.Y) / 2)
            TweenService:Create(tracer, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            Debris:AddItem(tracer, 0.2)
            if not hit then
                feedback.Text, feedback.Visible = "MISS — AIM AT THE WORDS", true
                return
            end
            shot = true
            flyingTween:Cancel()
            words.TextColor3 = Color3.new(1, 1, 1)
            feedback.Text, feedback.Visible = "BREAK!", true
            TweenService:Create(words, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1, Rotation = 12}):Play()
            task.delay(0.5, function()
                if token == generation then advance() end
            end)
        end
        return
    end
    task.spawn(function()
        local count = utf8.len(line.text) or #line.text
        for n = 1, count do
            if token ~= generation or not typing then return end
            dialogue.MaxVisibleGraphemes = n
            task.wait(0.025)
        end
        if token == generation then typing = false end
    end)
end
nextButton.Activated:Connect(advance)
UserInputService.InputBegan:Connect(function(input, processed)
    if transitioning then return end
    if orbit then
        -- Our debate overlay owns gameplay clicks, even when Roblox flags GUI input processed.
        if UserInputService:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local point = Vector2.new(input.Position.X, input.Position.Y)
            local inset = GuiService:GetGuiInset()
            if not gui.IgnoreGuiInset then point = point - inset end
            if point.Y >= 0 and fireAt then fireAt(point) end
        end
        return
    end
    if not processed and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA) then advance() end
end)
RunService.RenderStepped:Connect(function(dt)
    if orbit then
        orbitTime = orbitTime + dt * 0.22
        local center = room.Floor.Position + Vector3.new(0, 4, 0)
        local position = center + Vector3.new(math.sin(orbitTime) * 18, 5, math.cos(orbitTime) * 18)
        camera.CFrame, camera.Focus = CFrame.lookAt(position, center), CFrame.new(center)
    end
end)
player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Head", 15)
    if index > 0 then portrait(slots[tostring(lines[index].speaker)]) end
end)
player.CharacterAppearanceLoaded:Connect(function()
    if index > 0 and lines[index].speaker == 1 then portrait(slots["1"]) end
end)
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("Head")
slots:WaitForChild("8"):WaitForChild("Stand")
advance()
