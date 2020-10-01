local addonName, envTable = ...
setfenv(1, envTable)

LobbyStateMixin = CreateFromMixins(GameStateMixin)

local TIME_BETWEEN_LOBBY_PINGS = 10

local LobbyMessageHandlers = {}

function LobbyStateMixin:Begin()
    self.messageQueue = {}

    self.localPlayer = nil

    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(self)

    self.remotePlayers = {}
end

function LobbyStateMixin:End()
    local entityGraph = self:GetEntityGraph()
    if entityGraph then
        for i, entity in entityGraph:EnumerateAll() do
            entity:DestroyInternal()
        end
    end
    self.server:Disconnect()
    self.clientNetworkConnection:Disconnect()
    self.peerNetworkConnection:Disconnect()
    self.lobbyNetworkConnection:Disconnect()
end

local function GenerateLobbyCode()
    -- 8 values should be plenty unique enough to avoid collisions in the same group/raid
    return UnitGUID("player"):sub(-8)
end

function LobbyStateMixin:IsHost()
    return self.nextLobbyPing ~= nil
end

function LobbyStateMixin:HostLobby()
    self.server = CreateServer()
    self.lobbyCode = GenerateLobbyCode()

    self:CreateNetworkConnection(self.lobbyCode, self.server)
    self.server:CreateNetworkConnection(self.lobbyCode, self)

    self.server:BeginGame("Lobby", { UnitName("player") })

    self.nextLobbyPing = 0

    -- TODO: Better lobby settings
    self.lobbySettings = {
        MaxPlayers = 10,
    }
end

function LobbyStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode)
end

function LobbyStateMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function LobbyStateMixin:CreateNetworkConnection(lobbyCode, localServer)
    local localServerOnMessageReceived = localServer and function(messageName, ...) localServer:AddMessageToQueue(messageName, ...) end or nil

    local function OnMessageReceived(messageName, ...)
        self:AddMessageToQueue(messageName, ...)
    end

    local onServerMessageReceived = OnMessageReceived
    self.clientNetworkConnection = CreateClientConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onServerMessageReceived)

    local onPeerMessageReceived = OnMessageReceived
    self.peerNetworkConnection = CreatePeerConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onPeerMessageReceived)

    self.lobbyNetworkConnection = CreateLobbyConnection(UnitName("player"), OnMessageReceived)
end

function LobbyStateMixin:AddMessageToQueue(messageName, ...)
    table.insert(self.messageQueue, { messageName, ... })
end

function LobbyStateMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local messageName = messageData[1]
            LobbyMessageHandlers[messageName](self, unpack(messageData, 2))
        end
        self.messageQueue = {}
    end
end

function LobbyStateMixin:GetEntityGraph()
    return self.entityGraph
end

function LobbyStateMixin:Render(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:RenderInternal(delta)
    end

    self.physicsSystem:Render(delta)
end

function LobbyStateMixin:Tick(delta)
    self:ProcessMessages()
    self:CheckLobbyPing()

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end

    self.physicsSystem:Tick(delta)
end

function LobbyStateMixin:CheckLobbyPing()
    if self:IsHost() then
        local now = GetTime()
        if now >= self.nextLobbyPing or self.queuedLobbyPing then
            self.queuedLobbyPing = nil
            self:BroadcastLobbyState()
            self.nextLobbyPing = now +TIME_BETWEEN_LOBBY_PINGS
        end
    end
end

function LobbyStateMixin:QueueUpLobbyPing()
    self.queuedLobbyPing = true
end

function LobbyStateMixin:GetNumPlayersConnected()
    local playerCount = 1
    for playerID in pairs(self.remotePlayers) do
        playerCount = playerCount + 1
    end
    return playerCount
end

function LobbyStateMixin:BroadcastLobbyState()
    self.lobbyNetworkConnection:SendMessageToLobby("BroadcastLobby", self.lobbyCode, UnitName("player"), self:GetNumPlayersConnected(), self.lobbySettings.MaxPlayers)
end

function LobbyStateMixin:SendMessage(messageName, ...)
    self.clientNetworkConnection:SendMessageToServer(messageName, ...)
end

function LobbyStateMixin:SendMessageToPeers(messageName, ...)
    self.peerNetworkConnection:SendMessageToPeers(messageName, ...)
end

function LobbyStateMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function LobbyStateMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

-- Message Handlers --
function LobbyMessageHandlers:LoadLevel(levelName)
    self:LoadLevel(levelName)
end

function LobbyMessageHandlers:InitPlayer(playerName, playerID)
    if playerName == UnitName("player") then
        self.localPlayer = self:CreateEntity(PlayerEntityMixin)
        self.localPlayer:SetIsLobby(true)
        self.localPlayer:SetPlayerID(playerID)
        self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
        self:GetClient():BindKeyboardToPlayer(self.localPlayer)
    else
        local remotePlayer = self:CreateEntity(PlayerEntityMixin)
        remotePlayer:SetIsLobby(true)
        remotePlayer:SetPlayerID(playerID)

        self.remotePlayers[playerID] = remotePlayer
    end
end

function LobbyMessageHandlers:OnMovement(playerID, location, velocity)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:ApplyRemoveMovement(location, velocity)
    end
end

function LobbyMessageHandlers:Debug_ReplicateAABB(aabb)
    Debug.DrawDebugAABB(ZeroVector, aabb)
end