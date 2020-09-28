local addonName, envTable = ...
setfenv(1, envTable)

Level = {}

local levels = {}

function Level.RegisterLevelData(levelName, levelData)
    assert(levels[levelName] == nil)
    levels[levelName] = levelData
end

function Level.Load(owner, levelName)
    local levelData = levels[levelName]
    if levelData then
        for i, geometry in ipairs(levelData.Geometry) do
            local gameEntity = owner:CreateEntity(GameEntityMixin, nil, CreateVector2(geometry.WorldLocation.x, geometry.WorldLocation.y))
            CreateGameEntityComponent(GeometryComponentMixin, gameEntity, geometry.Vertices, geometry.Mobility, geometry.Occlusion)
        end
    end
end