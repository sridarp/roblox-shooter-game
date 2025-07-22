-- Game Manager (ServerScript) - Fixed Damage System
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
    scores = {},
    lastShotTime = {} -- Track last shot time per player to prevent spam
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
        currentWeapon = nil,
        health = GAME_CONFIG.MAX_HEALTH
    }

    gameState.lastShotTime[player.UserId] = 0

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
    if gameState.lastShotTime[player.UserId] then
        gameState.lastShotTime[player.UserId] = nil
    end
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

        -- Position barrel (rotate for cylinder)
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

        -- M4A1 Handguard/Rail System
        local handguard = Instance.new("Part")
        handguard.Name = "Handguard"
        handguard.Size = Vector3.new(0.35, 0.2, 1.2)
        handguard.Material = Enum.Material.Metal
        handguard.BrickColor = BrickColor.new("Dark stone grey")
        handguard.CanCollide = false
        handguard.Parent = handle

        local handguardWeld = Instance.new("WeldConstraint")
        handguardWeld.Part0 = handle
        handguardWeld.Part1 = handguard
        handguardWeld.Parent = handle

        handguard.CFrame = handle.CFrame * CFrame.new(0, 0.02, -0.8)

        -- M4A1 Front Sight
        local frontSight = Instance.new("Part")
        frontSight.Name = "FrontSight"
        frontSight.Size = Vector3.new(0.15, 0.15, 0.1)
        frontSight.Material = Enum.Material.Metal
        frontSight.BrickColor = BrickColor.new("Really black")
        frontSight.CanCollide = false
        frontSight.Parent = handle

        local frontSightWeld = Instance.new("WeldConstraint")
        frontSightWeld.Part0 = handle
        frontSightWeld.Part1 = frontSight
        frontSightWeld.Parent = handle

        frontSight.CFrame = handle.CFrame * CFrame.new(0, 0.15, -1.8)

        -- M4A1 Rear Sight
        local rearSight = Instance.new("Part")
        rearSight.Name = "RearSight"
        rearSight.Size = Vector3.new(0.12, 0.12, 0.08)
        rearSight.Material = Enum.Material.Metal
        rearSight.BrickColor = BrickColor.new("Really black")
        rearSight.CanCollide = false
        rearSight.Parent = handle

        local rearSightWeld = Instance.new("WeldConstraint")
        rearSightWeld.Part0 = handle
        rearSightWeld.Part1 = rearSight
        rearSightWeld.Parent = handle

        rearSight.CFrame = handle.CFrame * CFrame.new(0, 0.15, 0.3)

        -- M4A1 Carrying Handle (Classic M4 Style)
        local carryHandle = Instance.new("Part")
        carryHandle.Name = "CarryHandle"
        carryHandle.Size = Vector3.new(0.08, 0.25, 0.6)
        carryHandle.Material = Enum.Material.Metal
        carryHandle.BrickColor = BrickColor.new("Dark stone grey")
        carryHandle.CanCollide = false
        carryHandle.Parent = handle

        local carryHandleWeld = Instance.new("WeldConstraint")
        carryHandleWeld.Part0 = handle
        carryHandleWeld.Part1 = carryHandle
        carryHandleWeld.Parent = handle

        carryHandle.CFrame = handle.CFrame * CFrame.new(0, 0.25, 0.1)

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

        -- M4A1 Trigger Guard
        local triggerGuard = Instance.new("Part")
        triggerGuard.Name = "TriggerGuard"
        triggerGuard.Size = Vector3.new(0.25, 0.15, 0.3)
        triggerGuard.Material = Enum.Material.Metal
        triggerGuard.BrickColor = BrickColor.new("Dark stone grey")
        triggerGuard.CanCollide = false
        triggerGuard.Parent = handle

        local triggerGuardWeld = Instance.new("WeldConstraint")
        triggerGuardWeld.Part0 = handle
        triggerGuardWeld.Part1 = triggerGuard
        triggerGuardWeld.Parent = handle

        triggerGuard.CFrame = handle.CFrame * CFrame.new(0, -0.18, 0.2)

        -- M4A1 Pistol Grip
        local pistolGrip = Instance.new("Part")
        pistolGrip.Name = "PistolGrip"
        pistolGrip.Size = Vector3.new(0.2, 0.6, 0.35)
        pistolGrip.Material = Enum.Material.Plastic
        pistolGrip.BrickColor = BrickColor.new("Really black")
        pistolGrip.CanCollide = false
        pistolGrip.Parent = handle

        local pistolGripWeld = Instance.new("WeldConstraint")
        pistolGripWeld.Part0 = handle
        pistolGripWeld.Part1 = pistolGrip
        pistolGripWeld.Parent = handle

        pistolGrip.CFrame = handle.CFrame * CFrame.new(0, -0.4, 0.4) * CFrame.Angles(math.rad(-15), 0, 0)

        -- M4A1 Stock (Collapsible)
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

        -- M4A1 Buffer Tube
        local bufferTube = Instance.new("Part")
        bufferTube.Name = "BufferTube"
        bufferTube.Size = Vector3.new(0.1, 0.1, 0.8)
        bufferTube.Material = Enum.Material.Metal
        bufferTube.BrickColor = BrickColor.new("Dark stone grey")
        bufferTube.CanCollide = false
        bufferTube.Shape = Enum.PartType.Cylinder
        bufferTube.Parent = handle

        local bufferTubeWeld = Instance.new("WeldConstraint")
        bufferTubeWeld.Part0 = handle
        bufferTubeWeld.Part1 = bufferTube
        bufferTubeWeld.Parent = handle

        bufferTube.CFrame = handle.CFrame * CFrame.new(0, 0.05, 1.0) * CFrame.Angles(0, math.rad(90), 0)

        -- M4A1 Ejection Port
        local ejectionPort = Instance.new("Part")
        ejectionPort.Name = "EjectionPort"
        ejectionPort.Size = Vector3.new(0.05, 0.15, 0.25)
        ejectionPort.Material = Enum.Material.Metal
        ejectionPort.BrickColor = BrickColor.new("Really black")
        ejectionPort.CanCollide = false
        ejectionPort.Parent = handle

        local ejectionPortWeld = Instance.new("WeldConstraint")
        ejectionPortWeld.Part0 = handle
        ejectionPortWeld.Part1 = ejectionPort
        ejectionPortWeld.Parent = handle

        ejectionPort.CFrame = handle.CFrame * CFrame.new(0.22, 0.05, -0.2)

        -- M4A1 Charging Handle
        local chargingHandle = Instance.new("Part")
        chargingHandle.Name = "ChargingHandle"
        chargingHandle.Size = Vector3.new(0.08, 0.05, 0.15)
        chargingHandle.Material = Enum.Material.Metal
        chargingHandle.BrickColor = BrickColor.new("Really black")
        chargingHandle.CanCollide = false
        chargingHandle.Parent = handle

        local chargingHandleWeld = Instance.new("WeldConstraint")
        chargingHandleWeld.Part0 = handle
        chargingHandleWeld.Part1 = chargingHandle
        chargingHandleWeld.Parent = handle

        chargingHandle.CFrame = handle.CFrame * CFrame.new(0, 0.15, 0.5)

        -- Add some tactical accessories
        -- Tactical Light
        local tacticalLight = Instance.new("Part")
        tacticalLight.Name = "TacticalLight"
        tacticalLight.Size = Vector3.new(0.08, 0.08, 0.2)
        tacticalLight.Material = Enum.Material.Metal
        tacticalLight.BrickColor = BrickColor.new("Really black")
        tacticalLight.CanCollide = false
        tacticalLight.Shape = Enum.PartType.Cylinder
        tacticalLight.Parent = handle

        local tacticalLightWeld = Instance.new("WeldConstraint")
        tacticalLightWeld.Part0 = handguard
        tacticalLightWeld.Part1 = tacticalLight
        tacticalLightWeld.Parent = handle

        tacticalLight.CFrame = handguard.CFrame * CFrame.new(0, -0.15, -0.3) * CFrame.Angles(0, math.rad(90), 0)

        -- Add tactical light glow
        local lightSource = Instance.new("SpotLight")
        lightSource.Brightness = 0
        lightSource.Range = 50
        lightSource.Angle = 45
        lightSource.Color = Color3.new(1, 1, 0.8)
        lightSource.Parent = tacticalLight

        print("🔫 Created detailed M4A1 Assault Rifle model")

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.3, 0.2, 1.2)
        handle.BrickColor = BrickColor.new("Really black")

    elseif weaponType == "SniperRifle" then
        handle.Size = Vector3.new(0.3, 0.3, 3.5)
        handle.BrickColor = BrickColor.new("Dark stone grey")

        -- Create scope
        local scope = Instance.new("Part")
        scope.Name = "Scope"
        scope.Size = Vector3.new(0.2, 0.2, 0.8)
        scope.Material = Enum.Material.Glass
        scope.BrickColor = BrickColor.new("Really black")
        scope.CanCollide = false
        scope.Shape = Enum.PartType.Cylinder
        scope.Parent = handle

        local scopeWeld = Instance.new("WeldConstraint")
        scopeWeld.Part0 = handle
        scopeWeld.Part1 = scope
        scopeWeld.Parent = handle

        scope.CFrame = handle.CFrame * CFrame.new(0, 0.3, -0.5) * CFrame.Angles(0, math.rad(90), 0)

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

    -- Check fire rate limiting
    local currentTime = tick()
    local lastShot = gameState.lastShotTime[player.UserId] or 0
    local weaponStats = WEAPON_STATS[weaponType]
    local fireRate = weaponStats and weaponStats.fireRate or 0.1

    if currentTime - lastShot < fireRate then
        return -- Too soon to shoot again
    end

    gameState.lastShotTime[player.UserId] = currentTime

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    print("🔫 " .. player.Name .. " fired " .. weaponType)

    -- Create raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local startPosition = humanoidRootPart.Position + Vector3.new(0, 1.5, 0) -- Shoulder height
    local direction = (targetPosition - startPosition).Unit
    local range = weaponStats and weaponStats.range or 500

    local raycastResult = workspace:Raycast(startPosition, direction * range, raycastParams)

    -- Create bullet trail effect
    self:CreateBulletTrail(startPosition, raycastResult and raycastResult.Position or (startPosition + direction * range))

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

