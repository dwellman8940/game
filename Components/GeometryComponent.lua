local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GeometryComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function GeometryComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.vertices = {}

    local SIZE = 50
    table.insert(self.vertices, CreateVector2(-SIZE, -SIZE))
    table.insert(self.vertices, CreateVector2(-SIZE * 2, 0))
    table.insert(self.vertices, CreateVector2(-SIZE, SIZE))
    table.insert(self.vertices, CreateVector2(0, SIZE * 1.5))
    table.insert(self.vertices, CreateVector2(SIZE, SIZE))
    table.insert(self.vertices, CreateVector2(SIZE, -SIZE))

    --table.insert(self.vertices, CreateVector2(SIZE * 2, -SIZE * 2))
end

function GeometryComponentMixin:Destroy() -- override

    GameEntityComponentMixin.Destroy(self)
end

function GeometryComponentMixin:GetName()
    return "GeometryComponent"
end

function GeometryComponentMixin:GetVertices()
    return self.vertices
end

function GeometryComponentMixin:Render(delta) -- override
    Debug.DrawWorldVerts(self:GetWorldLocation(), self.vertices)
end

