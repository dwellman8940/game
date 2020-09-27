local addonName, envTable = ...
setfenv(1, envTable)

local PhysicsShapeMixin = {}

function CreatePhysicsShape(worldLocation, vertices)
    local physicsShape = CreateFromMixins(PhysicsShapeMixin)
    physicsShape:Initialize(worldLocation, vertices)
    return physicsShape
end

function PhysicsShapeMixin:Initialize(worldLocation, vertices)
    self.worldLocation = worldLocation
    self.vertices = vertices
    self:CalculateNormalsAndAxes()
end

local function IsAxisUnique(axes, axis)
    for i, existingAxis in ipairs(axes) do
        if existingAxis.x == axis.x and existingAxis.y == axis.y then
            return false
        end
        if existingAxis.x == -axis.x and existingAxis.y == -axis.y then
            return false
        end
    end
    return true
end

function PhysicsShapeMixin:CalculateNormalsAndAxes()
    self.normals = {}
    self.axes = {}
    for vertexIndex, vertex in ipairs(self.vertices) do
        local nextVertex = self.vertices[Math.WrapIndex(vertexIndex + 1, #self.vertices)]
        local line = vertex - nextVertex
        local normal = line:GetNormal():ToPerpendicular()
        table.insert(self.normals, normal)
        if IsAxisUnique(self.axes, normal) then
            table.insert(self.axes, normal)
        end
    end
end

local function IsAxis(axes, normal)
    for i, axis in ipairs(axes) do
        if axis == normal then
            return true
        end
    end
    return false
end

function PhysicsShapeMixin:RenderDebug(delta)     
    Debug.DrawConvexTriangleMesh(self.worldLocation, self.vertices)
    for i, normal in ipairs(self.normals) do
        local vertex = self.vertices[i]
        local nextVertex = self.vertices[Math.WrapIndex(i + 1, #self.vertices)]
        local startLocation = self.worldLocation + Math.Lerp(vertex, nextVertex, .5)
        if IsAxis(self.axes, normal) then
            Debug.DrawDebugLine(startLocation, startLocation + normal * 10, nil, 0, 1, 1, 0, 1, 1)
        else
            Debug.DrawDebugLine(startLocation, startLocation + normal * 10, nil, 0, 0, 1, 0, 0, 1)
        end
    end
end