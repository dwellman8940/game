local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_RequireParty = DebugViews.RegisterView("Client", "Require Party", true)

MainMenuStateMixin = CreateFromMixins(GameStateMixin)

local MainMenuFrame

function MainMenuStateMixin:Begin()
    if MainMenuFrame then
        MainMenuFrame:Show()
    else
        self:CreateMainMenuFrame()
    end
end

function MainMenuStateMixin:End()
    MainMenuFrame:Hide()
end

function MainMenuStateMixin:Tick(delta)
    local missingGroup = DebugView_RequireParty:IsViewEnabled() and not (IsInRaid() or IsInGroup())
    MainMenuFrame.PartyLabel:SetShown(missingGroup)

    MainMenuFrame.HostGameButton:SetEnabled(not missingGroup)
    MainMenuFrame.JoinGameButton:SetEnabled(not missingGroup)
end

function MainMenuStateMixin:HostLobby()
    local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
    lobbyState:HostLobby()
end

function MainMenuStateMixin:JoinLobby(lobbyCode)
    local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
    lobbyState:JoinGame(lobbyCode)
end

function MainMenuStateMixin:LevelEditor()
    self:GetClient():SwitchToGameState(LevelEditorStateMixin)
end

function MainMenuStateMixin:CreateMainMenuFrame()
    MainMenuFrame = CreateFrame("Frame", nil, self:GetClient():GetRootFrame())
    MainMenuFrame:SetAllPoints(MainMenuFrame:GetParent())

    do
        local Background = MainMenuFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
        local BORDER_SIZE = 3
        Background:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
        Background:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
        Background:SetColorTexture(Colors.Swamp:GetRGBA())
    end

    do
        local Border = MainMenuFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
        Border:SetColorTexture(Colors.Black:GetRGBA())
        Border:SetAllPoints(MainMenuFrame)
    end

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
        JoinGameButton:SetScript("OnClick", function() self:JoinLobby("RAWR") end)
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