local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Library = {}
Library.__index = Library

-- Theme colors
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Secondary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(45, 45, 45),
    Highlight = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(200, 200, 200),
    Border = Color3.fromRGB(60, 60, 60)
}

-- Animation presets
local Animations = {
    Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

function Library:CreateWindow(title)
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Console = {}
    Window.ConsoleVisible = false
    
    -- Main GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UILibrary"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Corner radius
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Drop shadow
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 6, 1, 6)
    Shadow.Position = UDim2.new(0, -3, 0, -3)
    Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.BackgroundTransparency = 0.7
    Shadow.ZIndex = MainFrame.ZIndex - 1
    Shadow.Parent = MainFrame
    
    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = UDim.new(0, 8)
    ShadowCorner.Parent = Shadow
    
    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Theme.Secondary
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    -- Fix corner clipping
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 8)
    TitleFix.Position = UDim2.new(0, 0, 1, -8)
    TitleFix.BackgroundColor3 = Theme.Secondary
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    -- Title text
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -100, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = title or "UI Library"
    TitleText.TextColor3 = Theme.Text
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamSemibold
    TitleText.TextSize = 14
    TitleText.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 5)
    CloseButton.BackgroundColor3 = Theme.Accent
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Theme.Text
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 18
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    -- Console button
    local ConsoleButton = Instance.new("TextButton")
    ConsoleButton.Size = UDim2.new(0, 30, 0, 30)
    ConsoleButton.Position = UDim2.new(1, -70, 0, 5)
    ConsoleButton.BackgroundColor3 = Theme.Accent
    ConsoleButton.BorderSizePixel = 0
    ConsoleButton.Text = "◯"
    ConsoleButton.TextColor3 = Theme.Text
    ConsoleButton.Font = Enum.Font.GothamBold
    ConsoleButton.TextSize = 14
    ConsoleButton.Parent = TitleBar
    
    local ConsoleCorner = Instance.new("UICorner")
    ConsoleCorner.CornerRadius = UDim.new(0, 4)
    ConsoleCorner.Parent = ConsoleButton
    
    -- Tab container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 0, 35)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = Theme.Accent
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabContainer
    
    -- Content container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, -75)
    ContentContainer.Position = UDim2.new(0, 0, 0, 75)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame
    
    -- Console frame
    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Name = "ConsoleFrame"
    ConsoleFrame.Size = UDim2.new(1, 0, 0, 150)
    ConsoleFrame.Position = UDim2.new(0, 0, 1, 0)
    ConsoleFrame.BackgroundColor3 = Theme.Secondary
    ConsoleFrame.BorderSizePixel = 0
    ConsoleFrame.Parent = MainFrame
    
    local ConsoleFrameCorner = Instance.new("UICorner")
    ConsoleFrameCorner.CornerRadius = UDim.new(0, 8)
    ConsoleFrameCorner.Parent = ConsoleFrame
    
    -- Console output
    local ConsoleOutput = Instance.new("ScrollingFrame")
    ConsoleOutput.Size = UDim2.new(1, -20, 1, -40)
    ConsoleOutput.Position = UDim2.new(0, 10, 0, 10)
    ConsoleOutput.BackgroundColor3 = Theme.Background
    ConsoleOutput.BorderSizePixel = 0
    ConsoleOutput.ScrollBarThickness = 4
    ConsoleOutput.Parent = ConsoleFrame
    
    local ConsoleOutputCorner = Instance.new("UICorner")
    ConsoleOutputCorner.CornerRadius = UDim.new(0, 4)
    ConsoleOutputCorner.Parent = ConsoleOutput
    
    local ConsoleLayout = Instance.new("UIListLayout")
    ConsoleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ConsoleLayout.Padding = UDim.new(0, 2)
    ConsoleLayout.Parent = ConsoleOutput
    
    -- Console input
    local ConsoleInput = Instance.new("TextBox")
    ConsoleInput.Size = UDim2.new(1, -20, 0, 25)
    ConsoleInput.Position = UDim2.new(0, 10, 1, -30)
    ConsoleInput.BackgroundColor3 = Theme.Background
    ConsoleInput.BorderSizePixel = 0
    ConsoleInput.PlaceholderText = "Enter command..."
    ConsoleInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    ConsoleInput.Text = ""
    ConsoleInput.TextColor3 = Theme.Text
    ConsoleInput.Font = Enum.Font.Gotham
    ConsoleInput.TextSize = 12
    ConsoleInput.TextXAlignment = Enum.TextXAlignment.Left
    ConsoleInput.Parent = ConsoleFrame
    
    local ConsoleInputCorner = Instance.new("UICorner")
    ConsoleInputCorner.CornerRadius = UDim.new(0, 4)
    ConsoleInputCorner.Parent = ConsoleInput
    
    -- Dragging functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Button animations
    local function AnimateButton(button, highlight)
        button.MouseEnter:Connect(function()
            if highlight then
                TweenService:Create(button, Animations.Fast, {BackgroundColor3 = Theme.Highlight}):Play()
                TweenService:Create(button, Animations.Fast, {TextColor3 = Theme.Background}):Play()
            else
                TweenService:Create(button, Animations.Fast, {BackgroundColor3 = Theme.Border}):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            if highlight then
                TweenService:Create(button, Animations.Fast, {BackgroundColor3 = Theme.Accent}):Play()
                TweenService:Create(button, Animations.Fast, {TextColor3 = Theme.Text}):Play()
            else
                TweenService:Create(button, Animations.Fast, {BackgroundColor3 = Theme.Accent}):Play()
            end
        end)
    end
    
    AnimateButton(CloseButton, true)
    AnimateButton(ConsoleButton, false)
    
    -- Close functionality
    CloseButton.MouseButton1Click:Connect(function()
        TweenService:Create(MainFrame, Animations.Medium, {Size = UDim2.new(0, 0, 0, 0)}):Play()
        wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Console functionality
    ConsoleButton.MouseButton1Click:Connect(function()
        Window.ConsoleVisible = not Window.ConsoleVisible
        if Window.ConsoleVisible then
            TweenService:Create(ConsoleFrame, Animations.Medium, {Position = UDim2.new(0, 0, 1, -150)}):Play()
            TweenService:Create(MainFrame, Animations.Medium, {Size = UDim2.new(0, 600, 0, 550)}):Play()
        else
            TweenService:Create(ConsoleFrame, Animations.Medium, {Position = UDim2.new(0, 0, 1, 0)}):Play()
            TweenService:Create(MainFrame, Animations.Medium, {Size = UDim2.new(0, 600, 0, 400)}):Play()
        end
    end)
    
    -- Console commands
    Window.AddConsoleMessage = function(message, color)
        local MessageLabel = Instance.new("TextLabel")
        MessageLabel.Size = UDim2.new(1, -10, 0, 15)
        MessageLabel.BackgroundTransparency = 1
        MessageLabel.Text = message
        MessageLabel.TextColor3 = color or Theme.Text
        MessageLabel.Font = Enum.Font.Gotham
        MessageLabel.TextSize = 11
        MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
        MessageLabel.TextWrapped = true
        MessageLabel.Parent = ConsoleOutput
        
        ConsoleOutput.CanvasSize = UDim2.new(0, 0, 0, ConsoleLayout.AbsoluteContentSize.Y)
        ConsoleOutput.CanvasPosition = Vector2.new(0, ConsoleOutput.CanvasSize.Y.Offset)
    end
    
    ConsoleInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and ConsoleInput.Text ~= "" then
            local command = ConsoleInput.Text
            Window.AddConsoleMessage("> " .. command, Theme.Highlight)
            
            -- Basic command processing
            if command:lower() == "clear" then
                for _, child in pairs(ConsoleOutput:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child:Destroy()
                    end
                end
                ConsoleOutput.CanvasSize = UDim2.new(0, 0, 0, 0)
            elseif command:lower() == "help" then
                Window.AddConsoleMessage("Available commands: clear, help", Color3.fromRGB(100, 200, 100))
            else
                Window.AddConsoleMessage("Unknown command: " .. command, Color3.fromRGB(200, 100, 100))
            end
            
            ConsoleInput.Text = ""
        end
    end)
    
    -- Tab creation
    function Window:CreateTab(name)
        local Tab = {}
        Tab.Elements = {}
        Tab.Content = nil
        
        -- Tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 120, 1, 0)
        TabButton.BackgroundColor3 = Theme.Accent
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Theme.Text
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 12
        TabButton.Parent = TabContainer
        
        -- Tab content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 5)
        ContentLayout.Parent = TabContent
        
        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 10)
        ContentPadding.PaddingLeft = UDim.new(0, 10)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.Parent = TabContent
        
        Tab.Content = TabContent
        
        -- Tab button functionality
        TabButton.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, tab in pairs(Window.Tabs) do
                tab.Content.Visible = false
                TweenService:Create(tab.Button, Animations.Fast, {BackgroundColor3 = Theme.Accent}):Play()
            end
            
            -- Show current tab
            TabContent.Visible = true
            TweenService:Create(TabButton, Animations.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
            Window.CurrentTab = Tab
        end)
        
        -- Tab button animation
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                TweenService:Create(TabButton, Animations.Fast, {BackgroundColor3 = Theme.Border}):Play()
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                TweenService:Create(TabButton, Animations.Fast, {BackgroundColor3 = Theme.Accent}):Play()
            end
        end)
        
        Tab.Button = TabButton
        Window.Tabs[#Window.Tabs + 1] = Tab
        
        -- Auto-select first tab
        if #Window.Tabs == 1 then
            TabButton.MouseButton1Click:Fire()
        end
        
        return Tab
    end
    
    -- Initial console message
    Window.AddConsoleMessage("Console initialized. Type 'help' for commands.", Color3.fromRGB(100, 200, 100))
    
    return Window
end

return Library
