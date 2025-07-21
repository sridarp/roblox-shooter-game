-- Weapon Handler (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

-- Update ammo display
local function updateAmmoDisplay()
    local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
    if gui and gui:FindFirstChild("HUD") then
        local ammoContainer = gui.HUD:FindFirstChild("AmmoContainer")
        if ammoContainer then
            local ammoLabel = ammoContainer:FindFirstChild("AmmoLabel")
            if ammoLabel then
                ammoLabel.Text = "AMMO\n" .. currentAmmo .. "/" .. maxAmmo
            end
        end
    end
end

-- Create muzzle flash effect
local function createMuzzleFlash(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Create flash part
    local flash = Instance.new("Part")
    flash.Name = "MuzzleFlash"
    flash.Size = Vector3.new(0.3, 0.3, 0.8)
    flash.Material = Enum.Material.Neon
    flash.BrickColor = BrickColor.new("Bright yellow")
    flash.Anchored = true
    flash.CanCollide = false
    flash.Shape = Enum.PartType.Ball
    flash.Parent = workspace

    -- Position flash at barrel
    flash.CFrame = handle.CFrame * CFrame.new(0, 0, -handle.Size.Z/2 - 0.5)

    -- Create light
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = Color3.new(1, 1, 0)
    light.Range = 10
    light.Parent = flash

    -- Remove flash quickly
    game:GetService("Debris"):AddItem(flash, 0.1)
end

-- Shoot function
local function shoot(tool)
    if not canShoot or currentAmmo <= 0 or isReloading then
        return
    end

    canShoot = false
    currentAmmo = currentAmmo - 1

    -- Fire weapon
    if shootEvent then
        shootEvent:FireServer(mouse.Hit.Position, tool.Name)
    end

    -- Create effects
    createMuzzleFlash(tool)

    -- Update ammo display
    updateAmmoDisplay()

    -- Fire rate delay
    local stats = weaponStats[tool.Name]
    local fireRate = stats and stats.fireRate or 0.1

    wait(fireRate)
    canShoot = true
end

-- Reload function
local function reload(tool)
    if isReloading or currentAmmo >= maxAmmo then
        return
    end

    isReloading = true
    print("Reloading " .. tool.Name .. "...")

    -- Update GUI to show reloading
    local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
    if gui and gui:FindFirstChild("HUD") then
        local ammoContainer = gui.HUD:FindFirstChild("AmmoContainer")
        if ammoContainer then
            local ammoLabel = ammoContainer:FindFirstChild("AmmoLabel")
            if ammoLabel then
                ammoLabel.Text = "RELOADING..."
            end
        end
    end

    -- Reload time
    local stats = weaponStats[tool.Name]
    local reloadTime = stats and stats.reloadTime or 2.0

    wait(reloadTime)

    -- Restore ammo
    currentAmmo = maxAmmo
    isReloading = false

    -- Update display
    updateAmmoDisplay()

    print("Reload complete!")
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

    updateAmmoDisplay()

    -- Connect tool events
    tool.Activated:Connect(function()
        shoot(tool)
    end)

    print("Equipped " .. tool.Name)
end

-- Handle tool unequipped
local function onToolUnequipped(tool)
    currentWeapon = nil
    print("Unequipped " .. tool.Name)
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

-- Handle reload input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R and currentWeapon then
        reload(currentWeapon)
    end
end)

print("Weapon Handler loaded successfully!")