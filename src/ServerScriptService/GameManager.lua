-- Game Manager (ServerScript) - Fixed Scoreboard & Ammo System
print("GameManager starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

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

local healthUpdateEvent = Instance.new("RemoteEvent")
healthUpdateEvent.Name = "HealthUpdateEvent"
healthUpdateEvent.Parent = remoteEvents

local scoreboardUpdateEvent = Instance.new("RemoteEvent")
scoreboardUpdateEvent.Name = "ScoreboardUpdateEvent"
scoreboardUpdateEvent.Parent = remoteEvents

local ammoUpdateEvent = Instance.new("RemoteEvent")
ammoUpdateEvent.Name = "AmmoUpdateEvent"
ammoUpdateEvent.Parent = remoteEvents

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

-- Game State
local gameState = {
    isActive = true,
    roundTime = 300,
    players = {},
    playerAmmo = {}, -- Track ammo per player
    lastShotTime = {}
}

-- Game Manager
local GameManager = {}

-- Broadcast scoreboard update to all players
function GameManager:UpdateScoreboard()
    local scoreData = {}

    for userId, data in pairs(gameState.players) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            table.insert(scoreData, {
                name = player.Name,
                kills = data.kills,
                deaths = data.deaths,
                score = data.score,
                health = data.health
            })
        end
    end

    -- Sort by score (highest first)
    table.sort(scoreData, function(a, b)
        return a.score > b.score
    end)

    -- Send to all clients
    scoreboardUpdateEvent:FireAllClients(scoreData)
    print("📊 Scoreboard updated with " .. #scoreData .. " players")
end

function GameManager:OnPlayerJoined(player)
    print(player.Name .. " joined the game!")

    -- Initialize player data
    gameState.players[player.UserId] = {
        kills = 0,
        deaths = 0,
        score = 0,
        currentWeapon = nil,
        health = GAME_CONFIG.MAX_HEALTH
    }

    -- Initialize ammo data
    gameState.playerAmmo[player.UserId] = {}
    gameState.lastShotTime[player.UserId] = 0

    -- Update scoreboard
    self:UpdateScoreboard()

    -- Setup character when spawned
    player.CharacterAdded:Connect(function(character)
        wait(3)
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
    if gameState.playerAmmo[player.UserId] then
        gameState.playerAmmo[player.UserId] = nil
    end
    if gameState.lastShotTime[player.UserId] then
        gameState.lastShotTime[player.UserId] = nil
    end

    -- Update scoreboard
    self:UpdateScoreboard()
end

function GameManager:SetupPlayerCharacter(player, character)
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid")
    if not humanoid then return end

    humanoid.MaxHealth = GAME_CONFIG.MAX_HEALTH
    humanoid.Health = GAME_CONFIG.MAX_HEALTH

    -- Update player health in game state
    if gameState.players[player.UserId] then
        gameState.players[player.UserId].health = GAME_CONFIG.MAX_HEALTH
    end

    -- Connect health changed event
    humanoid.HealthChanged:Connect(function(health)
        if gameState.players[player.UserId] then
            gameState.players[player.UserId].health = health
        end

        -- Update scoreboard when health changes
        self:UpdateScoreboard()

        -- Broadcast health update to all clients
        healthUpdateEvent:FireAllClients(player.UserId, health, humanoid.MaxHealth)
    end)

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
        -- M4A1 Main Body/Receiver
        handle.Size = Vector3.new(0.4, 0.25, 2.8)
        handle.BrickColor = BrickColor.new("Dark stone grey")
        handle.Material = Enum.Material.Metal

        -- Create M4A1 Barrel
        local barrel = Instance.new("Part")
        barrel.Name = "Barrel"
        barrel.Size = Vector3.new(0.08, 0.08, 1.4)
        barrel.Material = Enum.Material.Metal
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.CanCollide = false
        barrel.Shape = Enum.PartType.Cylinder
        barrel.TopSurface = Enum.SurfaceType.Smooth
        barrel.BottomSurface = Enum.SurfaceType.Smooth
        barrel.Parent = handle

        local barrelWeld = Instance.new("WeldConstraint")
        barrelWeld.Part0 = handle
        barrelWeld.Part1 = barrel
        barrelWeld.Parent = handle

        barrel.CFrame = handle.CFrame * CFrame.new(0, 0.05, -1.6) * CFrame.Angles(0, math.rad(90), 0)

        -- M4A1 Flash Hider
        local flashHider = Instance.new("Part")
        flashHider.Name = "FlashHider"
        flashHider.Size = Vector3.new(0.12, 0.12, 0.3)
        flashHider.Material = Enum.Material.Metal
        flashHider.BrickColor = BrickColor.new("Really black")
        flashHider.CanCollide = false
        flashHider.Shape = Enum.PartType.Cylinder
        flashHider.Parent = handle

        local flashHiderWeld = Instance.new("WeldConstraint")
        flashHiderWeld.Part0 = handle
        flashHiderWeld.Part1 = flashHider
        flashHiderWeld.Parent = handle

        flashHider.CFrame = handle.CFrame * CFrame.new(0, 0.05, -2.4) * CFrame.Angles(0, math.rad(90), 0)

        -- M4A1 Magazine
        local magazine = Instance.new("Part")
        magazine.Name = "Magazine"
        magazine.Size = Vector3.new(0.15, 0.8, 0.25)
        magazine.Material = Enum.Material.Metal
        magazine.BrickColor = BrickColor.new("Really black")
        magazine.CanCollide = false
        magazine.Parent = handle

        local magazineWeld = Instance.new("WeldConstraint")
        magazineWeld.Part0 = handle
        magazineWeld.Part1 = magazine
        magazineWeld.Parent = handle

        magazine.CFrame = handle.CFrame * CFrame.new(0, -0.5, -0.3)

        -- M4A1 Stock
        local stock = Instance.new("Part")
        stock.Name = "Stock"
        stock.Size = Vector3.new(0.25, 0.2, 1.0)
        stock.Material = Enum.Material.Plastic
        stock.BrickColor = BrickColor.new("Really black")
        stock.CanCollide = false
        stock.Parent = handle

        local stockWeld = Instance.new("WeldConstraint")
        stockWeld.Part0 = handle
        stockWeld.Part1 = stock
        stockWeld.Parent = handle

        stock.CFrame = handle.CFrame * CFrame.new(0, -0.05, 1.4)

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.3, 0.2, 1.2)
        handle.BrickColor = BrickColor.new("Really black")

    elseif weaponType == "SniperRifle" then
        handle.Size = Vector3.new(0.3, 0.3, 3.5)
        handle.BrickColor = BrickColor.new("Dark stone grey")

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

        local reloadTime = Instance.new("NumberValue")
        reloadTime.Name = "ReloadTime"
        reloadTime.Value = stats.reloadTime
        reloadTime.Parent = weapon
    end

    -- Initialize ammo for this weapon
    if not gameState.playerAmmo[player.UserId] then
        gameState.playerAmmo[player.UserId] = {}
    end
    gameState.playerAmmo[player.UserId][weaponType] = stats.maxAmmo

    -- Add weapon to player
    weapon.Parent = player.Backpack

    -- Update player's current weapon
    if gameState.players[player.UserId] then
        gameState.players[player.UserId].currentWeapon = weaponType
    end

    -- Send initial ammo to client
    ammoUpdateEvent:FireClient(player, stats.maxAmmo, stats.maxAmmo)

    print("Successfully gave " .. weaponType .. " to " .. player.Name)
end

function GameManager:HandleShooting(player, targetPosition, weaponType)
    if not player.Character then return end

    -- Check if player has ammo
    local playerAmmo = gameState.playerAmmo[player.UserId]
    if not playerAmmo or not playerAmmo[weaponType] or playerAmmo[weaponType] <= 0 then
        print("❌ " .. player.Name .. " has no ammo for " .. weaponType)
        return
    end

    -- Check fire rate limiting
    local currentTime = tick()
    local lastShot = gameState.lastShotTime[player.UserId] or 0
    local weaponStats = WEAPON_STATS[weaponType]
    local fireRate = weaponStats and weaponStats.fireRate or 0.1

    if currentTime - lastShot < fireRate then
        return
    end

    gameState.lastShotTime[player.UserId] = currentTime

    -- Consume ammo
    playerAmmo[weaponType] = playerAmmo[weaponType] - 1

    -- Send ammo update to client
    local maxAmmo = weaponStats and weaponStats.maxAmmo or 30
    ammoUpdateEvent:FireClient(player, playerAmmo[weaponType], maxAmmo)

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    print("🔫 " .. player.Name .. " fired " .. weaponType .. " - Ammo: " .. playerAmmo[weaponType] .. "/" .. maxAmmo)

    -- Create raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local startPosition = humanoidRootPart.Position + Vector3.new(0, 1.5, 0)
    local direction = (targetPosition - startPosition).Unit
    local range = weaponStats and weaponStats.range or 500

    local raycastResult = workspace:Raycast(startPosition, direction * range, raycastParams)

    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitPosition = raycastResult.Position
        local hitCharacter = hitPart.Parent

        -- Check if we hit another player
        if hitCharacter:FindFirstChild("Humanoid") and hitCharacter ~= character then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer and hitPlayer ~= player then
                print("🎯 Hit detected on " .. hitPlayer.Name)
                self:DamagePlayer(hitPlayer, player, weaponType, hitPosition)
            end
        end

        -- Create hit effect at impact point
        self:CreateHitEffect(hitPosition)
    end
end

function GameManager:HandleReload(player, weaponType)
    if not player.Character then return end

    local playerAmmo = gameState.playerAmmo[player.UserId]
    if not playerAmmo then return end

    local weaponStats = WEAPON_STATS[weaponType]
    if not weaponStats then return end

    -- Check if already full
    if playerAmmo[weaponType] >= weaponStats.maxAmmo then
        print("🔄 " .. player.Name .. "'s " .. weaponType .. " is already full")
        return
    end

    print("🔄 " .. player.Name .. " is reloading " .. weaponType .. "...")

    -- Set ammo to full after reload time
    spawn(function()
        wait(weaponStats.reloadTime)
        playerAmmo[weaponType] = weaponStats.maxAmmo

        -- Send updated ammo to client
        ammoUpdateEvent:FireClient(player, playerAmmo[weaponType], weaponStats.maxAmmo)

        print("✅ " .. player.Name .. " finished reloading " .. weaponType)
    end)
end

function GameManager:DamagePlayer(victim, attacker, weaponType, hitPosition)
    local character = victim.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Get weapon damage
    local damage = WEAPON_STATS[weaponType] and WEAPON_STATS[weaponType].damage or 25

    -- Calculate new health
    local oldHealth = humanoid.Health
    local newHealth = math.max(0, oldHealth - damage)

    -- Apply damage
    humanoid.Health = newHealth

    print("💥 " .. attacker.Name .. " hit " .. victim.Name .. " for " .. damage .. " damage (" .. math.floor(oldHealth) .. " → " .. math.floor(newHealth) .. ")")

    -- Update game state
    if gameState.players[victim.UserId] then
        gameState.players[victim.UserId].health = newHealth
    end

    -- Create damage effect
    self:CreateDamageEffect(hitPosition, damage, victim)

    -- Fire damage event to all clients
    damageEvent:FireAllClients(victim.UserId, damage, newHealth, humanoid.MaxHealth)

    -- Check if player was eliminated
    if newHealth <= 0 then
        self:HandlePlayerElimination(victim, attacker, weaponType)
    end

    -- Update scoreboard
    self:UpdateScoreboard()
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

    print("💀 " .. attacker.Name .. " eliminated " .. victim.Name .. " with " .. weaponType)

    -- Update scoreboard immediately
    self:UpdateScoreboard()

    -- Create elimination effect
    if victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") then
        self:CreateEliminationEffect(victim.Character.HumanoidRootPart.Position)
    end
end

function GameManager:CreateHitEffect(position)
    local spark = Instance.new("Part")
    spark.Name = "HitEffect"
    spark.Size = Vector3.new(0.4, 0.4, 0.4)
    spark.Material = Enum.Material.Neon
    spark.BrickColor = BrickColor.new("Bright yellow")
    spark.Anchored = true
    spark.CanCollide = false
    spark.Shape = Enum.PartType.Ball
    spark.Position = position
    spark.Parent = workspace

    local tween = TweenService:Create(spark, TweenInfo.new(0.3), {
        Size = Vector3.new(0.1, 0.1, 0.1),
        Transparency = 1
    })
    tween:Play()

    tween.Completed:Connect(function()
        spark:Destroy()
    end)
end

function GameManager:CreateDamageEffect(position, damage, victim)
    local damageGui = Instance.new("BillboardGui")
    damageGui.Size = UDim2.new(0, 100, 0, 50)
    damageGui.StudsOffset = Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))

    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. damage
    damageLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageLabel.Parent = damageGui

    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Position = position
    part.Parent = workspace

    damageGui.Parent = part

    Debris:AddItem(part, 1)
end

function GameManager:CreateEliminationEffect(position)
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = 10
    explosion.BlastPressure = 0
    explosion.Parent = workspace
end

-- Connect Remote Events
shootEvent.OnServerEvent:Connect(function(player, targetPosition, weaponType)
    GameManager:HandleShooting(player, targetPosition, weaponType)
end)

reloadEvent.OnServerEvent:Connect(function(player, weaponType)
    GameManager:HandleReload(player, weaponType)
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

-- Periodic scoreboard updates
spawn(function()
    while true do
        wait(5) -- Update scoreboard every 5 seconds
        GameManager:UpdateScoreboard()
    end
end)

print("🎮 GameManager initialized successfully!")
print("📊 Scoreboard system active")
print("🔫 Ammo tracking system ready")
print("🔄 Reload system operational")

return GameManager
