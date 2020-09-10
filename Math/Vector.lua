local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

Vector2Mixin = {}

function CreateVector2(x, y)
    local vector2 = CreateFromMixins(Vector2Mixin)
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