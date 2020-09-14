local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GameEntityComponentMixin = {}

function CreateGameEntityComponent(componentType, owningEntity, ...)
    local gameEntityComponent = CreateFromMixins(componentType)
    gameEntityComponent:Initialize(owningEntity, ...)
    return gameEntityComponent
end

function GameEntityComponentMixin:Initialize(owningEntity, ...)
    owningEntity:AddComponent(self)
    self.relativeLocation = CreateVector2(0, 0)
end

function GameEntityComponentMixin:Destroy()
    -- Override to handle being destroyed
end

function GameEntityComponentMixin:SetGameEntityOwner(owningEntity)
    self.owningEntity = owningEntity
end

function GameEntityComponentMixin:GetGameEntityOwner()
    return self.owningEntity
end

function GameEntityComponentMixin:SetRelativeLocation(relativeLocation)
    self.relativeLocation = relativeLocation
end

function GameEntityComponentMixin:GetRelativeLocation()
    return self.relativeLocation
end

function GameEntityComponentMixin:GetWorldLocation()
    return self:GetGameEntityOwner():GetWorldLocation() + self.relativeLocation
end

function GameEntityComponentMixin:TickServer(delta)
    -- Override to handle logic updates on the server, no rendering updates here
end

function GameEntityComponentMixin:TickClient(delta)
    -- Override to handle logic updates on the client, no rendering updates here
end

function GameEntityComponentMixin:Render(delta)
    -- Override to handling rendering on the client
end