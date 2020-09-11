local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

local ServerMixin = {}

function CreateServer()
    local server = CreateFromMixins(ServerMixin)
    server:Initialize()

    return server
end

function ServerMixin:Initialize()
    self.entityGraph = CreateEntityGraph()

    self.elapsed = 0
    self.lastTickTime = GetTime()
    C_Timer.NewTicker(0, function() self:TryTick() end)
end

local TARGET_FPS = 60
local SECONDS_PER_TICK = 1 / TARGET_FPS 
function ServerMixin:TryTick()
    local now = GetTime()
    local delta = now - self.lastTickTime
    self.lastTickTime = now

    self.elapsed = self.elapsed + delta

    while self.elapsed >= SECONDS_PER_TICK do
        self.elapsed = self.elapsed - SECONDS_PER_TICK
        self:Tick(SECONDS_PER_TICK)
    end
end

function ServerMixin:Tick(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickServer(delta)
    end
end

function ServerMixin:GetEntityGraph()
    return self.entityGraph
end

function ServerMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:InitializeOnServer(self, parentEntity, relativeLocation)
    if not parentEntity then
        self:GetEntityGraph():AddToRoot(gameEntity)
    end
    return gameEntity
end