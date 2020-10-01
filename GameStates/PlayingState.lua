local addonName, envTable = ...
setfenv(1, envTable)

local PlayingStateMixin = CreateFromMixins(GameStateMixin)

local ClientMessageHandlers = {}

function PlayingStateMixin:Begin()
    self.messageQueue = {}

    self.localPlayer = nil

    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(self)

    self.remotePlayers = {}
end

function PlayingStateMixin:End()
    local entityGraph = self:GetEntityGraph()
    if entityGraph then
        for i, entity in entityGraph:EnumerateAll() do
            entity:DestroyInternal()
        end
    end
    if self.server then
        self.server:Disconnect()
    end
    self.clientNetworkConnection:Disconnect()
    self.peerNetworkConnection:Disconnect()
end

function PlayingStateMixin:HostGame(lobbyCode, playersInLobby)
    self.server = CreateServer()

    self:CreateNetworkConnection(lobbyCode, self.server)
    self.server:CreateNetworkConnection(lobbyCode, self)

    self.server:BeginGame(playersInLobby, "Test")
end

function PlayingStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode, self.server)
end

function PlayingStateMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function PlayingStateMixin:CreateNetworkConnection(lobbyCode, localServer)
    local localServerOnMessageReceived = localServer and function(messageName, ...) localServer:AddMessageToQueue(messageName, ...) end or nil

    local function OnMessageReceived(messageName, ...)
        self:AddMessageToQueue(messageName, ...)
    end

    local onServerMessageReceived = OnMessageReceived
    self.clientNetworkConnection = CreateClientConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onServerMessageReceived)

    local onPeerMessageReceived = OnMessageReceived
    self.peerNetworkConnection = CreatePeerConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onPeerMessageReceived)
end

function PlayingStateMixin:AddMessageToQueue(messageName, ...)
    table.insert(self.messageQueue, { messageName, ... })
end

function PlayingStateMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local messageName = messageData[1]
            ClientMessageHandlers[messageName](self, unpack(messageData, 2))
        end
        self.messageQueue = {}
    end
end

function PlayingStateMixin:GetEntityGraph()
    return self.entityGraph
end

function PlayingStateMixin:Render(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:RenderInternal(delta)
    end

    self.physicsSystem:Render(delta)
end

function PlayingStateMixin:Tick(delta)
    self:ProcessMessages()

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end

    self.physicsSystem:Tick(delta)
end

function PlayingStateMixin:SendMessage(messageName, ...)
    self.clientNetworkConnection:SendMessageToServer(messageName, ...)
end

function PlayingStateMixin:SendMessageToPeers(messageName, ...)
    self.peerNetworkConnection:SendMessageToPeers(messageName, ...)
end

function PlayingStateMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function PlayingStateMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

-- Message Handlers --
function ClientMessageHandlers:LoadLevel(levelName)
    self:LoadLevel(levelName)
end

function ClientMessageHandlers:InitPlayer(playerName, playerID)
    if playerName == UnitName("player") then
        self.localPlayer = self:CreateEntity(PlayerEntityMixin)
        self.localPlayer:SetPlayerID(playerID)
        self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
        self:GetClient():BindKeyboardToPlayer(self.localPlayer)
    else
        local remotePlayer = self:CreateEntity(PlayerEntityMixin)
        remotePlayer:SetPlayerID(playerID)

        self.remotePlayers[playerID] = remotePlayer
    end
end

function ClientMessageHandlers:OnMovement(playerID, location, velocity)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:ApplyRemoveMovement(location, velocity)
    end
end

function ClientMessageHandlers:Debug_ReplicateAABB(aabb)
    Debug.DrawDebugAABB(ZeroVector, aabb)
end