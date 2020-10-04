local addonName, envTable = ...
setfenv(1, envTable)

local LoadingScreenFrame
local ClientFrame

UI.LoadingScreenUI = {}

function UI.LoadingScreenUI.Initialize(clientFrame)
    ClientFrame = clientFrame
end

local function CreateLoadingScreen()
    if LoadingScreenFrame then
        return
    end

    LoadingScreenFrame = CreateFrame("Frame", nil, ClientFrame)
    local BORDER_SIZE = 3
    LoadingScreenFrame:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
    LoadingScreenFrame:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
    LoadingScreenFrame:SetFrameStrata("DIALOG")
    LoadingScreenFrame:EnableKeyboard(true)
    local function Noop(frame, key)
        frame:SetPropagateKeyboardInput(false)
        -- TODO: Check with bindings
        if key == "A" then
        elseif key == "D" then
        elseif key == "W" then
        elseif key == "S" then
        else
            frame:SetPropagateKeyboardInput(true)
        end
    end
    LoadingScreenFrame:SetScript("OnKeyDown", Noop)
    LoadingScreenFrame:SetScript("OnKeyUp", Noop)

    Background.AddStandardBackground(LoadingScreenFrame, BORDER_SIZE)

    do
        local PrimaryText = LoadingScreenFrame:CreateFontString(nil, "OVERLAY")
        LoadingScreenFrame.PrimaryText = PrimaryText
        PrimaryText:SetWidth(400)
        PrimaryText:SetPoint("CENTER")
        PrimaryText:SetFontObject("GameFontHighlightHuge")
    end
end

function UI.LoadingScreenUI.End()
    if UI.LoadingScreenUI.IsVisible() then
        LoadingScreenFrame:Hide()
    end
end

function UI.LoadingScreenUI.ConnectingToLobby(hostName)
    CreateLoadingScreen()

    LoadingScreenFrame.PrimaryText:SetFormattedText(Localization.GetString("LoadingScreen_JoiningLobby"), hostName)
    LoadingScreenFrame:Show()
end

function UI.LoadingScreenUI.IsVisible()
    return LoadingScreenFrame and LoadingScreenFrame:IsShown()
end