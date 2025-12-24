--[[
    ARCADE UI LIBRARY (With Config System)
    Converted by Shadow
]]

local ArcadeUILib = {}
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ==================== CONFIG SAVE SYSTEM ====================
local ConfigSystem = {}
ConfigSystem.ConfigFile = "ArcadeUI_Config.json"

-- Default config
ConfigSystem.DefaultConfig = {}

-- Load config dari file
function ConfigSystem:Load()
    if isfile and isfile(self.ConfigFile) then
        local success, result = pcall(function()
            local fileContent = readfile(self.ConfigFile)
            local decoded = HttpService:JSONDecode(fileContent)
            return decoded
        end)
        
        if success and result then
            print("✅ ArcadeUI Config loaded!")
            return result
        else
            warn("⚠️ Failed to load config, using defaults")
            return self.DefaultConfig
        end
    else
        print("📝 No ArcadeUI config file found, creating new one...")
        return self.DefaultConfig
    end
end

-- Save config ke file
function ConfigSystem:Save(config)
    local success, error = pcall(function()
        local encoded = HttpService:JSONEncode(config)
        writefile(self.ConfigFile, encoded)
    end)
    
    if success then
        return true
    else
        warn("❌ Failed to save config:", error)
        return false
    end
end

-- Update satu setting sahaja
function ConfigSystem:UpdateSetting(config, key, value)
    config[key] = value
    self:Save(config)
end

-- ==================== UI VARIABLES ====================
local ScreenGui
local MainFrame
local ToggleButton
local ScrollFrame
local ListLayout

-- ==================== CREATE UI ====================
function ArcadeUILib:CreateUI()
    -- Load config awal-awal
    self.Config = ConfigSystem:Load()

    -- Cleanup
    if game.CoreGui:FindFirstChild("ArcadeUI") then
        game.CoreGui:FindFirstChild("ArcadeUI"):Destroy()
    end

    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArcadeUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game.CoreGui

    -- Toggle Button
    ToggleButton = Instance.new("ImageButton")
    ToggleButton.Size = UDim2.new(0, 60, 0, 60)
    ToggleButton.Position = UDim2.new(0, 20, 0.5, -30)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Image = "rbxassetid://121996261654076"
    ToggleButton.Active = true
    ToggleButton.Draggable = true
    ToggleButton.Parent = ScreenGui

    -- Main Frame
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 240, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -120, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    -- Styling
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 15)
    mainCorner.Parent = MainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 50, 50)
    mainStroke.Thickness = 1
    mainStroke.Parent = MainFrame

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 45)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "ttk : @N1ghtmare.gg"
    titleLabel.TextColor3 = Color3.fromRGB(139, 0, 0)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.Arcade
    titleLabel.Parent = MainFrame

    -- ScrollingFrame
    ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -125)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 55)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Parent = MainFrame

    -- UIListLayout
    ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 10)
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.Parent = ScrollFrame

    -- Auto-update canvas size
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- Social Buttons
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 2)
    divider.Position = UDim2.new(0, 10, 1, -65)
    divider.BackgroundTransparency = 1
    divider.BorderSizePixel = 0
    divider.Parent = MainFrame

    -- TikTok Button
    local tiktokButton = Instance.new("TextButton")
    tiktokButton.Size = UDim2.new(0, 100, 0, 32)
    tiktokButton.Position = UDim2.new(0, 15, 1, -55)
    tiktokButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tiktokButton.BorderSizePixel = 0
    tiktokButton.Text = "  TikTok"
    tiktokButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tiktokButton.TextSize = 13
    tiktokButton.Font = Enum.Font.Arcade
    tiktokButton.Parent = MainFrame

    local tiktokCorner = Instance.new("UICorner")
    tiktokCorner.CornerRadius = UDim.new(0, 8)
    tiktokCorner.Parent = tiktokButton

    local tiktokIcon = Instance.new("ImageLabel")
    tiktokIcon.Size = UDim2.new(0, 18, 0, 18)
    tiktokIcon.Position = UDim2.new(0, 8, 0.5, -9)
    tiktokIcon.BackgroundTransparency = 1
    tiktokIcon.Image = "rbxassetid://70531653995908"
    tiktokIcon.Parent = tiktokButton

    tiktokButton.MouseButton1Click:Connect(function()
        setclipboard("https://www.tiktok.com/@n1ghtmare.gg?_r=1&_t=ZS-92UYqNKwMLA")
        tiktokButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        task.wait(0.2)
        tiktokButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    end)

    -- Discord Button
    local discordButton = Instance.new("TextButton")
    discordButton.Size = UDim2.new(0, 100, 0, 32)
    discordButton.Position = UDim2.new(0, 125, 1, -55)
    discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordButton.BorderSizePixel = 0
    discordButton.Text = "  Discord"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.TextSize = 13
    discordButton.Font = Enum.Font.Arcade
    discordButton.Parent = MainFrame

    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordButton

    local discordIcon = Instance.new("ImageLabel")
    discordIcon.Size = UDim2.new(0, 16, 0, 16)
    discordIcon.Position = UDim2.new(0, 9, 0.5, -8)
    discordIcon.BackgroundTransparency = 1
    discordIcon.Image = "rbxassetid://131585302403438"
    discordIcon.Parent = discordButton

    discordButton.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/V4a7BbH5")
        discordButton.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
        task.wait(0.2)
        discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)

    -- Toggle button functionality
    ToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    print("✅ Arcade UI Created Successfully!")
end

-- ==================== TOGGLE CREATION FUNCTION ====================
function ArcadeUILib:AddToggleRow(text1, callback1, text2, callback2)
    -- Create the row container
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, 0, 0, 35)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = ScrollFrame

    -- Helper function to create a single toggle
    local function createSingleToggle(text, callback, position)
        local configKey = "Arcade_" .. text
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 100, 0, 32)
        toggle.Position = position
        toggle.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        toggle.BorderSizePixel = 0
        toggle.Text = text
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextSize = 13
        toggle.Font = Enum.Font.Arcade
        toggle.Parent = rowFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = toggle

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 50, 50)
        stroke.Thickness = 1
        stroke.Parent = toggle

        -- Load initial state from config
        local isToggled = self.Config[configKey] or false
        if isToggled then
            toggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        end

        -- Call callback on initial load
        if callback then callback(isToggled) end

        toggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            if isToggled then
                toggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            else
                toggle.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            end

            -- Save state to config
            ConfigSystem:UpdateSetting(self.Config, configKey, isToggled)

            -- Execute callback
            if callback then callback(isToggled) end
        end)
    end

    -- Create the first toggle
    createSingleToggle(text1, callback1, UDim2.new(0, 5, 0, 0))

    -- Create the second toggle if text2 is provided
    if text2 and callback2 then
        createSingleToggle(text2, callback2, UDim2.new(0, 115, 0, 0))
    end
end

return ArcadeUILib
