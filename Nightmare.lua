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
local RunService = game:GetService("RunService")
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

-- ==================== UNLOCK NEAREST VARIABLES ====================
local UnlockNearestUI = nil

-- ==================== UNLOCK NEAREST FUNCTIONS ====================
-- Function to find the closest plot to the player
local function getClosestPlot()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local closestPlot = nil
    local minDistance = 37
    
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
        warn("No plot nearby!")
        return
    end
    
    local unlockFolder = targetPlot:FindFirstChild("Unlock")
    if not unlockFolder then
        warn("No unlock folder found!")
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
        warn("Floor " .. number .. " not found!")
        return
    end
    
    local targetFloor = unlockItems[number].Object
    
    local prompts = {}
    findPrompts(targetFloor, prompts)
    
    if #prompts == 0 then
        warn("No prompts found on floor " .. number)
        return
    end
    
    for _, prompt in pairs(prompts) do
        fireproximityprompt(prompt)
    end
    
    print("✅ Unlocked Floor " .. number)
end

-- Function to create the Unlock Nearest UI (PREMIUM DESIGN)
local function createUnlockNearestUI()
    if UnlockNearestUI then
        UnlockNearestUI:Destroy()
    end
    
    local safeParent = getSafeCoreGuiParent()
    
    local unlockGui = Instance.new("ScreenGui")
    unlockGui.Name = "UnlockBaseUI"
    unlockGui.ResetOnSpawn = false
    unlockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    unlockGui.Parent = safeParent
    
    -- Main Frame (Horizontal Layout) - COMPACT SIZE
    local unlockMainFrame = Instance.new("Frame")
    unlockMainFrame.Size = UDim2.new(0, 266, 0, 50)
    unlockMainFrame.Position = UDim2.new(0.5, -133, 0.02, 0)
    unlockMainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    unlockMainFrame.BackgroundTransparency = 0.25
    unlockMainFrame.BorderSizePixel = 0
    unlockMainFrame.Active = true
    unlockMainFrame.Draggable = true
    unlockMainFrame.Parent = unlockGui
    
    local unlockCorner = Instance.new("UICorner")
    unlockCorner.CornerRadius = UDim.new(0, 15)
    unlockCorner.Parent = unlockMainFrame
    
    -- Animated Border (Red Gradient) - THICKNESS 1.0
    local unlockStroke = Instance.new("UIStroke")
    unlockStroke.Color = Color3.fromRGB(255, 50, 50)
    unlockStroke.Thickness = 1.0
    unlockStroke.Transparency = 0
    unlockStroke.Parent = unlockMainFrame
    
    -- Border Animation (Bright Red to Dark Red)
    task.spawn(function()
        while unlockMainFrame.Parent do
            for i = 0, 1, 0.02 do
                if not unlockMainFrame.Parent then break end
                local brightness = 255 - (155 * i)
                unlockStroke.Color = Color3.fromRGB(
                    math.floor(brightness),
                    0,
                    0
                )
                task.wait(0.05)
            end
            for i = 1, 0, -0.02 do
                if not unlockMainFrame.Parent then break end
                local brightness = 255 - (155 * i)
                unlockStroke.Color = Color3.fromRGB(
                    math.floor(brightness),
                    0,
                    0
                )
                task.wait(0.05)
            end
        end
    end)
    
    -- Lock Icon Button (Left Side) - EMOJI LOCK
    local lockButton = Instance.new("TextButton")
    lockButton.Size = UDim2.new(0, 38, 0, 38)
    lockButton.Position = UDim2.new(0, 6, 0.5, -19)
    lockButton.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
    lockButton.BackgroundTransparency = 0.75
    lockButton.BorderSizePixel = 0
    lockButton.Text = "🔒"
    lockButton.TextSize = 22
    lockButton.TextColor3 = Color3.fromRGB(255, 80, 80)
    lockButton.Font = Enum.Font.GothamBold
    lockButton.Parent = unlockMainFrame
    
    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 12)
    lockCorner.Parent = lockButton
    
    local lockStroke = Instance.new("UIStroke")
    lockStroke.Color = Color3.fromRGB(255, 50, 50)
    lockStroke.Thickness = 1.0
    lockStroke.Parent = lockButton
    
    -- Simple hover effect only (no click animation)
    lockButton.MouseEnter:Connect(function()
        TweenService:Create(lockButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        }):Play()
    end)
    
    lockButton.MouseLeave:Connect(function()
        TweenService:Create(lockButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(20, 5, 5)
        }):Play()
    end)
    
    -- Function to create floor button with new design (RED THEME) - SMALLER
    local function createFloorButton(floorNum, xPos)
        local floorFrame = Instance.new("Frame")
        floorFrame.Size = UDim2.new(0, 60, 0, 38)
        floorFrame.Position = UDim2.new(0, xPos, 0.5, -19)
        floorFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
        floorFrame.BackgroundTransparency = 0.75
        floorFrame.BorderSizePixel = 0
        floorFrame.Parent = unlockMainFrame
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 12)
        frameCorner.Parent = floorFrame
        
        local frameStroke = Instance.new("UIStroke")
        frameStroke.Color = Color3.fromRGB(255, 50, 50)
        frameStroke.Thickness = 1.0
        frameStroke.Parent = floorFrame
        
        local floorButton = Instance.new("TextButton")
        floorButton.Size = UDim2.new(1, 0, 1, 0)
        floorButton.BackgroundTransparency = 1
        floorButton.Text = tostring(floorNum)
        floorButton.TextColor3 = Color3.fromRGB(255, 80, 80)
        floorButton.TextSize = 32
        floorButton.Font = Enum.Font.Arcade
        floorButton.Parent = floorFrame
        
        -- Button Animation
        floorButton.MouseButton1Click:Connect(function()
            -- Flash effect
            frameStroke.Color = Color3.fromRGB(255, 255, 255)
            floorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            TweenService:Create(frameStroke, TweenInfo.new(0.3), {
                Color = Color3.fromRGB(255, 50, 50)
            }):Play()
            
            TweenService:Create(floorButton, TweenInfo.new(0.3), {
                TextColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
            
            smartInteract(floorNum)
        end)
        
        floorButton.MouseEnter:Connect(function()
            TweenService:Create(floorFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 10, 10)
            }):Play()
            
            TweenService:Create(frameStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 100, 100),
                Thickness = 1.5
            }):Play()
            
            TweenService:Create(floorButton, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(255, 150, 150),
                TextSize = 36
            }):Play()
        end)
        
        floorButton.MouseLeave:Connect(function()
            TweenService:Create(floorFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(20, 5, 5)
            }):Play()
            
            TweenService:Create(frameStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 50, 50),
                Thickness = 1.0
            }):Play()
            
            TweenService:Create(floorButton, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(255, 80, 80),
                TextSize = 32
            }):Play()
        end)
    end
    
    -- Create floor buttons (Horizontal Layout) - CLOSER TO LOCK
    createFloorButton(1, 48)   -- Button 1
    createFloorButton(2, 116)  -- Button 2
    createFloorButton(3, 184)  -- Button 3
    
    -- Bottom Info Bar (NEW) - FPS & PING DISPLAY
    local infoBar = Instance.new("Frame")
    infoBar.Size = UDim2.new(0, 180, 0, 28)
    infoBar.Position = UDim2.new(0.5, -90, 0, 58)
    infoBar.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    infoBar.BackgroundTransparency = 0.15
    infoBar.BorderSizePixel = 0
    infoBar.Parent = unlockMainFrame  -- Parent to main frame so it drags together!
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoBar
    
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Color = Color3.fromRGB(100, 0, 0)
    infoStroke.Thickness = 1.0
    infoStroke.Parent = infoBar
    
    -- Avatar Image (Left Side)
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 22, 0, 22)
    avatarImage.Position = UDim2.new(0, 3, 0.5, -11)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    avatarImage.Parent = infoBar
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatarImage
    
    -- FPS Label
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 70, 1, 0)
    fpsLabel.Position = UDim2.new(0, 30, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    fpsLabel.TextSize = 11
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = infoBar
    
    -- Ping Label
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0, 80, 1, 0)
    pingLabel.Position = UDim2.new(0, 100, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0ms"
    pingLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    pingLabel.TextSize = 11
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = infoBar
    
    -- FPS & Ping Update Loop
    local frameCount = 0
    local lastFPSUpdate = tick()
    local currentFPS = 60
    
    -- FPS Counter (accurate method)
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        
        if now - lastFPSUpdate >= 1 then
            currentFPS = frameCount
            frameCount = 0
            lastFPSUpdate = now
            
            fpsLabel.Text = "FPS: " .. tostring(currentFPS)
            
            -- Color based on performance
            if currentFPS >= 55 then
                fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif currentFPS >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end)
    
    -- Ping Update Loop
    task.spawn(function()
        while infoBar.Parent do
            -- Get Ping
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            pingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
            
            if ping <= 100 then
                pingLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif ping <= 200 then
                pingLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                pingLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
            
            task.wait(1)
        end
    end)
    
    UnlockNearestUI = unlockGui
