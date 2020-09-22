local addonName, envTable = ...
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

function Vector2Mixin:GetX()
    return self.x
end

function Vector2Mixin:GetY()
    return self.y
end

function Vector2Mixin:Cross(other)
    return self.x * other.y - self.y * other.x
end

function Vector2Mixin:ToPerpendicular()
    return CreateVector2(self.y, -self.x)
end

function Vector2Mixin:IsLeftOf(other)
    return self:Cross(other) < 0
end

function Vector2Mixin:IsLeftOrOnOf(other)
    return self:Cross(other) <= 0
end

function Vector2Mixin:IsRightOf(other)
    return self:Cross(other) > 0
end

function Vector2Mixin:IsRightOrOnOf(other)
    return self:Cross(other) >= 0
end

function Vector2Mixin:GetNormal()
    local length = self:Length()
    return CreateVector2(self.x / length, self.y / length)
end

function Vector2Mixin:LengthSquared()
    return self.x * self.x + self.y * self.y
end

function Vector2Mixin:Length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2Mixin:DistanceSquared(other)
    local deltaX = self.x - other.x
    local deltaY = self.y - other.y
    return deltaX * deltaX + deltaY * deltaY
end

function Vector2Mixin:Dot(other)
    return self.x * other.x + self.y * other.y
end

function Vector2Metatable:__add(other)
    return CreateVector2(self.x + other.x, self.y + other.y)
end

function Vector2Metatable:__sub(other)
    return CreateVector2(self.x - other.x, self.y - other.y)
end

function Vector2Metatable.__mul(left, right)
    if type(left) == "table" then
        return CreateVector2(left.x * right, left.y * right)
    end
    return CreateVector2(right.x * left, right.y * left)
end

function Vector2Metatable.__div(left, right)
    if type(left) == "table" then
        return CreateVector2(left.x / right, left.y / right)
    end
    return CreateVector2(right.x / left, right.y / left)
end
 
function Vector2Metatable:__eq(other)
    return self.x == other.x
        and self.y == other.y
end

function Vector2Metatable:__unm()
    return CreateVector2(-self.x, -self.y)
end

function Vector2Metatable:__tostring()
    return ("Vector2: %f %f"):format(self.x, self.y)
end

ZeroVector = CreateVector2(0, 0)
RightVector = CreateVector2(1, 0)
UpVector = CreateVector2(0, 1)