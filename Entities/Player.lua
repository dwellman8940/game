local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)


GameObjectMixin = {}

function GameObjectMixin:SetLocation(location)
end