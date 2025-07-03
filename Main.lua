-- Test Roblox Script - Modern Rewrite
-- Enhanced with Drawing Library ESP and Bubbly GUI
-- Optimized for performance and detection evasion

local script_info = {
    name = "Test",
    version = "3.0",
    author = "CodDemon"
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

-- Constants
local PLAYER = Players.LocalPlayer
local CAMERA = workspace.CurrentCamera
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")

-- Configuration
local Config = {
    GUI = {
        openCloseButton = true,
        keybindEnable = true,
        keybind = Enum.KeyCode.Insert,
        theme = {
            primary = Color3.fromRGB(138, 43, 226),
            secondary = Color3.fromRGB(75, 0, 130),
            accent = Color3.fromRGB(255, 20, 147),
            background = Color3.fromRGB(25, 25, 35),
            surface = Color3.fromRGB(35, 35, 50),
            text = Color3.fromRGB(255, 255, 255),
            textSecondary = Color3.fromRGB(200, 200, 200),
            success = Color3.fromRGB(46, 204, 113),
            warning = Color3.fromRGB(241, 196, 15),
            error = Color3.fromRGB(231, 76, 60)
        }
    },
    
    Aimbot = {
        enabled = false,
        teamCheck = false,
        wallCheck = false,
        showFov = false,
        fov = 100,
        smoothing = 0.5,
        aimPart = "Head",
        keybind = Enum.UserInputType.MouseButton2,
        isAiming = false,
        prediction = 0.1,
        
        -- Visual settings
        fovColor = Color3.fromRGB(138, 43, 226),
        fovFillColor = Color3.fromRGB(138, 43, 226),
        fovTransparency = 0.8,
        fovFillTransparency = 0.95,
        thickness = 2
    },
    
    ESP = {
        Box = {
            enabled = false,
            showName = false,
            showDistance = false,
            showHealth = false,
            teamCheck = false,
            healthType = "Bar", -- "Bar", "Text", "Both"
            color = Color3.fromRGB(138, 43, 226),
            thickness = 2,
            filled = false,
            fillTransparency = 0.1
        },
        
        Tracers = {
            enabled = false,
            teamCheck = false,
            teamColor = false,
            color = Color3.fromRGB(138, 43, 226),
            thickness = 2,
            from = "Bottom" -- "Bottom", "Center", "Top"
        },
        
        Skeleton = {
            enabled = false,
            teamCheck = false,
            color = Color3.fromRGB(255, 255, 255),
            thickness = 1
        },
        
        Chams = {
            enabled = false,
            teamCheck = false,
            fillColor = Color3.fromRGB(138, 43, 226),
            outlineColor = Color3.fromRGB(255, 255, 255),
            fillTransparency = 0.5,
            outlineTransparency = 0
        }
    }
}

-- Utility Functions
local Utils = {}

function Utils.createScreenGui(name, parent)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.Parent = parent or PLAYER_GUI
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    return gui
end

function Utils.isPlayerValid(player)
    return player and player ~= PLAYER and player.Character and 
           player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0 and
           player.Character:FindFirstChild("HumanoidRootPart")
end

function Utils.getDistance(player)
    if not (PLAYER.Character and PLAYER.Character:FindFirstChild("HumanoidRootPart") and
            player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
        return math.huge
    end
    
    return (PLAYER.Character.HumanoidRootPart.Position - 
            player.Character.HumanoidRootPart.Position).Magnitude
end

function Utils.isVisible(targetPosition, targetCharacter)
    if not Config.Aimbot.wallCheck then
        return true
    end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {CAMERA, PLAYER.Character, targetCharacter}
    
    local raycastResult = workspace:Raycast(CAMERA.CFrame.Position, 
                                          (targetPosition - CAMERA.CFrame.Position).Unit * 1000, 
                                          raycastParams)
    
    return not raycastResult
end

function Utils.worldToScreen(position)
    local screenPos, onScreen = CAMERA:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

function Utils.getCorners(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local size = humanoidRootPart.Size
    local cf = humanoidRootPart.CFrame
    
    local corners = {
        cf * CFrame.new(-size.X/2, size.Y/2, 0),
        cf * CFrame.new(size.X/2, size.Y/2, 0),
        cf * CFrame.new(-size.X/2, -size.Y/2, 0),
        cf * CFrame.new(size.X/2, -size.Y/2, 0)
    }
    
    local screenCorners = {}
    for i, corner in ipairs(corners) do
        local screenPos, onScreen = Utils.worldToScreen(corner.Position)
        if not onScreen then return nil end
        screenCorners[i] = screenPos
    end
    
    local minX = math.min(screenCorners[1].X, screenCorners[2].X, screenCorners[3].X, screenCorners[4].X)
    local maxX = math.max(screenCorners[1].X, screenCorners[2].X, screenCorners[3].X, screenCorners[4].X)
    local minY = math.min(screenCorners[1].Y, screenCorners[2].Y, screenCorners[3].Y, screenCorners[4].Y)
    local maxY = math.max(screenCorners[1].Y, screenCorners[2].Y, screenCorners[3].Y, screenCorners[4].Y)
    
    return {
        topLeft = Vector2.new(minX, minY),
        topRight = Vector2.new(maxX, minY),
        bottomLeft = Vector2.new(minX, maxY),
        bottomRight = Vector2.new(maxX, maxY),
        size = Vector2.new(maxX - minX, maxY - minY)
    }
end

-- Animation System
local AnimationSystem = {}

function AnimationSystem.tween(object, properties, duration, easingStyle, easingDirection)
    duration = duration or 0.3
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDirection = easingDirection or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function AnimationSystem.spring(object, properties, duration)
    return AnimationSystem.tween(object, properties, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function AnimationSystem.bounce(object, properties, duration)
    return AnimationSystem.tween(object, properties, duration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
end

-- FOV Circle Module
local FOVModule = {}

function FOVModule.init()
    FOVModule.circle = Drawing.new("Circle")
    FOVModule.circle.Thickness = Config.Aimbot.thickness
    FOVModule.circle.NumSides = 64
    FOVModule.circle.Radius = Config.Aimbot.fov
    FOVModule.circle.Filled = false
    FOVModule.circle.Color = Config.Aimbot.fovColor
    FOVModule.circle.Transparency = 1 - Config.Aimbot.fovTransparency
    FOVModule.circle.Visible = false
end

function FOVModule.update()
    if not FOVModule.circle then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    FOVModule.circle.Position = mousePos
    FOVModule.circle.Radius = Config.Aimbot.fov
    FOVModule.circle.Visible = Config.Aimbot.showFov
    FOVModule.circle.Color = Config.Aimbot.fovColor
    FOVModule.circle.Transparency = 1 - Config.Aimbot.fovTransparency
    FOVModule.circle.Thickness = Config.Aimbot.thickness
end

function FOVModule.cleanup()
    if FOVModule.circle then
        FOVModule.circle:Remove()
        FOVModule.circle = nil
    end
end

-- ESP Module with Drawing Library
local ESPModule = {}
ESPModule.objects = {}

function ESPModule.init()
    -- Initialize ESP system
end

function ESPModule.createESP(player)
    if ESPModule.objects[player] then
        ESPModule.removeESP(player)
    end
    
    local espObjects = {
        box = Drawing.new("Square"),
        boxOutline = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        nameText = Drawing.new("Text"),
        distanceText = Drawing.new("Text"),
        healthText = Drawing.new("Text"),
        healthBar = Drawing.new("Square"),
        healthBarOutline = Drawing.new("Square"),
        skeleton = {},
        chams = nil
    }
    
    -- Box setup
    espObjects.box.Thickness = Config.ESP.Box.thickness
    espObjects.box.Filled = Config.ESP.Box.filled
    espObjects.box.Color = Config.ESP.Box.color
    espObjects.box.Transparency = Config.ESP.Box.fillTransparency
    espObjects.box.Visible = false
    
    espObjects.boxOutline.Thickness = Config.ESP.Box.thickness + 1
    espObjects.boxOutline.Filled = false
    espObjects.boxOutline.Color = Color3.new(0, 0, 0)
    espObjects.boxOutline.Transparency = 0.5
    espObjects.boxOutline.Visible = false
    
    -- Tracer setup
    espObjects.tracer.Thickness = Config.ESP.Tracers.thickness
    espObjects.tracer.Color = Config.ESP.Tracers.color
    espObjects.tracer.Transparency = 0.8
    espObjects.tracer.Visible = false
    
    -- Text setup
    espObjects.nameText.Size = 16
    espObjects.nameText.Center = true
    espObjects.nameText.Outline = true
    espObjects.nameText.OutlineColor = Color3.new(0, 0, 0)
    espObjects.nameText.Color = Config.ESP.Box.color
    espObjects.nameText.Font = Drawing.Fonts.Plex
    espObjects.nameText.Visible = false
    
    espObjects.distanceText.Size = 14
    espObjects.distanceText.Center = true
    espObjects.distanceText.Outline = true
    espObjects.distanceText.OutlineColor = Color3.new(0, 0, 0)
    espObjects.distanceText.Color = Config.ESP.Box.color
    espObjects.distanceText.Font = Drawing.Fonts.Plex
    espObjects.distanceText.Visible = false
    
    espObjects.healthText.Size = 14
    espObjects.healthText.Center = true
    espObjects.healthText.Outline = true
    espObjects.healthText.OutlineColor = Color3.new(0, 0, 0)
    espObjects.healthText.Color = Config.ESP.Box.color
    espObjects.healthText.Font = Drawing.Fonts.Plex
    espObjects.healthText.Visible = false
    
    -- Health bar setup
    espObjects.healthBar.Filled = true
    espObjects.healthBar.Thickness = 1
    espObjects.healthBar.Transparency = 0.8
    espObjects.healthBar.Visible = false
    
    espObjects.healthBarOutline.Filled = false
    espObjects.healthBarOutline.Thickness = 1
    espObjects.healthBarOutline.Color = Color3.new(0, 0, 0)
    espObjects.healthBarOutline.Transparency = 0.5
    espObjects.healthBarOutline.Visible = false
    
    -- Skeleton setup
    local skeletonConnections = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    for i, connection in ipairs(skeletonConnections) do
        local line = Drawing.new("Line")
        line.Thickness = Config.ESP.Skeleton.thickness
        line.Color = Config.ESP.Skeleton.color
        line.Transparency = 0.8
        line.Visible = false
        espObjects.skeleton[i] = line
    end
    
    -- Chams setup
    if player.Character then
        espObjects.chams = Instance.new("Highlight")
        espObjects.chams.Parent = player.Character
        espObjects.chams.FillColor = Config.ESP.Chams.fillColor
        espObjects.chams.OutlineColor = Config.ESP.Chams.outlineColor
        espObjects.chams.FillTransparency = Config.ESP.Chams.fillTransparency
        espObjects.chams.OutlineTransparency = Config.ESP.Chams.outlineTransparency
        espObjects.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espObjects.chams.Enabled = false
    end
    
    ESPModule.objects[player] = espObjects
end

function ESPModule.updateESP(player)
    if not Utils.isPlayerValid(player) or not ESPModule.objects[player] then
        return
    end
    
    local espObjects = ESPModule.objects[player]
    local character = player.Character
    local humanoid = character.Humanoid
    local rootPart = character.HumanoidRootPart
    
    -- Team check
    local showForTeam = not ((Config.ESP.Box.teamCheck or Config.ESP.Tracers.teamCheck or Config.ESP.Skeleton.teamCheck) 
                            and player.Team == PLAYER.Team)
    
    if not showForTeam then
        ESPModule.hideESP(player)
        return
    end
    
    local corners = Utils.getCorners(character)
    if not corners then
        ESPModule.hideESP(player)
        return
    end
    
    -- Update box ESP
    if Config.ESP.Box.enabled then
        espObjects.boxOutline.Size = corners.size + Vector2.new(2, 2)
        espObjects.boxOutline.Position = corners.topLeft - Vector2.new(1, 1)
        espObjects.boxOutline.Visible = true
        
        espObjects.box.Size = corners.size
        espObjects.box.Position = corners.topLeft
        espObjects.box.Color = Config.ESP.Box.color
        espObjects.box.Visible = true
    else
        espObjects.box.Visible = false
        espObjects.boxOutline.Visible = false
    end
    
    -- Update tracer ESP
    if Config.ESP.Tracers.enabled then
        local tracerStart
        if Config.ESP.Tracers.from == "Bottom" then
            tracerStart = Vector2.new(CAMERA.ViewportSize.X / 2, CAMERA.ViewportSize.Y)
        elseif Config.ESP.Tracers.from == "Center" then
            tracerStart = Vector2.new(CAMERA.ViewportSize.X / 2, CAMERA.ViewportSize.Y / 2)
        else -- Top
            tracerStart = Vector2.new(CAMERA.ViewportSize.X / 2, 0)
        end
        
        local rootPos, onScreen = Utils.worldToScreen(rootPart.Position)
        if onScreen then
            espObjects.tracer.From = tracerStart
            espObjects.tracer.To = rootPos
            espObjects.tracer.Color = Config.ESP.Tracers.teamColor and player.TeamColor.Color or Config.ESP.Tracers.color
            espObjects.tracer.Visible = true
        else
            espObjects.tracer.Visible = false
        end
    else
        espObjects.tracer.Visible = false
    end
    
    -- Update text ESP
    if Config.ESP.Box.showName then
        espObjects.nameText.Text = player.Name
        espObjects.nameText.Position = Vector2.new(corners.topLeft.X + corners.size.X / 2, corners.topLeft.Y - 20)
        espObjects.nameText.Visible = true
    else
        espObjects.nameText.Visible = false
    end
    
    if Config.ESP.Box.showDistance then
        local distance = math.floor(Utils.getDistance(player))
        espObjects.distanceText.Text = distance .. "m"
        espObjects.distanceText.Position = Vector2.new(corners.topLeft.X + corners.size.X / 2, corners.bottomLeft.Y + 5)
        espObjects.distanceText.Visible = true
    else
        espObjects.distanceText.Visible = false
    end
    
    -- Update health ESP
    if Config.ESP.Box.showHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        if Config.ESP.Box.healthType == "Text" or Config.ESP.Box.healthType == "Both" then
            espObjects.healthText.Text = math.floor(humanoid.Health) .. " HP"
            espObjects.healthText.Position = Vector2.new(corners.topLeft.X + corners.size.X / 2, corners.bottomLeft.Y + 20)
            espObjects.healthText.Visible = true
        else
            espObjects.healthText.Visible = false
        end
        
        if Config.ESP.Box.healthType == "Bar" or Config.ESP.Box.healthType == "Both" then
            local barHeight = corners.size.Y * healthPercent
            local barWidth = 4
            
            espObjects.healthBarOutline.Size = Vector2.new(barWidth + 2, corners.size.Y + 2)
            espObjects.healthBarOutline.Position = Vector2.new(corners.topLeft.X - barWidth - 3, corners.topLeft.Y - 1)
            espObjects.healthBarOutline.Visible = true
            
            espObjects.healthBar.Size = Vector2.new(barWidth, barHeight)
            espObjects.healthBar.Position = Vector2.new(corners.topLeft.X - barWidth - 2, corners.bottomLeft.Y - barHeight)
            
            -- Color health bar based on health
            if healthPercent > 0.6 then
                espObjects.healthBar.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.3 then
                espObjects.healthBar.Color = Color3.fromRGB(255, 255, 0)
            else
                espObjects.healthBar.Color = Color3.fromRGB(255, 0, 0)
            end
            
            espObjects.healthBar.Visible = true
        else
            espObjects.healthBar.Visible = false
            espObjects.healthBarOutline.Visible = false
        end
    else
        espObjects.healthText.Visible = false
        espObjects.healthBar.Visible = false
        espObjects.healthBarOutline.Visible = false
    end
    
    -- Update skeleton ESP
    if Config.ESP.Skeleton.enabled then
        local skeletonConnections = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"}
        }
        
        for i, connection in ipairs(skeletonConnections) do
            local part1 = character:FindFirstChild(connection[1])
            local part2 = character:FindFirstChild(connection[2])
            
            if part1 and part2 and espObjects.skeleton[i] then
                local pos1, onScreen1 = Utils.worldToScreen(part1.Position)
                local pos2, onScreen2 = Utils.worldToScreen(part2.Position)
                
                if onScreen1 and onScreen2 then
                    espObjects.skeleton[i].From = pos1
                    espObjects.skeleton[i].To = pos2
                    espObjects.skeleton[i].Color = Config.ESP.Skeleton.color
                    espObjects.skeleton[i].Visible = true
                else
                    espObjects.skeleton[i].Visible = false
                end
            elseif espObjects.skeleton[i] then
                espObjects.skeleton[i].Visible = false
            end
        end
    else
        for _, line in ipairs(espObjects.skeleton) do
            line.Visible = false
        end
    end
    
    -- Update chams ESP
    if Config.ESP.Chams.enabled and espObjects.chams then
        espObjects.chams.Enabled = true
        espObjects.chams.FillColor = Config.ESP.Chams.fillColor
        espObjects.chams.OutlineColor = Config.ESP.Chams.outlineColor
        espObjects.chams.FillTransparency = Config.ESP.Chams.fillTransparency
        espObjects.chams.OutlineTransparency = Config.ESP.Chams.outlineTransparency
    elseif espObjects.chams then
        espObjects.chams.Enabled = false
    end
end

function ESPModule.hideESP(player)
    if not ESPModule.objects[player] then return end
    
    local espObjects = ESPModule.objects[player]
    espObjects.box.Visible = false
    espObjects.boxOutline.Visible = false
    espObjects.tracer.Visible = false
    espObjects.nameText.Visible = false
    espObjects.distanceText.Visible = false
    espObjects.healthText.Visible = false
    espObjects.healthBar.Visible = false
    espObjects.healthBarOutline.Visible = false
    
    for _, line in ipairs(espObjects.skeleton) do
        line.Visible = false
    end
    
    if espObjects.chams then
        espObjects.chams.Enabled = false
    end
end

function ESPModule.removeESP(player)
    if not ESPModule.objects[player] then return end
    
    local espObjects = ESPModule.objects[player]
    
    espObjects.box:Remove()
    espObjects.boxOutline:Remove()
    espObjects.tracer:Remove()
    espObjects.nameText:Remove()
    espObjects.distanceText:Remove()
    espObjects.healthText:Remove()
    espObjects.healthBar:Remove()
    espObjects.healthBarOutline:Remove()
    
    for _, line in ipairs(espObjects.skeleton) do
        line:Remove()
    end
    
    if espObjects.chams then
        espObjects.chams:Destroy()
    end
    
    ESPModule.objects[player] = nil
end

function ESPModule.cleanup()
    for player, _ in pairs(ESPModule.objects) do
        ESPModule.removeESP(player)
    end
end

-- Aimbot Module
local AimbotModule = {}

function AimbotModule.getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Config.Aimbot.fov
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if not Utils.isPlayerValid(player) then continue end
        
        if Config.Aimbot.teamCheck and player.Team == PLAYER.Team then continue end
        
        local aimPart = player.Character:FindFirstChild(Config.Aimbot.aimPart)
        if not aimPart then continue end
        
        -- Prediction
        local velocity = player.Character.HumanoidRootPart.Velocity
        local predictedPosition = aimPart.Position + (velocity * Config.Aimbot.prediction)
        
        local screenPos, onScreen = Utils.worldToScreen(predictedPosition)
        if not onScreen then continue end
        
        local distance = (screenPos - mousePos).Magnitude
        
        if distance < shortestDistance and Utils.isVisible(predictedPosition, player.Character) then
            shortestDistance = distance
            closestPlayer = player
        end
    end
    
    return closestPlayer
end

function AimbotModule.aimAt(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local aimPart = targetPlayer.Character:FindFirstChild(Config.Aimbot.aimPart)
    if not aimPart then return end
    
    -- Prediction
    local velocity = targetPlayer.Character.HumanoidRootPart.Velocity
    local predictedPosition = aimPart.Position + (velocity * Config.Aimbot.prediction)
    
    local currentCFrame = CAMERA.CFrame
    local direction = (predictedPosition - currentCFrame.Position).Unit
    local newCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)
    
    -- Apply smoothing
    local smoothedCFrame = currentCFrame:Lerp(newCFrame, Config.Aimbot.smoothing)
    CAMERA.CFrame = smoothedCFrame
end

-- Modern Bubbly GUI Module
local GUIModule = {}

function GUIModule.init()
    GUIModule.screenGui = Utils.createScreenGui("ModernGUI")
    
    if Config.GUI.openCloseButton then
        GUIModule.createToggleButton()
    end
    
    GUIModule.createMainFrame()
end

function GUIModule.createToggleButton()
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.Parent = GUIModule.screenGui
    toggleFrame.BackgroundColor3 = Config.GUI.theme.surface
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Position = UDim2.new(0, 20, 0, 20)
    toggleFrame.Size = UDim2.new(0, 60, 0, 60)
    toggleFrame.Active = true
    toggleFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 30)
    corner.Parent = toggleFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Config.GUI.theme.primary),
        ColorSequenceKeypoint.new(1, Config.GUI.theme.secondary)
    }
    gradient.Rotation = 45
    gradient.Parent = toggleFrame
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = toggleFrame
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = -1
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 40)
    shadowCorner.Parent = shadow
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Parent = toggleFrame
    toggleButton.BackgroundTransparency = 1
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Text = "⚙️"
    toggleButton.TextColor3 = Config.GUI.theme.text
    toggleButton.TextSize = 24
    toggleButton.TextScaled = true
    
    -- Hover effects
    toggleButton.MouseEnter:Connect(function()
        AnimationSystem.spring(toggleFrame, {Size = UDim2.new(0, 65, 0, 65)}, 0.2)
    end)
    
    toggleButton.MouseLeave:Connect(function()
        AnimationSystem.spring(toggleFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.2)
    end)
    
    toggleButton.MouseButton1Click:Connect(function()
        AnimationSystem.bounce(toggleFrame, {Size = UDim2.new(0, 55, 0, 55)}, 0.1)
        wait(0.1)
        AnimationSystem.spring(toggleFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.1)
        
        if GUIModule.mainFrame then
            local isVisible = GUIModule.mainFrame.Visible
            if isVisible then
                AnimationSystem.tween(GUIModule.mainFrame, {
                    Position = UDim2.new(0.5, 0, -0.5, 0)
                }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                wait(0.3)
                GUIModule.mainFrame.Visible = false
            else
                GUIModule.mainFrame.Visible = true
                GUIModule.mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
                AnimationSystem.spring(GUIModule.mainFrame, {
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }, 0.4)
            end
        end
    end)
end

function GUIModule.createMainFrame()
    GUIModule.mainFrame = Instance.new("Frame")
    GUIModule.mainFrame.Name = "MainFrame"
    GUIModule.mainFrame.Parent = GUIModule.screenGui
    GUIModule.mainFrame.BackgroundColor3 = Config.GUI.theme.background
    GUIModule.mainFrame.BorderSizePixel = 0
    GUIModule.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GUIModule.mainFrame.Size = UDim2.new(0, 600, 0, 400)
    GUIModule.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GUIModule.mainFrame.Active = true
    GUIModule.mainFrame.Draggable = true
    GUIModule.mainFrame.Visible = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = GUIModule.mainFrame
    
    -- Glass effect
    local glassEffect = Instance.new("Frame")
    glassEffect.Name = "GlassEffect"
    glassEffect.Parent = GUIModule.mainFrame
    glassEffect.BackgroundColor3 = Config.GUI.theme.surface
    glassEffect.BackgroundTransparency = 0.1
    glassEffect.BorderSizePixel = 0
    glassEffect.Size = UDim2.new(1, 0, 1, 0)
    
    local glassCorner = Instance.new("UICorner")
    glassCorner.CornerRadius = UDim.new(0, 20)
    glassCorner.Parent = glassEffect
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = GUIModule.mainFrame
    titleBar.BackgroundTransparency = 1
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    
    local title = Instance.new("TextLabel")
    title.Parent = titleBar
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 20, 0, 0)
    title.Size = UDim2.new(0, 300, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = script_info.name .. " v" .. script_info.version
    title.TextColor3 = Config.GUI.theme.text
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Gradient text effect
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Config.GUI.theme.primary),
        ColorSequenceKeypoint.new(1, Config.GUI.theme.accent)
    }
    titleGradient.Parent = title
    
    -- Content area
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Parent = GUIModule.mainFrame
    contentFrame.BackgroundTransparency = 1
    contentFrame.Position = UDim2.new(0, 0, 0, 60)
    contentFrame.Size = UDim2.new(1, 0, 1, -60)
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Config.GUI.theme.primary
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = contentFrame
    contentLayout.Padding = UDim.new(0, 20)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    -- Create sections
    GUIModule.createAimbotSection(contentFrame)
    GUIModule.createESPSection(contentFrame)
