local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_RawVertices = DebugViews.RegisterView("GeometryComponent", "Raw Vertices")
local DebugView_ConvexVertices = DebugViews.RegisterView("GeometryComponent", "Convex Vertices")
local DebugView_ConvexIndices = DebugViews.RegisterView("GeometryComponent", "Convex Indices")

GeometryComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function GeometryComponentMixin:Initialize(owningEntity, vertices, isDynamicShape) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.vertices = vertices

    self.convexVertexLists = Polygon.ConcaveDecompose(self.vertices)
    self.isDynamicShape = isDynamicShape

    self.bounds = Polygon.CalculateBoundsFromMultiple(self.convexVertexLists)

    if self.isDynamicShape then
        assert(#self.convexVertexLists == 1)
        self.dynamicPhysicsShape = self:GetPhysicsSystem():RegisterDynamicGeometry(self:GetWorldLocation(), self.convexVertexLists[1])
    else
        self:GetPhysicsSystem():RegisterStaticGeometryList(self:GetWorldLocation(), self.convexVertexLists)
    end
end

function GeometryComponentMixin:Destroy() -- override
    if self.textureList then
        for i, textures in ipairs(self.textureList) do
            Pools.Texture.ReleaseWorldTextureArray(textures)
        end
        self.textureList = nil
    end

    GameEntityComponentMixin.Destroy(self)
end

function GeometryComponentMixin:GetName()
    return "GeometryComponent"
end

function GeometryComponentMixin:GetBounds()
    return self.bounds
end

function GeometryComponentMixin:GetWorldBounds()
    return self.bounds:Translate(self:GetWorldLocation())
end

function GeometryComponentMixin:GetVertices()
    return self.vertices
end

function GeometryComponentMixin:GetConvexVertexList()
    return self.convexVertexLists
end

function GeometryComponentMixin:GetDynamicPhysicsShape()
    return self.dynamicPhysicsShape
end

function GeometryComponentMixin:CollideWithStatic(worldLocation)
    assert(self.isDynamicShape and self.dynamicPhysicsShape)
    return self:GetPhysicsSystem():CollideShapeWithStatic(worldLocation, self.dynamicPhysicsShape)
end

function GeometryComponentMixin:TickClient(delta) -- override
    if self.isDynamicShape then
        self.dynamicPhysicsShape:SetWorldLocation(self:GetWorldLocation())
    end
end

function GeometryComponentMixin:Render(delta) -- override
    if DebugView_RawVertices:IsViewEnabled() then
        Debug.DrawWorldVertsWithIndices(self:GetWorldLocation(), self:GetVertices())
    end
    if DebugView_ConvexVertices:IsViewEnabled() then
        for i, vertices in ipairs(self:GetConvexVertexList()) do
            Debug.DrawConvexTriangleMesh(self:GetWorldLocation(), vertices)
        end
    end
    if DebugView_ConvexIndices:IsViewEnabled() then
        for i, vertices in ipairs(self:GetConvexVertexList()) do
            for j, vertex in ipairs(vertices) do
                Debug.DrawWorldString(self:GetWorldLocation() + vertex, j)
            end
        end
    end

    if self.isDynamicShape then
        return
    end

    if self.textureList then
        if self.isDynamicShape then
            for i, vertices in ipairs(self:GetConvexVertexList()) do
                Rendering.DrawConvexTriangleMesh(self:GetWorldLocation(), vertices, self.textureList[i])
            end
        end
    else
        self.textureList = {}
        for i, vertices in ipairs(self:GetConvexVertexList()) do
            local numTextures = Rendering.GetNumTexturesRequiredForConvexTriangleMesh(#vertices)
            local textures = Pools.Texture.AcquireWorldTextureArray(numTextures)
            table.insert(self.textureList, textures)
            
            for j, texture in ipairs(textures) do
                texture:SetColorTexture(1, 1, 0, .8)
                texture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(20))
                texture:Show()
            end

            Rendering.DrawConvexTriangleMesh(self:GetWorldLocation(), vertices, textures)
        end
    end
end

