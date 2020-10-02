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
    self.physicsSystem = CreatePhysicsSystem(self)
    self.nextPlayerID = 1

    self.pendingPlayers = {}

    self.elapsed = 0
    self.lastTickTime = GetTime()
    self.ticker = C_Timer.NewTicker(0, function() self:TryTick() end)
end

function ServerMixin:Destroy()
    self.ticker:Cancel()
    self.serverNetworkConnection:Disconnect()
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

    local existingPlayer = self:FindPlayerByName(playerName)
    if existingPlayer then
        -- Reconnecting to the same player, restore player
        self.pendingFullPlayerInit = true
        return
    end

    local player = self:CreateEntity(PlayerEntityMixin, nil, nil, playerName)

    local playerID = self.nextPlayerID
    player:SetPlayerID(playerID)
    self.players[playerID] = player

    self.nextPlayerID = self.nextPlayerID + 1
    if self.nextPlayerID > 255 then
        self.nextPlayerID = 1
    end

    self.pendingFullPlayerInit = true
end

function ServerMixin:AddPendingPlayer(playerName)
    self.pendingPlayers[playerName] = GetTime()
end

function ServerMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function ServerMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function ServerMixin:SendMessageToAllClients(messageName, ...)
    self.serverNetworkConnection:SendMessageToAllClients(messageName, ...)
end

function ServerMixin:CreateNetworkConnection(lobbyCode, localClient, clientHandlers)
    local localClientOnMessageReceived = localClient and function(messageName, ...) localClient:AddMessageToQueue(clientHandlers, messageName, ...) end or nil

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
        self.physicsSystem:Tick(SECONDS_PER_TICK)
        self:Tick(SECONDS_PER_TICK)
    end
end

function ServerMixin:Tick(delta)
    self:ProcessMessages()

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

function ServerMixin:GetEntityGraph()
    return self.entityGraph
end

function ServerMixin:CreateEntity(entityMixin, parentEntity, relativeLocation, ...)
    local gameEntity = CreateFromMixins(entityMixin)
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