local addonName, envTable = ...
setfenv(1, envTable)

local ClientFrame

UI = {}

function UI.Initialize(clientFrame)
    ClientFrame = clientFrame
end

function UI.GetUIParentFrame()
    return ClientFrame
end

function UI.CreateFrameFromMixin(parentFrame, mixin)
    local frame = CreateFrame("Frame", nil, parentFrame)
    Mixin.MixinInto(frame, mixin)
    frame:Initialize()
    return frame
end