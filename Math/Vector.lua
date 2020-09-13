local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

local Vector2Mixin = {}

local Vector2Metatable = {}

function CreateVector2(x, y)
    local vector2 = CreateFromMixins(Vector2Mixin)
    setmetatable(vector2, Vector2Metatable)
    vector2:SetXY(x, y)
    return vector2
end

function Vector2Mixin:SetXY(x, y)
    self.x = x
    self.y = y
end

function Vector2Mixin:GetXY()
    return self.x, self.y
end

function Vector2Mixin:Equals(other)
    return self.x == other.x
        and self.y == other.y
end

local function Dot(leftX, leftY, rightX, rightY)
	return leftX * rightX + leftY * rightY
end

function Vector2Mixin:DistanceSquared(other)
    local deltaX = self.x - other.x
    local deltaY = self.y - other.y
    return deltaX * deltaX + deltaY * deltaY
end

function Vector2Mixin:Dot(other)
    return Dot(self.x, self.y, other.x, other.y)
end

function Vector2Metatable:__add(other)
    return CreateVector2(self.x + other.x, self.y + other.y)
end