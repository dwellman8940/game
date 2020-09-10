local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

local ClientFrame = CreateFrame("Frame")
ClientFrame:SetWidth(800)
ClientFrame:SetHeight(600)
ClientFrame:SetPoint("CENTER")

local Background = ClientFrame:CreateTexture(nil, "BACKGROUND", -8)
Background:SetColorTexture(0, 0, 0, 1)
Background:SetAllPoints(ClientFrame)

local RenderFrame = CreateFrame("Frame", nil, ClientFrame)
RenderFrame:SetClipsChildren(true)

local ClientMixin = {}

function CreateClient(game)
    local client = CreateFromMixins(ClientMixin)
    client:Initialize(game)

    return client
end

function ClientMixin:Initialize(game)
end