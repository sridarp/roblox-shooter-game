-- Game Manager (ServerScript) - Clean Version
print("GameManager starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Create RemoteEvents IMMEDIATELY
print("Creating RemoteEvents...")

-- Clean up existing RemoteEvents if they exist
local existingRemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if existingRemoteEvents then
    existingRemoteEvents:Destroy()
    wait(0.1)
end

local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local shootEvent = Instance.new("RemoteEvent")
shootEvent.Name = "ShootEvent"
shootEvent.Parent = remoteEvents

local reloadEvent = Instance.new("RemoteEvent")
reloadEvent.Name = "ReloadEvent"
reloadEvent.Parent = remoteEvents

local damageEvent = Instance.new("RemoteEvent")
damageEvent.Name = "DamageEvent"
damageEvent.Parent = remoteEvents

local playerStatsEvent = Instance.new("RemoteEvent")
playerStatsEvent.Name = "PlayerStatsEvent"
playerStatsEvent.Parent = remoteEvents

print("RemoteEvents created successfully!")

-- Game Configuration
local GAME_CONFIG = {
    MAX_PLAYERS = 12,
    ROUND_TIME = 300,
    RESPAWN_TIME = 5,
    MAX_HEALTH = 100
}

-- Weapon Configuration
local WEAPON_STATS = {
    AssaultRifle = {
        damage = 25,
        fireRate = 0.1,
        range = 500,
        maxAmmo = 30
    },
    Pistol = {
        damage = 35,
        fireRate = 0.3,
        range = 300,
        maxAmmo = 12
    },
    SniperRifle = {
        damage = 80,
        fireRate = 1.0,
        range = 1000,
        maxAmmo = 5
    },
    SMG = {
        damage = 20,
        fireRate = 0.05,
        range = 250,
        maxAmmo = 40
    }
}

-- Game State
local gameState = {
    isActive = true,
    roundTime = 300,
    players = {},
    scores = {}
}

-- Game Manager
local GameManager = {}

function GameManager:OnPlayerJoined(player)
    print(player.Name .. " joined the game!")

    -- Initialize player data
    gameState.players[player.UserId] = {
        kills = 0,
        deaths = 0,
        score = 0,
        currentWeapon = nil
    }

    -- Setup character when spawned
    player.CharacterAdded:Connect(function(character)
        wait(3) -- Wait for character to fully load
        self:SetupPlayerCharacter(player, character)
    end)

    -- Handle existing character
    if player.Character then
        wait(3)
        self:SetupPlayerCharacter(player, player.Character)
    end
end

function GameManager:OnPlayerLeft(player)
    print(player.Name .. " left the game!")
    if gameState.players[player.UserId] then
        gameState.players[player.UserId] = nil
    end
end

function GameManager:SetupPlayerCharacter(player, character)
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid")
    if not humanoid then return end

    humanoid.MaxHealth = GAME_CONFIG.MAX_HEALTH
    humanoid.Health = GAME_CONFIG.MAX_HEALTH

    print("Setting up character for " .. player.Name)

    -- Give weapon after delay
    wait(2)
    if player.Character == character then
        self:GiveWeapon(player, "AssaultRifle")
    end
end

function GameManager:CreateWeaponModel(weaponType)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.CanCollide = false
    handle.Material = Enum.Material.Metal
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth

    -- Configure based on weapon type
    if weaponType == "AssaultRifle" then
        handle.Size = Vector3.new(0.4, 0.3, 2.5)
        handle.BrickColor = BrickColor.new("Dark stone grey")

        -- Add barrel
        local barrel = Instance.new("Part")
        barrel.Name = "Barrel"
        barrel.Size = Vector3.new(0.1, 0.1, 1.0)
        barrel.Material = Enum.Material.Metal
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.CanCollide = false
        barrel.TopSurface = Enum.SurfaceType.Smooth
        barrel.BottomSurface = Enum.SurfaceType.Smooth
        barrel.Parent = handle

        -- Weld barrel to handle
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = barrel
        weld.Parent = handle

        -- Position barrel
        barrel.CFrame = handle.CFrame * CFrame.new(0, 0.1, -1.2)

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.3, 0.2, 1.2)
        handle.BrickColor = BrickColor.new("Really black")

    elseif weaponType == "SniperRifle" then
        handle.Size = Vector3.new(0.3, 0.3, 3.5)
        handle.BrickColor = BrickColor.new("Dark stone grey")

        -- Add scope
        local scope = Instance.new("Part")
        scope.Name = "Scope"
        scope.Size = Vector3.new(0.15, 0.15, 0.6)
        scope.Material = Enum.Material.Glass
        scope.BrickColor = BrickColor.new("Really black")
        scope.CanCollide = false
        scope.Shape = Enum.PartType.Cylinder
        scope.Parent = handle

        local scopeWeld = Instance.new("WeldConstraint")
        scopeWeld.Part0 = handle
        scopeWeld.Part1 = scope
        scopeWeld.Parent = handle

        scope.CFrame = handle.CFrame * CFrame.new(0, 0.25, -0.5) * CFrame.Angles(0, math.rad(90), 0)

    elseif weaponType == "SMG" then
        handle.Size = Vector3.new(0.3, 0.25, 1.8)
        handle.BrickColor = BrickColor.new("Dark stone grey")
    end

    return handle
