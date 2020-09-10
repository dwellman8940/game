local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GameEntityMixin = {}

function CreateGameEntity(game, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(GameEntityMixin)
    gameEntity:Initialize(game, parentEntity, relativeLocation)
    return gameEntity
end

function GameEntityMixin:Initialize(game, parentEntity, relativeLocation)
    self.game = game
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

function GameEntityMixin:GetChildEntities()
    return self.childEntities
end

function GameEntityMixin:GetParentEntity()
    return self.parentEntity
end

function GameEntityMixin:GetGame()
    return self.game
end

function GameEntityMixin:AddChildObject(childEntity)
    assert(childEntity:GetParentEntity() == self)

    table.insert(self.childEntities, childEntity)
end

function GameEntityMixin:Tick(delta)
    -- Override to handle logic updates, no rendering updates here
end

function GameEntityMixin:Render(delta)
    -- Override to handling rendering on the client
end