-- Weapon Handler (LocalScript) - Fixed Reload & Ammo System
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
    warn("RemoteEvents not found!")
    return
end

local shootEvent = remoteEvents:WaitForChild("ShootEvent", 5)
local reloadEvent = remoteEvents:WaitForChild("ReloadEvent", 5)
local damageEvent = remoteEvents:WaitForChild("DamageEvent", 5)
local healthUpdateEvent = remoteEvents:WaitForChild("HealthUpdateEvent", 5)
local scoreboardUpdateEvent = remoteEvents:WaitForChild("ScoreboardUpdateEvent", 5)
local ammoUpdateEvent = remoteEvents:WaitForChild("AmmoUpdateEvent", 5)

-- Weapon stats
local weaponStats = {
    AssaultRifle = {
        damage = 25,
        fireRate = 0.1,
        range = 500,
        maxAmmo = 30,
        reloadTime = 2.5
    },
    Pistol = {
        damage = 35,
        fireRate = 0.3,
        range = 300,
        maxAmmo = 12,
        reloadTime = 1.5
    },
    SniperRifle = {
        damage = 80,
        fireRate = 1.0,
        range = 1000,
        maxAmmo = 5,
        reloadTime = 3.0
    },
    SMG = {
        damage = 20,
        fireRate = 0.05,
        range = 250,
        maxAmmo = 40,
        reloadTime = 2.0
    }
}

-- Current weapon state
local currentWeapon = nil
local currentAmmo = 0
local maxAmmo = 0
local canShoot = true
local isReloading = false
local lastShotTime = 0

-- Update ammo display
local function updateAmmoDisplay()
    local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
    if gui and gui:FindFirstChild("HUD") then
        local ammoContainer = gui.HUD:FindFirstChild("AmmoContainer")
        if ammoContainer then
            local ammoLabel = ammoContainer:FindFirstChild("AmmoLabel")
            if ammoLabel then
                if isReloading then
                    ammoLabel.Text = "RELOADING..."
                    ammoLabel.TextColor3 = Color3.new(1, 1, 0)
                else
                    ammoLabel.Text = "AMMO\n" .. currentAmmo .. "/" .. maxAmmo
                    ammoLabel.TextColor3 = currentAmmo > 0 and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
                end
            end
        end
    end
end

