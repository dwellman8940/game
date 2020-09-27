local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_StaticGeometry = DebugViews.RegisterView("Physics", "Static Geometry")
local DebugView_DynamicCollisions = DebugViews.RegisterView("Physics", "Dynamic Collisions")

local PhysicsMixin = {}

function CreatePhysicsSystem()
    local physicsSystem = CreateFromMixins(PhysicsMixin)
    physicsSystem:Initialize()
    return physicsSystem
end

function PhysicsMixin:Initialize()
    self.staticShapes = {}
end

function PhysicsMixin:Tick(delta)
end

-- Attempt to move a dynamic shape, returns the adjusted world location to be outside of any collision shape
function PhysicsMixin:CollideShapeWithStatic(worldLocation, dynamicPhysicsShape)
    for i, physicsShape in ipairs(self.staticShapes) do
        local collisionNormal, depth = physicsShape:CollideWith(worldLocation, dynamicPhysicsShape)
        if collisionNormal then
            if DebugView_DynamicCollisions:IsViewEnabled() then
                Debug.DrawDebugLine(worldLocation, worldLocation + collisionNormal * depth * 15, nil, 1, 1, 1, 1, 1, 1)
            end

            worldLocation = worldLocation + collisionNormal * depth
        end
    end

    return worldLocation
end

function PhysicsMixin:RegisterStaticGeometryList(worldLocation, staticGeometryList)
    for i, staticGeometry in ipairs(staticGeometryList) do
        self:RegisterStaticGeometry(worldLocation, staticGeometry)
    end
end

function PhysicsMixin:RegisterStaticGeometry(worldLocation, staticGeometry)
    table.insert(self.staticShapes, CreatePhysicsShape(worldLocation, staticGeometry))
end

function PhysicsMixin:RegisterDynamicGeometry(worldLocation, dynamicGeometry)
    return CreatePhysicsShape(worldLocation, dynamicGeometry)
end

function PhysicsMixin:Render(delta)
    if DebugView_StaticGeometry:IsViewEnabled() then
        for i, physicsShape in ipairs(self.staticShapes) do
            physicsShape:RenderDebug(delta)
        end
    end
end