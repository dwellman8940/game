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
local ClientMessageHandlers = {}

function CreateClient()
    local client = CreateFromMixins(ClientMixin)
    client:Initialize()

    return client
end

function ClientMixin:Initialize()
    self.messageQueue = {}
    self:ResetGame()

    C_Timer.NewTicker(0, function() self:TryTick() end)
end

function ClientMixin:ResetGame()
    self.entityGraph = CreateEntityGraph()

    self.remotePlayers = {}

    self.elapsed = 0
    self.lastTickTime = GetTime()
end

function ClientMixin:CreateNetworkConnection(lobbyCode, localServer)
    local localServerOnMessageReceived = localServer and function(messageName, ...) localServer:AddMessageToQueue(messageName, ...) end or nil

    local function OnMessageReceived(messageName, ...)
        self:AddMessageToQueue(messageName, ...)
    end
    local onServerMessageReceived = OnMessageReceived
    local onPeerMessageReceived = OnMessageReceived
    self.networkConnection = CreateClientConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onServerMessageReceived, onPeerMessageReceived)
end

function ClientMixin:AddMessageToQueue(messageName, ...)
    table.insert(self.messageQueue, { messageName, ... })
end

function ClientMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local messageName = messageData[1]
            ClientMessageHandlers[messageName](self, unpack(messageData, 2))
        end
        self.messageQueue = {}
    end
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
    self:ProcessMessages()

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

function ClientMixin:SendMessage(messageName, ...)
    self.networkConnection:SendMessageToServer(messageName, ...)
end

function ClientMixin:SendMessageToPeers(messageName, ...)
    self.networkConnection:SendMessageToPeers(messageName, ...)
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
    --self.localPlayer = self:CreateEntity(PlayerEntityMixin)

    --self:BindKeyboardToPlayer(self.localPlayer)
end

function ClientMessageHandlers:ResetGame()
    self:ResetGame()
end

function ClientMessageHandlers:InitPlayer(playerName, playerID)
    if playerName == UnitName("player") then
        self.localPlayer = self:CreateEntity(PlayerEntityMixin)
        self.localPlayer:SetPlayerID(playerID)
        self.localPlayer:MarkAsLocalPlayer()
    else
        local remotePlayer = self:CreateEntity(PlayerEntityMixin)
        remotePlayer:SetPlayerID(playerID)

        self.remotePlayers[playerID] = remotePlayer
    end
end

function ClientMessageHandlers:OnMovement(playerID, x, y)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:SetWorldLocation(CreateVector2(x, y))
    end
end