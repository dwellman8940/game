local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_EnabledOcclusion = DebugViews.RegisterView("Occlusion", "Enabled Occlusion", true)
local DebugView_ShadowRays = DebugViews.RegisterView("Occlusion", "Shadow Rays")
local DebugView_ShadowMesh = DebugViews.RegisterView("Occlusion", "Shadow Mesh")

local DebugView_Time = DebugViews.RegisterProfileStatistic("Occlusion", "Time")

OcclusionComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function OcclusionComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)
end

function OcclusionComponentMixin:Destroy() -- override
    self:ReleaseAllTextures()
    GameEntityComponentMixin.Destroy(self)
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

local function AddShadowScreenVerts(shadowPolygon, worldBoundVertices, rayOrigin, leftRayDirection, rightRayDirection)
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

local function CreateConnectingVertices(rightVertIndex, leftVertIndex, vertices, shapeLocation, rayOrigin, worldBoundVertices)
    local shadowPolygon = {}

    AddShadowScreenVerts(shadowPolygon, worldBoundVertices, rayOrigin, shapeLocation + vertices[leftVertIndex] - rayOrigin, shapeLocation + vertices[rightVertIndex] - rayOrigin)

    local distance = rightVertIndex > leftVertIndex and (leftVertIndex + #vertices) - rightVertIndex or leftVertIndex - rightVertIndex
    local lastIndex = rightVertIndex + distance
    for vertIndex = rightVertIndex, rightVertIndex + distance do
        local effectiveIndex = Math.WrapIndex(vertIndex, #vertices)
        local vertex = shapeLocation + vertices[effectiveIndex]
        if vertIndex ~= lastIndex or not Polygon.AreVerticesTooClose(shadowPolygon[1], vertex) then
            Polygon.TryAddingVertex(shadowPolygon, vertex)
        end
    end

    return shadowPolygon
end

function OcclusionComponentMixin:Render(delta) -- override
    DebugView_Time:StartProfileCapture()

    self:ReleaseAllTextures()

    if not DebugView_EnabledOcclusion:IsViewEnabled() then
        DebugView_Time:EndProfileCapture()
        return
    end

    local rayOrigin = self:GetWorldLocation()

    local renderWorldBoundVertices = self:GetClient():GetRenderFrameWorldBoundVertices()
    local renderWorldBounds = self:GetClient():GetRenderFrameWorldBounds()

    local overlappingPhysicsShapes = self:GetPhysicsSystem():CalculateAllOverlaps(renderWorldBounds)

    for shapeIndex, shape in ipairs(overlappingPhysicsShapes) do
        if shape:GetGeometryComponent():GetOcclusionType() == GeometryOcclusion.Opaque then
            local shapeLocation = shape:GetWorldLocation()
            local vertexOrigin = shapeLocation - rayOrigin
            local vertices = shape:GetVertices()

            local clippedVertices = Polygon.ClipPolygon(vertices, Polygon.TranslatePolygon(renderWorldBoundVertices, -shapeLocation))
            local leftVertIndex, rightVertIndex
            local leftRay, rightRay

            for vertIndex, vertex in ipairs(clippedVertices) do
                local towards = vertexOrigin + vertex

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
                self:DrawShadowPolygon(CreateConnectingVertices(rightVertIndex, leftVertIndex, clippedVertices, shapeLocation, rayOrigin, renderWorldBoundVertices))

                if DebugView_ShadowRays:IsViewEnabled() then
                    Debug.DrawDebugLine(rayOrigin, rayOrigin + (shapeLocation + clippedVertices[leftVertIndex] - rayOrigin):GetNormal() * 1000, nil, Colors.Periwinkle, Colors.Periwinkle)
                    Debug.DrawDebugLine(rayOrigin, rayOrigin + (shapeLocation + clippedVertices[rightVertIndex] - rayOrigin):GetNormal() * 1000, nil, Colors.Black, Colors.Black)
                end
            end
        end
    end

    DebugView_Time:EndProfileCapture()
end

function OcclusionComponentMixin:DrawShadowPolygon(shadowPolygon)
    if not self.textureList then
        self.textureList = {}
    end

    if DebugView_ShadowMesh:IsViewEnabled() then
        Debug.DrawConvexTriangleMesh(ZeroVector, shadowPolygon)
    end

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
