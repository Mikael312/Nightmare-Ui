--[[
    NIGHTMARE LIBRARY (With Config System + Notification System + Integrated Utility)
    Converted by shadow
]]

local Nightmare = {}
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==================== ANTI-DETECTION PARENT (INFINITE YIELD METHOD) ====================
-- Fungsi untuk mendapatkan parent GUI yang paling selamat.
-- Keutamaan: gethui() > syn.protect_gui()
local function getSafeCoreGuiParent()
    -- 1. Cuba gunakan gethui() (kaedah paling selamat dan moden)
    if gethui then
        local success, result = pcall(function()
            return gethui()
        end)
        if success and result then
            return result
        end
    end

    -- 2. Jika gethui gagal, Cuba gunakan syn.protect_gui()
    if syn and syn.protect_gui then
        local protectedGui = Instance.new("ScreenGui")
        protectedGui.Name = "Nightmare_Protected"
        protectedGui.ResetOnSpawn = false
        protectedGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        syn.protect_gui(protectedGui)
        protectedGui.Parent = CoreGui
        return protectedGui
    end

    -- Jika kedua-duanya gagal, kembalikan CoreGui sebagai fallback
    return CoreGui
end

-- ==================== CONFIG SAVE SYSTEM ====================
local ConfigSystem = {}
ConfigSystem.ConfigFile = "Nightmare_Config.json"

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
            return result
        else
            warn("⚠️ Failed to load config, using defaults")
            return self.DefaultConfig
        end
    else
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

-- ==================== NOTIFICATION SYSTEM ====================
local NotificationGui = nil
local DEFAULT_NOTIFICATION_SOUND_ID = 3398620867 -- ID untuk bunyi 'ding' default

-- Function untuk mencipta NotificationGui (dipanggil sekali sahaja)
local function createNotificationGui()
    if NotificationGui then return end -- Jika sudah wujud, jangan cipta lagi
    
    -- Dapatkan parent yang selamat untuk notifikasi juga
    local safeParent = getSafeCoreGuiParent()
    
    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "NightmareNotificationGui"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = safeParent
end

-- ==================== UTILITY SYSTEM VARIABLES ====================
local UtilityFrame = nil
local UtilityScrollFrame = nil
local UtilityListLayout = nil

-- Anti-Lag Variables
local antiLagRunning = false
local antiLagConnections = {}
local cleanedCharacters = {}

-- Unlock Nearest Variables
local unlockNearestUI = nil

-- ==================== UTILITY FUNCTIONS ====================
local function destroyAllEquippableItems(character)
    if not character then return end
    if not antiLagRunning then return end
    
    pcall(function()
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Hat") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child.ClassName == "LayeredClothing" or child.ClassName == "WrapLayer" then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                if not (child.Name == "face" and child.Parent and child.Parent.Name == "Head") then
                    child:Destroy()
                end
            end
        end
    end)
end

local function antiLagCleanCharacter(char)
    if not char then return end
    destroyAllEquippableItems(char)
    cleanedCharacters[char] = true
end

