local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

local GameMixin = {}

local function StartGame()
    local game = CreateFromMixins(GameMixin)
    game:Initialize()
    game:Run()
end

function GameMixin:Initialize()
    self.client = CreateClient()
    self.server = CreateServer()
end

function GameMixin:Run()
    self.client:BeginGame()
end

StartGame()