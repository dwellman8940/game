local addonName, envTable = ...
setfenv(1, envTable)

UI.LobbyUI = {}

local LobbyFrame
local LobbyFrameMixin = {}

function UI.LobbyUI.Open(callbacks)
    if not LobbyFrame then
        LobbyFrame = UI.CreateFrameFromMixin(UI.GetUIParentFrame(), LobbyFrameMixin)
    end

    LobbyFrame:SetCallbacks(callbacks)
    LobbyFrame:Show()
end

function UI.LobbyUI.SetIsHost(isHost)
    LobbyFrame:SetIsHost(isHost)
end

function UI.LobbyUI.UpdateNumPlayers(numPlayers, maxPlayers)
    LobbyFrame:UpdateNumPlayers(numPlayers, maxPlayers)
end

function UI.LobbyUI.UpdateGameStartCountdown(timeLeft)
    LobbyFrame:UpdateGameStartCountdown(timeLeft)
end

function UI.LobbyUI.Close()
    if LobbyFrame then
        LobbyFrame:OnClosed()
    end
end

function LobbyFrameMixin:Initialize()
    self:SetAllPoints(self:GetParent())

    do
        local SettingsIcon = Button.CreateIconButton(self, 136243)
        SettingsIcon:SetPoint("TOPRIGHT", -10, -10)

        -- TODO: Open actual options
        SettingsIcon:SetScript("OnClick", function() self.callbacks.ExitToMainMenu() end)
    end

    do
        local StartButton = Button.CreateStandardButton(self)
        self.StartButton = StartButton
        StartButton:SetText(Localization.GetString("StartGame"))
        StartButton:SetScript("OnClick", function() self:StartGame() end)
        StartButton:SetPoint("BOTTOM", 0, 90)
        StartButton:Hide()
    end

    do
        local PlayersLabel = self:CreateFontString()
        self.PlayersLabel = PlayersLabel
        PlayersLabel:SetFontObject("GameFontHighlightHugeOutline2")
        PlayersLabel:SetPoint("BOTTOM", 0, 130)
    end

    do
        local GameStartCountdown = self:CreateFontString()
        self.GameStartCountdown = GameStartCountdown
        GameStartCountdown:SetFontObject("GameFontNormalHuge3Outline")
        GameStartCountdown:SetPoint("BOTTOM", 0, 90)
    end
end

function LobbyFrameMixin:OnClosed()
    self:SetCallbacks(nil)
    self:SetIsHost(false)
    self.GameStartCountdown:Hide()
    self:Hide()
end

function LobbyFrameMixin:SetCallbacks(callbacks)
    self.callbacks = callbacks
end

function LobbyFrameMixin:SetIsHost(isHost)
    self.StartButton:SetShown(isHost)
end

function LobbyFrameMixin:UpdateNumPlayers(numPlayers, maxPlayers)
    self.PlayersLabel:SetFormattedText(Localization.GetString("NumPlayersOnLobby"), numPlayers, maxPlayers)
end

function LobbyFrameMixin:UpdateGameStartCountdown(timeLeft)
    local timeLeftSeconds = math.max(math.ceil(timeLeft), 0)
    self.GameStartCountdown:SetText(timeLeftSeconds)
    self.GameStartCountdown:Show()
end

function LobbyFrameMixin:StartGame()
    self.StartButton:Hide()
    self.callbacks.StartGame()
end