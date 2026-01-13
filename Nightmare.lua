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

-- ==================== ANTI RAGDOLL VARIABLES ====================
local isAntiRagdollEnabled = false
local antiRagdollConnections = {}
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false

-- ==================== NEAREST UI VARIABLES ====================
local nearestUI = nil
local nearestStealConnection = nil

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

-- ==================== ANTI RAGDOLL FUNCTIONS ====================
local function stopRagdoll()
    if not ragdollActive then return end
    
    ragdollActive = false
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    
    -- Paksa watak untuk mula bangun
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    -- Kembalikan kawalan fizik kepada humanoid
    hum.PlatformStand = false
    
    -- Pastikan root part tidak terlekat di bawah tanah
    root.CanCollide = true
    if root.Anchored then root.Anchored = false end
    
    -- Musnahkan sebarang constraint yang mungkin ditambah oleh sistem ragdoll
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then
            for _, c in part:GetChildren() do
                if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then
                    c:Destroy()
                end
            end
            -- Pastikan sendi motor (Motor6D) untuk anggota badan diaktifkan semula
            local motor = part:FindFirstChildWhichIsA("Motor6D")
            if motor then
                motor.Enabled = true
            end
        end
    end
    
    -- Reset halaju untuk mengelakkan terlempar selepas bangun
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
    
    -- Pastikan kamera mengikuti humanoid semula
    workspace.CurrentCamera.CameraSubject = hum
end

local function startRagdollTimer()
    -- Hentikan timer sebelumnya jika ada
    if ragdollTimer then ragdollTimer:Disconnect() end
    
    ragdollActive = true
    -- Cipta timer yang sangat singkat untuk memanggil stopRagdoll pada frame seterusnya
    ragdollTimer = RunService.Heartbeat:Connect(function()
        ragdollTimer:Disconnect()
        ragdollTimer = nil
        stopRagdoll()
    end)
end

local function watchHumanoidStates(char)
    local hum = char:WaitForChild("Humanoid")
    
    -- Putuskan sambungan lama jika ada
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() end
    
    humanoidWatchConnection = hum.StateChanged:Connect(function(_, newState)
        -- Jika anti-ragdoll tidak dihidupkan, abaikan
        if not isAntiRagdollEnabled then return end
        
        -- Periksa jika watak memasuki keadaan ragdoll
        if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Physics then
            -- Jika belum aktif, mulakan proses pencegahan
            if not ragdollActive then
                hum.PlatformStand = true -- Hentikan kawalan humanoid sementara
                startRagdollTimer() -- Mulakan timer untuk bangun
            end
        -- Periksa jika watak sudah bangun atau berjalan
        elseif newState == Enum.HumanoidStateType.GettingUp or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
            hum.PlatformStand = false -- Kembalikan kawalan
            if ragdollActive then
                stopRagdoll() -- Pastikan semua sisa-sisa ragdoll dibersihkan
            end
        end
    end)
end

local function setupAntiRagdollCharacter(char)
    -- Reset keadaan
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    
    -- Mula memantau state humanoid watak baru
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    watchHumanoidStates(char)
end