end

function GUIModule.createSection(parent, title)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Parent = parent
    section.BackgroundColor3 = Config.GUI.theme.surface
    section.BorderSizePixel = 0
    section.Size = UDim2.new(0, 560, 0, 200)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Parent = section
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Position = UDim2.new(0, 20, 0, 10)
    sectionTitle.Size = UDim2.new(1, -40, 0, 30)
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Config.GUI.theme.primary
    sectionTitle.TextSize = 18
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = section
    contentArea.BackgroundTransparency = 1
    contentArea.Position = UDim2.new(0, 20, 0, 50)
    contentArea.Size = UDim2.new(1, -40, 1, -60)
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = contentArea
    layout.Padding = UDim.new(0, 10)
    layout.FillDirection = Enum.FillDirection.Vertical
    
    return section, contentArea
end

function GUIModule.createToggle(parent, text, callback, defaultValue)
    local toggle = Instance.new("Frame")
    toggle.Name = text .. "Toggle"
    toggle.Parent = parent
    toggle.BackgroundTransparency = 1
    toggle.Size = UDim2.new(1, 0, 0, 30)
    
    local label = Instance.new("TextLabel")
    label.Parent = toggle
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Config.GUI.theme.text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Parent = toggle
    toggleButton.BackgroundColor3 = Config.GUI.theme.background
    toggleButton.BorderSizePixel = 0
    toggleButton.Position = UDim2.new(1, -50, 0, 5)
    toggleButton.Size = UDim2.new(0, 50, 0, 20)
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleButton
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Parent = toggleButton
    toggleCircle.BackgroundColor3 = Config.GUI.theme.textSecondary
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Position = UDim2.new(0, 2, 0, 2)
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 8)
    circleCorner.Parent = toggleCircle
    
    local enabled = defaultValue or false
    
    local function updateToggle()
        if enabled then
            AnimationSystem.tween(toggleCircle, {
                Position = UDim2.new(1, -18, 0, 2),
                BackgroundColor3 = Config.GUI.theme.text
            }, 0.2)
            AnimationSystem.tween(toggleButton, {
                BackgroundColor3 = Config.GUI.theme.primary
            }, 0.2)
        else
            AnimationSystem.tween(toggleCircle, {
                Position = UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Config.GUI.theme.textSecondary
            }, 0.2)
            AnimationSystem.tween(toggleButton, {
                BackgroundColor3 = Config.GUI.theme.background
            }, 0.2)
        end
    end
    
    local clickDetector = Instance.new("TextButton")
    clickDetector.Parent = toggleButton
    clickDetector.BackgroundTransparency = 1
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.Text = ""
    
    clickDetector.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateToggle()
        if callback then
            callback(enabled)
        end
    end)
    
    updateToggle()
    return toggle