local function antiLagDisconnectAll()
    for _, conn in ipairs(antiLagConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    antiLagConnections = {}
    cleanedCharacters = {}
end

local function enableAntiLag()
    if antiLagRunning then 
        return false
    end
    
    antiLagRunning = true
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            antiLagCleanCharacter(plr.Character)
        end
    end
    
    table.insert(antiLagConnections, Players.PlayerAdded:Connect(function(plr)
        table.insert(antiLagConnections, plr.CharacterAdded:Connect(function(char)
            if not antiLagRunning then return end
            task.wait(0.5)
            antiLagCleanCharacter(char)
        end))
    end))
    
    table.insert(antiLagConnections, task.spawn(function()
        while antiLagRunning do
            task.wait(3)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and not cleanedCharacters[plr.Character] then
                    antiLagCleanCharacter(plr.Character)
                end
            end
        end
    end))
    
    return true
end

local function disableAntiLag()
    if not antiLagRunning then 
        return false
    end
    
    antiLagRunning = false
    antiLagDisconnectAll()
    
    return true
end

-- Function to find the closest plot to the player
local function getClosestPlot()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local closestPlot = nil
    local minDistance = 25
    
    for _, plot in pairs(plots:GetChildren()) do
        local plotPos = nil
        if plot.PrimaryPart then
            plotPos = plot.PrimaryPart.Position
        elseif plot:FindFirstChild("Base") then
            plotPos = plot.Base.Position
        elseif plot:FindFirstChild("Floor") then
            plotPos = plot.Floor.Position
        else
            plotPos = plot:GetPivot().Position
        end
        
        if plotPos then
            local distance = (rootPart.Position - plotPos).Magnitude
            if distance < minDistance then
                closestPlot = plot
                minDistance = distance
            end
        end
    end
    
    return closestPlot
end

-- Function to recursively find all proximity prompts in an object
local function findPrompts(instance, found)
    for _, child in pairs(instance:GetChildren()) do
        if child:IsA("ProximityPrompt") then
            table.insert(found, child)
        end
        findPrompts(child, found)
    end
end

-- Function to interact with a specific floor number
local function smartInteract(number)
    local targetPlot = getClosestPlot()
    
    if not targetPlot then
        Nightmare:Notify("No plot nearby!", false)
        return
    end
    
    local unlockFolder = targetPlot:FindFirstChild("Unlock")
    if not unlockFolder then
        Nightmare:Notify("No unlock folder found!", false)
        return
    end
    
    local unlockItems = {}
    for _, item in pairs(unlockFolder:GetChildren()) do
        local pos = nil
        if item:IsA("Model") then
            pos = item:GetPivot().Position
        elseif item:IsA("BasePart") then
            pos = item.Position
        end
        
        if pos then
            table.insert(unlockItems, {
                Object = item,
                Height = pos.Y
            })
        end
    end
    
    table.sort(unlockItems, function(a, b)
        return a.Height < b.Height
    end)
    
    if number > #unlockItems then
        Nightmare:Notify("Floor " .. number .. " not found!", false)
        return
    end
    
    local targetFloor = unlockItems[number].Object
    
    local prompts = {}
    findPrompts(targetFloor, prompts)
    
    if #prompts == 0 then
        Nightmare:Notify("No prompts found on floor " .. number, false)
        return
    end
    
    for _, prompt in pairs(prompts) do
        fireproximityprompt(prompt)
    end
    
    Nightmare:Notify("Unlocked Floor " .. number, false)
end

-- Function to create the Unlock Nearest UI
local function createUnlockNearestUI()
    if unlockNearestUI then
        unlockNearestUI:Destroy()
    end
    
    local safeParent = getSafeCoreGuiParent()
    
    local unlockGui = Instance.new("ScreenGui")
    unlockGui.Name = "UnlockBaseUI"
    unlockGui.ResetOnSpawn = false
    unlockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    unlockGui.Parent = safeParent
    
    local unlockMainFrame = Instance.new("Frame")
    unlockMainFrame.Size = UDim2.new(0, 90, 0, 200)
    unlockMainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
    unlockMainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    unlockMainFrame.BackgroundTransparency = 0.1
    unlockMainFrame.BorderSizePixel = 0
    unlockMainFrame.Active = true
    unlockMainFrame.Draggable = true
    unlockMainFrame.Parent = unlockGui
    
    local unlockCorner = Instance.new("UICorner")
    unlockCorner.CornerRadius = UDim.new(0, 15)
    unlockCorner.Parent = unlockMainFrame
    
    local unlockStroke = Instance.new("UIStroke")
    unlockStroke.Color = Color3.fromRGB(255, 50, 50)
    unlockStroke.Thickness = 2
    unlockStroke.Parent = unlockMainFrame
    
    local function createFloorButton(floorNum, yPos)
        local floorButton = Instance.new("TextButton")
        floorButton.Size = UDim2.new(0, 75, 0, 50)
        floorButton.Position = UDim2.new(0.5, -37.5, 0, yPos)
        floorButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        floorButton.BorderSizePixel = 0
        floorButton.Text = floorNum .. " Floor"
        floorButton.TextColor3 = Color3.fromRGB(255, 100, 100)
        floorButton.TextSize = 18
        floorButton.Font = Enum.Font.Arcade
        floorButton.Parent = unlockMainFrame
        
        local floorCorner = Instance.new("UICorner")
        floorCorner.CornerRadius = UDim.new(0, 10)
        floorCorner.Parent = floorButton
        
        floorButton.MouseButton1Click:Connect(function()
            local originalColor = floorButton.BackgroundColor3
            floorButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            
            TweenService:Create(floorButton, TweenInfo.new(0.2), {
                BackgroundColor3 = originalColor
            }):Play()
            
            smartInteract(floorNum)
        end)
        
        floorButton.MouseEnter:Connect(function()
            TweenService:Create(floorButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 0, 0)
            }):Play()
        end)
        
        floorButton.MouseLeave:Connect(function()
            TweenService:Create(floorButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
        end)
    end
    
    createFloorButton(1, 10)
    createFloorButton(2, 70)
    createFloorButton(3, 130)
    
    unlockNearestUI = unlockGui
end

-- Function to destroy the Unlock Nearest UI
local function destroyUnlockNearestUI()
    if unlockNearestUI then
        unlockNearestUI:Destroy()
        unlockNearestUI = nil
    end
end

-- ==================== UI VARIABLES ====================
local ScreenGui -- Pembolehubah untuk disimpan di luar fungsi
local MainFrame
local ToggleButton
local ScrollFrame
local ListLayout

-- ==================== CREATE UI ====================
function Nightmare:CreateUI()
    -- Load config awal-awal
    self.Config = ConfigSystem:Load()

    -- Cleanup: Hapus UI lama jika wujud
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end

    -- Dapatkan parent yang selamat
    local safeParent = getSafeCoreGuiParent()

    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Nightmare"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = safeParent

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

    ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 10)
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.Parent = ScrollFrame

    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- ==================== UTILITY UI ====================
    UtilityFrame = Instance.new("Frame")
    UtilityFrame.Size = UDim2.new(0, 220, 0, 300)
    UtilityFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
    UtilityFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    UtilityFrame.BackgroundTransparency = 0.1
    UtilityFrame.BorderSizePixel = 0
    UtilityFrame.Active = true
    UtilityFrame.Draggable = true
    UtilityFrame.Visible = false
    UtilityFrame.Parent = ScreenGui

    local utilityCorner = Instance.new("UICorner")
    utilityCorner.CornerRadius = UDim.new(0, 15)
    utilityCorner.Parent = UtilityFrame

    local utilityStroke = Instance.new("UIStroke")
    utilityStroke.Color = Color3.fromRGB(255, 50, 50)
    utilityStroke.Thickness = 1
    utilityStroke.Parent = UtilityFrame

    -- Utility Title
    local utilityTitle = Instance.new("TextLabel")
    utilityTitle.Size = UDim2.new(1, 0, 0, 40)
    utilityTitle.Position = UDim2.new(0, 0, 0, 5)
    utilityTitle.BackgroundTransparency = 1
    utilityTitle.Text = "Utility"
    utilityTitle.TextColor3 = Color3.fromRGB(139, 0, 0)
    utilityTitle.TextSize = 15
    utilityTitle.Font = Enum.Font.Arcade
    utilityTitle.Parent = UtilityFrame

    UtilityScrollFrame = Instance.new("ScrollingFrame")
    UtilityScrollFrame.Size = UDim2.new(1, -20, 1, -55)
    UtilityScrollFrame.Position = UDim2.new(0, 10, 0, 45)
    UtilityScrollFrame.BackgroundTransparency = 1
    UtilityScrollFrame.BorderSizePixel = 0
    UtilityScrollFrame.ScrollBarThickness = 4
    UtilityScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)
    UtilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    UtilityScrollFrame.Parent = UtilityFrame

    UtilityListLayout = Instance.new("UIListLayout")
    UtilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UtilityListLayout.Padding = UDim.new(0, 8)
    UtilityListLayout.FillDirection = Enum.FillDirection.Vertical
    UtilityListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UtilityListLayout.Parent = UtilityScrollFrame

    UtilityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UtilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UtilityListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 2)
    divider.Position = UDim2.new(0, 10, 1, -65)
    divider.BackgroundTransparency = 1
    divider.BorderSizePixel = 0
    divider.Parent = MainFrame

    -- Utility Button
    local utilityButton = Instance.new("TextButton")
    utilityButton.Size = UDim2.new(0, 100, 0, 32)
    utilityButton.Position = UDim2.new(0, 15, 1, -55)
    utilityButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    utilityButton.BorderSizePixel = 0
    utilityButton.Text = "Utility"
    utilityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    utilityButton.TextSize = 13
    utilityButton.Font = Enum.Font.Arcade
    utilityButton.Parent = MainFrame

    local utilityCornerBtn = Instance.new("UICorner")
    utilityCornerBtn.CornerRadius = UDim.new(0, 8)
    utilityCornerBtn.Parent = utilityButton

    local utilityStrokeBtn = Instance.new("UIStroke")
    utilityStrokeBtn.Color = Color3.fromRGB(255, 50, 50)
    utilityStrokeBtn.Thickness = 1
    utilityStrokeBtn.Parent = utilityButton

    utilityButton.MouseButton1Click:Connect(function()
        UtilityFrame.Visible = not UtilityFrame.Visible
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
        setclipboard("https://discord.gg/WB2p6Zvh")
        discordButton.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
        task.wait(0.2)
        discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)

    -- Toggle button functionality
    ToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- ==================== CREATE UTILITY TOGGLES (DIINTEGRASIKAN) ====================
    local function createIntegratedUtilityToggle(toggleName, configKey, callback)
        local utilityToggle = Instance.new("TextButton")
        utilityToggle.Name = "UtilityToggle_" .. toggleName
        utilityToggle.Size = UDim2.new(1, -10, 0, 32)
        utilityToggle.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        utilityToggle.BorderSizePixel = 0
        utilityToggle.Text = toggleName
        utilityToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        utilityToggle.TextSize = 12
        utilityToggle.Font = Enum.Font.Arcade
        utilityToggle.Parent = UtilityScrollFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = utilityToggle
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(255, 50, 50)
        btnStroke.Thickness = 1
        btnStroke.Parent = utilityToggle
        
        -- Load initial state from config
        local isToggled = self.Config[configKey] or false
        if isToggled then
            utilityToggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        end

        -- Call callback on initial load
        if callback then callback(isToggled) end
        
        utilityToggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            
            if isToggled then
                utilityToggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            else
                utilityToggle.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            end
            
            -- Save state to config
            ConfigSystem:UpdateSetting(self.Config, configKey, isToggled)
            
            -- Execute callback
            if callback then callback(isToggled) end
        end)
    end

    -- Create the utility toggle here
    createIntegratedUtilityToggle("Hide Skin", "Nightmare_Utility_HideSkin", function(state)
        if state then
            enableAntiLag()
        else
            disableAntiLag()
        end
    end)
    
    -- Create the Unlock Nearest toggle
    createIntegratedUtilityToggle("Unlock Nearest", "Nightmare_Utility_UnlockNearest", function(state)
        if state then
            createUnlockNearestUI()
        else
            destroyUnlockNearestUI()
        end
    end)

    -- Create Notification Gui at the end
    createNotificationGui()

    print("✅ Nightmare Created Successfully!")
