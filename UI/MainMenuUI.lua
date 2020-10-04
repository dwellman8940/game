local GameTooltip = GameTooltip

local addonName, envTable = ...
setfenv(1, envTable)

UI.MainMenuUI = {}

local MainMenuFrameMixin = {}

function MainMenuFrameMixin:Initialize()
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
        HostGameButton:SetScript("OnClick", function() self.callbacks.Host() end)
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
        LevelEditorButton:SetScript("OnClick", function() self.callbacks.LevelEditor() end)
    end
end

function MainMenuFrameMixin:SetCallbacks(callbacks)
    self.callbacks = callbacks
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

function MainMenuFrameMixin:Close()
    self:Hide()
    self.lobbies = nil
    self.callbacks = nil

    if self.LobbySelectionFrame then
        self.LobbySelectionFrame:Hide()
        self.LobbySelectionFrame:SetCallbacks(nil)
        self.LobbySelectionFrame:UpdateLobbies(nil)
    end

    if self.AlertFrame then
        self.AlertFrame:Hide()
    end
end

function MainMenuFrameMixin:SetLobbyDisplayShown(shown)
    if not self.LobbySelectionFrame and shown then
        self.LobbySelectionFrame = UI.MainMenuUI.CreateJoinLobbyDialog(self)
    end

    if self.LobbySelectionFrame then
        self.LobbySelectionFrame:SetShown(shown)
        if shown then
            local callbacks =
            {
                Join = self.callbacks.Join,
                CloseDialog = function() self:SetLobbyDisplayShown(false) end,
            }
            self.LobbySelectionFrame:SetCallbacks(callbacks)
            self.LobbySelectionFrame:UpdateLobbies(self.lobbies)
        end
    end
end

function MainMenuFrameMixin:ShowAlert(messageText, button1Text, button1Callback)
    if not self.AlertFrame then
        self.AlertFrame = UI.MainMenuUI.CreateAlertDialog(self)
    end
    self:SetLobbyDisplayShown(false)

    self.AlertFrame:ShowMessage(messageText, button1Text, button1Callback)
end

function UI.MainMenuUI.CreateMainMenuFrame(parentFrame)
    local MainMenuFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(MainMenuFrame, MainMenuFrameMixin)
    MainMenuFrame:Initialize()

    return MainMenuFrame
end

local JoinLobbyDialogMixin = {}

function JoinLobbyDialogMixin:Initialize()
    self:CreateSubFrames()

    self:SetFrameStrata("DIALOG")
    self:SetPoint("CENTER")
    self:SetWidth(250)
    self:SetHeight(350)

    self.selectedLobbyData = nil

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

function JoinLobbyDialogMixin:SetCallbacks(callbacks)
    self.callbacks = callbacks
end

local function IsLobbyFull(lobbyData)
    return lobbyData.numPlayers >= lobbyData.maxPlayers
end

local function CompareLobbyVersion(lobbyData)
    local minor, major = Version.GetVersionFromString(lobbyData.versionString)
    return Version.CompareVersions(minor, major)
end

local function IsLobbyVersionSame(lobbyData)
    return CompareLobbyVersion(lobbyData) == Version.CompareResult.Same
end

function JoinLobbyDialogMixin:CreateJoinLobbyClosure(lobbies, lobbyData)
    return function()
        if (not self.selectedLobbyData or self.selectedLobbyData.lobbyCode ~= lobbyData.lobbyCode) and not IsLobbyFull(lobbyData) then
            self.selectedLobbyData = lobbyData
            self:UpdateLobbies(lobbies)
        end
    end
end

local function LobbySort(a, b)
    if IsLobbyVersionSame(a) ~= IsLobbyVersionSame(b) then
        if IsLobbyVersionSame(a) then
            return true
        end
        return false
    end

    if IsLobbyFull(a) ~= IsLobbyFull(b) then
        if IsLobbyFull(a) then
            return false
        end
        return true
    end

    return a.hostPlayer < b.hostPlayer
end

local function CanLobbyBeJoined(lobbyData)
    return not IsLobbyFull(lobbyData) and IsLobbyVersionSame(lobbyData)
end