end

function GameManager:GiveWeapon(player, weaponType)
    if not player.Character then
        print("No character found for " .. player.Name)
        return
    end

    -- Create tool
    local weapon = Instance.new("Tool")
    weapon.Name = weaponType
    weapon.RequiresHandle = true
    weapon.CanBeDropped = false

    -- Create weapon model
    local handle = self:CreateWeaponModel(weaponType)
    handle.Parent = weapon

    -- Store weapon stats in tool for reference
    local stats = WEAPON_STATS[weaponType]
    if stats then
        local damage = Instance.new("IntValue")
        damage.Name = "Damage"
        damage.Value = stats.damage
        damage.Parent = weapon

        local maxAmmo = Instance.new("IntValue")
        maxAmmo.Name = "MaxAmmo"
        maxAmmo.Value = stats.maxAmmo
        maxAmmo.Parent = weapon

        local fireRate = Instance.new("NumberValue")
        fireRate.Name = "FireRate"
        fireRate.Value = stats.fireRate
        fireRate.Parent = weapon
    end

    -- Add weapon to player
    weapon.Parent = player.Backpack

    -- Update player's current weapon
    if gameState.players[player.UserId] then
        gameState.players[player.UserId].currentWeapon = weaponType
    end

    print("Successfully gave " .. weaponType .. " to " .. player.Name)
end

function GameManager:HandleShooting(player, targetPosition, weaponType)
    if not player.Character then return end

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    print(player.Name .. " fired " .. weaponType .. " at " .. tostring(targetPosition))

    -- Create raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local startPosition = humanoidRootPart.Position + Vector3.new(0, 1.5, 0) -- Shoulder height
    local direction = (targetPosition - startPosition).Unit
    local range = WEAPON_STATS[weaponType] and WEAPON_STATS[weaponType].range or 500

    local raycastResult = workspace:Raycast(startPosition, direction * range, raycastParams)

    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitPosition = raycastResult.Position
        local hitCharacter = hitPart.Parent

        -- Check if we hit another player
        if hitCharacter:FindFirstChild("Humanoid") and hitCharacter ~= character then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer and hitPlayer ~= player then
                self:DamagePlayer(hitPlayer, player, weaponType, hitPosition)
            end
        end

        -- Create hit effect at impact point
        self:CreateHitEffect(hitPosition)
    else
        -- Create effect at max range if nothing was hit
        local maxRangePosition = startPosition + (direction * range)
        self:CreateHitEffect(maxRangePosition)
    end
end