end

-- Fungsi utama untuk menunjukkan notifikasi
function Nightmare:Notify(text, soundId)
    if not NotificationGui then
        createNotificationGui()
    end

    local soundToPlay = soundId or DEFAULT_NOTIFICATION_SOUND_ID
    
    if soundToPlay then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. soundToPlay
        sound.Volume = 0.4
        sound.Parent = SoundService
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 0)
    notifFrame.Position = UDim2.new(0.5, 0, 0, -100)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notifFrame.BackgroundTransparency = 0.1
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = NotificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notifFrame
    
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(255, 50, 50)
    outline.Thickness = 1.0
    outline.Parent = notifFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    textLabel.Font = Enum.Font.Arcade
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = notifFrame
    
    local targetHeight = 60
    local targetYPosition = 20
    
    local tweenInfoIn = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local goalIn = { Size = UDim2.new(0, 300, 0, targetHeight), Position = UDim2.new(0.5, 0, 0, targetYPosition) }
    local tweenIn = TweenService:Create(notifFrame, tweenInfoIn, goalIn)
    tweenIn:Play()
    
    task.spawn(function()
        task.wait(3)
        
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local goalOut = { Size = UDim2.new(0, 300, 0, 0), Position = UDim2.new(0.5, 0, 0, -100) }
        local tweenOut = TweenService:Create(notifFrame, tweenInfoOut, goalOut)
        tweenOut:Play()
        
        tweenOut.Completed:Connect(function()
            notifFrame:Destroy()
        end)
    end)
end

-- ==================== TOGGLE CREATION FUNCTION ====================
function Nightmare:AddToggleRow(text1, callback1, text2, callback2)
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, 0, 0, 35)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = ScrollFrame

    local function createSingleToggle(text, callback, position)
        local configKey = "Nightmare_" .. text
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

        local isToggled = self.Config[configKey] or false
        if isToggled then
            toggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        end

        if callback then callback(isToggled) end

        toggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            if isToggled then
                toggle.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            else
                toggle.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            end

            ConfigSystem:UpdateSetting(self.Config, configKey, isToggled)

            if callback then callback(isToggled) end
        end)
    end

    createSingleToggle(text1, callback1, UDim2.new(0, 5, 0, 0))

    if text2 and callback2 then
        createSingleToggle(text2, callback2, UDim2.new(0, 115, 0, 0))
    end
end

return Nightmare
