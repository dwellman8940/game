local GameTooltip = GameTooltip

local addonName, envTable = ...
setfenv(1, envTable)

UI.MainMenuUI = {}

local MainMenuFrameMixin = {}

function MainMenuFrameMixin:Initialize(callbacks)
    self.callbacks = callbacks

    self:SetAllPoints(self:GetParent())

    local BORDER_SIZE = 3
    self:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    self:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)

    Background.AddStandardBackground(self, BORDER_SIZE)

    do
        local PartyLabel = self:CreateFontString(nil, "ARTWORK")
        PartyLabel:SetFontObject("GameFontNormalHuge")
        PartyLabel:SetText(Localization.GetString("PartyRequired"))
        PartyLabel:SetPoint("CENTER", 0, 170)
        self.PartyLabel = PartyLabel
    end

    do
        local HostGameButton = Button.CreateLargeButton(self)
        HostGameButton:SetPoint("CENTER", 0, 100)
        HostGameButton:SetText(Localization.GetString("HostGame"))
        HostGameButton:SetScript("OnClick", callbacks.Host)
        self.HostGameButton = HostGameButton
    end

    do
        local JoinGameButton = Button.CreateLargeButton(self)
        JoinGameButton:SetPoint("CENTER")
        JoinGameButton:SetText(Localization.GetString("JoinGame"))
        JoinGameButton:SetScript("OnClick", function() self:SetLobbyDisplayShown(true) end)
        self.JoinGameButton = JoinGameButton
    end

    do
        -- TODO
        local OptionsButton = Button.CreateLargeButton(self)
        OptionsButton:SetPoint("CENTER", 0, -100)
        OptionsButton:SetText(Localization.GetString("Options"))
        OptionsButton:SetScript("OnClick", function() end)
    end

    do
        local ExitButton = Button.CreateStandardButton(self)
        ExitButton:SetPoint("BOTTOMRIGHT", -10, 10)
        ExitButton:SetText(Localization.GetString("Exit"))
        ExitButton:SetScript("OnClick", function() GameFrame:Hide() end)
    end

    do
        local LevelEditorButton = Button.CreateStandardButton(self)
        LevelEditorButton:SetPoint("BOTTOMLEFT", 10, 10)
        LevelEditorButton:SetText(Localization.GetString("LevelEditor"))
        LevelEditorButton:SetScript("OnClick", callbacks.LevelEditor)
    end
end

function MainMenuFrameMixin:SetHasGroup(hasGroup)
    self.PartyLabel:SetShown(not hasGroup)

    self.HostGameButton:SetEnabled(hasGroup)
    self.JoinGameButton:SetEnabled(hasGroup)
end

function MainMenuFrameMixin:UpdateLobbies(lobbies)
    assert(lobbies)
    self.lobbies = lobbies

    if self.LobbySelectionFrame and self.LobbySelectionFrame:IsVisible() then
        self.LobbySelectionFrame:UpdateLobbies(self.lobbies)
    end
end

function MainMenuFrameMixin:SetLobbyDisplayShown(shown)
    if not self.LobbySelectionFrame and shown then
        local callbacks =
        {
            Join = self.callbacks.Join,
            CloseDialog = function() self:SetLobbyDisplayShown(false) end,
        }
        self.LobbySelectionFrame = UI.MainMenuUI.CreateJoinLobbyDialog(self, callbacks)
    end

    if self.LobbySelectionFrame then
        self.LobbySelectionFrame:SetShown(shown)
        if shown and self.lobbies then
            self:UpdateLobbies(self.lobbies)
        end
    end
end

function UI.MainMenuUI.CreateMainMenuFrame(parentFrame, callbacks)
    local MainMenuFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(MainMenuFrame, MainMenuFrameMixin)
    MainMenuFrame:Initialize(callbacks)

    return MainMenuFrame
end

local JoinLobbyDialogMixin = {}

function JoinLobbyDialogMixin:Initialize(callbacks)
    self.callbacks = callbacks

    self:CreateSubFrames()

    self:SetFrameStrata("DIALOG")
    self:SetPoint("CENTER")
    self:SetWidth(250)
    self:SetHeight(350)

    self.selectedLobbyCode = nil

    local function RowReset(pool, button)
        button:SetWidth(200)
        button:SetHeight(14)
        button:ClearAllPoints()
        button:Hide()
        button:SetMotionScriptsWhileDisabled(true)
        button:Enable()

        button:SetNormalFontObject("GameFontNormalSmall")
        button:SetDisabledFontObject("GameFontRedSmall")
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

    self.rowPool = CreateFramePool("Button", self, nil, RowReset)
end

local function IsLobbyFull(lobbyData)
    return lobbyData.numPlayers >= lobbyData.maxPlayers
end