function JoinLobbyDialogMixin:UpdateLobbies(lobbies)
    self.rowPool:ReleaseAll()

    if not lobbies or not next(lobbies) then
        self.selectedLobbyData = nil
        self.JoinButton:SetEnabled(false)
        self.SearchingForGamesLabel:Show()
        return
    end

    if self.selectedLobbyData and not lobbies[self.selectedLobbyData.lobbyCode] then
        self.selectedLobbyData = nil
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
        row:SetEnabled(CanLobbyBeJoined(lobbyData))
        row:Show()

        row:SetScript("OnClick", self:CreateJoinLobbyClosure(lobbies, lobbyData))
        row:SetScript("OnEnter", function()
            if not IsLobbyVersionSame(lobbyData) then
                GameTooltip:SetOwner(row, "ANCHOR_NONE")
                GameTooltip:SetPoint("LEFT", row, "RIGHT", 5, 0)
                local tooltipText = Localization.GetString(CompareLobbyVersion(lobbyData) == Version.CompareResult.Newer and "LobbyNewerVersionTooltip" or "LobbyOlderVersionTooltip"):format(lobbyData.versionString)
                GameTooltip:SetText(tooltipText, Colors.Red:GetRGB())
            elseif IsLobbyFull(lobbyData) then
                GameTooltip:SetOwner(row, "ANCHOR_NONE")
                GameTooltip:SetPoint("LEFT", row, "RIGHT", 5, 0)
                GameTooltip:SetText(Localization.GetString("LobbyFullTooltip"), Colors.Red:GetRGB())
            end
        end)

        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        if self.selectedLobbyData and self.selectedLobbyData.lobbyCode == lobbyData.lobbyCode then
            row:LockHighlight()
        else
            row:UnlockHighlight()
        end

        previousRow = row
    end

    self.SearchingForGamesLabel:Hide()
    self.JoinButton:SetEnabled(self.selectedLobbyData ~= nil)
end

function JoinLobbyDialogMixin:CreateSubFrames()
    do
        local ModalFrame = CreateFrame("Frame", nil, self:GetParent())
        ModalFrame:SetFrameStrata("HIGH")
        ModalFrame:SetAllPoints(self:GetParent())
        ModalFrame:EnableMouse(true)

        self:SetScript("OnShow", function() ModalFrame:Show() end)
        self:SetScript("OnHide", function() ModalFrame:Hide() end)

        Background.AddModalUnderlay(ModalFrame)
    end

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
        CloseButton:SetScript("OnClick", function() self.callbacks.CloseDialog() end)
    end

    do
        local JoinButton = Button.CreateStandardButton(self)
        JoinButton:SetEnabled(false)
        JoinButton:SetText(Localization.GetString("JoinLobby"))
        JoinButton:SetPoint("BOTTOM", 0, 4)
        JoinButton:SetScript("OnClick", function() self.callbacks.Join(self.selectedLobbyData.hostPlayer, self.selectedLobbyData.lobbyCode) end)
        self.JoinButton = JoinButton
    end
end

function UI.MainMenuUI.CreateJoinLobbyDialog(parentFrame)
    local LobbySelectionFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(LobbySelectionFrame, JoinLobbyDialogMixin)
    LobbySelectionFrame:Initialize()
    return LobbySelectionFrame
end

local AlertDialogFrameMixin = {}

function AlertDialogFrameMixin:Initialize()
    do
        local ModalFrame = CreateFrame("Frame", nil, self:GetParent())
        ModalFrame:SetFrameStrata("HIGH")
        ModalFrame:SetAllPoints(self:GetParent())
        ModalFrame:EnableMouse(true)

        self:SetScript("OnShow", function() ModalFrame:Show() end)
        self:SetScript("OnHide", function() ModalFrame:Hide() end)

        Background.AddModalUnderlay(ModalFrame)
    end

    Background.AddStandardBackground(self)

    self:SetFrameStrata("DIALOG")
    self:SetWidth(250)
    self:SetHeight(130)
    self:SetPoint("CENTER")

    self.MessageText = self:CreateFontString(nil, "ARTWORK")
    self.MessageText:SetFontObject("GameFontHighlight")
    self.MessageText:SetPoint("TOPLEFT", 20, -20)
    self.MessageText:SetPoint("BOTTOMRIGHT", -20, 35)

    self.Button1 = Button.CreateStandardButton(self)
    self.Button2 = Button.CreateStandardButton(self)
end

function AlertDialogFrameMixin:ShowMessage(messageText, button1Text, button1Callback)
    self.MessageText:SetText(messageText)

    self.Button1:SetPoint("BOTTOM", 0, 15)
    self.Button1:SetText(button1Text)
    self.Button1:SetScript("OnClick", button1Callback or function() self:Hide() end)

    self.Button2:Hide()

    self:Show()
end

function UI.MainMenuUI.CreateAlertDialog(parentFrame)
    local AlertDialogFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(AlertDialogFrame, AlertDialogFrameMixin)
    AlertDialogFrame:Initialize()
    return AlertDialogFrame
end