-- Update scoreboard display
local function updateScoreboardDisplay(scoreData)
    local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
    if not gui then return end

    local scoreboard = gui:FindFirstChild("Scoreboard")
    if not scoreboard then return end

    local content = scoreboard:FindFirstChild("Content")
    if not content then return end

    -- Clear existing entries
    for _, child in pairs(content:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Header" then
            child:Destroy()
        end
    end

    -- Add player entries
    for i, playerData in ipairs(scoreData) do
        local entry = Instance.new("Frame")
        entry.Name = "Player" .. i
        entry.Size = UDim2.new(1, -10, 0, 25)
        entry.Position = UDim2.new(0, 5, 0, 30 + (i-1) * 27)
        entry.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        entry.BackgroundTransparency = 0.3
        entry.BorderSizePixel = 0
        entry.Parent = content

        -- Player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerData.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entry

        -- Kills
        local killsLabel = Instance.new("TextLabel")
        killsLabel.Size = UDim2.new(0.15, 0, 1, 0)
        killsLabel.Position = UDim2.new(0.4, 0, 0, 0)
        killsLabel.BackgroundTransparency = 1
        killsLabel.Text = tostring(playerData.kills)
        killsLabel.TextColor3 = Color3.new(0, 1, 0)
        killsLabel.TextScaled = true
        killsLabel.Font = Enum.Font.SourceSansBold
        killsLabel.Parent = entry

        -- Deaths
        local deathsLabel = Instance.new("TextLabel")
        deathsLabel.Size = UDim2.new(0.15, 0, 1, 0)
        deathsLabel.Position = UDim2.new(0.55, 0, 0, 0)
        deathsLabel.BackgroundTransparency = 1
        deathsLabel.Text = tostring(playerData.deaths)
        deathsLabel.TextColor3 = Color3.new(1, 0, 0)
        deathsLabel.TextScaled = true
        deathsLabel.Font = Enum.Font.SourceSansBold
        deathsLabel.Parent = entry

        -- Score
        local scoreLabel = Instance.new("TextLabel")
        scoreLabel.Size = UDim2.new(0.3, 0, 1, 0)
        scoreLabel.Position = UDim2.new(0.7, 0, 0, 0)
        scoreLabel.BackgroundTransparency = 1
        scoreLabel.Text = tostring(playerData.score)
        scoreLabel.TextColor3 = Color3.new(1, 1, 0)
        scoreLabel.TextScaled = true
        scoreLabel.Font = Enum.Font.SourceSansBold
        scoreLabel.Parent = entry

        -- Highlight current player
        if playerData.name == player.Name then
            entry.BackgroundColor3 = Color3.new(0, 0.5, 1)
            entry.BackgroundTransparency = 0.5
        end
    end

    print("📊 Scoreboard updated with " .. #scoreData .. " players")
end

-- Enhanced muzzle flash
local function createMuzzleFlash(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Find the flash hider for M4A1, or use handle for other weapons
    local flashPoint = handle:FindFirstChild("FlashHider") or handle

    -- Create main muzzle flash
    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Size = Vector3.new(0.6, 0.6, 1.5)
    flash.Material = Enum.Material.Neon
    flash.BrickColor = BrickColor.new("Bright yellow")
    flash.Anchored = true
    flash.CanCollide = false
    flash.Shape = Enum.PartType.Ball
    flash.Parent = workspace

    -- Position flash at the flash hider/barrel end
    if tool.Name == "AssaultRifle" and flashPoint.Name == "FlashHider" then
        flash.CFrame = flashPoint.CFrame * CFrame.new(0, 0, -0.3)
    else
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - 0.8)
    end

    -- Create secondary flash effects
    local flash2 = Instance.new("Part")
    flash2.Name = "MuzzleFlash2"
    flash2.Size = Vector3.new(0.3, 0.3, 0.8)
    flash2.Material = Enum.Material.Neon
    flash2.BrickColor = BrickColor.new("Bright orange")
    flash2.Anchored = true
    flash2.CanCollide = false
    flash2.Shape = Enum.PartType.Ball
    flash2.CFrame = flash.CFrame
    flash2.Parent = workspace

    -- Create bright light
    local light = Instance.new("PointLight")
    light.Brightness = 8
    light.Color = Color3.new(1, 0.8, 0)
    light.Range = 20
    light.Parent = flash

    -- Create smoke effect
    local smoke = Instance.new("Part")
    smoke.Name = "GunSmoke"
    smoke.Size = Vector3.new(0.2, 0.2, 0.2)
    smoke.Material = Enum.Material.Neon
    smoke.BrickColor = BrickColor.new("Light stone grey")
    smoke.Anchored = true
    smoke.CanCollide = false
    smoke.Transparency = 0.5
    smoke.CFrame = flash.CFrame
    smoke.Parent = workspace

    -- Animate all effects
    local flashTween = TweenService:Create(flash, TweenInfo.new(0.1), {
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1
    })

    local flash2Tween = TweenService:Create(flash2, TweenInfo.new(0.08), {
        Size = Vector3.new(0.05, 0.05, 0.05),
        Transparency = 1
    })

    local smokeTween = TweenService:Create(smoke, TweenInfo.new(0.5), {
        Size = Vector3.new(1, 1, 1),
        Transparency = 1,
        CFrame = smoke.CFrame * CFrame.new(math.random(-2, 2), math.random(1, 3), math.random(-2, 2))
    })

    flashTween:Play()
    flash2Tween:Play()
    smokeTween:Play()

    -- Clean up
    flashTween.Completed:Connect(function()
        flash:Destroy()
    end)

    flash2Tween.Completed:Connect(function()
        flash2:Destroy()
    end)

    smokeTween.Completed:Connect(function()
        smoke:Destroy()
    end)
end

-- Enhanced shoot function
local function shoot(tool)
    local currentTime = tick()
    local stats = weaponStats[tool.Name]

    if not stats then return end
    if not canShoot then return end
    if isReloading then return end
    if currentAmmo <= 0 then
        print("❌ No ammo! Press R to reload")
        return
    end

    -- Check fire rate
    if currentTime - lastShotTime < stats.fireRate then
        return
    end

    lastShotTime = currentTime

    -- Fire the weapon
    shootEvent:FireServer(mouse.Hit.Position, tool.Name)

    -- Create muzzle flash
    createMuzzleFlash(tool)

    print("🔫 Fired " .. tool.Name .. " - Ammo remaining: " .. (currentAmmo - 1))
end

-- Reload function
local function reload(tool)
    if not tool then return end
    if isReloading then return end
    if currentAmmo >= maxAmmo then
        print("🔄 Weapon is already fully loaded!")
        return
    end

    local stats = weaponStats[tool.Name]
    if not stats then return end

    print("🔄 Reloading " .. tool.Name .. "...")
    isReloading = true
    canShoot = false

    -- Update ammo display to show reloading
    updateAmmoDisplay()

    -- Send reload request to server
    reloadEvent:FireServer(tool.Name)

    -- Wait for reload time
    spawn(function()
        wait(stats.reloadTime)
        isReloading = false
        canShoot = true
        print("✅ Reload complete!")
    end)
end

-- Handle tool equipped
local function onToolEquipped(tool)
    if not tool then return end

    currentWeapon = tool
    local stats = weaponStats[tool.Name]

    if stats then
        maxAmmo = stats.maxAmmo
        -- Don't reset ammo here - wait for server update
        print("🔫 Equipped " .. tool.Name)
    end

    -- Connect mouse events
    tool.Activated:Connect(function()
        shoot(tool)
    end)

    -- Update display
    updateAmmoDisplay()
end

-- Handle tool unequipped
local function onToolUnequipped(tool)
    currentWeapon = nil
    currentAmmo = 0
    maxAmmo = 0
    canShoot = true
    isReloading = false

    -- Update display
    updateAmmoDisplay()

    print("🔫 Unequipped weapon")
end

-- Connect input events
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R then
        if currentWeapon then
            reload(currentWeapon)
        end
    end
end)

-- Connect character events
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")

    -- Connect tool equipped/unequipped events
    humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolEquipped(child)
        end
    end)

    humanoid.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            onToolUnequipped(child)
        end
    end)

    -- Check for existing tool
    for _, child in pairs(humanoid:GetChildren()) do
        if child:IsA("Tool") then
            onToolEquipped(child)
        end
    end
