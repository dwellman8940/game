local addonName, envTable = ...
setfenv(1, envTable)

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

function MainMenuStateMixin:HostGame(lobbyCode)
    local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
    lobbyState:HostGame(lobbyCode)
end

function MainMenuStateMixin:JoinGame(lobbyCode)
    local lobbyState = self:GetClient():SwitchToGameState(LobbyStateMixin)
    lobbyState:JoinGame(lobbyCode)
end

function MainMenuStateMixin:CreateMainMenuFrame()
    MainMenuFrame = CreateFrame("Frame", nil, self:GetClient():GetRootFrame())
    MainMenuFrame:SetAllPoints(MainMenuFrame:GetParent())

    do
        local Background = MainMenuFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
        local BORDER_SIZE = 3
        Background:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
        Background:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
        Background:SetColorTexture(Colors.Swamp:GetRGBA())
    end

    do
        local Border = MainMenuFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
        Border:SetColorTexture(Colors.Black:GetRGBA())
        Border:SetAllPoints(MainMenuFrame)
    end

    do
        local HostGameButton = Button.CreateLargeButton(MainMenuFrame)
        HostGameButton:SetPoint("CENTER", 0, 100)
        HostGameButton:SetText("Host Game")
        HostGameButton:SetScript("OnClick", function() self:HostGame("RAWR") end)
    end

    do
        local JoinGameButton = Button.CreateLargeButton(MainMenuFrame)
        JoinGameButton:SetPoint("CENTER")
        JoinGameButton:SetText("Join Game")
        JoinGameButton:SetScript("OnClick", function() self:JoinGame("RAWR") end)
    end

    do
        -- TODO
        local OptionsButton = Button.CreateLargeButton(MainMenuFrame)
        OptionsButton:SetPoint("CENTER", 0, -100)
        OptionsButton:SetText("Options")
        OptionsButton:SetScript("OnClick", function() end)
    end

    do
        -- TODO
        local ExitButton = Button.CreateStandardButton(MainMenuFrame)
        ExitButton:SetPoint("BOTTOMRIGHT", -10, 10)
        ExitButton:SetText("Exit")
        ExitButton:SetScript("OnClick", function() end)
    end
end