function JoinLobbyDialogMixin:CreateJoinLobbyClosure(lobbies, lobbyData)
    return function()
        if self.selectedLobbyCode ~= lobbyData.lobbyCode and not IsLobbyFull(lobbyData) then
            self.selectedLobbyCode = lobbyData.lobbyCode
            self:UpdateLobbies(lobbies)
        end
    end
end

local function LobbySort(a, b)
    if IsLobbyFull(a) and IsLobbyFull(b) then
        return a.hostPlayer < b.hostPlayer
    end

    if IsLobbyFull(a) then
        return false
    end
    
    if IsLobbyFull(b) then
        return true
    end

    return a.hostPlayer < b.hostPlayer
end

function JoinLobbyDialogMixin:UpdateLobbies(lobbies)
    self.rowPool:ReleaseAll()

    if not next(lobbies) then
        self.selectedLobbyCode = nil
        self.JoinButton:SetEnabled(false)
        self.SearchingForGamesLabel:Show()
        return
    end

    if not lobbies[self.selectedLobbyCode] then
        self.selectedLobbyCode = nil
    end

    local sortedLobbies = {}
    for lobbyCode, lobbyData in pairs(lobbies) do
        table.insert(sortedLobbies, lobbyData)
    end
    table.sort(sortedLobbies, LobbySort)

    local previousRow
    local yPadding = -2
    for i, lobbyData in ipairs(sortedLobbies) do
        local row = self.rowPool:Acquire()
        if previousRow then
            row:SetPoint("TOP", previousRow, "BOTTOM", 0, yPadding)
        else
            row:SetPoint("TOP", self, "TOP", 0, -45)
        end
        row:SetText(("%s %d/%d"):format(lobbyData.hostPlayer, lobbyData.numPlayers, lobbyData.maxPlayers))
        row:SetEnabled(not IsLobbyFull(lobbyData))
        row:Show()

        row:SetScript("OnClick", self:CreateJoinLobbyClosure(lobbies, lobbyData))
        row:SetScript("OnEnter", function()
            if IsLobbyFull(lobbyData) then
                GameTooltip:SetOwner(row, "ANCHOR_NONE")
                GameTooltip:SetPoint("LEFT", row, "RIGHT", 5, 0)
                GameTooltip:SetText(Localization.GetString("LobbyFullTooltip"), Colors.Red:GetRGB())
            end
        end)

        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        if self.selectedLobbyCode == lobbyData.lobbyCode then
            row:LockHighlight()
        else
            row:UnlockHighlight()
        end

        previousRow = row
    end

    self.SearchingForGamesLabel:Hide()
    self.JoinButton:SetEnabled(self.selectedLobbyCode ~= nil)
end

function JoinLobbyDialogMixin:CreateSubFrames()
    local LobbySelectionFrameModal = CreateFrame("Frame", nil, self:GetParent())
    LobbySelectionFrameModal:SetFrameStrata("HIGH")
    LobbySelectionFrameModal:SetAllPoints(self:GetParent())
    LobbySelectionFrameModal:EnableMouse(true)

    self:SetScript("OnShow", function() LobbySelectionFrameModal:Show() end)
    self:SetScript("OnHide", function() LobbySelectionFrameModal:Hide() end)

    Background.AddModalUnderlay(LobbySelectionFrameModal)

    do
        local JoinLabel = self:CreateFontString(nil, "ARTWORK")
        JoinLabel:SetWidth(200)
        JoinLabel:SetFontObject("GameFontNormalHuge")
        JoinLabel:SetText(Localization.GetString("JoinLobbyTitle"))
        JoinLabel:SetPoint("TOP", 0, -15)
    end

    do
        local SearchingForGamesLabel = self:CreateFontString(nil, "ARTWORK")
        SearchingForGamesLabel:SetWidth(200)
        SearchingForGamesLabel:SetFontObject("GameFontHighlight")
        SearchingForGamesLabel:SetText(Localization.GetString("SearchingForHosted"))
        SearchingForGamesLabel:SetPoint("CENTER")

        self.SearchingForGamesLabel = SearchingForGamesLabel
    end

    Background.AddStandardBackground(self)

    do
        local CloseButton = Button.CreateCloseButton(self)
        CloseButton:SetPoint("TOPRIGHT", -2, -2)
        CloseButton:SetScript("OnClick", self.callbacks.CloseDialog)
    end

    do
        local JoinButton = Button.CreateStandardButton(self)
        JoinButton:SetEnabled(false)
        JoinButton:SetText(Localization.GetString("JoinLobby"))
        JoinButton:SetPoint("BOTTOM", 0, 4)
        JoinButton:SetScript("OnClick", function() self.callbacks.Join(self.selectedLobbyCode) end)
        self.JoinButton = JoinButton
    end
end

function UI.MainMenuUI.CreateJoinLobbyDialog(parentFrame, callbacks)
    local LobbySelectionFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(LobbySelectionFrame, JoinLobbyDialogMixin)
    LobbySelectionFrame:Initialize(callbacks)
    return LobbySelectionFrame
end