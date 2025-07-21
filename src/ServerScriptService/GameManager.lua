-- Main Game Manager (Fixed Version)
local GameManager = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Game Configuration
local GAME_CONFIG = {
    MAX_PLAYERS = 12,
    ROUND_TIME = 300, -- 5 minutes
    RESPAWN_TIME = 5,
    MAX_HEALTH = 100
}

-- Game State
local gameState = {
    isActive = false,
    roundTime = 0,
    players = {},
    scores = {}
}

function GameManager:InitializeGame()
    print("Initializing Shooter Game...")

    -- Setup remote events FIRST before anything else
    self:SetupRemoteEvents()

    -- Small delay to ensure replication
    wait(1)

    self:SetupPlayerConnections()
    self:StartGameLoop()

    print("Game Manager initialized successfully!")
end

function GameManager:SetupRemoteEvents()
    print("Setting up Remote Events...")

    -- Create RemoteEvents folder
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end

    -- Create remote events for client-server communication
    local function createRemoteEvent(name)
        local existingEvent = remoteEvents:FindFirstChild(name)
        if existingEvent then
            existingEvent:Destroy()
        end

        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = remoteEvents
        return remoteEvent
    end

    local shootEvent = createRemoteEvent("ShootEvent")
    local reloadEvent = createRemoteEvent("ReloadEvent")
    local damageEvent = createRemoteEvent("DamageEvent")

    -- Connect events
    shootEvent.OnServerEvent:Connect(function(player, targetPosition, weaponType)
        self:HandleShooting(player, targetPosition, weaponType)
    end)

    reloadEvent.OnServerEvent:Connect(function(player, weaponType)
        print(player.Name .. " is reloading " .. weaponType)
    end)

    print("Remote Events created successfully!")
end

function GameManager:SetupPlayerConnections()
    print("Setting up Player Connections...")

    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)

    -- Handle players already in game
    for _, player in pairs(Players:GetPlayers()) do
        self:OnPlayerJoined(player)
    end
end

function GameManager:OnPlayerJoined(player)
    print(player.Name .. " joined the game!")

    -- Initialize player data
    gameState.players[player.UserId] = {
        kills = 0,
        deaths = 0,
        score = 0
    }

    -- Setup player character
    player.CharacterAdded:Connect(function(character)
        wait(1) -- Wait for character to fully load
        self:SetupPlayerCharacter(player, character)
    end)

    -- Handle if player already has character
    if player.Character then
        wait(1)
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
    humanoid.MaxHealth = GAME_CONFIG.MAX_HEALTH
    humanoid.Health = GAME_CONFIG.MAX_HEALTH

    -- Add weapon to player after a short delay
    wait(2)
    if player.Character == character then -- Make sure character still exists
        self:GiveWeapon(player, "AssaultRifle")
    end
end

function GameManager:GiveWeapon(player, weaponType)
    if not player.Character then return end

    local weapon = self:CreateWeapon(weaponType)
    if weapon then
        weapon.Parent = player.Backpack
        print("Gave " .. weaponType .. " to " .. player.Name)
    end
end

function GameManager:CreateWeapon(weaponType)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponType
    weapon.RequiresHandle = true

    -- Create weapon handle (3D model)
    local handle = self:CreateWeaponModel(weaponType)
    handle.Name = "Handle"
    handle.Parent = weapon

    -- Add weapon script
    local weaponScript = self:CreateWeaponScript(weaponType)
    weaponScript.Parent = weapon

    return weapon
end

function GameManager:CreateWeaponModel(weaponType)
    local handle = Instance.new("Part")
    handle.Size = Vector3.new(0.5, 0.3, 3)
    handle.Material = Enum.Material.Metal
    handle.BrickColor = BrickColor.new("Dark stone grey")
    handle.CanCollide = false

    -- Add weapon details based on type
    if weaponType == "AssaultRifle" then
        handle.Size = Vector3.new(0.4, 0.3, 2.5)

        -- Create barrel
        local barrel = Instance.new("Part")
        barrel.Size = Vector3.new(0.1, 0.1, 1)
        barrel.Material = Enum.Material.Metal
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.CanCollide = false
        barrel.Parent = handle

        local barrelWeld = Instance.new("WeldConstraint")
        barrelWeld.Part0 = handle
        barrelWeld.Part1 = barrel
        barrelWeld.Parent = handle

        barrel.CFrame = handle.CFrame * CFrame.new(0, 0.1, -1.2)

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.3, 0.2, 1.2)
    end

    return handle
end

