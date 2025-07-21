-- Game Manager (ServerScript) - Fixed Version
print("GameManager starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create RemoteEvents IMMEDIATELY when script starts
print("Creating RemoteEvents...")

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

print("RemoteEvents created successfully!")

-- Game Configuration
local GAME_CONFIG = {
    MAX_PLAYERS = 12,
    ROUND_TIME = 300,
    RESPAWN_TIME = 5,
    MAX_HEALTH = 100
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
        score = 0
    }

    -- Setup character when spawned
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Wait for character to load
        self:SetupPlayerCharacter(player, character)
    end)

    -- Handle existing character
    if player.Character then
        wait(2)
        self:SetupPlayerCharacter(player, player.Character)
    end
end

function GameManager:SetupPlayerCharacter(player, character)
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.MaxHealth = GAME_CONFIG.MAX_HEALTH
    humanoid.Health = GAME_CONFIG.MAX_HEALTH

    -- Give weapon after short delay
    wait(1)
    if player.Character == character then
        self:GiveWeapon(player, "AssaultRifle")
    end
end

function GameManager:CreateWeaponModel(weaponType)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.CanCollide = false
    handle.Material = Enum.Material.Metal
    handle.BrickColor = BrickColor.new("Dark stone grey")

    -- Different models for different weapons
    if weaponType == "AssaultRifle" then
        handle.Size = Vector3.new(0.4, 0.3, 2.5)

        -- Create barrel
        local barrel = Instance.new("Part")
        barrel.Name = "Barrel"
        barrel.Size = Vector3.new(0.1, 0.1, 1.2)
        barrel.Material = Enum.Material.Metal
        barrel.BrickColor = BrickColor.new("Really black")
        barrel.CanCollide = false
        barrel.Parent = handle

        local barrelWeld = Instance.new("WeldConstraint")
        barrelWeld.Part0 = handle
        barrelWeld.Part1 = barrel
        barrelWeld.Parent = handle

        -- Position barrel
        barrel.CFrame = handle.CFrame * CFrame.new(0, 0.1, -0.8)

        -- Create stock
        local stock = Instance.new("Part")
        stock.Name = "Stock"
        stock.Size = Vector3.new(0.3, 0.2, 1.0)
        stock.Material = Enum.Material.Wood
        stock.BrickColor = BrickColor.new("Brown")
        stock.CanCollide = false
        stock.Parent = handle

        local stockWeld = Instance.new("WeldConstraint")
        stockWeld.Part0 = handle
        stockWeld.Part1 = stock
        stockWeld.Parent = handle

        stock.CFrame = handle.CFrame * CFrame.new(0, -0.1, 0.8)

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.3, 0.2, 1.2)
        handle.BrickColor = BrickColor.new("Really black")

    elseif weaponType == "SniperRifle" then
        handle.Size = Vector3.new(0.3, 0.3, 3.5)

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
    if not player.Character then return end

    local weapon = Instance.new("Tool")
    weapon.Name = weaponType
    weapon.RequiresHandle = true

    -- Create weapon model
    local handle = self:CreateWeaponModel(weaponType)
    handle.Parent = weapon

    -- Add weapon script
    local weaponScript = Instance.new("LocalScript")
    weaponScript.Source = [[
        local tool = script.Parent
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
        local shootEvent = remoteEvents:WaitForChild("ShootEvent")

        local currentAmmo = 30
        local maxAmmo = 30
        local canShoot = true

        -- Update ammo display
        local function updateAmmoDisplay()
            local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
            if gui and gui:FindFirstChild("HUD") then
                local ammoFrame = gui.HUD:FindFirstChild("AmmoFrame")
                if ammoFrame then
                    local ammoLabel = ammoFrame:FindFirstChild("AmmoLabel")
                    if ammoLabel then
                        ammoLabel.Text = currentAmmo .. "/" .. maxAmmo
                    end
                end
            end
        end

        -- Shooting function
        tool.Activated:Connect(function()
            if canShoot and currentAmmo > 0 then
                canShoot = false
                currentAmmo = currentAmmo - 1

                -- Fire weapon
                shootEvent:FireServer(mouse.Hit.Position, tool.Name)

                -- Create muzzle flash
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    local flash = Instance.new("Part")
                    flash.Size = Vector3.new(0.2, 0.2, 0.5)
                    flash.Material = Enum.Material.Neon
                    flash.BrickColor = BrickColor.new("Bright yellow")
                    flash.Anchored = true
                    flash.CanCollide = false
                    flash.Position = handle.Position + handle.CFrame.LookVector * 2
                    flash.Parent = workspace

                    -- Remove flash
                    game:GetService("Debris"):AddItem(flash, 0.1)
                end

                -- Update ammo
                updateAmmoDisplay()

                -- Fire rate delay
                wait(0.1)
                canShoot = true
            end
        end)

        -- Update ammo when equipped
        tool.Equipped:Connect(function()
            updateAmmoDisplay()
        end)
    ]]
    weaponScript.Parent = weapon

    weapon.Parent = player.Backpack
    print("Gave " .. weaponType .. " to " .. player.Name)
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

    local direction = (targetPosition - humanoidRootPart.Position).Unit * 500
    local raycastResult = workspace:Raycast(humanoidRootPart.Position, direction, raycastParams)

    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitCharacter = hitPart.Parent

        -- Check if hit another player
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

    -- Weapon damage values
    local weaponDamage = {
        AssaultRifle = 25,
        Pistol = 35,
        SniperRifle = 80,
        SMG = 20
    }

    local damage = weaponDamage[weaponType] or 25
    humanoid.Health = humanoid.Health - damage

    if humanoid.Health <= 0 then
        -- Player eliminated
        if gameState.players[attacker.UserId] then
            gameState.players[attacker.UserId].kills = gameState.players[attacker.UserId].kills + 1
        end
        if gameState.players[victim.UserId] then
            gameState.players[victim.UserId].deaths = gameState.players[victim.UserId].deaths + 1
        end

        print(attacker.Name .. " eliminated " .. victim.Name .. " with " .. weaponType)
    end
end

function GameManager:CreateHitEffect(position)
    -- Create spark effect
    local spark = Instance.new("Part")
    spark.Name = "HitSpark"
    spark.Size = Vector3.new(0.2, 0.2, 0.2)
    spark.Material = Enum.Material.Neon
    spark.BrickColor = BrickColor.new("Bright yellow")
    spark.Anchored = true
    spark.CanCollide = false
    spark.Shape = Enum.PartType.Ball
    spark.Position = position
    spark.Parent = workspace

    -- Create light
    local light = Instance.new("PointLight")
    light.Brightness = 1
    light.Color = Color3.new(1, 1, 0)
    light.Range = 5
    light.Parent = spark

    -- Remove effect
    game:GetService("Debris"):AddItem(spark, 0.3)
end

-- Connect events
shootEvent.OnServerEvent:Connect(function(player, targetPosition, weaponType)
    GameManager:HandleShooting(player, targetPosition, weaponType)
end)

-- Connect player events
Players.PlayerAdded:Connect(function(player)
    GameManager:OnPlayerJoined(player)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    GameManager:OnPlayerJoined(player)
end

print("GameManager initialized successfully!")

