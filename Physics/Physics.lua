local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_StaticGeometry = DebugViews.RegisterView("Physics", "Static Geometry")

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

function PhysicsMixin:RegisterStaticGeometryList(worldLocation, staticGeometryList)
    for i, staticGeometry in ipairs(staticGeometryList) do
        self:RegisterStaticGeometry(worldLocation, staticGeometry)
    end
end

function PhysicsMixin:RegisterStaticGeometry(worldLocation, staticGeometry)
    table.insert(self.staticShapes, CreatePhysicsShape(worldLocation, staticGeometry))
end

function PhysicsMixin:Render(delta)
    if DebugView_StaticGeometry:IsViewEnabled() then
        for i, physicsShape in ipairs(self.staticShapes) do
            physicsShape:RenderDebug(delta)
        end
    end
end