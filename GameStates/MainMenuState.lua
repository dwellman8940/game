local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_RequireGroup = DebugViews.RegisterView("Client", "Require Group", true)

MainMenuStateMixin = CreateFromMixins(NetworkedGameStateMixin)

local LobbyMessageHandlers = {}

local MainMenuFrame
local LobbySelectionFrame

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
    MainMenuFrame.PartyLabel:SetShown(missingGroup)

    MainMenuFrame.HostGameButton:SetEnabled(not missingGroup)
    MainMenuFrame.JoinGameButton:SetEnabled(not missingGroup)

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
    MainMenuFrame = CreateFrame("Frame", nil, self:GetClient():GetRootFrame())
    MainMenuFrame:SetAllPoints(MainMenuFrame:GetParent())

    local BORDER_SIZE = 3
    MainMenuFrame:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    MainMenuFrame:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)

    Background.AddStandardBackground(MainMenuFrame, BORDER_SIZE)

    do
        local PartyLabel = MainMenuFrame:CreateFontString(nil, "ARTWORK")
        MainMenuFrame.PartyLabel = PartyLabel
        PartyLabel:SetFontObject("GameFontNormalHuge")
        PartyLabel:SetText(Localization.GetString("PartyRequired"))
        PartyLabel:SetPoint("CENTER", 0, 170)
    end

    do
        local HostGameButton = Button.CreateLargeButton(MainMenuFrame)
        MainMenuFrame.HostGameButton = HostGameButton
        HostGameButton:SetPoint("CENTER", 0, 100)
        HostGameButton:SetText(Localization.GetString("HostGame"))
        HostGameButton:SetScript("OnClick", function() self:HostLobby() end)
    end

    do
        local JoinGameButton = Button.CreateLargeButton(MainMenuFrame)
        MainMenuFrame.JoinGameButton = JoinGameButton
        JoinGameButton:SetPoint("CENTER")
        JoinGameButton:SetText(Localization.GetString("JoinGame"))
        JoinGameButton:SetScript("OnClick", function() self:SetLobbyDisplayShown(true) end)
    end

    do
        -- TODO
        local OptionsButton = Button.CreateLargeButton(MainMenuFrame)
        OptionsButton:SetPoint("CENTER", 0, -100)
        OptionsButton:SetText(Localization.GetString("Options"))
        OptionsButton:SetScript("OnClick", function() end)
    end

    do
        local ExitButton = Button.CreateStandardButton(MainMenuFrame)
        ExitButton:SetPoint("BOTTOMRIGHT", -10, 10)
        ExitButton:SetText(Localization.GetString("Exit"))
        ExitButton:SetScript("OnClick", function() GameFrame:Hide() end)
    end

    do
        local LevelEditorButton = Button.CreateStandardButton(MainMenuFrame)
        LevelEditorButton:SetPoint("BOTTOMLEFT", 10, 10)
        LevelEditorButton:SetText(Localization.GetString("LevelEditor"))
        LevelEditorButton:SetScript("OnClick", function() self:LevelEditor() end)
    end
end

function MainMenuStateMixin:RefreshLobbyDisplay()
    if not LobbySelectionFrame or not LobbySelectionFrame:IsShown() then
        return
    end

    LobbySelectionFrame:UpdateLobbies(self.activeLobbies)
end

function MainMenuStateMixin:SetLobbyDisplayShown(shown)
    if shown and not LobbySelectionFrame then
        self:CreateLobbyDisplay()
    end

    LobbySelectionFrame:SetShown(shown)

    if shown then
        LobbySelectionFrame:UpdateLobbies(self.activeLobbies)
    end
end

