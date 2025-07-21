v-- Advanced Weapon System
local WeaponSystem = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Weapon configurations
WeaponSystem.WeaponStats = {
    AssaultRifle = {
        damage = 25,
        fireRate = 0.1,
        range = 500,
        maxAmmo = 30,
        reloadTime = 2.5,
        accuracy = 0.95,
        recoil = 0.1
    },
    Pistol = {
        damage = 35,
        fireRate = 0.3,
        range = 300,
        maxAmmo = 12,
        reloadTime = 1.5,
        accuracy = 0.85,
        recoil = 0.15
    },
    Sniper = {
        damage = 80,
        fireRate = 1.0,
        range = 1000,
        maxAmmo = 5,
        reloadTime = 3.0,
        accuracy = 0.99,
        recoil = 0.3
    },
    SMG = {
        damage = 18,
        fireRate = 0.05,
        range = 250,
        maxAmmo = 40,
        reloadTime = 2.0,
        accuracy = 0.8,
        recoil = 0.2
    }
}

function WeaponSystem:CreateAdvancedWeapon(weaponType)
    local weapon = Instance.new("Tool")
    weapon.Name = weaponType
    weapon.RequiresHandle = true

    -- Create detailed weapon model
    local handle = self:CreateDetailedWeaponModel(weaponType)
    handle.Name = "Handle"
    handle.Parent = weapon

    -- Add weapon configuration
    local config = Instance.new("Configuration")
    config.Name = "WeaponConfig"
    config.Parent = weapon

    local stats = self.WeaponStats[weaponType]
    for statName, value in pairs(stats) do
        local stat = Instance.new("NumberValue")
        stat.Name = statName
        stat.Value = value
        stat.Parent = config
    end

    -- Add advanced weapon script
    local weaponScript = self:CreateAdvancedWeaponScript()
    weaponScript.Parent = weapon

    return weapon
end

function WeaponSystem:CreateDetailedWeaponModel(weaponType)
    local handle = Instance.new("Part")
    handle.CanCollide = false
    handle.Material = Enum.Material.Metal

    if weaponType == "AssaultRifle" then
        handle.Size = Vector3.new(0.4, 0.3, 2.5)
        handle.BrickColor = BrickColor.new("Really black")

        -- Create detailed parts
        self:AddWeaponParts(handle, {
            {name = "Barrel", size = Vector3.new(0.08, 0.08, 1.2), pos = Vector3.new(0, 0.1, -1.5), color = "Dark stone grey"},
            {name = "Stock", size = Vector3.new(0.3, 0.2, 0.8), pos = Vector3.new(0, -0.05, 1.2), color = "Brown"},
            {name = "Scope", size = Vector3.new(0.1, 0.15, 0.3), pos = Vector3.new(0, 0.2, -0.3), color = "Really black"},
            {name = "Magazine", size = Vector3.new(0.2, 0.8, 0.15), pos = Vector3.new(0, -0.4, 0.2), color = "Dark stone grey"}
        })

    elseif weaponType == "Pistol" then
        handle.Size = Vector3.new(0.25, 0.2, 1.0)
        handle.BrickColor = BrickColor.new("Dark stone grey")

        self:AddWeaponParts(handle, {
            {name = "Barrel", size = Vector3.new(0.06, 0.06, 0.4), pos = Vector3.new(0, 0.05, -0.6), color = "Really black"},
            {name = "Grip", size = Vector3.new(0.15, 0.4, 0.1), pos = Vector3.new(0, -0.2, 0.3), color = "Brown"}
        })

    elseif weaponType == "Sniper" then
        handle.Size = Vector3.new(0.3, 0.25, 3.5)
        handle.BrickColor = BrickColor.new("Dark green")

        self:AddWeaponParts(handle, {
            {name = "Barrel", size = Vector3.new(0.06, 0.06, 2.0), pos = Vector3.new(0, 0.08, -2.5), color = "Really black"},
            {name = "Stock", size = Vector3.new(0.25, 0.15, 1.0), pos = Vector3.new(0, -0.05, 1.5), color = "Brown"},
            {name = "Scope", size = Vector3.new(0.12, 0.2, 0.8), pos = Vector3.new(0, 0.25, -0.5), color = "Really black"},
            {name = "Bipod", size = Vector3.new(0.05, 0.3, 0.05), pos = Vector3.new(0, -0.2, -1.5), color = "Dark stone grey"}
        })

    elseif weaponType == "SMG" then
        handle.Size = Vector3.new(0.3, 0.25, 1.8)
        handle.BrickColor = BrickColor.new("Really black")

        self:AddWeaponParts(handle, {
            {name = "Barrel", size = Vector3.new(0.07, 0.07, 0.8), pos = Vector3.new(0, 0.08, -1.2), color = "Dark stone grey"},
            {name = "Stock", size = Vector3.new(0.2, 0.15, 0.6), pos = Vector3.new(0, -0.03, 1.0), color = "Really black"},
            {name = "Magazine", size = Vector3.new(0.15, 0.6, 0.12), pos = Vector3.new(0, -0.35, 0.1), color = "Dark stone grey"}
        })
    end

    return handle
end

function WeaponSystem:AddWeaponParts(handle, parts)
    for _, partData in ipairs(parts) do
        local part = Instance.new("Part")
        part.Name = partData.name
        part.Size = partData.size
        part.Material = Enum.Material.Metal
        part.BrickColor = BrickColor.new(partData.color)
        part.CanCollide = false
        part.Parent = handle

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = part
        weld.Parent = handle

        part.CFrame = handle.CFrame * CFrame.new(partData.pos.X, partData.pos.Y, partData.pos.Z)
    end
end

