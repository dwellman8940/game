local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_RequireGroup = DebugViews.RegisterView("Client", "Require Group", true)

MainMenuStateMixin = Mixin.CreateFromMixins(NetworkedGameStateMixin)

local LobbyMessageHandlers = {}

local MainMenuFrame

function MainMenuStateMixin:Begin() -- override
    NetworkedGameStateMixin.Begin(self)

    if MainMenuFrame then
        MainMenuFrame:Show()
    else
        MainMenuFrame = UI.MainMenuUI.CreateMainMenuFrame(self:GetClient():GetRootFrame())
    end

    local callbacks =
    {
        Host = function() self:HostLobby() end,
        Join = function(lobbyHost, lobbyCode) self:JoinLobby(lobbyHost, lobbyCode) end,
        LevelEditor = function() self:LevelEditor() end,
    }
    MainMenuFrame:SetCallbacks(callbacks)

    self:CreateLobbyConnection(LobbyMessageHandlers)
    self.activeLobbies = {}
end

function MainMenuStateMixin:End() -- override
    NetworkedGameStateMixin.End(self)

    MainMenuFrame:Close()

    self.activeLobbies = nil
end

function MainMenuStateMixin:OnDisconnected(serverDisconnectReason)
    Debug.Print(serverDisconnectReason)
    if serverDisconnectReason == Server.RemovedReason.HostLeft then
        MainMenuFrame:ShowAlert(Localization.GetString("DisconnectedReason_HostLeft"), Localization.GetString("ButtonOK"))
    elseif serverDisconnectReason == Server.RemovedReason.Kicked then
        MainMenuFrame:ShowAlert(Localization.GetString("DisconnectedReason_Kicked"), Localization.GetString("ButtonOK"))
    elseif serverDisconnectReason == Server.RemovedReason.TimedOut then
        MainMenuFrame:ShowAlert(Localization.GetString("DisconnectedReason_TimedOut"), Localization.GetString("ButtonOK"))
    end
end

function MainMenuStateMixin:OnFailedToConnectToLobby(lobbyJoinResponse)
    UI.LoadingScreenUI.End()
    self.sendLobbyRequestTime = nil

    if not lobbyJoinResponse or lobbyJoinResponse == LobbyJoinResponse.Unknown then
        MainMenuFrame:ShowAlert(Localization.GetString("UnableToConnectToLobby"), Localization.GetString("ButtonOK"))
    elseif lobbyJoinResponse == LobbyJoinResponse.Full then
        MainMenuFrame:ShowAlert(Localization.GetString("UnableToConnectToLobby_Full"), Localization.GetString("ButtonOK"))
    end
end

function MainMenuStateMixin:MarkLobbiesChanged()
    self.lobbiesChanged = true
end

function MainMenuStateMixin:UpdateOrAddLobby(timeStamp, lobbyCode, hostPlayer, numPlayers, maxPlayers, versionString)
    self.activeLobbies[lobbyCode] = {
        timeStamp = timeStamp,
        lobbyCode = lobbyCode,
        hostPlayer = hostPlayer,
        numPlayers = numPlayers,
        maxPlayers = maxPlayers,
        versionString = versionString,
    }

    self:MarkLobbiesChanged()
end

function MainMenuStateMixin:CloseLobby(lobbyCode)
    if self.activeLobbies[lobbyCode] then
        self.activeLobbies[lobbyCode] = nil

        self:MarkLobbiesChanged()
    end
end

local LOBBY_TIMEOUT = 10
function MainMenuStateMixin:PurgeStaleLobbies()
    local now = GetTime()
    for lobbyCode, lobbyData in pairs(self.activeLobbies) do
        local delta = now - lobbyData.timeStamp
        if delta >= LOBBY_TIMEOUT then
            self.activeLobbies[lobbyCode] = nil
            self:MarkLobbiesChanged()
        end
    end
end

function MainMenuStateMixin:CheckJoinRequestTimeout()
    if self.sendLobbyRequestTime then
        local lobbyRequestDelta = GetTime() - self.sendLobbyRequestTime
        if lobbyRequestDelta > 8 then
            self:OnFailedToConnectToLobby(nil)
        end
    end
end

function MainMenuStateMixin:Tick(delta) -- override
    NetworkedGameStateMixin.Tick(self, delta)

    self:CheckJoinRequestTimeout()

    if not self.activeLobbies then
        return
    end

    self:PurgeStaleLobbies()

    local missingGroup = DebugView_RequireGroup:IsViewEnabled() and not (IsInRaid() or IsInGroup())
    MainMenuFrame:SetHasGroup(not missingGroup)

    if self.lobbiesChanged then
        self.lobbiesChanged = nil
        self:RefreshLobbyDisplay()
    end
end

function MainMenuStateMixin:HostLobby()
    local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
    lobbyState:HostLobby()
end

function MainMenuStateMixin:JoinLobby(hostPlayer, lobbyCode)
    UI.LoadingScreenUI.ConnectingToLobby(hostPlayer)
    self.sendLobbyRequestTime = GetTime()
    self:SendLobbyMessage("JoinLobby", lobbyCode, UnitName("player"))
end

function MainMenuStateMixin:JoinLobbyResponse(lobbyCode, response)
    if response == LobbyJoinResponse.Success then
        local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
        lobbyState:JoinGame(lobbyCode)
    else
        self:OnFailedToConnectToLobby(response)
    end
end

function MainMenuStateMixin:LevelEditor()
    self:GetClient():SwitchToGameState(LevelEditorStateMixin)
end

function MainMenuStateMixin:RefreshLobbyDisplay()
    MainMenuFrame:UpdateLobbies(self.activeLobbies)
end

function LobbyMessageHandlers:BroadcastLobby(lobbyCode, hostPlayer, numPlayers, maxPlayers, versionString)
    self:UpdateOrAddLobby(GetTime(), lobbyCode, hostPlayer, numPlayers, maxPlayers, versionString)
end

function LobbyMessageHandlers:CloseLobby(lobbyCode)
    self:CloseLobby(lobbyCode)
end

function LobbyMessageHandlers:JoinLobbyResponse(lobbyCode, targetPlayer, response)
    if targetPlayer == UnitName("player") then
        self:JoinLobbyResponse(lobbyCode, response)
    end
end