end

function GUIModule.createSlider(parent, text, min, max, default, callback)
    local slider = Instance.new("Frame")
    slider.Name = text .. "Slider"
    slider.Parent = parent
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, 0, 0, 50)
    
    local label = Instance.new("TextLabel")
    label.Parent = slider
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Config.GUI.theme.text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = slider
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -60, 0, 0)
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.GUI.theme.primary
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Parent = slider
    sliderTrack.BackgroundColor3 = Config.GUI.theme.background
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Position = UDim2.new(0, 0, 0, 25)
    sliderTrack.Size = UDim2.new(1, 0, 0, 6)
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = sliderTrack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderTrack
    sliderFill.BackgroundColor3 = Config.GUI.theme.primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderHandle = Instance.new("Frame")
    sliderHandle.Parent = slider
    sliderHandle.BackgroundColor3 = Config.GUI.theme.text
    sliderHandle.BorderSizePixel = 0
    sliderHandle.Position = UDim2.new((default - min) / (max - min), -8, 0, 22)
    sliderHandle.Size = UDim2.new(0, 16, 0, 12)
    
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(0, 6)
    handleCorner.Parent = sliderHandle
    
    local dragging = false
    local currentValue = default
    
    local function updateSlider(value)
        currentValue = math.clamp(value, min, max)
        local percentage = (currentValue - min) / (max - min)
        
        AnimationSystem.tween(sliderFill, {Size = UDim2.new(percentage, 0, 1, 0)}, 0.1)
        AnimationSystem.tween(sliderHandle, {Position = UDim2.new(percentage, -8, 0, 22)}, 0.1)
        
        valueLabel.Text = string.format("%.1f", currentValue)
        
        if callback then
            callback(currentValue)
        end
    end
    
    sliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            AnimationSystem.tween(sliderHandle, {Size = UDim2.new(0, 20, 0, 16)}, 0.1)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            AnimationSystem.tween(sliderHandle, {Size = UDim2.new(0, 16, 0, 12)}, 0.1)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderTrack.AbsolutePosition
            local sliderSize = sliderTrack.AbsoluteSize
            
            local percentage = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local value = min + (percentage * (max - min))
            
            updateSlider(value)
        end
    end)
    
    return slider