function GameManager:DamagePlayer(victim, attacker, weaponType, hitPosition)
    local character = victim.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Get weapon damage
    local damage = WEAPON_STATS[weaponType] and WEAPON_STATS[weaponType].damage or 25

    -- Apply damage
    humanoid.Health = math.max(0, humanoid.Health - damage)

    print(attacker.Name .. " hit " .. victim.Name .. " for " .. damage .. " damage with " .. weaponType)

    -- Create damage effect on victim
    self:CreateDamageEffect(hitPosition, damage)

    -- Check if player was eliminated
    if humanoid.Health <= 0 then
        self:HandlePlayerElimination(victim, attacker, weaponType)
    end
end

function GameManager:HandlePlayerElimination(victim, attacker, weaponType)
    -- Update stats
    if gameState.players[attacker.UserId] then
        gameState.players[attacker.UserId].kills = gameState.players[attacker.UserId].kills + 1
        gameState.players[attacker.UserId].score = gameState.players[attacker.UserId].score + 100
    end

    if gameState.players[victim.UserId] then
        gameState.players[victim.UserId].deaths = gameState.players[victim.UserId].deaths + 1
    end

    print("🎯 " .. attacker.Name .. " eliminated " .. victim.Name .. " with " .. weaponType)

    -- Broadcast elimination message
    for _, player in pairs(Players:GetPlayers()) do
        if player.PlayerGui:FindFirstChild("ShooterGameGUI") then
            -- Could send elimination message to GUI here
        end
    end
end

function GameManager:CreateHitEffect(position)
    -- Create spark effect
    local spark = Instance.new("Part")
    spark.Name = "HitEffect"
    spark.Size = Vector3.new(0.3, 0.3, 0.3)
    spark.Material = Enum.Material.Neon
    spark.BrickColor = BrickColor.new("Bright yellow")
    spark.Anchored = true
    spark.CanCollide = false
    spark.Shape = Enum.PartType.Ball
    spark.Position = position
    spark.Parent = workspace

    -- Add light
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = Color3.new(1, 1, 0)
    light.Range = 8
    light.Parent = spark

    -- Add particle effect
    local attachment = Instance.new("Attachment")
    attachment.Parent = spark

    -- Remove effect after short time
    Debris:AddItem(spark, 0.5)
end

function GameManager:CreateDamageEffect(position, damage)
    -- Create damage number display
    local damageGui = Instance.new("BillboardGui")
    damageGui.Size = UDim2.new(0, 100, 0, 50)
    damageGui.StudsOffset = Vector3.new(0, 2, 0)

    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. damage
    damageLabel.TextColor3 = Color3.new(1, 0, 0)
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageLabel.Parent = damageGui

    -- Create invisible part to attach GUI to
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Position = position
    part.Parent = workspace

    damageGui.Parent = part

    -- Remove after time
    Debris:AddItem(part, 2)
end

-- Connect Remote Events
shootEvent.OnServerEvent:Connect(function(player, targetPosition, weaponType)
    GameManager:HandleShooting(player, targetPosition, weaponType)
end)

reloadEvent.OnServerEvent:Connect(function(player, weaponType)
    print(player.Name .. " is reloading " .. weaponType)
end)

-- Connect Player Events
Players.PlayerAdded:Connect(function(player)
    GameManager:OnPlayerJoined(player)
end)

Players.PlayerRemoving:Connect(function(player)
    GameManager:OnPlayerLeft(player)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    GameManager:OnPlayerJoined(player)
end

-- Game loop
spawn(function()
    while true do
        wait(1)
        if gameState.isActive then
            gameState.roundTime = gameState.roundTime - 1

            if gameState.roundTime <= 0 then
                print("Round ended!")
                gameState.roundTime = GAME_CONFIG.ROUND_TIME
            end
        end
    end
end)

print("🎮 GameManager initialized successfully!")
print("📡 RemoteEvents ready for client communication")
print("⚔️ Weapon system loaded")
print("🎯 Combat system active")

return GameManager

