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
        self:CreateMainMenuFrame()
    end

    self:CreateLobbyConnection(LobbyMessageHandlers)
    self.activeLobbies = {}
end

function MainMenuStateMixin:End() -- override
    NetworkedGameStateMixin.End(self)

    MainMenuFrame:Hide()

    self.activeLobbies = nil
end

function MainMenuStateMixin:MarkLobbiesChanged()
    self.lobbiesChanged = true
end

function MainMenuStateMixin:UpdateOrAddLobby(timeStamp, lobbyCode, hostPlayer, numPlayers, maxPlayers)
    self.activeLobbies[lobbyCode] = {
        timeStamp = timeStamp,
        lobbyCode = lobbyCode,
        hostPlayer = hostPlayer,
        numPlayers = numPlayers,
        maxPlayers = maxPlayers,
    }

    self:MarkLobbiesChanged()
end

function MainMenuStateMixin:CloseLobby(lobbyCode)
    if self.activeLobbies[lobbyCode] then
        self.activeLobbies[lobbyCode] = nil

        self:MarkLobbiesChanged()
    end
end

local LOBBY_TIMEOUT = 15
function MainMenuStateMixin:PurgeStaleLobbies()
    local now = GetTime()
    for lobbyCode, lobbyData in pairs(self.activeLobbies) do
        local delta = now - lobbyData.timeStamp
        if delta > LOBBY_TIMEOUT then
            self.activeLobbies[lobbyCode] = nil
            self:MarkLobbiesChanged()
        end
    end
end

function MainMenuStateMixin:Tick(delta) -- override
    NetworkedGameStateMixin.Tick(self, delta)

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

function MainMenuStateMixin:JoinLobby(lobbyCode)
    self:SendLobbyMessage("JoinLobby", lobbyCode, UnitName("player"))
end

function MainMenuStateMixin:JoinLobbyResponse(lobbyCode, response)
    if response == LobbyJoinResponse.Success then
        local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
        lobbyState:JoinGame(lobbyCode)
    end
end

function MainMenuStateMixin:LevelEditor()
    self:GetClient():SwitchToGameState(LevelEditorStateMixin)
end

function MainMenuStateMixin:CreateMainMenuFrame()
    local callbacks =
    {
        Host = function() self:HostLobby() end,
        Join = function(lobbyCode) self:JoinLobby(lobbyCode) end,
        LevelEditor = function() self:LevelEditor() end,
    }
    MainMenuFrame = UI.MainMenuUI.CreateMainMenuFrame(self:GetClient():GetRootFrame(), callbacks)
end

function MainMenuStateMixin:RefreshLobbyDisplay()
    MainMenuFrame:UpdateLobbies(self.activeLobbies)
end

function LobbyMessageHandlers:BroadcastLobby(lobbyCode, hostPlayer, numPlayers, maxPlayers)
    self:UpdateOrAddLobby(GetTime(), lobbyCode, hostPlayer, numPlayers, maxPlayers)
end

function LobbyMessageHandlers:CloseLobby(lobbyCode)
    self:CloseLobby(lobbyCode)
end

function LobbyMessageHandlers:JoinLobbyResponse(lobbyCode, targetPlayer, response)
    if targetPlayer == UnitName("player") then
        self:JoinLobbyResponse(lobbyCode, response)
    end
end