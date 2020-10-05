local addonName, envTable = ...
setfenv(1, envTable)

PlayingStateMixin = Mixin.CreateFromMixins(NetworkedGameStateMixin)

local ClientMessageHandlers = {}
local PeerToPeerMessageHandlers = {}

function PlayingStateMixin:Begin() -- override
    NetworkedGameStateMixin.Begin(self)

    self.localPlayer = nil

    self.entityGraph = CreateEntityGraph()
    self.physicsSystem = CreatePhysicsSystem(self:GetClient())

    self.remotePlayers = {}
end

function PlayingStateMixin:End() -- override
    NetworkedGameStateMixin.End(self)

    local entityGraph = self:GetEntityGraph()
    if entityGraph then
        entityGraph:DestroyAll()
    end

    if self.server then
        self.server:Destroy()
        self.server = nil
    end
end

function PlayingStateMixin:HostGame(lobbyCode, playersInLobby)
    self.server = CreateServer()

    self:CreateNetworkConnection(lobbyCode, self.server)
    self.server:CreateNetworkConnection(lobbyCode, self, ClientMessageHandlers)

    self.server:BeginGame("Test", playersInLobby)
    self:LoadLevel("Test")
    self.server:AddPlayer(UnitName("player"))
end

function PlayingStateMixin:JoinGame(lobbyCode)
    self:CreateNetworkConnection(lobbyCode)
    self:LoadLevel("Test")
    self:SendServerMessage("PlayerReady", UnitName("player"))
end

function PlayingStateMixin:IsHost()
    return self.server ~= nil
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
    local gameEntity = Mixin.CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation, ...)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

-- Message Handlers --
function ClientMessageHandlers:LoadLevel(levelName)
    if not self:IsHost() then
        self:LoadLevel(levelName)
    end
end

function ClientMessageHandlers:InitPlayer(playerName, playerID, location, velocity)
    if playerName == UnitName("player") then
        if self.localPlayer then
            assert(self.localPlayer:GetPlayerID() == playerID)
        else
            self.localPlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
            self.localPlayer:SetPlayerID(playerID)
            self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
            self:GetClient():BindKeyboardToPlayer(self.localPlayer)

            if self:IsHost() then
                self.server:IgnorePlayerTimeout(playerID)
            end

            -- Hacky, should wait for a "all clear" server message
            C_Timer.After(1, function() UI.LoadingScreenUI.Close() end)
        end
    else
        if not self.remotePlayers[playerID] then
            local remotePlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
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