local addonName, envTable = ...
setfenv(1, envTable)

Server = {}
Server.RemovedReason =
{
    Left = 1,
    TimedOut = 2,
    Leaving = 3,
    HostLeft = 4,
    Kicked = 5,
}

local ServerMessageHandlers = {}

local ServerMixin = {}

function CreateServer()
    local server = Mixin.CreateFromMixins(ServerMixin)
    server:Initialize()

    return server
end

function ServerMixin:Initialize()
    self.messageQueue = {}
    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(nil)
    self.nextPlayerID = 1

    self.pendingPlayers = {}
    self.outstandingPings = {}
    self.ignorePlayerTimeout = {}

    self.elapsed = 0
    self.lastTickTime = GetTime()
    self.ticker = C_Timer.NewTicker(0, function() self:TryTick() end)

    self:MarkSentToClientActivity()
end

function ServerMixin:Destroy()
    self.ticker:Cancel()
    self.serverNetworkConnection:Disconnect()
end

function ServerMixin:SetOnPlayerAddedCallback(OnPlayerAddedCallback)
    self.OnPlayerAddedCallback = OnPlayerAddedCallback
end

function ServerMixin:SetOnPlayerRemovedCallback(OnPlayerRemovedCallback)
    self.OnPlayerRemovedCallback = OnPlayerRemovedCallback
end

function ServerMixin:BeginGame(levelToLoad, playersInLobbby)
    self:SendMessageToAllClients("LoadLevel", levelToLoad)

    self:LoadLevel(levelToLoad)

    self.players = {}

    if playersInLobbby then
        for i, playerName in ipairs(playersInLobbby) do
            self:AddPlayer(playerName)
        end
    end
end

function ServerMixin:FindPlayerByName(playerName)
    for playerID, playerEntity in pairs(self.players) do
        if playerEntity:GetPlayerName() == playerName then
            return playerEntity
        end
    end
    return nil
end

function ServerMixin:AddPlayer(playerName)
    self.pendingPlayers[playerName] = nil

    local existingPlayerEntity = self:FindPlayerByName(playerName)
    if existingPlayerEntity then
        existingPlayerEntity:MarkPlayerActivity()
        -- Reconnecting to the same player, restore player
        self.pendingFullPlayerInit = true
        return
    end

    local playerEntity = self:CreateEntity(PlayerEntityMixin, nil, nil, playerName)

    local playerID = self.nextPlayerID
    playerEntity:SetPlayerID(playerID)
    self.players[playerID] = playerEntity

    self.nextPlayerID = self.nextPlayerID + 1
    if self.nextPlayerID > 255 then
        self.nextPlayerID = 1
    end

    self.pendingFullPlayerInit = true

    if self.OnPlayerAddedCallback then
        self.OnPlayerAddedCallback(playerName, playerID)
    end
end

function ServerMixin:RemovePlayer(playerID, reason)
    local playerEntity = self.players[playerID]
    assert(playerEntity)
    if playerEntity then
        local playerName = playerEntity:GetPlayerName()
        self.players[playerID] = nil
        self.outstandingPings[playerID] = nil
        self.pendingPlayers[playerName] = nil
        self.ignorePlayerTimeout[playerID] = nil

        self:GetEntityGraph():DestroyEntity(playerEntity)

        self:SendMessageToAllClients("RemovePlayer", playerID, reason)

        if self.OnPlayerRemovedCallback then
            self.OnPlayerRemovedCallback(playerName, playerID)
        end
    end
end

function ServerMixin:AddPendingPlayer(playerName)
    self.pendingPlayers[playerName] = GetTime()
end

function ServerMixin:IgnorePlayerTimeout(playerID)
    local playerEntity = self.players[playerID]
    assert(playerEntity)

    if playerEntity then
        self.ignorePlayerTimeout[playerID] = true
    end
end

function ServerMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function ServerMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function ServerMixin:MarkSentToClientActivity()
    self.lastMessageToClientsTime = GetTime()