end

function GUIModule.createAimbotSection(parent)
    local section, contentArea = GUIModule.createSection(parent, "Aimbot")
    
    GUIModule.createToggle(contentArea, "Enable", function(enabled)
        Config.Aimbot.enabled = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Team Check", function(enabled)
        Config.Aimbot.teamCheck = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Wall Check", function(enabled)
        Config.Aimbot.wallCheck = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Show FOV", function(enabled)
        Config.Aimbot.showFov = enabled
    end)
    
    GUIModule.createSlider(contentArea, "FOV", 10, 500, Config.Aimbot.fov, function(value)
        Config.Aimbot.fov = value
    end)
    
    GUIModule.createSlider(contentArea, "Smoothing", 0.1, 1, Config.Aimbot.smoothing, function(value)
        Config.Aimbot.smoothing = value
    end)
    
    section.Size = UDim2.new(0, 560, 0, 300)
end

function GUIModule.createESPSection(parent)
    local section, contentArea = GUIModule.createSection(parent, "ESP")
    
    GUIModule.createToggle(contentArea, "Box ESP", function(enabled)
        Config.ESP.Box.enabled = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Show Names", function(enabled)
        Config.ESP.Box.showName = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Show Distance", function(enabled)
        Config.ESP.Box.showDistance = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Show Health", function(enabled)
        Config.ESP.Box.showHealth = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Tracers", function(enabled)
        Config.ESP.Tracers.enabled = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Skeleton", function(enabled)
        Config.ESP.Skeleton.enabled = enabled
    end)
    
    GUIModule.createToggle(contentArea, "Chams", function(enabled)
        Config.ESP.Chams.enabled = enabled
    end)
    
    section.Size = UDim2.new(0, 560, 0, 350)
