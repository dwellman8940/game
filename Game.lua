local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

GameMixin = {}

local function StartGame()
    local game = CreateFromMixins(GameMixin)
    local client = CreateClient(game)

    game:Run()
end

function GameMixin:Run()
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
    end
end

function GameMixin:Tick(delta)
    print(delta)
end

StartGame()