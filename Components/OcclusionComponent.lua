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

function OcclusionComponentMixin:Render(delta) -- override
    self:ReleaseAllTextures()

    local rayOrigin = self:GetWorldLocation()
    for componentIndex, geometryComponent in ipairs(self.geometryComponents) do
        local geometryComponentLocation = geometryComponent:GetWorldLocation()
        local vertexOrigin = geometryComponentLocation - rayOrigin

        local convexVertexList = geometryComponent:GetConvexVertexList()
        for listIndex, vertices in ipairs(convexVertexList) do
            local leftVertIndex, rightVertIndex
            local leftRay, rightRay

            for vertIndex, vertex in ipairs(vertices) do
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

            local shadowPolygon = {}
            -- TODO: intersect with window edges
            local distance = rightVertIndex > leftVertIndex and (leftVertIndex + #vertices) - rightVertIndex or leftVertIndex - rightVertIndex
            table.insert(shadowPolygon, vertices[leftVertIndex] + (geometryComponentLocation + vertices[leftVertIndex] - rayOrigin):GetNormal() * 2000)
            for vertIndex = leftVertIndex, leftVertIndex - distance, -1 do
                local effectiveIndex = (vertIndex - 1) % #vertices + 1
                table.insert(shadowPolygon, vertices[effectiveIndex])
            end
            table.insert(shadowPolygon, vertices[rightVertIndex] + (geometryComponentLocation + vertices[rightVertIndex] - rayOrigin):GetNormal() * 2000)


            self:DrawShadowPolygon(geometryComponentLocation, shadowPolygon)

            --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + vertices[leftVertIndex] - rayOrigin):GetNormal() * 1000, nil, .8, .8, 1, .8, .8, 1)
            --Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + vertices[rightVertIndex] - rayOrigin):GetNormal() * 1000, nil, 0, 0, 0, 0, 0, 0)
            --return
        end
    end
end

function OcclusionComponentMixin:DrawShadowPolygon(worldLocation, shadowPolygon)
    --Debug.DrawWorldVerts(worldLocation, shadowPolygon)
    if not self.textureList then
        self.textureList = {}
    end

    -- TODO: Fix needing to reverse winding, build it in the correct order
    local function Reverse(t)
        local r = {}
        for i = #t, 1, -1 do
            table.insert(r, t[i])
        end
        return r
    end

    --for i, vertices in ipairs({shadowPolygon}) do
    for i, vertices in ipairs(Polygon.ConcaveDecompose(Reverse(shadowPolygon))) do
        local numTextures = Rendering.GetNumTexturesRequiredForConvexTriangleMesh(#vertices)
        local textures = Pools.Texture.AcquireWorldTextureArray(numTextures)
        table.insert(self.textureList, textures)
        
        for i, texture in ipairs(textures) do
            texture:SetTexture("Interface/Addons/Game/Assets/Textures/fog")
            texture:SetDrawLayer(Texture.RenderDrawToWidgetLayer(22))
            texture:Show()
        end

        Rendering.DrawConvexTriangleMesh(worldLocation, vertices, textures)
    end
end
