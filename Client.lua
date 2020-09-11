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

function CreateClient()
    local client = CreateFromMixins(ClientMixin)
    client:Initialize()

    return client
end

function ClientMixin:Initialize()
    self.entityGraph = CreateEntityGraph()

    self.elapsed = 0
    self.lastTickTime = GetTime()
    C_Timer.NewTicker(0, function() self:TryTick() end)
end

local TARGET_FPS = 60
local SECONDS_PER_TICK = 1 / TARGET_FPS 
function ClientMixin:TryTick()
    local now = GetTime()
    local delta = now - self.lastTickTime
    do
        self.elapsed = self.elapsed + delta
    
        while self.elapsed >= SECONDS_PER_TICK do
            self.elapsed = self.elapsed - SECONDS_PER_TICK
            self:Tick(SECONDS_PER_TICK)
        end
    end

    self:Render(delta)

    self.lastTickTime = now
end

function ClientMixin:Render(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:Render(delta)
    end
end

function ClientMixin:Tick(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClient(delta)
    end
end

function ClientMixin:GetRootFrame()
    return RenderFrame
end

function ClientMixin:GetEntityGraph()
    return self.entityGraph
end

function ClientMixin:GetCursorLocation()
    local x, y = GetCursorPosition()

    local rootFrame = self:GetRootFrame()
    local scale = rootFrame:GetScale()
    local clientX = Clamp(x / scale - rootFrame:GetLeft(), 0, rootFrame:GetWidth())
    local clientY = Clamp(y / scale - rootFrame:GetBottom(), 0, rootFrame:GetWidth())
    return CreateVector2(clientX, clientY)
end

function ClientMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnClient(self, parentEntity, relativeLocation)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end

function ClientMixin:BeginGame()
    self.localPlayer = self:CreateEntity(PlayerEntityMixin)

    --self:BindKeyboardToPlayer(self.localPlayer)
end