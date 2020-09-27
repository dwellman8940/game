local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_RawVertices = DebugViews.RegisterView("GeometryComponent", "Raw Vertices")
local DebugView_ConvexVertices = DebugViews.RegisterView("GeometryComponent", "Convex Vertices")

GeometryComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function GeometryComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.vertices = {}

    local WIDTH = 50
    local HEIGHT = 50
    table.insert(self.vertices, CreateVector2(-WIDTH, -HEIGHT))
    --table.insert(self.vertices, CreateVector2(-WIDTH * 2, 0))
    table.insert(self.vertices, CreateVector2(-WIDTH, HEIGHT))
    --table.insert(self.vertices, CreateVector2(-WIDTH, HEIGHT * 5))
    --table.insert(self.vertices, CreateVector2(WIDTH * 2, HEIGHT * 5))
    --table.insert(self.vertices, CreateVector2(0, WIDTH * 1.5))
    table.insert(self.vertices, CreateVector2(WIDTH, HEIGHT))
    table.insert(self.vertices, CreateVector2(WIDTH, -HEIGHT))

    --table.insert(self.vertices, CreateVector2(WIDTH * 2, -HEIGHT * 2))

    self.convexVertexLists = Polygon.ConcaveDecompose(self.vertices)

    self:GetPhysicsSystem():RegisterStaticGeometryList(self:GetWorldLocation(), self.convexVertexLists)
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

function GeometryComponentMixin:GetVertices()
    return self.vertices
end

function GeometryComponentMixin:GetConvexVertexList()
    return self.convexVertexLists
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
    
    if not self.textureList then
        self.textureList = {}
        for i, vertices in ipairs(self.convexVertexLists) do
            local numTextures = Rendering.GetNumTexturesRequiredForConvexTriangleMesh(#vertices)
            local textures = Pools.Texture.AcquireWorldTextureArray(numTextures)
            table.insert(self.textureList, textures)
            
            for i, texture in ipairs(textures) do
                texture:SetColorTexture(1, 1, 0, .8)
                texture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(20))
                texture:Show()
            end

            Rendering.DrawConvexTriangleMesh(self:GetWorldLocation(), vertices, textures)

            for i, vertex in ipairs(vertices) do
                local fontString = Pools.FontString.AcquireWorldFontString()
                fontString:SetFontObject("GameFontNormal")
                fontString:SetText(i)
                Rendering.DrawAtWorldPoint(fontString, self:GetWorldLocation() + vertex)
                --fontString:Show()
            end
        end
    end
end