end

function ServerMixin:SendMessageToAllClients(messageName, ...)
    self:MarkSentToClientActivity()
    self.serverNetworkConnection:SendMessageToAllClients(messageName, ...)
end

function ServerMixin:CreateNetworkConnection(lobbyCode, localClient, clientHandlers)
    local localClientOnMessageReceived = localClient and function(messageName, ...) localClient:AddMessageToQueue(clientHandlers, messageName, ...) end or nil

    local function OnMessageReceived(messageName, ...)
        self:AddMessageToQueue(messageName, ...)
    end

    self.serverNetworkConnection = Networking.CreateServerConnection(UnitName("player"), lobbyCode, localClientOnMessageReceived, OnMessageReceived)
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
        self.physicsSystem:Tick(SECONDS_PER_TICK)
        self:Tick(SECONDS_PER_TICK)
    end
end

function ServerMixin:Tick(delta)
    self:ProcessMessages()
    self:CheckForStaleConnections()

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickServerInternal(delta)
    end

    if self.pendingFullPlayerInit then
        self.pendingFullPlayerInit = nil
        for playerID, playerEntity in pairs(self.players) do
            self:SendMessageToAllClients("InitPlayer", playerEntity:GetPlayerName(), playerID, playerEntity:GetWorldLocation(), playerEntity:GetVelocity())
        end
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

-- Best to not have these constants multiples of each other, otherwise the pings can become cyclic
local PLAYER_DISCONNECT_TIMEOUT = 13
local PLAYER_PING_TIMEOUT = 9
local SERVER_PING_TIMEOUT = 5
function ServerMixin:CheckForStaleConnections()
    local pingsToSend
    for playerID, playerEntity in pairs(self.players) do
        if not self.ignorePlayerTimeout[playerID] then
            if not playerEntity:HasBeenActiveRecently(PLAYER_DISCONNECT_TIMEOUT) then
                self:RemovePlayer(playerID, Server.RemovedReason.TimedOut)
            elseif not playerEntity:HasBeenActiveRecently(PLAYER_PING_TIMEOUT) then
                if not self.outstandingPings[playerID] then
                    self.outstandingPings[playerID] = true
                    pingsToSend = pingsToSend or {}
                    table.insert(pingsToSend, playerID)
                end
            end
        end
    end

    local now = GetTime()
    for pendingPlayerName, addedTime in pairs(self.pendingPlayers) do
        local delta = now - addedTime
        if delta >= PLAYER_PING_TIMEOUT then
            self.pendingPlayers[pendingPlayerName] = nil
        end
    end

    if pingsToSend then
        self:SendMessageToAllClients("Ping", unpack(pingsToSend))
    else
        -- Haven't sent anything to clients recently, ping them all to let them know we're still here
        local deltaMessageToClients = now - self.lastMessageToClientsTime
        if deltaMessageToClients >= SERVER_PING_TIMEOUT then
            self:SendMessageToAllClients("Ping")
        end
    end
end

function ServerMixin:GetEntityGraph()
    return self.entityGraph
end

function ServerMixin:CreateEntity(entityMixin, parentEntity, relativeLocation, ...)
    local gameEntity = Mixin.CreateFromMixins(entityMixin)
    gameEntity:InitializeOnServer(self, parentEntity, relativeLocation, ...)
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

function ServerMessageHandlers:PlayerReady(playerName)
    if self.pendingPlayers[playerName] then
        self:AddPlayer(playerName)
    end
end

function ServerMessageHandlers:PlayerLeaving(playerID)
    local playerEntity = self.players[playerID]
    if playerEntity then
        self:RemovePlayer(playerID, Server.RemovedReason.Leaving)
    end
end

function ServerMessageHandlers:Pong(playerID)
    if self.outstandingPings[playerID] then
        self.outstandingPings[playerID] = nil
        local player = self.players[playerID]
        if player then
            player:MarkPlayerActivity()
        end
    end
end