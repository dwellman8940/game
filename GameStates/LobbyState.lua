local addonName, envTable = ...
setfenv(1, envTable)

LobbyJoinResponse =
{
    Success = 1,
    Full = 2,
    Unknown = 3,
}

LobbyStateMixin = Mixin.CreateFromMixins(NetworkedGameStateMixin)

local TIME_BETWEEN_LOBBY_PINGS = 5

local LobbyMessageHandlers = {}
local ClientMessageHandlers = {}
local PeerToPeerMessageHandlers = {}

function LobbyStateMixin:Begin()
    NetworkedGameStateMixin.Begin(self)

    self.localPlayer = nil

    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(self:GetClient())

    self.remotePlayers = {}
end

function LobbyStateMixin:End()
    if self.lobbyCode then
        self:SendLobbyMessage("CloseLobby", self.lobbyCode)
    end

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
    self.server:CreateNetworkConnection(self.lobbyCode, self, ClientMessageHandlers)

    self.server:BeginGame("Lobby", { UnitName("player") })
    self:LoadLevel("Lobby")

    self.nextLobbyPing = 0

    -- TODO: Better lobby settings
    self.lobbySettings = {
        MaxPlayers = 10,
    }
end

function LobbyStateMixin:PlayerRequestedJoin(playerName)
    if self:GetNumPlayersConnected() >= self.lobbySettings.MaxPlayers then
        self:SendLobbyMessage("JoinLobbyResponse", self.lobbyCode, playerName, LobbyJoinResponse.Full)
    else
        self:SendLobbyMessage("JoinLobbyResponse", self.lobbyCode, playerName, LobbyJoinResponse.Success)
        self.server:AddPendingPlayer(playerName)
    end
end

function LobbyStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode)
    self:LoadLevel("Lobby")
    self:SendServerMessage("PlayerReady", UnitName("player"))
end

function LobbyStateMixin:LoadLevel(levelName)
    Level.Load(self, levelName)
    self:GetPhysicsSystem():FinalizeStaticShapes()
end

function LobbyStateMixin:CreateNetworkConnection(lobbyCode, localServer)
    self:CreatePeerToPeerConnection(lobbyCode, PeerToPeerMessageHandlers, localServer)
    self:CreateClientNetworkConnection(lobbyCode, ClientMessageHandlers, localServer)
    self:CreateLobbyConnection(LobbyMessageHandlers)
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
    NetworkedGameStateMixin.Tick(self, delta)
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
    self:SendLobbyMessage("BroadcastLobby", self.lobbyCode, UnitName("player"), self:GetNumPlayersConnected(), self.lobbySettings.MaxPlayers)
end

function LobbyStateMixin:GetPhysicsSystem()
    return self.physicsSystem
end

function LobbyStateMixin:CreateEntity(entityMixin, parentEntity, relativeLocation, ...)
    local gameEntity = Mixin.CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation, ...)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

-- Message Handlers --
function ClientMessageHandlers:InitPlayer(playerName, playerID, location, velocity)
    if playerName == UnitName("player") then
        if not self.localPlayer then
            self.localPlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
            self.localPlayer:SetIsLobby(true)
            self.localPlayer:SetPlayerID(playerID)
            self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
            self:GetClient():BindKeyboardToPlayer(self.localPlayer)
        end
    else
        if not self.remotePlayers[playerID] then
            local remotePlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
            remotePlayer:SetIsLobby(true)
            remotePlayer:SetPlayerID(playerID)
            remotePlayer:ApplyRemoveMovement(location, velocity)

            self.remotePlayers[playerID] = remotePlayer
        end
    end
end

function PeerToPeerMessageHandlers:OnMovement(playerID, location, velocity)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:ApplyRemoveMovement(location, velocity)
    end
end

function ClientMessageHandlers:Debug_ReplicateAABB(aabb)
    Debug.DrawDebugAABB(ZeroVector, aabb)
end

function LobbyMessageHandlers:JoinLobby(lobbyCode, playerName)
    if self:IsHost() and self.lobbyCode == lobbyCode then
        self:PlayerRequestedJoin(playerName)
    end
end