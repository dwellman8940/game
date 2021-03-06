local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_StaticGeometry = DebugViews.RegisterView("Physics", "Static Geometry")
local DebugView_StaticAABB = DebugViews.RegisterView("Physics", "Static AABB")
local DebugView_StaticBVH = DebugViews.RegisterView("Physics", "Static BVH")
local DebugView_DynamicGeometry = DebugViews.RegisterView("Physics", "Dynamic Geometry")
local DebugView_DynamicAABB = DebugViews.RegisterView("Physics", "Dynamic AABB")
local DebugView_DynamicCollisions = DebugViews.RegisterView("Physics", "Dynamic Collisions")

local DebugView_CollisionTime = DebugViews.RegisterProfileStatistic("Physics", "Collision")

local PhysicsMixin = {}

function CreatePhysicsSystem(client)
    local physicsSystem = Mixin.CreateFromMixins(PhysicsMixin)
    physicsSystem:Initialize(client)
    return physicsSystem
end

function PhysicsMixin:Initialize(client)
    self.client = client
    self.staticShapeAabbTree = CreateAABBTree()
    self.staticShapes = {}
    self.dynamicShapes = {}
end

function PhysicsMixin:FinalizeStaticShapes()
    self.staticShapeAabbTree:BuildFromStatic(self.staticShapes)
end

function PhysicsMixin:Tick(delta)

end

-- Attempt to move a dynamic shape, returns the adjusted world location to be outside of any collision shape
function PhysicsMixin:CollideShapeWithStatic(worldLocation, dynamicPhysicsShape)
    DebugView_CollisionTime:StartProfileCapture()


    local adjustLocated
    local overlaps = self:CalculateAllOverlaps(dynamicPhysicsShape:GetBounds():Translate(worldLocation))
    for i, physicsShape in ipairs(overlaps) do
        local collisionNormal, depth = physicsShape:CollideWith(worldLocation, dynamicPhysicsShape)
        if collisionNormal then
            if DebugView_DynamicCollisions:IsViewEnabled() then
                Debug.DrawDebugLine(worldLocation, worldLocation + collisionNormal * depth * 15, nil, Colors.White, Colors.White)
            end

            adjustLocated = (adjustLocated or worldLocation) + collisionNormal * depth
        end
    end

    DebugView_CollisionTime:EndProfileCapture()

    return adjustLocated or worldLocation
end

function PhysicsMixin:CalculateAllOverlaps(aabb)
    return self.staticShapeAabbTree:GetOverlaps(aabb)
end

function PhysicsMixin:RegisterStaticGeometryList(geometryComponent, staticGeometryList)
    for i, staticGeometry in ipairs(staticGeometryList) do
        self:RegisterStaticGeometry(geometryComponent, staticGeometry)
    end
end

function PhysicsMixin:RegisterStaticGeometry(geometryComponent, staticGeometry)
    table.insert(self.staticShapes, CreatePhysicsShape(geometryComponent, staticGeometry))
end

function PhysicsMixin:RegisterDynamicGeometry(geometryComponent, dynamicGeometry)
    local dynamicShape = CreatePhysicsShape(geometryComponent, dynamicGeometry)
    table.insert(self.dynamicShapes, dynamicShape)
    return dynamicShape
end

function PhysicsMixin:Render(delta)
    assert(self.client)
    
    if DebugView_StaticGeometry:IsViewEnabled() or DebugView_StaticAABB:IsViewEnabled() then
        local renderBounds = self.client:GetRenderFrameWorldBounds()
        local overlaps = self.staticShapeAabbTree:GetOverlaps(renderBounds)
        for i, physicsShape in ipairs(overlaps) do
            physicsShape:RenderDebug(delta, DebugView_StaticGeometry:IsViewEnabled(), DebugView_StaticAABB:IsViewEnabled())
        end
    end

    if DebugView_DynamicGeometry:IsViewEnabled() or DebugView_DynamicAABB:IsViewEnabled() then
        for i, physicsShape in ipairs(self.dynamicShapes) do
            physicsShape:RenderDebug(delta, DebugView_DynamicGeometry:IsViewEnabled(), DebugView_DynamicAABB:IsViewEnabled())
        end
    end

    if DebugView_StaticBVH:IsViewEnabled() then
        self.staticShapeAabbTree:DrawDebug()
    end
end