end

-- Function to destroy the Unlock Nearest UI
local function destroyUnlockNearestUI()
    if UnlockNearestUI then
        UnlockNearestUI:Destroy()
        UnlockNearestUI = nil
    end
end

-- ==================== TOGGLE CREATION FUNCTIONS ====================
-- Function to create a toggle button with the new design
local function createToggleButton(parent, name, text, position, size)
    -- Mencipta TextButton utama
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 160, 0, 32) -- Saiz default disesuaikan
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.Font = Enum.Font.Arcade -- DITUKAR BALIK KE ARCADE
    button.AutoButtonColor = false -- Mematikan kesan butang default
    button.Parent = parent
    
    -- Mencipta bucu bulat (Rounded Corners)
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    -- Mencipta garis luar (Outline)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana)
    btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Parent = button
    
    return button
end

-- Function to set the toggle state with the new design
local function setToggleState(button, enabled)
    local btnStroke = button:FindFirstChildOfClass("UIStroke")
    
    if enabled then
        -- on
        button.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Warna latar belakang ON (Merah Cerah)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(255, 60, 60) -- Warna garis luar ON (Merah Terang)
            btnStroke.Thickness = 1.0 -- Ketebalan garis luar ON (Lebih Tebal)
        end
    else
        -- off
        button.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana)
            btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF (Nipis)
        end
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
    UtilityFrame.Size = UDim2.new(0, 180, 0, 250) -- DIPERKECIL
    UtilityFrame.Position = UDim2.new(0.5, -90, 0.5, -125) -- DISESUAIKAN
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
        -- Create toggle using the new design
        local utilityToggle = createToggleButton(
            UtilityScrollFrame, 
            "UtilityToggle_" .. toggleName, 
            toggleName, 
            UDim2.new(0, 10, 0, 0), 
            UDim2.new(0, 160, 0, 32)
        )
        
        -- Load initial state from config
        local isToggled = self.Config[configKey] or false
        setToggleState(utilityToggle, isToggled)

        -- Call callback on initial load
        if callback then callback(isToggled) end
        
        utilityToggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            setToggleState(utilityToggle, isToggled)
            
            -- Save state to config
            ConfigSystem:UpdateSetting(self.Config, configKey, isToggled)
            
            -- Execute callback
            if callback then callback(isToggled) end
        end)
    end

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
        
        -- Create toggle using the new design
        local toggle = createToggleButton(
            rowFrame, 
            "Toggle_" .. text, 
            text, 
            position, 
            UDim2.new(0, 100, 0, 32)
        )

        local isToggled = self.Config[configKey] or false
        setToggleState(toggle, isToggled)

        if callback then callback(isToggled) end

        toggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            setToggleState(toggle, isToggled)

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
