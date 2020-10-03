local addonName, envTable = ...
setfenv(1, envTable)

local EntityGraphMixin = {}

function CreateEntityGraph()
    local entityGraph = Mixin.CreateFromMixins(EntityGraphMixin)
    entityGraph:Initialize()
    return entityGraph
end

function EntityGraphMixin:Initialize()
    self.childEntities = {}
end

function EntityGraphMixin:AddToRoot(gameEntity)
    table.insert(self.childEntities, gameEntity)
end

do
    local function Flatten(flattened, childEntities)
        for i, childEntity in ipairs(childEntities) do
            table.insert(flattened, childEntity)
        end

        for i, childEntity in ipairs(childEntities) do
            Flatten(flattened, childEntity:GetChildEntities())
        end
    end

    function EntityGraphMixin:EnumerateAll()
        local flattened = {}
        Flatten(flattened, self.childEntities)

        return ipairs(flattened)
    end
end