function WeaponSystem:CreateAdvancedWeaponScript()
    local script = Instance.new("LocalScript")
    script.Source = [[
        local tool = script.Parent
        local player = game.Players.LocalPlayer
        local mouse = player:GetMouse()
        local camera = workspace.CurrentCamera

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")
        local TweenService = game:GetService("TweenService")
        local SoundService = game:GetService("SoundService")

        -- Get weapon stats
        local config = tool:WaitForChild("WeaponConfig")
        local weaponStats = {}
        for _, stat in pairs(config:GetChildren()) do
            weaponStats[stat.Name] = stat.Value
        end

        -- Weapon state
        local currentAmmo = weaponStats.maxAmmo
        local canShoot = true
        local isReloading = false
        local isAiming = false

        -- Get remote events
        local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
        local shootEvent = remoteEvents:WaitForChild("ShootEvent")
        local reloadEvent = remoteEvents:WaitForChild("ReloadEvent")

        -- Sound effects
        local shootSound = Instance.new("Sound")
        shootSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        shootSound.Volume = 0.5
        shootSound.Parent = tool.Handle

        local reloadSound = Instance.new("Sound")
        reloadSound.SoundId = "rbxasset://sounds/switch3.wav"
        reloadSound.Volume = 0.3
        reloadSound.Parent = tool.Handle

        -- Muzzle flash effect
        local function createMuzzleFlash()
            local handle = tool.Handle
            local barrel = handle:FindFirstChild("Barrel") or handle

            local flash = Instance.new("Part")
            flash.Name = "MuzzleFlash"
            flash.Size = Vector3.new(0.2, 0.2, 0.5)
            flash.Material = Enum.Material.Neon
            flash.BrickColor = BrickColor.new("Bright yellow")
            flash.Anchored = true
            flash.CanCollide = false
            flash.Parent = workspace

            -- Position at barrel end
            flash.CFrame = barrel.CFrame * CFrame.new(0, 0, -barrel.Size.Z/2 - 0.3)

            -- Animate flash
            local flashTween = TweenService:Create(flash,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1, Size = Vector3.new(0.5, 0.5, 1)}
            )
            flashTween:Play()

            flashTween.Completed:Connect(function()
                flash:Destroy()
            end)
        end

        -- Weapon recoil
        local function applyRecoil()
            if not camera then return end

            local recoilAmount = weaponStats.recoil or 0.1
            local recoilX = (math.random() - 0.5) * recoilAmount * 2
            local recoilY = math.random() * recoilAmount

            local currentCFrame = camera.CFrame
            local recoilCFrame = currentCFrame * CFrame.Angles(-recoilY, recoilX, 0)

            local recoilTween = TweenService:Create(camera,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = recoilCFrame}
            )
            recoilTween:Play()

            -- Return to original position
            wait(0.05)
            local returnTween = TweenService:Create(camera,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = currentCFrame}
            )
            returnTween:Play()
        end

        -- Shooting function
        local function shoot()
            if not canShoot or currentAmmo <= 0 or isReloading then return end

            canShoot = false
            currentAmmo = currentAmmo - 1

            -- Apply accuracy
            local accuracy = weaponStats.accuracy or 0.9
            local spread = (1 - accuracy) * 10
            local targetPos = mouse.Hit.Position

            -- Add random spread
            targetPos = targetPos + Vector3.new(
                (math.random() - 0.5) * spread,
                (math.random() - 0.5) * spread,
                (math.random() - 0.5) * spread
            )

            -- Fire weapon
            shootEvent:FireServer(targetPos, tool.Name)

            -- Effects
            shootSound:Play()
            createMuzzleFlash()
            applyRecoil()

            -- Update GUI
            local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
            if gui then
                local ammoLabel = gui:FindFirstChild("HUD"):FindFirstChild("AmmoLabel")
                if ammoLabel then
                    ammoLabel.Text = currentAmmo .. "/" .. weaponStats.maxAmmo
                end
            end

            wait(weaponStats.fireRate or 0.1)
            canShoot = true
        end

        -- Reload function
        local function reload()
            if isReloading or currentAmmo >= weaponStats.maxAmmo then return end

            isReloading = true
            reloadSound:Play()

            -- Show reload animation
            local gui = player.PlayerGui:FindFirstChild("ShooterGameGUI")
            if gui then
                local ammoLabel = gui:FindFirstChild("HUD"):FindFirstChild("AmmoLabel")
                if ammoLabel then
                    ammoLabel.Text = "RELOADING..."
                end
            end

            wait(weaponStats.reloadTime or 2.0)

            currentAmmo = weaponStats.maxAmmo
            isReloading = false

            -- Update GUI
            if gui then
                local ammoLabel = gui:FindFirstChild("HUD"):FindFirstChild("AmmoLabel")
                if ammoLabel then
                    ammoLabel.Text = currentAmmo .. "/" .. weaponStats.maxAmmo
                end
            end
        end

        -- Aiming function
        local function toggleAim()
            isAiming = not isAiming

            if isAiming then
                -- Zoom in
                camera.FieldOfView = 30
            else
                -- Zoom out
                camera.FieldOfView = 70
            end
        end

        -- Tool events
        tool.Activated:Connect(shoot)

        -- Input handling
        tool.Equipped:Connect(function()
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end

                if input.KeyCode == Enum.KeyCode.R then
                    reload()
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    toggleAim()
                end
            end)

            UserInputService.InputEnded:Connect(function(input, gameProcessed)
                if gameProcessed then return end

                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    if isAiming then
                        toggleAim()
                    end
                end
            end)
        end)

        tool.Unequipped:Connect(function()
            if isAiming then
                camera.FieldOfView = 70
                isAiming = false
            end
        end)
    ]]

    return script
end

return WeaponSystem
