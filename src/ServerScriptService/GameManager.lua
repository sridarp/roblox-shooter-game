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

-- Game Manager object
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

function GameManager:GiveWeapon(player, weaponType)
    if not player.Character then return end

    local weapon = Instance.new("Tool")
    weapon.Name = weaponType
    weapon.RequiresHandle = true

    -- Create weapon handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 0.3, 2.5)
    handle.Material = Enum.Material.Metal
    handle.BrickColor = BrickColor.new("Dark stone grey")
    handle.CanCollide = false
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

    -- Simple raycast
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
                -- Damage player
                local humanoid = hitCharacter.Humanoid
                humanoid.Health = humanoid.Health - 25

                if humanoid.Health <= 0 then
                    print(player.Name .. " eliminated " .. hitPlayer.Name)
                    if gameState.players[player.UserId] then
                        gameState.players[player.UserId].kills = gameState.players[player.UserId].kills + 1
                    end
                end
            end
        end

        -- Create hit effect
        local hitEffect = Instance.new("Explosion")
        hitEffect.Position = raycastResult.Position
        hitEffect.BlastRadius = 5
        hitEffect.BlastPressure = 0
        hitEffect.Parent = workspace
    end
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

