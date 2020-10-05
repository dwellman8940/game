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

    local callbacks =
    {
        ExitToMainMenu = function() self:GetClient():SwitchToGameState(MainMenuStateMixin) end,
        StartGame = function() self:StartGame() end
    }
    UI.LobbyUI.Open(callbacks)
end

function LobbyStateMixin:End()
    UI.LobbyUI.Close()

    if not self:IsGameStarting() then
        if self:IsHost() then
            self:SendLobbyMessage("CloseLobby", self.lobbyCode)
        elseif self.localPlayer then
            self:SendServerMessage("PlayerLeaving", self.localPlayer:GetPlayerID())
        end
    end

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

local TIME_TO_START_GAME = 5
function LobbyStateMixin:StartGame()
    if self:IsHost() then
        self.server:SendMessageToAllClients("GameStartCountdown")
        self.gameStartingTimeLeft = TIME_TO_START_GAME + Networking.GetPingSeconds() * 2
        self:QueueUpLobbyPing()
    else
        self.gameStartingTimeLeft = TIME_TO_START_GAME - Networking.GetPingSeconds() * 2
    end
    UI.LobbyUI.UpdateGameStartCountdown(self.gameStartingTimeLeft)
end

local function GenerateLobbyCode(seed)
    local randomStream = CreateRandomStream(GetTime(), seed)
    local lobbyCode = ""
    for i = 1, 4 do
        lobbyCode = lobbyCode .. randomStream:GetNextPrintableChar()
    end
    return lobbyCode
end

function LobbyStateMixin:IsHost()
    return self.nextLobbyPing ~= nil
end

function LobbyStateMixin:IsGameStarting()
    return self.gameStartingTimeLeft ~= nil
end

function LobbyStateMixin:HostLobby()
    self.server = CreateServer()
    self.lobbyCode = GenerateLobbyCode(tostring(self))

    UI.LobbyUI.SetIsHost(true)

    self:CreateNetworkConnection(self.lobbyCode, self.server)
    self.server:CreateNetworkConnection(self.lobbyCode, self, ClientMessageHandlers)

    self.server:BeginGame("Lobby", { UnitName("player") })
    self:LoadLevel("Lobby")
    self.server:AddPlayer(UnitName("player"))

    self.server:SetOnPlayerAddedCallback(function()
        self:QueueUpLobbyPing()
    end)

    self.server:SetOnPlayerRemovedCallback(function()
        self:QueueUpLobbyPing()
    end)

    self.nextLobbyPing = 0

    -- TODO: Better lobby settings
    self.lobbySettings = {
        MaxPlayers = 10,
    }

    self:UpdateNumPlayerUI()
end

function LobbyStateMixin:UpdateNumPlayerUI()
    UI.LobbyUI.UpdateNumPlayers(self:GetNumPlayersConnected(), self.lobbySettings.MaxPlayers)
end

function LobbyStateMixin:PlayerRequestedJoin(playerName)
    if self:GetNumPlayersConnected() >= self.lobbySettings.MaxPlayers then
        self:SendLobbyMessage("JoinLobbyResponse", self.lobbyCode, playerName, LobbyJoinResponse.Full)
    else
        self:SendLobbyMessage("JoinLobbyResponse", self.lobbyCode, playerName, LobbyJoinResponse.Success)
        self.server:AddPendingPlayer(playerName)
    end
end

function LobbyStateMixin:JoinLobby(lobbyCode)
    -- TODO: Better lobby settings
    self.lobbySettings = {
        MaxPlayers = 10,
    }

    self.lobbyCode = lobbyCode
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
    if self:CheckForServerTimeout() then
        return
    end
    self:CheckLobbyPing()

    if self:UpdateStartGameCountdown(delta) then
        return
    end

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end

    self.physicsSystem:Tick(delta)
end