function MainMenuStateMixin:CreateLobbyDisplay()
    LobbySelectionFrame = CreateFrame("Frame", nil, MainMenuFrame)
    LobbySelectionFrame:SetFrameStrata("DIALOG")
    LobbySelectionFrame:SetPoint("CENTER")
    LobbySelectionFrame:SetWidth(250)
    LobbySelectionFrame:SetHeight(350)

    local LobbySelectionFrameModal = CreateFrame("Frame", nil, MainMenuFrame)
    LobbySelectionFrameModal:SetFrameStrata("HIGH")
    LobbySelectionFrameModal:SetAllPoints(MainMenuFrame)
    LobbySelectionFrameModal:EnableMouse(true)
    Background.AddModalUnderlay(LobbySelectionFrameModal)


    do
        local JoinLabel = LobbySelectionFrame:CreateFontString(nil, "ARTWORK")
        JoinLabel:SetWidth(200)
        JoinLabel:SetFontObject("GameFontNormalHuge")
        JoinLabel:SetText(Localization.GetString("JoinLobbyTitle"))
        JoinLabel:SetPoint("TOP", 0, -15)
    end

    local SearchingForGamesLabel
    do
        SearchingForGamesLabel = LobbySelectionFrame:CreateFontString(nil, "ARTWORK")
        SearchingForGamesLabel:SetWidth(200)
        SearchingForGamesLabel:SetFontObject("GameFontHighlight")
        SearchingForGamesLabel:SetText(Localization.GetString("SearchingForHosted"))
        SearchingForGamesLabel:SetPoint("CENTER")
    end

    local selectedLobbyCode
    local function CreateJoinLobbyClosure(lobbyData)
        return function()
            if selectedLobbyCode ~= lobbyData.lobbyCode and lobbyData.numPlayers < lobbyData.maxPlayers then
                selectedLobbyCode = lobbyData.lobbyCode
                self:RefreshLobbyDisplay()
            end
        end
    end

    Background.AddStandardBackground(LobbySelectionFrame)

    do
        local CloseButton = Button.CreateCloseButton(LobbySelectionFrame)
        CloseButton:SetPoint("TOPRIGHT", -2, -2)
        CloseButton:SetScript("OnClick", function() self:SetLobbyDisplayShown(false) end)
    end

    local JoinButton
    do
        JoinButton = Button.CreateStandardButton(LobbySelectionFrame)
        JoinButton:SetEnabled(false)
        JoinButton:SetText(Localization.GetString("JoinLobby"))
        JoinButton:SetPoint("BOTTOM", 0, 4)
        JoinButton:SetScript("OnClick", function() self:JoinLobby(selectedLobbyCode) end)
    end

    local function Reset(pool, button)
        button:SetWidth(200)
        button:SetHeight(14)
        button:ClearAllPoints()
        button:Hide()

        button:SetNormalFontObject("GameFontNormalSmall")
        button:SetHighlightFontObject("GameFontHighlightSmall")

        if not button:GetHighlightTexture() then
            do
                local HighlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
                HighlightTexture:SetAllPoints(button)
                HighlightTexture:SetColorTexture(Colors.Yellow:WithAlpha(.25):GetRGBA())

                button:SetHighlightTexture(HighlightTexture)
            end

            do
                local NormalTextureTexture = button:CreateTexture(nil, "HIGHLIGHT")
                NormalTextureTexture:SetAllPoints(button)
                NormalTextureTexture:SetColorTexture(Colors.CursedGrey:WithAlpha(.25):GetRGBA())

                button:SetNormalTexture(NormalTextureTexture)
            end
        end
    end

    local rowPool = CreateFramePool("Button", LobbySelectionFrame, nil, Reset)

    local function LobbySort(a, b)
        return a.lobbyCode < b.lobbyCode
    end
    function LobbySelectionFrame:UpdateLobbies(lobbies)
        rowPool:ReleaseAll()

        if not next(lobbies) then
            selectedLobbyCode = nil
            JoinButton:SetEnabled(false)
            SearchingForGamesLabel:Show()
            return
        end

        if not lobbies[selectedLobbyCode] then
            selectedLobbyCode = nil
        end

        local sortedLobbies = {}
        for lobbyCode, lobbyData in pairs(lobbies) do
            table.insert(sortedLobbies, lobbyData)
        end
        table.sort(sortedLobbies, LobbySort)

        local previousRow
        local yPadding = -2
        for i, lobbyData in ipairs(sortedLobbies) do
            local row = rowPool:Acquire()
            if previousRow then
                row:SetPoint("TOP", previousRow, "BOTTOM", 0, yPadding)
            else
                row:SetPoint("TOP", LobbySelectionFrame, "TOP", 0, -45)
            end
            row:SetText(("%s %d/%d"):format(lobbyData.hostPlayer, lobbyData.numPlayers, lobbyData.maxPlayers))
            row:Show()

            row:SetScript("OnClick", CreateJoinLobbyClosure(lobbyData))

            if selectedLobbyCode == lobbyData.lobbyCode then
                row:LockHighlight()
            else
                row:UnlockHighlight()
            end

            previousRow = row
        end

        SearchingForGamesLabel:Hide()
        JoinButton:SetEnabled(selectedLobbyCode ~= nil)
    end
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