function GameManager:DamagePlayer(victim, attacker, weaponType, hitPosition)
    local character = victim.Character
    if not character then
        print("❌ No character found for victim")
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        print("❌ No humanoid found for victim")
        return
    end

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

    -- Create damage effect on victim (visible to all players)
    self:CreateDamageEffect(hitPosition, damage, victim)

    -- Fire damage event to all clients for UI updates
    damageEvent:FireAllClients(victim.UserId, damage, newHealth, humanoid.MaxHealth)

    -- Check if player was eliminated
    if newHealth <= 0 then
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

    print("💀 " .. attacker.Name .. " eliminated " .. victim.Name .. " with " .. weaponType)

    -- Create elimination effect
    if victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") then
        self:CreateEliminationEffect(victim.Character.HumanoidRootPart.Position)
    end
end

function GameManager:CreateBulletTrail(startPos, endPos)
    local trail = Instance.new("Part")
    trail.Name = "BulletTrail"
    trail.Size = Vector3.new(0.1, 0.1, (startPos - endPos).Magnitude)
    trail.Material = Enum.Material.Neon
    trail.BrickColor = BrickColor.new("Bright yellow")
    trail.Anchored = true
    trail.CanCollide = false
    trail.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -trail.Size.Z/2)
    trail.Parent = workspace

    -- Fade out trail
    local tween = TweenService:Create(trail, TweenInfo.new(0.1), {Transparency = 1})
    tween:Play()

    tween.Completed:Connect(function()
        trail:Destroy()
    end)