function LobbyStateMixin:UpdateStartGameCountdown(delta)
    if self:IsGameStarting() then
        self.gameStartingTimeLeft = self.gameStartingTimeLeft - delta
        UI.LobbyUI.UpdateGameStartCountdown(self.gameStartingTimeLeft)
        if self.gameStartingTimeLeft <= 0 then
            UI.LoadingScreenUI.StartingGame()
            if self:IsHost() then
                local playerState = self:GetClient():SwitchToGameState(PlayingStateMixin)

                local playersInLobby = { UnitName("player"), }
                for playerID, playerEntity in pairs(self.remotePlayers) do
                    table.insert(playersInLobby, playerEntity:GetPlayerName())
                end
                playerState:HostGame(self.lobbyCode, playersInLobby)
            else
                local playerState = self:GetClient():SwitchToGameState(PlayingStateMixin)
                playerState:JoinGame(self.lobbyCode)
            end

            return true
        end
    end
    return false
end

function LobbyStateMixin:CheckLobbyPing()
    if self:IsHost() then
        if self:IsGameStarting() then
            if self.queuedLobbyPing then
                self.queuedLobbyPing = nil
                self:BroadcastLobbyState()
            end
        else
            local now = GetTime()
            if now >= self.nextLobbyPing or self.queuedLobbyPing then
                self.queuedLobbyPing = nil
                self:BroadcastLobbyState()
                self.nextLobbyPing = now + TIME_BETWEEN_LOBBY_PINGS
            end
    end
    end
end

local SERVER_TIMEOUT = 10
function LobbyStateMixin:CheckForServerTimeout()
    if not self:IsHost() then
        if self:HasClientToServerConnection() and not self:HasRecentServerToClientActivity(SERVER_TIMEOUT) then
            local mainMenu = self:GetClient():SwitchToGameState(MainMenuStateMixin)
            mainMenu:OnDisconnected(Server.RemovedReason.TimedOut)
            return true
        end
    end
    return false
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
    self:SendLobbyMessage("BroadcastLobby", self.lobbyCode, UnitName("player"), self:IsGameStarting(), self:GetNumPlayersConnected(), self.lobbySettings.MaxPlayers, Version.GetVersionAsString())
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
        if self.localPlayer then
            assert(self.localPlayer:GetPlayerID() == playerID)
        else
            self.localPlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
            self.localPlayer:SetIsLobby(true)
            self.localPlayer:SetPlayerID(playerID)
            self.localPlayer:MarkAsLocalPlayer(self:GetClient():GetWorldFrame())
            self:GetClient():BindKeyboardToPlayer(self.localPlayer)

            if self.server then
                self.server:IgnorePlayerTimeout(playerID)
            end

            UI.LoadingScreenUI.Close()
        end
    else
        if not self.remotePlayers[playerID] then
            local remotePlayer = self:CreateEntity(PlayerEntityMixin, nil, location, playerName)
            remotePlayer:SetIsLobby(true)
            remotePlayer:SetPlayerID(playerID)
            remotePlayer:ApplyRemoveMovement(location, velocity)

            self.remotePlayers[playerID] = remotePlayer

            self:UpdateNumPlayerUI()
        end
    end
end

function ClientMessageHandlers:Ping(...)
    if self.localPlayer then
        local localPlayerID = self.localPlayer:GetPlayerID()
        if VarArgs.Contains(localPlayerID, ...) then
            self:SendServerMessage("Pong", localPlayerID)
        end
    end
end

function ClientMessageHandlers:RemovePlayer(playerID, removedReason)
    if self.localPlayer and self.localPlayer:GetPlayerID() == playerID then
        local mainMenu = self:GetClient():SwitchToGameState(MainMenuStateMixin)
        mainMenu:OnDisconnected(removedReason)
    else
        local remotePlayer = self.remotePlayers[playerID]
        if remotePlayer then
            self.remotePlayers[playerID] = nil
            self:GetEntityGraph():DestroyEntity(remotePlayer)

            self:UpdateNumPlayerUI()
        end
    end
end

function ClientMessageHandlers:GameStartCountdown()
    if not self:IsHost() then
        self:StartGame()
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

function LobbyMessageHandlers:CloseLobby(lobbyCode)
    if not self:IsHost() and self.lobbyCode == lobbyCode then
        local mainMenu = self:GetClient():SwitchToGameState(MainMenuStateMixin)
        mainMenu:OnDisconnected(Server.RemovedReason.HostLeft)
    end
end