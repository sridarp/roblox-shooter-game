-- Game GUI Manager (LocalScript)
wait(2) -- Wait for game to load

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("GameGUI LocalScript starting...")

-- Wait for ReplicatedStorage and RemoteEvents
local function waitForServices()
    local attempts = 0
    local maxAttempts = 50

    while attempts < maxAttempts do
        if ReplicatedStorage then
            print("ReplicatedStorage found!")
            break
        end
        attempts = attempts + 1
        wait(0.1)
        ReplicatedStorage = game:GetService("ReplicatedStorage")
    end

    if not ReplicatedStorage then
        warn("Failed to find ReplicatedStorage after " .. maxAttempts .. " attempts")
        return false
    end

    return true
end

-- Initialize GUI
local function createGameGUI()
    if not waitForServices() then
        return
    end

    print("Creating Game GUI...")

    -- Create main GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShooterGameGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Create HUD Frame
    local hudFrame = Instance.new("Frame")
    hudFrame.Name = "HUD"
    hudFrame.Size = UDim2.new(1, 0, 1, 0)
    hudFrame.BackgroundTransparency = 1
    hudFrame.Parent = screenGui

    -- Health Bar Background
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(0, 200, 0, 25)
    healthFrame.Position = UDim2.new(0, 20, 1, -50)
    healthFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    healthFrame.BorderSizePixel = 2
    healthFrame.BorderColor3 = Color3.new(1, 1, 1)
    healthFrame.Parent = hudFrame

    -- Health Bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 0.8, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthFrame

    -- Health Text
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "100/100"
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Parent = healthFrame

    -- Ammo Counter
    local ammoFrame = Instance.new("Frame")
    ammoFrame.Name = "AmmoFrame"
    ammoFrame.Size = UDim2.new(0, 120, 0, 40)
    ammoFrame.Position = UDim2.new(1, -140, 1, -60)
    ammoFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    ammoFrame.BorderSizePixel = 2
    ammoFrame.BorderColor3 = Color3.new(1, 1, 1)
    ammoFrame.Parent = hudFrame

    local ammoLabel = Instance.new("TextLabel")
    ammoLabel.Name = "AmmoLabel"
    ammoLabel.Size = UDim2.new(1, 0, 1, 0)
    ammoLabel.BackgroundTransparency = 1
    ammoLabel.Text = "30/30"
    ammoLabel.TextColor3 = Color3.new(1, 1, 1)
    ammoLabel.TextScaled = true
    ammoLabel.Font = Enum.Font.SourceSansBold
    ammoLabel.TextStrokeTransparency = 0
    ammoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    ammoLabel.Parent = ammoFrame

    -- Crosshair
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 20, 0, 20)
    crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshair.BackgroundTransparency = 1
    crosshair.Parent = hudFrame

    -- Crosshair lines
    local function createCrosshairLine(size, position)
        local line = Instance.new("Frame")
        line.Size = size
        line.Position = position
        line.BackgroundColor3 = Color3.new(1, 1, 1)
        line.BorderSizePixel = 1
        line.BorderColor3 = Color3.new(0, 0, 0)
        line.Parent = crosshair
        return line
    end

    -- Create crosshair parts
    createCrosshairLine(UDim2.new(0, 2, 0, 8), UDim2.new(0.5, -1, 0, 0))      -- Top
    createCrosshairLine(UDim2.new(0, 2, 0, 8), UDim2.new(0.5, -1, 1, -8))     -- Bottom
    createCrosshairLine(UDim2.new(0, 8, 0, 2), UDim2.new(0, 0, 0.5, -1))      -- Left
    createCrosshairLine(UDim2.new(0, 8, 0, 2), UDim2.new(1, -8, 0.5, -1))     -- Right

    -- Game Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 400, 0, 50)
    statusLabel.Position = UDim2.new(0.5, -200, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "GAME READY"
    statusLabel.TextColor3 = Color3.new(1, 1, 0)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextStrokeTransparency = 0
    statusLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    statusLabel.Parent = hudFrame

    -- Scoreboard
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 200, 0, 120)
    scoreFrame.Position = UDim2.new(1, -220, 0, 20)
    scoreFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    scoreFrame.BackgroundTransparency = 0.3
    scoreFrame.BorderSizePixel = 2
    scoreFrame.BorderColor3 = Color3.new(1, 1, 1)
    scoreFrame.Parent = hudFrame

    local scoreTitle = Instance.new("TextLabel")
    scoreTitle.Size = UDim2.new(1, 0, 0, 30)
    scoreTitle.BackgroundTransparency = 1
    scoreTitle.Text = "SCOREBOARD"
    scoreTitle.TextColor3 = Color3.new(1, 1, 1)
    scoreTitle.TextScaled = true
    scoreTitle.Font = Enum.Font.SourceSansBold
    scoreTitle.Parent = scoreFrame

    local scoreList = Instance.new("ScrollingFrame")
    scoreList.Size = UDim2.new(1, 0, 1, -30)
    scoreList.Position = UDim2.new(0, 0, 0, 30)
    scoreList.BackgroundTransparency = 1
    scoreList.ScrollBarThickness = 5
    scoreList.Parent = scoreFrame

    -- Update health function
    local function updateHealth()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local healthPercent = humanoid.Health / humanoid.MaxHealth

            -- Update health bar
            healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
            healthLabel.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)

            -- Change color based on health
            if healthPercent > 0.6 then
                healthBar.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Green
            elseif healthPercent > 0.3 then
                healthBar.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow
            else
                healthBar.BackgroundColor3 = Color3.new(1, 0, 0) -- Red
            end
        end
    end

    -- Connect health updates
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.HealthChanged:Connect(updateHealth)
        updateHealth()
    end

    -- Connect to character spawning
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)

    print("Game GUI created successfully!")
end

createGameGUI()