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

    if false then
        local UnionPolygonsA = {}
        for i, v in ipairs(Game_Debug.UnionPolygonsA) do
            table.insert(UnionPolygonsA, CreateVector2(v.x, v.y))
        end

        local UnionPolygonsB = {}
        for i, v in ipairs(Game_Debug.UnionPolygonsB) do
            table.insert(UnionPolygonsB, CreateVector2(v.x, v.y))
        end

        Debug.DrawWorldVerts(ZeroVector, UnionPolygonsA, 15, .2, .2, .2, .2, .2, .2)
        Debug.DrawWorldVerts(ZeroVector, UnionPolygonsB, 15, .2, .2, .5, .2, .2, .5)

        local unionPoly = Polygon.UnionPolygons(UnionPolygonsA, UnionPolygonsB)
        Debug.DrawWorldVertsWithIndices(ZeroVector, unionPoly)
        --Debug.DrawWorldVerts(ZeroVector, unionPoly, 15, .2, .2, .5, .2, .2, .5)

        --do return end

        if false then
            local decompTest = Polygon.ConcaveDecompose(unionPoly)
            for i, d in ipairs(decompTest) do
                Debug.Print("Decomp", i)
                Debug.DrawWorldVertsWithIndices(ZeroVector, d)
                for j, v in ipairs(d) do
                    Debug.Print("     ", j, v)
                end
            end
        end

        do return end

        local SIZE_A = 50
        local offsetA = CreateVector2(0, 0)
        local testPolyA = {
            CreateVector2(-SIZE_A, -SIZE_A) + offsetA,
            CreateVector2(-SIZE_A, SIZE_A) + offsetA,
            CreateVector2(SIZE_A, SIZE_A) + offsetA,
            CreateVector2(SIZE_A, -SIZE_A) + offsetA,
        }

        local SIZE_B = 75
        local offsetB = self:GetClient():GetWorldCursorLocation()
        local testPolyB = {
            CreateVector2(-SIZE_B, -SIZE_B) + offsetB,
            CreateVector2(-SIZE_B * 2, 0) + offsetB,
            CreateVector2(-SIZE_B, SIZE_B) + offsetB,
            CreateVector2(SIZE_B, SIZE_B) + offsetB,
            CreateVector2(SIZE_B, -SIZE_B) + offsetB,
        }


        local unionPoly = Polygon.UnionPolygons(testPolyA, testPolyB)

        if unionPoly then
            Debug.DrawWorldVertsWithIndices(ZeroVector, unionPoly)
            self:DrawShadowPolygon(unionPoly)
        else
            Debug.DrawWorldVertsWithIndices(ZeroVector, testPolyA)
            Debug.DrawWorldVertsWithIndices(ZeroVector, testPolyB)
        end

        do return end
    end

    local worldBoundVertices = self:GetClient():GetRenderFrameWorldBoundVertices()
    --Debug.DrawWorldVerts(ZeroVector, worldBoundVertices)

    local shadowPolygons = {}

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
                table.insert(shadowPolygons, CreateConnectingVertices(rightVertIndex, leftVertIndex, clippedVertices, geometryComponentLocation, rayOrigin, worldBoundVertices))

                --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + clippedVertices[leftVertIndex] - rayOrigin):GetNormal() * 1000, nil, .8, .8, 1, .8, .8, 1)
                --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + clippedVertices[rightVertIndex] - rayOrigin):GetNormal() * 1000, nil, 0, 0, 0, 0, 0, 0)
            end

            if listIndex == 2 then
                break
            end
        end
    end


    for i, shadowPolygon in ipairs(shadowPolygons) do
        --self:DrawShadowPolygon(shadowPolygon)
    end

    local finalShadowPolygon = shadowPolygons[1]
    for i = 2, #shadowPolygons do
        finalShadowPolygon = Polygon.UnionPolygons(finalShadowPolygon, shadowPolygons[i])
        if finalShadowPolygon then
            Debug.DrawWorldVertsWithIndices(ZeroVector, finalShadowPolygon)
            --self:DrawShadowPolygon(finalShadowPolygon)
        else
            Debug.DrawWorldVerts(ZeroVector, shadowPolygons[1])
            Debug.DrawWorldVerts(ZeroVector, shadowPolygons[i])
            --self:DrawShadowPolygon(shadowPolygons[1])
            --self:DrawShadowPolygon(shadowPolygons[i])
        end
    end
    if finalShadowPolygon then
        --self:DrawShadowPolygon(finalShadowPolygon)
    end
end

function OcclusionComponentMixin:DrawShadowPolygon(shadowPolygon)
    --Debug.DrawWorldVerts(ZeroVector, shadowPolygon)
    if not self.textureList then
        self.textureList = {}
    end

    --for i, vertices in ipairs({shadowPolygon}) do
    for i, vertices in ipairs(Polygon.ConcaveDecompose(shadowPolygon)) do
        for j, vertex in ipairs(vertices) do
            --Debug.DrawWorldString(worldLocation + vertex, j)
        end
        Debug.DrawConvexTriangleMesh(ZeroVector, vertices)
        local numTextures = Rendering.GetNumTexturesRequiredForConvexTriangleMesh(#vertices)
        local textures = Pools.Texture.AcquireWorldTextureArray(numTextures)
        table.insert(self.textureList, textures)
        
        for i, texture in ipairs(textures) do
            texture:SetTexture("Interface/Addons/Game/Assets/Textures/fog")
            texture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(22))
            texture:Show()
        end

        Rendering.DrawConvexTriangleMesh(ZeroVector, vertices, textures)
    end
end
