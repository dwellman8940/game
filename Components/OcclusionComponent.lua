local addonName, envTable = ...
setfenv(1, envTable)

OcclusionComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function OcclusionComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.geometryComponents = {}
end

function OcclusionComponentMixin:Destroy() -- override
    self:ReleaseAllTextures()
    GameEntityComponentMixin.Destroy(self)
end

function OcclusionComponentMixin:AddGeometry(geometryComponent)
    table.insert(self.geometryComponents, geometryComponent)
end

function OcclusionComponentMixin:ReleaseAllTextures()
    if self.textureList then
        for i, textures in ipairs(self.textureList) do
            Pools.Texture.ReleaseWorldTextureArray(textures)
        end
        self.textureList = nil
    end
end

function OcclusionComponentMixin:GetName()
    return "OcclusionComponent"
end

local function AddShadowScreenVerts(shadowPolygon, worldBoundVertices, rayOrigin, leftRayDirection, rightRayDirection, slop)
    for leftVertexIndex, leftVertex in ipairs(worldBoundVertices) do
        local nextLeftVertex = worldBoundVertices[leftVertexIndex == #worldBoundVertices and 1 or leftVertexIndex + 1]
        local leftIntersection = Math.CalculateRayLineIntersection(rayOrigin, leftRayDirection, leftVertex, nextLeftVertex)

        if leftIntersection then
            Polygon.TryAddingVertex(shadowPolygon, leftIntersection)
            for rightVertexIndex in ipairs(worldBoundVertices) do
                local effectiveRightIndex = Math.WrapIndex(leftVertexIndex + rightVertexIndex - 1, #worldBoundVertices)
                
                local rightVertex = worldBoundVertices[effectiveRightIndex]
                local nextRightVertex = worldBoundVertices[effectiveRightIndex == #worldBoundVertices and 1 or effectiveRightIndex + 1]
                local rightIntersection = Math.CalculateRayLineIntersection(rayOrigin, rightRayDirection, rightVertex, nextRightVertex)
                if rightIntersection then
                    if effectiveRightIndex ~= leftVertexIndex then
                        Polygon.TryAddingVertex(shadowPolygon, rightVertex)
                    end
                    Polygon.TryAddingVertex(shadowPolygon, rightIntersection)
                    return
                end
                Polygon.TryAddingVertex(shadowPolygon, nextRightVertex)
            end
        end
    end
end

local function CreateConnectingVertices(rightVertIndex, leftVertIndex, vertices, geometryComponentLocation, rayOrigin, worldBoundVertices)
    local shadowPolygon = {}

    AddShadowScreenVerts(shadowPolygon, worldBoundVertices, rayOrigin, geometryComponentLocation + vertices[leftVertIndex] - rayOrigin, geometryComponentLocation + vertices[rightVertIndex] - rayOrigin)

    local distance = rightVertIndex > leftVertIndex and (leftVertIndex + #vertices) - rightVertIndex or leftVertIndex - rightVertIndex
    local lastIndex = rightVertIndex + distance
    for vertIndex = rightVertIndex, rightVertIndex + distance do
        local effectiveIndex = Math.WrapIndex(vertIndex, #vertices)
        local vertex = geometryComponentLocation + vertices[effectiveIndex]
        if vertIndex ~= lastIndex or not Polygon.AreVerticesTooClose(shadowPolygon[1], vertex) then
            Polygon.TryAddingVertex(shadowPolygon, vertex)
        end
    end

    return shadowPolygon
end

function OcclusionComponentMixin:Render(delta) -- override
    self:ReleaseAllTextures()

    local worldBoundVertices = self:GetClient():GetRenderFrameWorldBoundVertices()
    --Debug.DrawWorldVerts(ZeroVector, worldBoundVertices)

    local rayOrigin = self:GetWorldLocation()
    for componentIndex, geometryComponent in ipairs(self.geometryComponents) do
        local geometryComponentLocation = geometryComponent:GetWorldLocation()
        local vertexOrigin = geometryComponentLocation - rayOrigin

        local convexVertexList = geometryComponent:GetConvexVertexList()
        for listIndex, vertices in ipairs(convexVertexList) do
            local clippedVertices = Polygon.ClipPolygon(vertices, Polygon.TranslatePolygon(worldBoundVertices, -geometryComponentLocation))
            local leftVertIndex, rightVertIndex
            local leftRay, rightRay

            for vertIndex, vertex in ipairs(clippedVertices) do
                local towards = vertexOrigin + vertex

                --Debug.DrawDebugLine(rayOrigin, geometryComponentLocation + vertex, 30, 1, 1, 1, 1, 1, 1)

                if not leftVertIndex then
                    leftVertIndex = vertIndex
                    rightVertIndex = vertIndex

                    leftRay = towards
                    rightRay = towards
                else
                    if towards:IsLeftOf(leftRay) then
                        leftVertIndex = vertIndex
                        leftRay = towards
                    end

                    if not towards:IsLeftOf(rightRay) then
                        rightVertIndex = vertIndex
                        rightRay = towards
                    end
                end
            end

            if leftVertIndex then
                self:DrawShadowPolygon(CreateConnectingVertices(rightVertIndex, leftVertIndex, clippedVertices, geometryComponentLocation, rayOrigin, worldBoundVertices))

                --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + clippedVertices[leftVertIndex] - rayOrigin):GetNormal() * 1000, nil, .8, .8, 1, .8, .8, 1)
                --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + clippedVertices[rightVertIndex] - rayOrigin):GetNormal() * 1000, nil, 0, 0, 0, 0, 0, 0)
            end
        end
    end
end

function OcclusionComponentMixin:DrawShadowPolygon(shadowPolygon)
    --Debug.DrawWorldVerts(ZeroVector, shadowPolygon)
    if not self.textureList then
        self.textureList = {}
    end

    --Debug.DrawConvexTriangleMesh(ZeroVector, vertices)
    local numTextures = Rendering.GetNumTexturesRequiredForConvexTriangleMesh(#shadowPolygon)
    local textures = Pools.Texture.AcquireWorldTextureArray(numTextures)
    table.insert(self.textureList, textures)
    
    for i, texture in ipairs(textures) do
        texture:SetTexture("Interface/Addons/Game/Assets/Textures/fog")
        texture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(22))
        texture:Show()
    end

    Rendering.DrawConvexTriangleMesh(ZeroVector, shadowPolygon, textures)
end
