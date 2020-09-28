local addonName, envTable = ...
setfenv(1, envTable)

local PhysicsShapeMixin = {}

function CreatePhysicsShape(worldLocation, vertices)
    local physicsShape = CreateFromMixins(PhysicsShapeMixin)
    physicsShape:Initialize(worldLocation, vertices)
    return physicsShape
end

function PhysicsShapeMixin:Initialize(worldLocation, vertices)
    assert(#vertices >= 3)
    self.worldLocation = worldLocation
    self.vertices = vertices
    self:PreprocessVertices()
end

function PhysicsShapeMixin:SetWorldLocation(worldLocation)
    self.worldLocation = worldLocation
end

function PhysicsShapeMixin:GetVerticesCenter()
    return self.verticesCenter
end

function PhysicsShapeMixin:GetVerticesWorldCenter()
    return self.worldLocation + self.verticesCenter
end

local function Project(worldLocation, physicsShape, axis)
    local vertices = physicsShape.vertices
    local min
    local max

    for vertexIndex, vertex in ipairs(vertices) do
        local projection = axis:Dot(worldLocation + vertex)

        min = min and math.min(min, projection) or projection
        max = max and math.max(max, projection) or projection
    end

    return min, max
end

local function CalculateOverlap(min1, max1, min2, max2)
    if min1 > max2 or min2 > max1 then
        return nil
    end

    return math.min(max1, max2) - math.max(min1, min2)
end

local function SeparationAxisTest(axes, shape1Location, shape1, shape2Location, shape2)
    local smallestOverlap
    local smallestAxis
    for i, axis in ipairs(axes) do
        local min1, max1 = Project(shape1Location, shape1, axis)
        local min2, max2 = Project(shape2Location, shape2, axis)

        local overlap = CalculateOverlap(min1, max1, min2, max2)
        if overlap then
            if not smallestOverlap or overlap < smallestOverlap then
                smallestOverlap = overlap
                smallestAxis = axis
            end
        else
            return -- no collision
        end
    end
    return smallestOverlap, smallestAxis
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

local function MergeAxes(axes1, axes2)
    if #axes1 > #axes2 then
        return MergeAxes(axes2, axes1)
    end
    local mergedAxes = {}
    for i, axis in ipairs(axes1) do
        table.insert(mergedAxes, axis)
    end

    for i, axis in ipairs(axes2) do
        if IsAxisUnique(axes1, axis) then
            table.insert(mergedAxes, axis)
        end
    end
    return mergedAxes
end

function PhysicsShapeMixin:CollideWith(worldLocation, physicsShape)
    local smallestOverlap, smallestAxis = SeparationAxisTest(MergeAxes(self.axes, physicsShape.axes), self.worldLocation, self, worldLocation, physicsShape)
    if smallestOverlap then
        local towards = self:GetVerticesWorldCenter() - (worldLocation + physicsShape:GetVerticesCenter())
        if towards:Dot(smallestAxis) > 0 then
            return -smallestAxis, smallestOverlap
        end
        return smallestAxis:Clone(), smallestOverlap
    end
end

function PhysicsShapeMixin:GetWorldLocation()
    return self.worldLocation
end

function PhysicsShapeMixin:GetBounds()
    return self.bounds
end

function PhysicsShapeMixin:GetWorldBounds()
    return self.bounds:Translate(self:GetWorldLocation())
end

function PhysicsShapeMixin:PreprocessVertices()
    self.normals = {}
    self.axes = {}
    self.bounds = CreateAABB()
    for vertexIndex, vertex in ipairs(self.vertices) do
        local nextVertex = self.vertices[Math.WrapIndex(vertexIndex + 1, #self.vertices)]
        self.bounds:InlineExpandToContainPoint(vertex)
        local line = vertex - nextVertex
        local normal = line:GetNormal():ToPerpendicular()
        table.insert(self.normals, normal)
        if IsAxisUnique(self.axes, normal) then
            table.insert(self.axes, normal)
        end
    end
    self.verticesCenter = self.bounds:GetCenter()
end

local function IsAxis(axes, normal)
    for i, axis in ipairs(axes) do
        if axis == normal then
            return true
        end
    end
    return false
end

function PhysicsShapeMixin:RenderDebug(delta, renderGeometry, renderAABB)
    if renderGeometry then
        Debug.DrawConvexTriangleMesh(self.worldLocation, self.vertices)
        for i, normal in ipairs(self.normals) do
            local vertex = self.vertices[i]
            local nextVertex = self.vertices[Math.WrapIndex(i + 1, #self.vertices)]
            local startLocation = self.worldLocation + Math.Lerp(vertex, nextVertex, .5)
            if IsAxis(self.axes, normal) then
                Debug.DrawDebugLine(startLocation, startLocation + normal * 10, nil, Colors.Cyan, Colors.Cyan)
            else
                Debug.DrawDebugLine(startLocation, startLocation + normal * 10, nil, Colors.Blue, Colors.Blue)
            end
        end
    end

    if renderAABB then
        Debug.DrawDebugAABB(self.worldLocation, self.bounds)
    end
end