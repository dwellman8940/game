local addonName, envTable = ...
setfenv(1, envTable)

local GameMixin = {}

function GameMixin:Initialize()
    self.client = CreateClient()
end

do
    local game = Mixin.CreateFromMixins(GameMixin)
    game:Initialize()
end