-- Particle Effects System
local EffectsSystem = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

function EffectsSystem:CreateBulletTrail(startPos, endPos)
    local trail = Instance.new("Part")
    trail.Name = "BulletTrail"
    trail.Size = Vector3.new(0.05, 0.05, (startPos - endPos).Magnitude)
    trail.Material = Enum.Material.Neon
    trail.BrickColor = BrickColor.new("Bright yellow")
    trail.Anchored = true
    trail.CanCollide = false
    trail.Parent = workspace

    -- Position trail between start and end
    trail.CFrame = CFrame.new((startPos + endPos) / 2, endPos)

    -- Fade out trail
    local fadeTween = TweenService:Create(trail,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 1}
    )
    fadeTween:Play()

    fadeTween.Completed:Connect(function()
        trail:Destroy()
    end)
end

function EffectsSystem:CreateExplosionEffect(position, size)
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = size or 10
    explosion.BlastPressure = 0
    explosion.Parent = workspace

    -- Add particle effect
    local particles = Instance.new("Part")
    particles.Size = Vector3.new(0.1, 0.1, 0.1)
    particles.Transparency = 1
    particles.Anchored = true
    particles.CanCollide = false
    particles.Position = position
    particles.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Parent = particles

    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    particleEmitter.Lifetime = NumberRange.new(0.5, 1.5)
    particleEmitter.Rate = 100
    particleEmitter.SpreadAngle = Vector2.new(45, 45)
    particleEmitter.Speed = NumberRange.new(10, 20)
    particleEmitter.Parent = attachment

    -- Clean up after 3 seconds
    Debris:AddItem(particles, 3)
end

function EffectsSystem:CreateBloodEffect(position)
    local blood = Instance.new("Part")
    blood.Size = Vector3.new(0.1, 0.1, 0.1)
    blood.Transparency = 1
    blood.Anchored = true
    blood.CanCollide = false
    blood.Position = position
    blood.Parent = workspace

    local attachment = Instance.new("Attachment")
    attachment.Parent = blood

    local bloodEmitter = Instance.new("ParticleEmitter")
    bloodEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    bloodEmitter.Color = ColorSequence.new(Color3.new(0.8, 0, 0))
    bloodEmitter.Lifetime = NumberRange.new(0.3, 0.8)
    bloodEmitter.Rate = 50
    bloodEmitter.SpreadAngle = Vector2.new(30, 30)
    bloodEmitter.Speed = NumberRange.new(5, 15)
    bloodEmitter.Parent = attachment

    -- Stop emitting after short burst
    wait(0.1)
    bloodEmitter.Enabled = false

    Debris:AddItem(blood, 2)
end

return EffectsSystem