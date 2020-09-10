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
RenderFrame:SetAllPoints(ClientFrame)

local ClientMixin = {}

function CreateClient(game)
    local client = CreateFromMixins(ClientMixin)
    client:Initialize(game)

    return client
end

function ClientMixin:Initialize(game)
    self.game = game

    self.lastTickTime = GetTime()
    C_Timer.NewTicker(0, function() self:TryTick() end)
end

function ClientMixin:TryTick()
    local now = GetTime()
    local delta = now - self.lastTickTime
    self.lastTickTime = now
    self:Tick(delta)
end

function ClientMixin:Tick(delta)
    local entityGraph = self.game:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:Render(delta)
    end
end

function ClientMixin:GetRootFrame()
    return RenderFrame
end

function ClientMixin:GetCursorLocation()
    local x, y = GetCursorPosition()

    local rootFrame = self:GetRootFrame()
    local scale = rootFrame:GetScale()
    local clientX = Clamp(x / scale - rootFrame:GetLeft(), 0, rootFrame:GetWidth())
    local clientY = Clamp(y / scale - rootFrame:GetBottom(), 0, rootFrame:GetWidth())
    return CreateVector2(clientX, clientY)
end