end

function GameManager:CreateHitEffect(position)
    -- Create spark effect
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

    -- Add light
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Color = Color3.new(1, 1, 0)
    light.Range = 10
    light.Parent = spark

    -- Animate spark
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
    -- Create damage number that all players can see
    local damageGui = Instance.new("BillboardGui")
    damageGui.Size = UDim2.new(0, 100, 0, 50)
    damageGui.StudsOffset = Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
    damageGui.LightInfluence = 0

    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. damage
    damageLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageLabel.TextStrokeTransparency = 0.5
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

    -- Animate damage number
    local tween1 = TweenService:Create(damageGui, TweenInfo.new(0.5), {
        StudsOffset = damageGui.StudsOffset + Vector3.new(0, 2, 0)
    })

    local tween2 = TweenService:Create(damageLabel, TweenInfo.new(0.5), {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })

    tween1:Play()
    wait(0.1)
    tween2:Play()

    -- Remove after animation
    Debris:AddItem(part, 1)
end

function GameManager:CreateEliminationEffect(position)
    -- Create explosion effect for elimination
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = 10
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- Create elimination text
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 200, 0, 100)
    gui.StudsOffset = Vector3.new(0, 5, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "ELIMINATED!"
    label.TextColor3 = Color3.new(1, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = gui

    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Position = position
    part.Parent = workspace

    gui.Parent = part

    Debris:AddItem(part, 3)
end

-- Connect Remote Events
shootEvent.OnServerEvent:Connect(function(player, targetPosition, weaponType)
    GameManager:HandleShooting(player, targetPosition, weaponType)
end)

reloadEvent.OnServerEvent:Connect(function(player, weaponType)
    print("🔄 " .. player.Name .. " is reloading " .. weaponType)
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

-- Game loop for stats broadcasting
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
print("⚔️ Enhanced weapon system loaded")
print("🎯 Improved damage system active")
print("💥 Visual effects system ready")

return GameManager
