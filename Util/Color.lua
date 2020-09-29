local addonName, envTable = ...
setfenv(1, envTable)

local ColorProto = {}
local ColorMetatable = { __index = ColorProto }

function CreateColor(r, g, b, a)
    local color = setmetatable({}, ColorMetatable)
    color:SetRGBA(r or 0, g or 0, b or 0, a or 1)
    return color
end

function ColorProto:SetRGBA(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a
end

function ColorProto:GetRGBA()
    return self.r, self.g, self.b, self.a
end

function ColorProto:GetRGB()
    return self.r, self.g, self.b
end

function ColorProto:WithAlpha(alpha)
    return CreateColor(self.r, self.g, self.b, alpha)
end

function ColorMetatable:__tostring()
    return ("Color: r %f g %f b %f a %f"):format(self:GetRGBA())
end

Colors = {
    Black = CreateColor(0, 0, 0, 1),
    White = CreateColor(1, 1, 1, 1),

    Red = CreateColor(1, 0, 0, 1),
    Green = CreateColor(0, 1, 0, 1),
    Blue = CreateColor(0, 0, 1, 1),

    Yellow = CreateColor(1, 1, 0, 1),
    Cyan = CreateColor(0, 1, 1, 1),
    Periwinkle = CreateColor(.8, .8, 1, 1),
    Magenta = CreateColor(1, 0, 1, 1),

    BayLeaf = CreateColor(.5, .7, .5, 1),
    Bouquet = CreateColor(.7, .5, .7, 1),
    Goblin = CreateColor(.2, .5, .2, 1),
    Swamp = CreateColor(0, .1, .1, 1),
}