local addonName, envTable = ...
setfenv(1, envTable)

local Vector2Proto = {}
local Vector2Metatable = { __index = Vector2Proto }

function CreateVector2(x, y)
    local vector2 = setmetatable({}, Vector2Metatable)
    vector2:SetXY(x or 0, y or 0)
    return vector2
end

function Vector2Proto:SetXY(x, y)
    self.x = x
    self.y = y
end

function Vector2Proto:GetXY()
    return self.x, self.y
end

function Vector2Proto:GetX()
    return self.x
end

function Vector2Proto:GetY()
    return self.y
end

function Vector2Proto:Cross(other)
    return self.x * other.y - self.y * other.x
end

function Vector2Proto:ToPerpendicular()
    return CreateVector2(self.y, -self.x)
end

function Vector2Proto:IsLeftOf(other)
    return self:Cross(other) < 0
end

function Vector2Proto:IsLeftOrOnOf(other)
    return self:Cross(other) <= 0
end

function Vector2Proto:IsRightOf(other)
    return self:Cross(other) > 0
end

function Vector2Proto:IsRightOrOnOf(other)
    return self:Cross(other) >= 0
end

function Vector2Proto:GetNormal()
    local length = self:Length()
    return CreateVector2(self.x / length, self.y / length)
end

function Vector2Proto:GetSafeNormal(tolerance)
    local lengthSq = self:LengthSquared()

    if lengthSq <= (tolerance or Math.SmallNumber) then
        return CreateVector2()
    end

    local length = math.sqrt(lengthSq)
    return CreateVector2(self.x / length, self.y / length)
end

function Vector2Proto:LengthSquared()
    return self.x * self.x + self.y * self.y
end

function Vector2Proto:Length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2Proto:DistanceSquared(other)
    local deltaX = self.x - other.x
    local deltaY = self.y - other.y
    return deltaX * deltaX + deltaY * deltaY
end

function Vector2Proto:Distance(other)
    return math.sqrt(self:DistanceSquared(other))
end

function Vector2Proto:Dot(other)
    return self.x * other.x + self.y * other.y
end

function Vector2Proto:Clone()
    return CreateVector2(self:GetXY())
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

ZeroVector = CreateVector2()
RightVector = CreateVector2(1, 0)
UpVector = CreateVector2(0, 1)