local addonName, envTable = ...
setfenv(1, envTable)

local AABBTreeMixin = {}

function CreateAABBTree()
    local aabbTree = Mixin.CreateFromMixins(AABBTreeMixin)
    aabbTree:Initialize()
    return aabbTree
end

function AABBTreeMixin:Initialize()
    self.root = nil
end

local function GetOverlaps(overlaps, aabb, node)
    if node then
        if node.boundingVolume:Overlaps(aabb) then
            if node.shape then
                table.insert(overlaps, node.shape)
            else
                GetOverlaps(overlaps, aabb, node.left)
                GetOverlaps(overlaps, aabb, node.right)
            end
        end
    end
end

function AABBTreeMixin:GetOverlaps(aabb)
    local overlaps = {}
    GetOverlaps(overlaps, aabb, self.root)

    return overlaps
end

local function CreateNode()
    return {
        boundingVolume = nil,
        shape = nil,
        left = nil,
        right = nil,
    }
end

local function Slice(t, startIndex, endIndex)
    local slice = {}
    for i = startIndex, endIndex do
        table.insert(slice, t[i])
    end
    return slice
end

local function PredicateOnX(a, b)
    return a:GetVerticesWorldCenter().x < b:GetVerticesWorldCenter().x
end

local function PredicateOnY(a, b)
    return a:GetVerticesWorldCenter().y < b:GetVerticesWorldCenter().y
end

local function PartitionShapes(shapes)
    local xSize = 0
    local ySize = 0
    for i, shape in ipairs(shapes) do
        local bounds = shape:GetWorldBounds()

        xSize = xSize + bounds:GetWidth()
        ySize = ySize + bounds:GetHeight()
    end

    table.sort(shapes, xSize > ySize and PredicateOnX or PredicateOnY)
    local halfIndex = math.floor(#shapes * .5)
    return Slice(shapes, 1, halfIndex), Slice(shapes, halfIndex + 1, #shapes)
end

local function CalculateBoundingVolume(shapes)
    local aabb
    for i, shape in ipairs(shapes) do
        local bounds = shape:GetWorldBounds()
        if aabb then
            aabb:InlineExpandToContainBounds(bounds)
        else
            aabb = bounds:Clone()
        end
    end
    return aabb
end

local function BuildTopDown(shapes)
    if #shapes == 0 then
        return nil
    end

    local node = CreateNode()
    node.boundingVolume = CalculateBoundingVolume(shapes)

    if #shapes == 1 then
        node.shape = shapes[1]
    else
        local left, right = PartitionShapes(shapes)
        node.left = BuildTopDown(left)
        node.right = BuildTopDown(right)
    end

    return node
end

function AABBTreeMixin:BuildFromStatic(shapes)
    self.root = BuildTopDown(shapes)
end

local function DrawDebug(node, parentNode, parentColor, randomStream)
    if not node then
        return
    end

    local color = randomStream:GetNextColor()

    Debug.DrawDebugAABB(ZeroVector, node.boundingVolume, nil, color, color, color)
    if parentNode then
        Debug.DrawDebugLine(parentNode.boundingVolume:GetCenter(), node.boundingVolume:GetCenter(), nil, parentColor:WithAlpha(.5), color:WithAlpha(.5))
    end

    if not node.shape then
        DrawDebug(node.left, node, color, randomStream)
        DrawDebug(node.right, node, color, randomStream)
    end
end

function AABBTreeMixin:DrawDebug()
    local randomStream = CreateRandomStream(self)

    DrawDebug(self.root, nil, nil, randomStream)
end