end

-- Connect player events
if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Connect remote events
ammoUpdateEvent.OnClientEvent:Connect(function(newAmmo, newMaxAmmo)
    currentAmmo = newAmmo
    maxAmmo = newMaxAmmo
    updateAmmoDisplay()
    print("🔫 Ammo updated: " .. currentAmmo .. "/" .. maxAmmo)
end)

scoreboardUpdateEvent.OnClientEvent:Connect(function(scoreData)
    updateScoreboardDisplay(scoreData)
end)

damageEvent.OnClientEvent:Connect(function(victimUserId, damage, newHealth, maxHealth)
    local victim = Players:GetPlayerByUserId(victimUserId)
    if victim then
        print("💥 " .. victim.Name .. " took " .. damage .. " damage (" .. math.floor(newHealth) .. "/" .. maxHealth .. ")")
    end
end)

healthUpdateEvent.OnClientEvent:Connect(function(playerUserId, health, maxHealth)
    local targetPlayer = Players:GetPlayerByUserId(playerUserId)
    if targetPlayer then
        print("❤️ " .. targetPlayer.Name .. " health: " .. math.floor(health) .. "/" .. maxHealth)
    end
end)

print("🔫 WeaponHandler initialized successfully!")
print("🎯 Controls: Left Click = Shoot, R = Reload")
print("📊 Scoreboard and ammo systems ready")
