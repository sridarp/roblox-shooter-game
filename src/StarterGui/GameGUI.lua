-- Game GUI Manager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShooterGameGUI"
screenGui.Parent = playerGui

-- Create HUD Frame
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.new(1, 0, 1, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = screenGui

-- Health Bar
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0, 200, 0, 20)
healthFrame.Position = UDim2.new(0, 20, 1, -40)
healthFrame.BackgroundColor3 = Color3.new(0, 0, 0)
healthFrame.BorderSizePixel = 2
healthFrame.Parent = hudFrame

local healthBar = Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
healthBar.BorderSizePixel = 0
healthBar.Parent = healthFrame

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, 0, 1, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "100/100"
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.SourceSansBold
healthLabel.Parent = healthFrame

-- Ammo Counter
local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.Size = UDim2.new(0, 100, 0, 30)
ammoLabel.Position = UDim2.new(1, -120, 1, -50)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = "30/30"
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.SourceSansBold
ammoLabel.Parent = hudFrame

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
    line.BorderSizePixel = 0
    line.Parent = crosshair
    return line
end

createCrosshairLine(UDim2.new(0, 2, 0, 8), UDim2.new(0.5, -1, 0, 0))
createCrosshairLine(UDim2.new(0, 2, 0, 8), UDim2.new(0.5, -1, 1, -8))
createCrosshairLine(UDim2.new(0, 8, 0, 2), UDim2.new(0, 0, 0.5, -1))
createCrosshairLine(UDim2.new(0, 8, 0, 2), UDim2.new(1, -8, 0.5, -1))

-- Scoreboard
local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 200, 0, 100)
scoreFrame.Position = UDim2.new(1, -220, 0, 20)
scoreFrame.BackgroundColor3 = Color3.new(0, 0, 0)
scoreFrame.BackgroundTransparency = 0.3
scoreFrame.BorderSizePixel = 1
scoreFrame.Parent = hudFrame

local scoreTitle = Instance.new("TextLabel")
scoreTitle.Size = UDim2.new(1, 0, 0, 25)
scoreTitle.BackgroundTransparency = 1
scoreTitle.Text = "SCOREBOARD"
scoreTitle.TextColor3 = Color3.new(1, 1, 1)
scoreTitle.TextScaled = true
scoreTitle.Font = Enum.Font.SourceSansBold
scoreTitle.Parent = scoreFrame

-- Update health display
local function updateHealthDisplay()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        local healthPercent = humanoid.Health / humanoid.MaxHealth

        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        healthLabel.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)

        -- Change color based on health
        if healthPercent > 0.6 then
            healthBar.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
        elseif healthPercent > 0.3 then
            healthBar.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            healthBar.BackgroundColor3 = Color3.new(1, 0, 0) -- Red
        end
    end
end

-- Connect health updates
player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(updateHealthDisplay)
    updateHealthDisplay()
end)

if player.Character then
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(updateHealthDisplay)
        updateHealthDisplay()
    end
end