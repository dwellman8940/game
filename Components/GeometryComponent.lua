local addonName, envTable = ...
setfenv(1, envTable)

GeometryComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function GeometryComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.vertices = {}

    local WIDTH = 50
    local HEIGHT = 10
    table.insert(self.vertices, CreateVector2(-WIDTH, -HEIGHT))
    --table.insert(self.vertices, CreateVector2(-SIZE * 2, 0))
    table.insert(self.vertices, CreateVector2(-WIDTH, HEIGHT))
    --table.insert(self.vertices, CreateVector2(-SIZE, SIZE * 5))
    --table.insert(self.vertices, CreateVector2(SIZE * 2, SIZE * 5))
    --table.insert(self.vertices, CreateVector2(0, SIZE * 1.5))
    table.insert(self.vertices, CreateVector2(WIDTH, HEIGHT))
    table.insert(self.vertices, CreateVector2(WIDTH, -HEIGHT))

    --table.insert(self.vertices, CreateVector2(SIZE * 2, -SIZE * 2))

    self.convexVertexLists = Polygon.ConcaveDecompose(self.vertices)
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

            --return
        end
    end
end

