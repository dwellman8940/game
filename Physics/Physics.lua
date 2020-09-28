local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_StaticGeometry = DebugViews.RegisterView("Physics", "Static Geometry")
local DebugView_StaticAABB = DebugViews.RegisterView("Physics", "Static AABB")
local DebugView_StaticBVH = DebugViews.RegisterView("Physics", "Static BVH")
local DebugView_DynamicGeometry = DebugViews.RegisterView("Physics", "Dynamic Geometry")
local DebugView_DynamicAABB = DebugViews.RegisterView("Physics", "Dynamic AABB")
local DebugView_DynamicCollisions = DebugViews.RegisterView("Physics", "Dynamic Collisions")

local PhysicsMixin = {}

function CreatePhysicsSystem(owner)
    local physicsSystem = CreateFromMixins(PhysicsMixin)
    physicsSystem:Initialize(owner)
    return physicsSystem
end

function PhysicsMixin:Initialize(owner)
    self.owner = owner
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
    local overlaps = self.staticShapeAabbTree:GetOverlaps(dynamicPhysicsShape:GetBounds():Translate(worldLocation))
    for i, physicsShape in ipairs(overlaps) do
        local collisionNormal, depth = physicsShape:CollideWith(worldLocation, dynamicPhysicsShape)
        if collisionNormal then
            if DebugView_DynamicCollisions:IsViewEnabled() then
                Debug.DrawDebugLine(worldLocation, worldLocation + collisionNormal * depth * 15, nil, Colors.White, Colors.White)
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
    local dynamicShape = CreatePhysicsShape(worldLocation, dynamicGeometry)
    table.insert(self.dynamicShapes, dynamicShape)
    return dynamicShape
end

function PhysicsMixin:Render(delta)
    if DebugView_StaticGeometry:IsViewEnabled() or DebugView_StaticAABB:IsViewEnabled() then
        local renderBounds = self.owner:GetRenderFrameWorldBounds()
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