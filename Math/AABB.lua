local addonName, envTable = ...
setfenv(1, envTable)

local AABBProto = {}
local AABBMetatable = { __index = AABBProto }

function CreateAABB(minPoint, maxPoint)
    local aabb = setmetatable({}, AABBMetatable)
    aabb:SetMinMax(minPoint or CreateVector2(), maxPoint or CreateVector2())
    return aabb
end

function AABBProto:SetMinMax(minPoint, maxPoint)
    self.minPoint = minPoint
    self.maxPoint = maxPoint
end

function AABBProto:GetMinMaxPoints()
    return self.minPoint, self.maxPoint
end

function AABBProto:GetMinPoint()
    return self.minPoint
end

function AABBProto:GetMaxPoint()
    return self.maxPoint
end

function AABBProto:GetCenter()
    return Math.Lerp(self.minPoint, self.maxPoint, .5)
end

function AABBProto:GetWidth()
    return self.maxPoint.x - self.minPoint.x
end

function AABBProto:GetHeight()
    return self.maxPoint.y - self.minPoint.y
end

function AABBProto:Overlaps(other)
    if self.maxPoint.x < other.minPoint.x or self.minPoint.x > other.maxPoint.x then
        return false
    end
    if self.maxPoint.y < other.minPoint.y or self.minPoint.y > other.maxPoint.y then
        return false
    end
    return true
end

function AABBProto:InlineExpandToContainPoint(point)
    self.minPoint.x = math.min(self.minPoint.x, point.x)
    self.minPoint.y = math.min(self.minPoint.y, point.y)

    self.maxPoint.x = math.max(self.maxPoint.x, point.x)
    self.maxPoint.y = math.max(self.maxPoint.y, point.y)
    return self
end

function AABBProto:ExpandToContainPoint(point)
    return self:Clone():InlineExpandToContainPoint(point)
end

function AABBProto:InlineExpandToContainBounds(aabb)
    self:InlineExpandToContainPoint(aabb:GetMinPoint())
    self:InlineExpandToContainPoint(aabb:GetMaxPoint())
    return self
end

function AABBProto:ExpandToContainBounds(aabb)
    return self:Clone():InlineExpandToContainBounds(aabb)
end

function AABBProto:InlineTranslate(translation)
    self.minPoint = self.minPoint + translation
    self.maxPoint = self.maxPoint + translation
    return self
end

function AABBProto:Translate(translation)
    return self:Clone():InlineTranslate(translation)
end

function AABBProto:Clone()
    return CreateAABB(self:GetMinMaxPoints())
end

function AABBMetatable:__tostring()
    return ("AABB: %s %s"):format(self.minPoint, self.maxPoint)
end