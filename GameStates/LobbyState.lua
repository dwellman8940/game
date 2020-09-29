local addonName, envTable = ...
setfenv(1, envTable)

LobbyStateMixin = CreateFromMixins(GameStateMixin)

local ClientMessageHandlers = {}

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
end

function LobbyStateMixin:HostGame(lobbyCode)
    self.server = CreateServer()

    self:CreateNetworkConnection(lobbyCode, self.server)
    self.server:CreateNetworkConnection(lobbyCode, self)

    -- todo: real lobby
    local playersInLobby = {
        "Ladreiline",
        "Cereekeloran",
        --"Dorbland"
    }

    self.server:BeginGame(playersInLobby)
end

function LobbyStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode, self.server)
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
end

function LobbyStateMixin:AddMessageToQueue(messageName, ...)
    table.insert(self.messageQueue, { messageName, ... })
end

function LobbyStateMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local messageName = messageData[1]
            ClientMessageHandlers[messageName](self, unpack(messageData, 2))
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

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end

    self.physicsSystem:Tick(delta)
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
function ClientMessageHandlers:ResetGame()
    --self:ResetGame()
end

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