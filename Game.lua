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
    if UnitName("player") == "Ladreiline" then
        self.server = CreateServer()
    end
end

function GameMixin:Run()
    local lobbyCode = "RAWR"
    self.client:CreateNetworkConnection(lobbyCode, self.server)

    if self.server then
        self.server:CreateNetworkConnection(lobbyCode)

        local playersInLobby = {"Ladreiline", "Cereekeloran", "Dorbland"} -- todo: real lobby
        self.server:BeginGame(playersInLobby)
    end

    self.client:BeginGame()
end

StartGame()