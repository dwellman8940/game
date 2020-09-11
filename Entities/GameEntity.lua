local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GameEntityMixin = {}

function GameEntityMixin:InitializeOnServer(server, parentEntity, relativeLocation)
    self.server = server
    self:Initialize(parentEntity, relativeLocation)
end

function GameEntityMixin:InitializeOnClient(client, parentEntity, relativeLocation)
    self.client = client
    self:Initialize(parentEntity, relativeLocation)
end

function GameEntityMixin:Initialize(parentEntity, relativeLocation)
    self:SetRelativeLocation(relativeLocation or CreateVector2(0, 0))
    self.parentEntity = parentEntity
    self.childEntities = {}

    if self.parentEntity then
        self.parentEntity:AddChildObject(self)
    end
end

function GameEntityMixin:SetRelativeLocation(relativeLocation)
    self.relativeLocation = relativeLocation
end

function GameEntityMixin:GetRelativeLocation()
    return self.relativeLocation
end

function GameEntityMixin:GetWorldLocation()
    -- todo: resolve world location
    return self.relativeLocation
end

function GameEntityMixin:SetWorldLocation(worldLocation)
    -- todo: resolve world location
    self.relativeLocation = worldLocation
end

function GameEntityMixin:GetChildEntities()
    return self.childEntities
end

function GameEntityMixin:GetParentEntity()
    return self.parentEntity
end

function GameEntityMixin:GetClient()
    -- only non-nil if this is running on a client
    return self.client
end

function GameEntityMixin:GetServer()
    -- only non-nil if this is running on a server
    return self.server
end

function GameEntityMixin:AddChildObject(childEntity)
    assert(childEntity:GetParentEntity() == self)

    table.insert(self.childEntities, childEntity)
end

function GameEntityMixin:TickServer(delta)
    -- Override to handle logic updates on the server, no rendering updates here
end

function GameEntityMixin:TickClient(delta)
    -- Override to handle logic updates on the client, no rendering updates here
end

function GameEntityMixin:Render(delta)
    -- Override to handling rendering on the client
end