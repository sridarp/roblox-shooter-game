-- Weapon Handler (LocalScript) - Enhanced Version
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

-- Create enhanced muzzle flash effect
local function createMuzzleFlash(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Create flash part
    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Size = Vector3.new(0.5, 0.5, 1.2)
    flash.Material = Enum.Material.Neon
    flash.BrickColor = BrickColor.new("Bright yellow")
    flash.Anchored = true
    flash.CanCollide = false
    flash.Shape = Enum.PartType.Ball
    flash.Parent = workspace

    -- Position flash at barrel
    flash.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - 0.8)

    -- Create light
    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Color = Color3.new(1, 1, 0)
    light.Range = 15
    light.Parent = flash

    -- Animate flash
    local tween = TweenService:Create(flash, TweenInfo.new(0.1), {
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1
    })
    tween:Play()

    tween.Completed:Connect(function()
        flash:Destroy()
    end)
end

-- Enhanced shoot function with better timing
local function shoot(tool)
    local currentTime = tick()
    local stats = weaponStats[tool.Name]
    local fireRate = stats and stats.fireRate or 0.1

    -- Check if we can shoot (fire rate, ammo, reloading)
    if not canShoot or currentAmmo <= 0 or isReloading or (currentTime - lastShotTime) < fireRate then
        return
    end

    canShoot = false
    lastShotTime = currentTime
    currentAmmo = currentAmmo - 1

    print("🔫 Firing " .. tool.Name .. " - Ammo: " .. currentAmmo .. "/" .. maxAmmo)

    -- Fire weapon to server
    if shootEvent then
        shootEvent:FireServer(mouse.Hit.Position, tool.Name)
    end

    -- Create effects
    createMuzzleFlash(tool)

    -- Update ammo display
    updateAmmoDisplay()

    -- Create crosshair hit feedback
    local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
    if gui and gui:FindFirstChild("HUD") then
        local crosshair = gui.HUD:FindFirstChild("Crosshair")
        if crosshair then
            -- Briefly expand crosshair
            local originalSize = crosshair.Size
            crosshair.Size = UDim2.new(0, 8, 0, 8)
            crosshair.Position = UDim2.new(0.5, -4, 0.5, -4)

            wait(0.05)

            crosshair.Size = originalSize
            crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
        end
    end

    -- Reset shoot cooldown
    wait(fireRate)
    canShoot = true
end

-- Enhanced reload function
local function reload(tool)
    if isReloading or currentAmmo >= maxAmmo then
        return
    end

    isReloading = true
    canShoot = false

    print("🔄 Reloading " .. tool.Name .. "...")

    -- Update GUI to show reloading
    updateAmmoDisplay()

    -- Send reload event to server
    if reloadEvent then
        reloadEvent:FireServer(tool.Name)
    end

    -- Reload time
    local stats = weaponStats[tool.Name]
    local reloadTime = stats and stats.reloadTime or 2.0

    wait(reloadTime)

    -- Restore ammo
    currentAmmo = maxAmmo
    isReloading = false
    canShoot = true

    -- Update display
    updateAmmoDisplay()

    print("✅ Reload complete! Ammo: " .. currentAmmo .. "/" .. maxAmmo)
end

-- Handle tool equipped
local function onToolEquipped(tool)
    currentWeapon = tool

    -- Set ammo based on weapon type
    local stats = weaponStats[tool.Name]
    if stats then
        maxAmmo = stats.maxAmmo
        currentAmmo = maxAmmo
    else
        maxAmmo = 30
        currentAmmo = 30
    end

    canShoot = true
    isReloading = false

    updateAmmoDisplay()

    -- Connect tool events
    tool.Activated:Connect(function()
        shoot(tool)
    end)

    print("⚔️ Equipped " .. tool.Name .. " - Ammo: " .. currentAmmo .. "/" .. maxAmmo)
end

-- Handle tool unequipped
local function onToolUnequipped(tool)
    currentWeapon = nil
    canShoot = false
    print("📦 Unequipped " .. tool.Name)
end

-- Connect to backpack changes
player.CharacterAdded:Connect(function(character)
    local backpack = player:WaitForChild("Backpack")

    -- Connect to existing tools
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Equipped:Connect(function()
                onToolEquipped(tool)
            end)
            tool.Unequipped:Connect(function()
                onToolUnequipped(tool)
            end)
        end
    end

    -- Connect to new tools
    backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                onToolEquipped(child)
            end)
            child.Unequipped:Connect(function()
                onToolUnequipped(child)
            end)
        end
    end)
end)

-- Handle existing character
if player.Character then
    local backpack = player:WaitForChild("Backpack")

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Equipped:Connect(function()
                onToolEquipped(tool)
            end)
            tool.Unequipped:Connect(function()
                onToolUnequipped(tool)
            end)
        end
    end

    backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                onToolEquipped(child)
            end)
            child.Unequipped:Connect(function()
                onToolUnequipped(child)
            end)
        end
    end)
end

-- Handle reload input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R and currentWeapon then
        reload(currentWeapon)
    end
end)

if damageEvent then
    damageEvent.OnClientEvent:Connect(function(victimUserId, damage, newHealth, maxHealth)
        if victimUserId == player.UserId then
            print("💔 Took " .. damage .. " damage! Health: " .. math.floor(newHealth) .. "/" .. math.floor(maxHealth))

            -- Create screen damage effect
            local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
            if gui then
                local damageOverlay = Instance.new("Frame")
                damageOverlay.Name = "DamageOverlay"
                damageOverlay.Size = UDim2.new(1, 0, 1, 0)
                damageOverlay.BackgroundColor3 = Color3.new(1, 0, 0)
                damageOverlay.BackgroundTransparency = 0.7
                damageOverlay.BorderSizePixel = 0
                damageOverlay.Parent = gui

                -- Fade out damage overlay
                local tween = TweenService:Create(damageOverlay, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1
                })
                tween:Play()
            end
        end
    end)
end