local addonName, envTable = ...
setfenv(1, envTable)

local GameMixin = {}

function GameMixin:Initialize()
    self.client = CreateClient()
end

function GameMixin:Run()
    self.client:SwitchToGameState(MainMenuStateMixin)
end

do
    local game = CreateFromMixins(GameMixin)
    game:Initialize()
    game:Run()
end