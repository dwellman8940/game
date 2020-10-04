local addonName, envTable = ...
setfenv(1, envTable)

UI.LobbyUI = {}

local LobbyFrameMixin = {}

function UI.LobbyUI.CreateLobbyUI(parentFrame)
    local LobbyFrame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(LobbyFrame, LobbyFrameMixin)
    LobbyFrame:Initialize()

    return LobbyFrame
end

function LobbyFrameMixin:Initialize()
    self:SetAllPoints(self:GetParent())
end

function LobbyFrameMixin:SetCallbacks(callbacks)
    self.callbacks = callbacks
end