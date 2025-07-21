-- Map Generator for Shooter Game
local MapGenerator = {}

function MapGenerator:CreateMap()
    local map = Instance.new("Folder")
    map.Name = "ShooterMap"
    map.Parent = workspace

    -- Create ground
    self:CreateGround(map)

    -- Create buildings and cover
    self:CreateBuildings(map)

    -- Create spawn points
    self:CreateSpawnPoints(map)

    print("Map generated successfully!")
end

function MapGenerator:CreateGround(parent)
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(500, 1, 500)
    ground.Position = Vector3.new(0, -0.5, 0)
    ground.Material = Enum.Material.Concrete
    ground.BrickColor = BrickColor.new("Medium stone grey")
    ground.Anchored = true
    ground.Parent = parent

    -- Add texture
    local texture = Instance.new("Texture")
    texture.Texture = "rbxasset://textures/terrain/concrete.png"
    texture.StudsPerTileU = 10
    texture.StudsPerTileV = 10
    texture.Face = Enum.NormalId.Top
    texture.Parent = ground
end

function MapGenerator:CreateBuildings(parent)
    local buildingsFolder = Instance.new("Folder")
    buildingsFolder.Name = "Buildings"
    buildingsFolder.Parent = parent

    -- Create several buildings for cover
    local buildingPositions = {
        Vector3.new(50, 10, 50),
        Vector3.new(-50, 10, 50),
        Vector3.new(50, 10, -50),
        Vector3.new(-50, 10, -50),
        Vector3.new(0, 5, 100),
        Vector3.new(0, 5, -100),
        Vector3.new(100, 5, 0),
        Vector3.new(-100, 5, 0)
    }

    for i, position in ipairs(buildingPositions) do
        self:CreateBuilding(buildingsFolder, position, i)
    end

    -- Create walls for cover
    self:CreateWalls(buildingsFolder)
end

function MapGenerator:CreateBuilding(parent, position, index)
    local building = Instance.new("Part")
    building.Name = "Building" .. index
    building.Size = Vector3.new(20, 20, 20)
    building.Position = position
    building.Material = Enum.Material.Brick
    building.BrickColor = BrickColor.new("Brick yellow")
    building.Anchored = true
    building.Parent = parent

    -- Add windows
    for face = 1, 4 do
        local window = Instance.new("Part")
        window.Name = "Window" .. face
        window.Size = Vector3.new(0.1, 8, 6)
        window.Material = Enum.Material.Glass
        window.BrickColor = BrickColor.new("Cyan")
        window.Transparency = 0.5
        window.Anchored = true
        window.CanCollide = false
        window.Parent = building

        if face == 1 then
            window.Position = position + Vector3.new(10, 0, 0)
        elseif face == 2 then
            window.Position = position + Vector3.new(-10, 0, 0)
        elseif face == 3 then
            window.Position = position + Vector3.new(0, 0, 10)
            window.Size = Vector3.new(6, 8, 0.1)
        else
            window.Position = position + Vector3.new(0, 0, -10)
            window.Size = Vector3.new(6, 8, 0.1)
        end
    end
end

function MapGenerator:CreateWalls(parent)
    local wallPositions = {
        {pos = Vector3.new(25, 2.5, 0), size = Vector3.new(1, 5, 30)},
        {pos = Vector3.new(-25, 2.5, 0), size = Vector3.new(1, 5, 30)},
        {pos = Vector3.new(0, 2.5, 25), size = Vector3.new(30, 5, 1)},
        {pos = Vector3.new(0, 2.5, -25), size = Vector3.new(30, 5, 1)},
    }

    for i, wallData in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = wallData.size
        wall.Position = wallData.pos
        wall.Material = Enum.Material.Concrete
        wall.BrickColor = BrickColor.new("Dark stone grey")
        wall.Anchored = true
        wall.Parent = parent
    end
end

function MapGenerator:CreateSpawnPoints(parent)
    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "SpawnPoints"
    spawnFolder.Parent = parent

    local spawnPositions = {
        Vector3.new(0, 5, 200),
        Vector3.new(0, 5, -200),
        Vector3.new(200, 5, 0),
        Vector3.new(-200, 5, 0),
        Vector3.new(150, 5, 150),
        Vector3.new(-150, 5, 150),
        Vector3.new(150, 5, -150),
        Vector3.new(-150, 5, -150)
    }

    for i, position in ipairs(spawnPositions) do
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "Spawn" .. i
        spawn.Size = Vector3.new(6, 1, 6)
        spawn.Position = position
        spawn.Material = Enum.Material.Neon
        spawn.BrickColor = BrickColor.new("Bright green")
        spawn.Anchored = true
        spawn.CanCollide = true
        spawn.TopSurface = Enum.SurfaceType.Smooth
        spawn.Parent = spawnFolder
    end
end

-- Generate the map
MapGenerator:CreateMap()

return MapGenerator