function GameManager:CreateWeaponScript(weaponType)
    local script = Instance.new("LocalScript")
    script.Source = [[
        local tool = script.Parent
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        -- Wait for remote events to be available
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
        if not remoteEvents then
            warn("RemoteEvents not found!")
            return
        end

        local shootEvent = remoteEvents:WaitForChild("ShootEvent", 5)
        if not shootEvent then
            warn("ShootEvent not found!")
            return
        end

        local weaponStats = {
            AssaultRifle = {damage = 25, fireRate = 0.1, range = 500, ammo = 30},
            Pistol = {damage = 35, fireRate = 0.3, range = 300, ammo = 12}
        }

        local currentAmmo = weaponStats[tool.Name] and weaponStats[tool.Name].ammo or 30
        local canShoot = true

        -- Update ammo display
        local function updateAmmoDisplay()
            local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
            if gui and gui:FindFirstChild("HUD") then
                local ammoLabel = gui.HUD:FindFirstChild("AmmoLabel")
                if ammoLabel then
                    ammoLabel.Text = currentAmmo .. "/" .. (weaponStats[tool.Name] and weaponStats[tool.Name].ammo or 30)
                end
            end
        end

        tool.Activated:Connect(function()
            if canShoot and currentAmmo > 0 then
                canShoot = false
                currentAmmo = currentAmmo - 1

                -- Fire weapon
                shootEvent:FireServer(mouse.Hit.Position, tool.Name)

                -- Create muzzle flash effect
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    local flash = Instance.new("Explosion")
                    flash.Position = handle.Position + handle.CFrame.LookVector * 2
                    flash.BlastRadius = 5
                    flash.BlastPressure = 0
                    flash.Parent = workspace
                end

                -- Update ammo display
                updateAmmoDisplay()

                local fireRate = weaponStats[tool.Name] and weaponStats[tool.Name].fireRate or 0.1
                wait(fireRate)
                canShoot = true
            end
        end)

        -- Update ammo when tool is equipped
        tool.Equipped:Connect(function()
            updateAmmoDisplay()
        end)
    ]]

    return script
end

function GameManager:HandleShooting(player, targetPosition, weaponType)
    if not player.Character then return end

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Create raycast
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local raycastResult = workspace:Raycast(
        humanoidRootPart.Position,
        (targetPosition - humanoidRootPart.Position).Unit * 500,
        raycastParams
    )

    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitCharacter = hitPart.Parent

        -- Check if we hit another player
        if hitCharacter:FindFirstChild("Humanoid") then
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            if hitPlayer and hitPlayer ~= player then
                self:DamagePlayer(hitPlayer, player, weaponType)
            end
        end

        -- Create hit effect
        self:CreateHitEffect(raycastResult.Position)
    end
end

function GameManager:DamagePlayer(victim, attacker, weaponType)
    local character = victim.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local damage = 25 -- Default damage
    if weaponType == "AssaultRifle" then
        damage = 25
    elseif weaponType == "Pistol" then
        damage = 35
    end

    humanoid.Health = humanoid.Health - damage

    if humanoid.Health <= 0 then
        -- Player eliminated
        if gameState.players[attacker.UserId] then
            gameState.players[attacker.UserId].kills = gameState.players[attacker.UserId].kills + 1
        end
        if gameState.players[victim.UserId] then
            gameState.players[victim.UserId].deaths = gameState.players[victim.UserId].deaths + 1
        end

        print(attacker.Name .. " eliminated " .. victim.Name)
    end
end

function GameManager:CreateHitEffect(position)
    local effect = Instance.new("Explosion")
    effect.Position = position
    effect.BlastRadius = 2
    effect.BlastPressure = 0
    effect.Visible = false
    effect.Parent = workspace

    -- Create spark effect
    local spark = Instance.new("Part")
    spark.Size = Vector3.new(0.1, 0.1, 0.1)
    spark.Material = Enum.Material.Neon
    spark.BrickColor = BrickColor.new("Bright yellow")
    spark.Anchored = true
    spark.CanCollide = false
    spark.Position = position
    spark.Parent = workspace

    -- Remove spark after short time
    game:GetService("Debris"):AddItem(spark, 0.5)
end

function GameManager:StartGameLoop()
    gameState.isActive = true
    gameState.roundTime = GAME_CONFIG.ROUND_TIME

    RunService.Heartbeat:Connect(function()
        if gameState.isActive then
            gameState.roundTime = gameState.roundTime - RunService.Heartbeat:Wait()

            if gameState.roundTime <= 0 then
                self:EndRound()
            end
        end
    end)
end

function GameManager:EndRound()
    gameState.isActive = false
    print("Round ended!")

    -- Reset for next round
    wait(10)
    gameState.roundTime = GAME_CONFIG.ROUND_TIME
    gameState.isActive = true
end

-- Initialize the game
GameManager:InitializeGame()

return GameManager