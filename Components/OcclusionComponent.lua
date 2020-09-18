local addonName, envTable = ...
setfenv(1, envTable)

OcclusionComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function OcclusionComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.geometryComponents = {}
end

function OcclusionComponentMixin:Destroy() -- override

    GameEntityComponentMixin.Destroy(self)
end

function OcclusionComponentMixin:AddGeometry(geometryComponent)
    table.insert(self.geometryComponents, geometryComponent)
end

function OcclusionComponentMixin:GetName()
    return "OcclusionComponent"
end

function OcclusionComponentMixin:Render(delta) -- override
    local rayOrigin = self:GetWorldLocation()
    for i, geometryComponent in ipairs(self.geometryComponents) do
        local leftVertIndex, rightVertIndex
        local leftRay, rightRay

        local geometryComponentLocation = geometryComponent:GetWorldLocation()
        local vertexOrigin = geometryComponentLocation - rayOrigin

        local vertices = geometryComponent:GetVertices()
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
        Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + vertices[leftVertIndex] - rayOrigin):GetNormal() * 1000, nil, 0, 0, 0, 0, 0, 0)
        Debug.DrawDebugLine(rayOrigin, rayOrigin + (geometryComponentLocation + vertices[rightVertIndex] - rayOrigin):GetNormal() * 1000, nil, 0, 0, 0, 0, 0, 0)
    end
end