end

-- Input Handler
local InputHandler = {}

function InputHandler.init()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Config.Aimbot.keybind and Config.Aimbot.enabled then
            Config.Aimbot.isAiming = true
        end
        
        if input.KeyCode == Config.GUI.keybind and Config.GUI.keybindEnable then
            if GUIModule.mainFrame then
                local isVisible = GUIModule.mainFrame.Visible
                if isVisible then
                    AnimationSystem.tween(GUIModule.mainFrame, {
                        Position = UDim2.new(0.5, 0, -0.5, 0)
                    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    wait(0.3)
                    GUIModule.mainFrame.Visible = false
                else
                    GUIModule.mainFrame.Visible = true
                    GUIModule.mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
                    AnimationSystem.spring(GUIModule.mainFrame, {
                        Position = UDim2.new(0.5, 0, 0.5, 0)
                    }, 0.4)
                end
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Config.Aimbot.keybind then
            Config.Aimbot.isAiming = false
        end
    end)
end

-- Main Update Loop
local function mainLoop()
    -- Update FOV circle
    FOVModule.update()
    
    -- Handle aimbot
    if Config.Aimbot.enabled and Config.Aimbot.isAiming then
        local target = AimbotModule.getClosestPlayer()
        if target then
            AimbotModule.aimAt(target)
        end
    end
    
    -- Update ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if Utils.isPlayerValid(player) then
            ESPModule.updateESP(player)
        else
            ESPModule.hideESP(player)
        end
    end
end

-- Player Management
local function onPlayerAdded(player)
    if player == PLAYER then return end
    ESPModule.createESP(player)
    
    player.CharacterAdded:Connect(function()
        wait(1) -- Wait for character to fully load
        if ESPModule.objects[player] and ESPModule.objects[player].chams then
            ESPModule.objects[player].chams:Destroy()
        end
        if player.Character then
            local chams = Instance.new("Highlight")
            chams.Parent = player.Character
            chams.FillColor = Config.ESP.Chams.fillColor
            chams.OutlineColor = Config.ESP.Chams.outlineColor
            chams.FillTransparency = Config.ESP.Chams.fillTransparency
            chams.OutlineTransparency = Config.ESP.Chams.outlineTransparency
            chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            chams.Enabled = false
            
            if ESPModule.objects[player] then
                ESPModule.objects[player].chams = chams
            end
        end
    end)
end

local function onPlayerRemoving(player)
    ESPModule.removeESP(player)
end

-- Cleanup function
local function cleanup()
    FOVModule.cleanup()
    ESPModule.cleanup()
    if GUIModule.screenGui then
        GUIModule.screenGui:Destroy()
    end
end

-- Initialize Everything
local function initialize()
    -- Send notification
    StarterGui:SetCore("SendNotification", {
        Title = script_info.name,
        Text = "Loaded successfully! Version " .. script_info.version,
        Duration = 3
    })
    
    -- Initialize modules
    FOVModule.init()
    ESPModule.init()
    GUIModule.init()
    InputHandler.init()
    
    -- Connect player events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- Start main loop
    RunService.Heartbeat:Connect(mainLoop)
    
    -- Cleanup on game close
    game:BindToClose(cleanup)
    
    print(script_info.name .. " v" .. script_info.version .. " loaded successfully!")
end

-- Start the script
initialize()
