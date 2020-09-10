local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GameMixin = {}

local function StartGame()
    local game = CreateFromMixins(GameMixin)
    game:Initialize()
    game:Run()
end

function GameMixin:Initialize()
    self.client = CreateClient(self)
end

function GameMixin:Run()
    self.entityGraph = CreateFromMixins(EntityGraphMixin)
    self.entityGraph:Initialize(self)

    self.localPlayer = self:CreateEntity(PlayerEntityMixin)

    -- unfortunately we're tied to wow's render rate so we can't simulate logic any faster than our FPS
    C_Timer.NewTicker(0, function() self:TryTick() end)
end

local TARGET_FPS = 60
local SECONDS_PER_TICK = 1 / TARGET_FPS 
function GameMixin:TryTick()
    local now = GetTime()

    if not self.lastTickTime then
        self.elapsed = 0
        self.lastTickTime = now
        return
    end

    local delta = now - self.lastTickTime
    self.lastTickTime = now

    self.elapsed = self.elapsed + delta

    while self.elapsed >= SECONDS_PER_TICK do
        self.elapsed = self.elapsed - SECONDS_PER_TICK
        self:Tick(SECONDS_PER_TICK)
        c = c + 1
    end
end

function GameMixin:Tick(delta)
    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:Tick(delta)
    end
end

function GameMixin:GetEntityGraph()
    return self.entityGraph
end

function GameMixin:GetClient()
    return self.client
end

function GameMixin:CreateEntity(entityMixin, parentEntity, relativeLocation)
    local gameEntity = CreateFromMixins(entityMixin)
    gameEntity:Initialize(self, parentEntity or self.entityGraph:GetRootEntity(), relativeLocation)
    return gameEntity
end

StartGame()