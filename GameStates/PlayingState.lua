local addonName, envTable = ...
setfenv(1, envTable)

local PlayingStateMixin = CreateFromMixins(NetworkedGameStateMixin)

local ClientMessageHandlers = {}
local PeerToPeerMessageHandlers = {}

function PlayingStateMixin:Begin() -- override
    NetworkedGameStateMixin.Begin(self)

    self.localPlayer = nil

    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(self)

    self.remotePlayers = {}
end

function PlayingStateMixin:End() -- override
    NetworkedGameStateMixin.End(self)

    local entityGraph = self:GetEntityGraph()
    if entityGraph then
        for i, entity in entityGraph:EnumerateAll() do
            entity:DestroyInternal()
        end
    end

    if self.server then
        self.server:Destroy()
        self.server = nil
    end
end

function PlayingStateMixin:HostGame(lobbyCode, playersInLobby)
    self.server = CreateServer()

    self:CreateNetworkConnection(lobbyCode, self.server)
    self.server:CreateNetworkConnection(lobbyCode, self)

    self.server:BeginGame(playersInLobby, "Test")
end

function PlayingStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode)
end

function PlayingStateMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function PlayingStateMixin:CreateNetworkConnection(lobbyCode, localServer)
    self:CreatePeerToPeerConnection(lobbyCode, PeerToPeerMessageHandlers, localServer)
    self:CreateClientNetworkConnection(lobbyCode, ClientMessageHandlers, localServer)
end

function PlayingStateMixin:GetEntityGraph()
    return self.entityGraph
end

function PlayingStateMixin:Render(delta) -- override
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:RenderInternal(delta)
    end

    self.physicsSystem:Render(delta)
end

function PlayingStateMixin:Tick(delta) -- override
    NetworkedGameStateMixin.Tick(self, delta)

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end

    self.physicsSystem:Tick(delta)
end

function PlayingStateMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function PlayingStateMixin:CreateEntity(entityMixin, parentEntity, relativeLocation, ...)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation, ...)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

-- Message Handlers --
function ClientMessageHandlers:LoadLevel(levelName)
    self:LoadLevel(levelName)
end

function ClientMessageHandlers:InitPlayer(playerName, playerID, location, velocity)
    if playerName == UnitName("player") then
        if not self.localPlayer then
            self.localPlayer = self:CreateEntity(PlayerEntityMixin, nil, nil, playerName)
            self.localPlayer:SetIsLobby(true)
            self.localPlayer:SetPlayerID(playerID)
            self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
            self:GetClient():BindKeyboardToPlayer(self.localPlayer)
        end
    else
        if not self.remotePlayers[playerID] then
            local remotePlayer = self:CreateEntity(PlayerEntityMixin, nil, nil, playerName)
            remotePlayer:SetIsLobby(true)
            remotePlayer:SetPlayerID(playerID)
            remotePlayer:ApplyRemoveMovement(location, velocity)

            self.remotePlayers[playerID] = remotePlayer
        end
    end
end

function ClientMessageHandlers:Debug_ReplicateAABB(aabb)
    Debug.DrawDebugAABB(ZeroVector, aabb)
end

function PeerToPeerMessageHandlers:OnMovement(playerID, location, velocity)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:ApplyRemoveMovement(location, velocity)
    end
end