local function startAntiRagdoll()
    isAntiRagdollEnabled = true
    
    -- Bersihkan sambungan lama
    for _, conn in pairs(antiRagdollConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(antiRagdollConnections)
    
    if humanoidWatchConnection then
        humanoidWatchConnection:Disconnect()
        humanoidWatchConnection = nil
    end
    
    -- Pasang pada watak semasa
    if LocalPlayer.Character then
        setupAntiRagdollCharacter(LocalPlayer.Character)
    end
    
    -- Pasang pada watak akan datang (respawn)
    table.insert(antiRagdollConnections, LocalPlayer.CharacterAdded:Connect(setupAntiRagdollCharacter))
end

local function stopAntiRagdoll()
    isAntiRagdollEnabled = false
    ragdollActive = false
    
    -- Hentikan semua proses aktif
    if ragdollTimer then
        ragdollTimer:Disconnect()
        ragdollTimer = nil
    end
    
    -- Putuskan semua sambungan
    for _, conn in pairs(antiRagdollConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(antiRagdollConnections)
    
    if humanoidWatchConnection then
        humanoidWatchConnection:Disconnect()
        humanoidWatchConnection = nil
    end
end

local function toggleAntiRagdoll(state)
    if state then
        startAntiRagdoll()
    else
        stopAntiRagdoll()
    end
end

-- Sambungan event untuk memuat semula fungsi jika watak respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    if isAntiRagdollEnabled then
        task.wait(0.5) -- Tunggu sebentar untuk watak dimuatkan sepenuhnya
        setupAntiRagdollCharacter(newCharacter)
    end
end)

-- ==================== NEAREST UI FUNCTIONS ====================
local function createNearestUI()
    if nearestUI then
        nearestUI:Destroy()
    end
    
    local safeParent = getSafeCoreGuiParent()
    
    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Variables
    local allAnimalsCache = {}
    local PromptMemoryCache = {}
    local InternalStealCache = {}
    local AUTO_STEAL_PROX_RADIUS = 35
    
    -- MODE: "nearest" or "bestgen"
    local stealMode = "bestgen"
    
    -- Get Packages
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")
    
    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local RaritiesData = require(Datas:WaitForChild("Rarities"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealBar"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = safeParent
    
    -- Main Frame (280x90 - taller untuk button)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 90)
    mainFrame.Position = UDim2.new(0.5, -140, 0.15, 0)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 18)
    mainCorner.Parent = mainFrame
    
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.fromRGB(220, 50, 50)
    outerStroke.Thickness = 1.0
    outerStroke.Transparency = 0
    outerStroke.Parent = mainFrame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 18)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "WAITING FOR STEAL"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.Arcade
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = mainFrame
    
    -- Stud label
    local studLabel = Instance.new("TextLabel")
    studLabel.Size = UDim2.new(0.35, 0, 0, 16)
    studLabel.Position = UDim2.new(0.65, 0, 0, 7)
    studLabel.BackgroundTransparency = 1
    studLabel.Text = "0.0 studs"
    studLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    studLabel.TextSize = 10
    studLabel.Font = Enum.Font.Arcade
    studLabel.TextXAlignment = Enum.TextXAlignment.Right
    studLabel.TextTruncate = Enum.TextTruncate.AtEnd
    studLabel.Parent = mainFrame
    
    -- Money label
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -20, 0, 15)
    moneyLabel.Position = UDim2.new(0, 10, 0, 24)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "$0.0M/s"
    moneyLabel.TextColor3 = Color3.fromRGB(70, 220, 90)
    moneyLabel.TextSize = 11
    moneyLabel.Font = Enum.Font.Arcade
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
    moneyLabel.Parent = mainFrame
    
    -- Mode Toggle Button (NEW)
    local modeButton = Instance.new("TextButton")
    modeButton.Size = UDim2.new(1, -20, 0, 20)
    modeButton.Position = UDim2.new(0, 10, 0, 42)
    modeButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    modeButton.BorderSizePixel = 0
    modeButton.Text = "MODE: BEST GEN"
    modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeButton.TextSize = 10
    modeButton.Font = Enum.Font.Arcade
    modeButton.Parent = mainFrame
    
    local modeCorner = Instance.new("UICorner")
    modeCorner.CornerRadius = UDim.new(0, 8)
    modeCorner.Parent = modeButton
    
    local modeStroke = Instance.new("UIStroke")
    modeStroke.Color = Color3.fromRGB(220, 50, 50)
    modeStroke.Thickness = 1.0
    modeStroke.Transparency = 0.3
    modeStroke.Parent = modeButton
    
    -- Progress bar container
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, -20, 0, 12)
    barContainer.Position = UDim2.new(0, 10, 1, -18)
    barContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = mainFrame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 6)
    barCorner.Parent = barContainer
    
    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(40, 40, 40)
    barStroke.Thickness = 1.0
    barStroke.Parent = barContainer
    
    -- Fill bar
    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    fillBar.BorderSizePixel = 0
    fillBar.Parent = barContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fillBar
    
    -- Percent label
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Size = UDim2.new(1, 0, 1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = ""
    percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    percentLabel.TextSize = 8
    percentLabel.Font = Enum.Font.Arcade
    percentLabel.ZIndex = 2
    percentLabel.Parent = barContainer
    
    local isAnimating = false
    
    local function animateFill()
        if isAnimating then return end 
        isAnimating = true
        
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
        
        tween:Play()
        
        task.spawn(function()
            for i = 0, 100 do
                percentLabel.Text = i .. "%"
                task.wait(0.7 / 100)
            end
        end)
        
        tween.Completed:Wait()
        task.wait(0.14)
        
        fillBar.Size = UDim2.new(0, 0, 1, 0)
        percentLabel.Text = ""
        isAnimating = false
    end
    
    -- Mode Toggle Button Click
    modeButton.MouseButton1Click:Connect(function()
        if stealMode == "bestgen" then
            stealMode = "nearest"
            modeButton.Text = "MODE: NEAREST"
            modeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            modeStroke.Color = Color3.fromRGB(80, 80, 90)
        else
            stealMode = "bestgen"
            modeButton.Text = "MODE: BEST GEN"
            modeButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
            modeStroke.Color = Color3.fromRGB(220, 50, 50)
        end
    end)
    
    do
        local oldInfo
        oldInfo = hookfunction(debug.info, function(...)
            local src = oldInfo(1, "s")
            
            if src and src:find("Packages.Synchronizer") then
                return nil
            end
            
            return oldInfo(...)
        end)
    end
    
    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot then return false end
        
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end
        
        local plot = plots:FindFirstChild(animalData.plot)
        if not plot then return false end
        
        local channel = Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then
                    return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "table" and owner.UserId then
                    return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "Instance" then
                    return owner == LocalPlayer
                end
            end
        end
        
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase:IsA("BillboardGui") then
                return yourBase.Enabled == true
            end
        end
        
        return false
    end
    
    local function findProximityPromptForAnimal(animalData)
        if not animalData then return nil end
        
        local cachedPrompt = PromptMemoryCache[animalData.uid]
        if cachedPrompt and cachedPrompt.Parent then
            return cachedPrompt
        end
        
        local plot = workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return nil end
        
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then return nil end
        
        local podium = podiums:FindFirstChild(animalData.slot)
        if not podium then return nil end
        
        local base = podium:FindFirstChild("Base")
        if not base then return nil end
        
        local spawn = base:FindFirstChild("Spawn")
        if not spawn then return nil end
        
        local attach = spawn:FindFirstChild("PromptAttachment")
        if not attach then return nil end
        
        for _, p in ipairs(attach:GetChildren()) do
            if p:IsA("ProximityPrompt") then
                PromptMemoryCache[animalData.uid] = p
                return p
            end
        end
        
        return nil
    end
    
    local function getAnimalPosition(animalData)
        if not animalData or not animalData.plot or not animalData.slot then return nil end
        
        local plot = workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return nil end
        
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then return nil end
        
        local podium = podiums:FindFirstChild(animalData.slot)
        if not podium then return nil end
        
        return podium:GetPivot().Position
    end
    
    -- Get Best Gen Animal
    local function getBestStealableAnimal()
        for _, animal in ipairs(allAnimalsCache) do
            if not isMyBaseAnimal(animal) then
                return animal
            end
        end
        return nil
    end
    
    -- Get Nearest Animal (NEW)
    local function getNearestAnimal()
        local character = LocalPlayer.Character
        if not character then return nil end
        
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
        if not hrp then return nil end
        
        local nearest = nil
        local minDist = math.huge
        
        for _, animalData in ipairs(allAnimalsCache) do
            if isMyBaseAnimal(animalData) then
                continue
            end
            
            local pos = getAnimalPosition(animalData)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                
                if dist < minDist then
                    minDist = dist
                    nearest = animalData
                end
            end
        end
        
        return nearest
    end
    
    -- Get Target Based on Mode (NEW)
    local function getTargetAnimal()
        if stealMode == "nearest" then
            return getNearestAnimal()
        else
            return getBestStealableAnimal()
        end
    end
    
    local function buildStealCallbacks(prompt)
        if InternalStealCache[prompt] then return end
        
        local data = {
            holdCallbacks = {},
            triggerCallbacks = {},
            ready = true,
        }
        
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table" then
            for _, conn in ipairs(conns1) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table" then
            for _, conn in ipairs(conns2) do
                if type(conn.Function) == "function" then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        
        if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then
            InternalStealCache[prompt] = data
        end
    end
    
    local function executeInternalStealAsync(prompt)
        local data = InternalStealCache[prompt]
        if not data or not data.ready then return false end
        
        data.ready = false
        
        task.spawn(function()
            if #data.holdCallbacks > 0 then
                for _, fn in ipairs(data.holdCallbacks) do
                    task.spawn(fn)
                end
            end
            
            task.wait(1.3)
            
            if #data.triggerCallbacks > 0 then
                for _, fn in ipairs(data.triggerCallbacks) do
                    task.spawn(fn)
                end
            end
            
            task.wait(0.1)
            data.ready = true
        end)
        
        return true
    end
    
    local function attemptSteal(prompt)
        if not prompt or not prompt.Parent then
            return false
        end
        
        buildStealCallbacks(prompt)
        if not InternalStealCache[prompt] then
            return false
        end
        
        return executeInternalStealAsync(prompt)
    end
    
    local function scanAllPlots()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return {} end
        
        local newCache = {}
        
        for _, plot in ipairs(plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if not channel then continue end
            
            local animalList = channel:Get("AnimalList")
            if not animalList then continue end
            
            local owner = channel:Get("Owner")
            if not owner then continue end
            
            local ownerName = "Unknown"
            if typeof(owner) == "Instance" and owner:IsA("Player") then
                ownerName = owner.Name
            elseif typeof(owner) == "table" and owner.Name then
                ownerName = owner.Name
            end
            
            for slot, animalData in pairs(animalList) do
                if type(animalData) == "table" then
                    local animalName = animalData.Index
                    local animalInfo = AnimalsData[animalName]
                    if not animalInfo then continue end
                    
                    local genValue = AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
                    
                    table.insert(newCache, {
                        name = animalInfo.DisplayName or animalName,
                        genValue = genValue,
                        plot = plot.Name,
                        slot = tostring(slot),
                        uid = plot.Name .. "_" .. tostring(slot),
                    })
                end
            end
        end
        
        allAnimalsCache = newCache
        
        table.sort(allAnimalsCache, function(a, b)
            return a.genValue > b.genValue
        end)
        
        return #allAnimalsCache
    end
    
    local function startAutoSteal()
        if nearestStealConnection then return end
        
        nearestStealConnection = RunService.Heartbeat:Connect(function()
            local targetAnimal = getTargetAnimal()
            
            if not targetAnimal then
                titleLabel.Text = "WAITING FOR STEAL"
                studLabel.Text = "0.0 studs"
                moneyLabel.Text = "$0.0M/s"
                return
            end
            
            local character = LocalPlayer.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
            if not hrp then return end
            
            local animalPos = getAnimalPosition(targetAnimal)
            if not animalPos then return end
            
            local dist = (hrp.Position - animalPos).Magnitude
            
            titleLabel.Text = string.upper(targetAnimal.name)
            studLabel.Text = string.format("%.1f studs", dist)
            moneyLabel.Text = string.format("$%.1fM/s", targetAnimal.genValue / 1000000)
            
            if dist <= AUTO_STEAL_PROX_RADIUS then
                task.spawn(animateFill)
                
                local prompt = PromptMemoryCache[targetAnimal.uid]
                if not prompt or not prompt.Parent then
                    prompt = findProximityPromptForAnimal(targetAnimal)
                end
                
                if prompt then
                    attemptSteal(prompt)
                end
            end
        end)
    end
    
    local function stopAutoSteal()
        if not nearestStealConnection then return end
        nearestStealConnection:Disconnect()
        nearestStealConnection = nil
    end
    
    task.spawn(function()
        while task.wait(5) do
            scanAllPlots()
        end
    end)
    
    startAutoSteal()
    
    nearestUI = screenGui
end

local function destroyNearestUI()
    if nearestUI then
        nearestUI:Destroy()
        nearestUI = nil
    end
    if nearestStealConnection then
        nearestStealConnection:Disconnect()
        nearestStealConnection = nil
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
    
    -- Create the Anti Knockback toggle
    createIntegratedUtilityToggle("Anti Knockback", "Nightmare_Utility_AntiKnockback", function(state)
        toggleAntiRagdoll(state)
    end)
    
    -- Create the Nearest toggle
    createIntegratedUtilityToggle("Nearest", "Nightmare_Utility_Nearest", function(state)
        if state then
            createNearestUI()
        else
            destroyNearestUI()
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
