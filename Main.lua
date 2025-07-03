-- Modern Roblox Script Rewrite
-- Clean, organized, and optimized version

local script_info = {
    name = "Enhanced Script",
    version = "2.0",
    author = "Rewritten"
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Constants
local PLAYER = Players.LocalPlayer
local CAMERA = workspace.CurrentCamera
local PLAYER_GUI = PLAYER:WaitForChild("PlayerGui")

-- Configuration
local Config = {
    GUI = {
        openCloseButton = true,
        keybindEnable = false,
        keybind = Enum.KeyCode.Z
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
        
        -- Visual settings
        fovColor = Color3.fromRGB(100, 0, 100),
        fovFillColor = Color3.fromRGB(100, 0, 100),
        fovTransparency = 0,
        fovFillTransparency = 1,
        thickness = 1
    },
    
    ESP = {
        Box = {
            enabled = false,
            showName = false,
            showDistance = false,
            showHealth = false,
            teamCheck = false,
            healthType = "Bar", -- "Bar", "Text", "Both"
            color = Color3.fromRGB(255, 255, 255)
        },
        
        Outlines = {
            enabled = false,
            teamCheck = false,
            teamColor = false,
            alwaysShow = true,
            fillColor = Color3.fromRGB(75, 0, 10),
            fillTransparency = 0.5,
            outlineColor = Color3.fromRGB(0, 0, 0),
            outlineTransparency = 0
        },
        
        Tracers = {
            enabled = false,
            teamCheck = false,
            teamColor = false,
            color = Color3.fromRGB(75, 0, 10)
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
    return gui
end

function Utils.isPlayerValid(player)
    return player and player ~= PLAYER and player.Character and 
           player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0
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

-- FOV Circle
local FOVModule = {}

function FOVModule.init()
    FOVModule.gui = Utils.createScreenGui("FOVCircle")
    
    FOVModule.frame = Instance.new("Frame")
    FOVModule.frame.Name = "FOVFrame"
    FOVModule.frame.Parent = FOVModule.gui
    FOVModule.frame.BackgroundTransparency = 1
    FOVModule.frame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVModule.frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVModule.frame.Size = UDim2.new(0, 100, 0, 100)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = FOVModule.frame
    
    FOVModule.stroke = Instance.new("UIStroke")
    FOVModule.stroke.Parent = FOVModule.frame
    FOVModule.stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FOVModule.stroke.Thickness = Config.Aimbot.thickness
    FOVModule.stroke.Color = Config.Aimbot.fovColor
    FOVModule.stroke.Transparency = Config.Aimbot.fovTransparency
end

function FOVModule.update()
    if not FOVModule.frame then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    FOVModule.frame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
    FOVModule.frame.Size = UDim2.new(0, Config.Aimbot.fov * 2, 0, Config.Aimbot.fov * 2)
    FOVModule.frame.Visible = Config.Aimbot.showFov
    FOVModule.frame.BackgroundColor3 = Config.Aimbot.fovFillColor
    FOVModule.frame.BackgroundTransparency = Config.Aimbot.fovFillTransparency
    
    FOVModule.stroke.Color = Config.Aimbot.fovColor
    FOVModule.stroke.Transparency = Config.Aimbot.fovTransparency
    FOVModule.stroke.Thickness = Config.Aimbot.thickness
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
        
        local screenPos, onScreen = CAMERA:WorldToViewportPoint(aimPart.Position)
        if not onScreen then continue end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distance < shortestDistance and Utils.isVisible(aimPart.Position, player.Character) then
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
    
    local targetPosition = aimPart.Position
    local currentCFrame = CAMERA.CFrame
    
    -- Calculate smooth aim
    local direction = (targetPosition - currentCFrame.Position).Unit
    local newCFrame = CFrame.lookAt(currentCFrame.Position, 
                                   currentCFrame.Position + direction)
    
    -- Apply smoothing
    local smoothedCFrame = currentCFrame:Lerp(newCFrame, Config.Aimbot.smoothing)
    CAMERA.CFrame = smoothedCFrame
end

-- ESP Module
local ESPModule = {}
ESPModule.objects = {}

function ESPModule.init()
    ESPModule.boxGui = Utils.createScreenGui("BoxESP")
    ESPModule.tracerGui = Utils.createScreenGui("TracerESP")
    ESPModule.highlightGui = Utils.createScreenGui("HighlightESP")
end

function ESPModule.createBox(player)
    local container = Instance.new("BillboardGui")
    container.Name = player.Name
    container.Parent = ESPModule.boxGui
    container.AlwaysOnTop = true
    container.Size = UDim2.new(4, 0, 5.4, 0)
    container.StudsOffset = Vector3.new(0, 0, 0)
    
    -- Box outline
    local box = Instance.new("Frame")
    box.Parent = container
    box.Size = UDim2.new(1, 0, 1, 0)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = Config.ESP.Box.color
    
    -- Info container
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Parent = container
    infoContainer.Size = UDim2.new(1, 0, 0, 60)
    infoContainer.Position = UDim2.new(0, 0, 1, 5)
    infoContainer.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = infoContainer
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = infoContainer
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.ESP.Box.color
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    
    -- Distance label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Parent = infoContainer
    distanceLabel.Size = UDim2.new(1, 0, 0, 20)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Config.ESP.Box.color
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    
    -- Health label
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Parent = infoContainer
    healthLabel.Size = UDim2.new(1, 0, 0, 20)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Config.ESP.Box.color
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Gotham
    
    -- Health bar
    local healthBarContainer = Instance.new("Frame")
    healthBarContainer.Name = "HealthBarContainer"
    healthBarContainer.Parent = container
    healthBarContainer.Size = UDim2.new(0, 4, 1, 0)
    healthBarContainer.Position = UDim2.new(0, -8, 0, 0)
    healthBarContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBarContainer.BorderSizePixel = 1
    healthBarContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Parent = healthBarContainer
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    
    return container
end

function ESPModule.createTracer(player)
    local tracer = Instance.new("Frame")
    tracer.Name = player.Name
    tracer.Parent = ESPModule.tracerGui
    tracer.BackgroundColor3 = Config.ESP.Tracers.color
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Visible = false
    
    return tracer
end

function ESPModule.createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name
    highlight.Parent = ESPModule.highlightGui
    highlight.FillColor = Config.ESP.Outlines.fillColor
    highlight.FillTransparency = Config.ESP.Outlines.fillTransparency
    highlight.OutlineColor = Config.ESP.Outlines.outlineColor
    highlight.OutlineTransparency = Config.ESP.Outlines.outlineTransparency
    highlight.DepthMode = Config.ESP.Outlines.alwaysShow and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    
    if player.Character then
        highlight.Adornee = player.Character
    end
    
    return highlight
end

function ESPModule.addPlayer(player)
    if ESPModule.objects[player] then return end
    
    ESPModule.objects[player] = {
        box = ESPModule.createBox(player),
        tracer = ESPModule.createTracer(player),
        highlight = ESPModule.createHighlight(player)
    }
    
    -- Handle character respawning
    local function onCharacterAdded(character)
        if ESPModule.objects[player] and ESPModule.objects[player].highlight then
            ESPModule.objects[player].highlight.Adornee = character
        end
        if ESPModule.objects[player] and ESPModule.objects[player].box then
            ESPModule.objects[player].box.Adornee = character:FindFirstChild("HumanoidRootPart")
        end
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

function ESPModule.removePlayer(player)
    if not ESPModule.objects[player] then return end
    
    for _, object in pairs(ESPModule.objects[player]) do
        if object then
            object:Destroy()
        end
    end
    
    ESPModule.objects[player] = nil
end

function ESPModule.updatePlayer(player)
    if not Utils.isPlayerValid(player) or not ESPModule.objects[player] then return end
    
    local objects = ESPModule.objects[player]
    local character = player.Character
    local humanoid = character.Humanoid
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return end
    
    -- Team check
    local showForTeam = not ((Config.ESP.Box.teamCheck or Config.ESP.Outlines.teamCheck or Config.ESP.Tracers.teamCheck) 
                            and player.Team == PLAYER.Team)
    
    -- Update box ESP
    if objects.box then
        objects.box.Enabled = Config.ESP.Box.enabled and showForTeam
        objects.box.Adornee = rootPart
        
        local nameLabel = objects.box:FindFirstChild("InfoContainer"):FindFirstChild("NameLabel")
        local distanceLabel = objects.box:FindFirstChild("InfoContainer"):FindFirstChild("DistanceLabel")
        local healthLabel = objects.box:FindFirstChild("InfoContainer"):FindFirstChild("HealthLabel")
        local healthBar = objects.box:FindFirstChild("HealthBarContainer"):FindFirstChild("HealthBar")
        
        if nameLabel then
            nameLabel.Visible = Config.ESP.Box.showName
        end
        
        if distanceLabel then
            distanceLabel.Visible = Config.ESP.Box.showDistance
            if Config.ESP.Box.showDistance then
                distanceLabel.Text = string.format("Distance: %.0f", Utils.getDistance(player))
            end
        end
        
        if healthLabel and healthBar then
            local showHealth = Config.ESP.Box.showHealth
            healthLabel.Visible = showHealth and (Config.ESP.Box.healthType == "Text" or Config.ESP.Box.healthType == "Both")
            healthBar.Parent.Visible = showHealth and (Config.ESP.Box.healthType == "Bar" or Config.ESP.Box.healthType == "Both")
            
            if showHealth then
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                healthLabel.Text = string.format("Health: %.0f", humanoid.Health)
                healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
                
                -- Color health bar based on health
                if healthPercent > 0.6 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 0.3 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                else
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
    
    -- Update highlight ESP
    if objects.highlight then
        objects.highlight.Enabled = Config.ESP.Outlines.enabled and showForTeam
        if Config.ESP.Outlines.teamColor and player.Team then
            objects.highlight.FillColor = player.Team.TeamColor.Color
        else
            objects.highlight.FillColor = Config.ESP.Outlines.fillColor
        end
    end
    
    -- Update tracer ESP
    if objects.tracer then
        local showTracer = Config.ESP.Tracers.enabled and showForTeam
        objects.tracer.Visible = showTracer
        
        if showTracer then
            local screenPos, onScreen = CAMERA:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local screenCenter = Vector2.new(CAMERA.ViewportSize.X / 2, CAMERA.ViewportSize.Y)
                local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                
                local distance = (screenCenter - targetPos).Magnitude
                local midPoint = (screenCenter + targetPos) / 2
                local angle = math.atan2(targetPos.Y - screenCenter.Y, targetPos.X - screenCenter.X)
                
                objects.tracer.Position = UDim2.new(0, midPoint.X, 0, midPoint.Y)
                objects.tracer.Size = UDim2.new(0, distance, 0, 2)
                objects.tracer.Rotation = math.deg(angle)
                
                if Config.ESP.Tracers.teamColor and player.Team then
                    objects.tracer.BackgroundColor3 = player.Team.TeamColor.Color
                else
                    objects.tracer.BackgroundColor3 = Config.ESP.Tracers.color
                end
            else
                objects.tracer.Visible = false
            end
        end
    end
end

-- GUI Module
local GUIModule = {}

function GUIModule.init()
    -- Create main GUI
    GUIModule.screenGui = Utils.createScreenGui("MainGUI")
    
    -- Create toggle button
    if Config.GUI.openCloseButton then
        GUIModule.createToggleButton()
    end
    
    -- Create main frame (initially hidden)
    GUIModule.createMainFrame()
end

function GUIModule.createToggleButton()
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.Parent = GUIModule.screenGui
    toggleFrame.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    toggleFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    toggleFrame.Position = UDim2.new(0.5, -75, 0, 20)
    toggleFrame.Size = UDim2.new(0, 150, 0, 50)
    toggleFrame.Active = true
    toggleFrame.Draggable = true
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Parent = toggleFrame
    toggleButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
    toggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Size = UDim2.new(1, 0, 0.68, 0)
    toggleButton.Position = UDim2.new(0, 0, 0.32, 0)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Text = "Toggle GUI"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 14
    
    toggleButton.MouseButton1Click:Connect(function()
        if GUIModule.mainFrame then
            GUIModule.mainFrame.Visible = not GUIModule.mainFrame.Visible
        end
    end)
end

function GUIModule.createMainFrame()
    -- This would contain the full GUI implementation
    -- For brevity, I'll create a simplified version
    
    GUIModule.mainFrame = Instance.new("Frame")
    GUIModule.mainFrame.Name = "MainFrame"
    GUIModule.mainFrame.Parent = GUIModule.screenGui
    GUIModule.mainFrame.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
    GUIModule.mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    GUIModule.mainFrame.Position = UDim2.new(0.5, -400, 0.5, -200)
    GUIModule.mainFrame.Size = UDim2.new(0, 800, 0, 400)
    GUIModule.mainFrame.Active = true
    GUIModule.mainFrame.Draggable = true
    GUIModule.mainFrame.Visible = false
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Parent = GUIModule.mainFrame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Size = UDim2.new(0, 200, 0, 30)
    title.Font = Enum.Font.GothamBold
    title.Text = script_info.name .. " v" .. script_info.version
    title.TextColor3 = Color3.fromRGB(17, 223, 255)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Add sections for different features
    GUIModule.createAimbotSection()
    GUIModule.createESPSection()
end

function GUIModule.createAimbotSection()
    -- Simplified aimbot controls
    local section = Instance.new("Frame")
    section.Name = "AimbotSection"
    section.Parent = GUIModule.mainFrame
    section.BackgroundTransparency = 1
    section.Position = UDim2.new(0, 20, 0, 50)
    section.Size = UDim2.new(0, 200, 1, -60)
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = section
    layout.Padding = UDim.new(0, 5)
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Parent = section
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Font = Enum.Font.GothamBold
    title.Text = "Aimbot"
    title.TextColor3 = Color3.fromRGB(17, 223, 255)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Create toggle buttons
    GUIModule.createToggle(section, "Enable", function(enabled)
        Config.Aimbot.enabled = enabled
    end)
    
    GUIModule.createToggle(section, "Team Check", function(enabled)
        Config.Aimbot.teamCheck = enabled
    end)
    
    GUIModule.createToggle(section, "Wall Check", function(enabled)
        Config.Aimbot.wallCheck = enabled
    end)
    
    GUIModule.createToggle(section, "Show FOV", function(enabled)
        Config.Aimbot.showFov = enabled
    end)
end

function GUIModule.createESPSection()
    -- Simplified ESP controls
    local section = Instance.new("Frame")
    section.Name = "ESPSection"
    section.Parent = GUIModule.mainFrame
    section.BackgroundTransparency = 1
    section.Position = UDim2.new(0, 250, 0, 50)
    section.Size = UDim2.new(0, 200, 1, -60)
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = section
    layout.Padding = UDim.new(0, 5)
    
    -- Section title
    local title = Instance.new("TextLabel")
    title.Parent = section
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Font = Enum.Font.GothamBold
    title.Text = "ESP"
    title.TextColor3 = Color3.fromRGB(17, 223, 255)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Create toggle buttons
    GUIModule.createToggle(section, "Box ESP", function(enabled)
        Config.ESP.Box.enabled = enabled
    end)
    
    GUIModule.createToggle(section, "Outlines", function(enabled)
        Config.ESP.Outlines.enabled = enabled
    end)
    
    GUIModule.createToggle(section, "Tracers", function(enabled)
        Config.ESP.Tracers.enabled = enabled
    end)
    
    GUIModule.createToggle(section, "Show Names", function(enabled)
        Config.ESP.Box.showName = enabled
    end)
    
    GUIModule.createToggle(section, "Show Distance", function(enabled)
        Config.ESP.Box.showDistance = enabled
    end)
    
    GUIModule.createToggle(section, "Show Health", function(enabled)
        Config.ESP.Box.showHealth = enabled
    end)
end

function GUIModule.createToggle(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.Size = UDim2.new(1, 0, 0, 30)
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    
    local enabled = false
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.BackgroundColor3 = enabled and Color3.fromRGB(2, 54, 8) or Color3.fromRGB(52, 52, 52)
        callback(enabled)
    end)
    
    return button
end

-- Input Handler
local InputHandler = {}

function InputHandler.init()
    -- Handle aimbot keybind
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Config.Aimbot.keybind and Config.Aimbot.enabled then
            Config.Aimbot.isAiming = true
        end
        
        if input.KeyCode == Config.GUI.keybind and Config.GUI.keybindEnable then
            if GUIModule.mainFrame then
                GUIModule.mainFrame.Visible = not GUIModule.mainFrame.Visible
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
            ESPModule.updatePlayer(player)
        end
    end
end

-- Player Management
local function onPlayerAdded(player)
    if player == PLAYER then return end
    ESPModule.addPlayer(player)
end

local function onPlayerRemoving(player)
    ESPModule.removePlayer(player)
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
    RunService.RenderStepped:Connect(mainLoop)
    
    print(script_info.name .. " v" .. script_info.version .. " loaded successfully!")
end

-- Start the script
initialize()
