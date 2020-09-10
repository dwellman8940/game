local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

EntityGraphMixin = {}

function EntityGraphMixin:Initialize(game)
    self.rootEntity = CreateGameEntity(game)
end

function EntityGraphMixin:GetRootEntity()
    return self.rootEntity
end

do
    local function Flatten(flattened, node)
        local childEntities = node:GetChildEntities()

        for i, childEntity in ipairs(childEntities) do
            table.insert(flattened, childEntity)
        end

        for i, childEntity in ipairs(childEntities) do
            Flatten(flattened, childEntity)
        end
    end

    function EntityGraphMixin:EnumerateAll()
        local flattened = {}
        Flatten(flattened, self.rootEntity)

        return ipairs(flattened)
    end
end