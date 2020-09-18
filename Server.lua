local addonName, envTable = ...
setfenv(1, envTable)

local ServerMessageHandlers = {}

local ServerMixin = {}

function CreateServer()
    local server = CreateFromMixins(ServerMixin)
    server:Initialize()

    return server
end

function ServerMixin:Initialize()
    self.messageQueue = {}
    self.entityGraph = CreateEntityGraph()

    self.elapsed = 0
    self.lastTickTime = GetTime()
    C_Timer.NewTicker(0, function() self:TryTick() end)
end

function ServerMixin:BeginGame(playersInLobbby)
    self:SendMessageToAllClients("ResetGame")

    self.players = {}

    for i, playerName in ipairs(playersInLobbby) do
        local player = self:CreateEntity(PlayerEntityMixin)
        player:SetPlayerID(i)
        self.players[i] = player
        self:SendMessageToAllClients("InitPlayer", playerName, i)
    end
end

function ServerMixin:SendMessageToAllClients(messageName, ...)
    self.serverNetworkConnection:SendMessageToAllClients(messageName, ...)
end

function ServerMixin:CreateNetworkConnection(lobbyCode, localClient)
    local localClientOnMessageReceived = localClient and function(messageName, ...) localClient:AddMessageToQueue(messageName, ...) end or nil

    local function OnMessageReceived(messageName, ...)
        self:AddMessageToQueue(messageName, ...)
    end

    self.serverNetworkConnection = CreateServerConnection(UnitName("player"), lobbyCode, localClientOnMessageReceived, OnMessageReceived)
end

function ServerMixin:AddMessageToQueue(messageName, ...)
    table.insert(self.messageQueue, { messageName, ... })
end

local TARGET_FPS = 60
local SECONDS_PER_TICK = 1 / TARGET_FPS 
function ServerMixin:TryTick()
    local now = GetTime()
    local delta = now - self.lastTickTime
    self.lastTickTime = now

    self.elapsed = self.elapsed + delta

    while self.elapsed >= SECONDS_PER_TICK do
        self.elapsed = self.elapsed - SECONDS_PER_TICK
        self:Tick(SECONDS_PER_TICK)
    end
end

function ServerMixin:Tick(delta)
    self:ProcessMessages()

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickServerInternal(delta)
    end
end

function ServerMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local messageName = messageData[1]
            ServerMessageHandlers[messageName](self, unpack(messageData, 2))
        end
        self.messageQueue = {}
    end
end

function ServerMixin:GetEntityGraph()
    return self.entityGraph
end

function ServerMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnServer(self, parentEntity, relativeLocation)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

function ServerMessageHandlers:OnMovement(playerID, location, velocity)
    local player = self.players[playerID]
    if player then
        player:ApplyRemoveMovement(location, velocity)
    end
end