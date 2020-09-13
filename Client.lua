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

TexturePool.Initialize(RenderFrame)

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
    local entityGraph = self:GetEntityGraph()
    if entityGraph then
        for i, entity in entityGraph:EnumerateAll() do
            entity:DestroyInternal()
        end
    end
    self.localPlayer = nil
    ClientFrame:EnableKeyboard(false)


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
    self.clientNetworkConnection = CreateClientConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onServerMessageReceived)

    local onPeerMessageReceived = OnMessageReceived
    self.peerNetworkConnection = CreatePeerConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, onPeerMessageReceived)
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
        entity:RenderInternal(delta)
    end
end

function ClientMixin:Tick(delta)
    self:ProcessMessages()

    local entityGraph = self:GetEntityGraph()
    for i, entity in entityGraph:EnumerateAll() do
        entity:TickClientInternal(delta)
    end
end

function ClientMixin:GetRootFrame()
    return RenderFrame
end

function ClientMixin:GetEntityGraph()
    return self.entityGraph
end

function ClientMixin:SendMessage(messageName, ...)
    self.clientNetworkConnection:SendMessageToServer(messageName, ...)
end

function ClientMixin:SendMessageToPeers(messageName, ...)
    self.peerNetworkConnection:SendMessageToPeers(messageName, ...)
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

end

function ClientMixin:BindKeyboardToPlayer()
    ClientFrame:EnableKeyboard(true)

    local function OnKeyDown(f, key)
        ClientFrame:SetPropagateKeyboardInput(false)
        if key == "A" then
            self.localPlayer:SetMovingLeft(true)
        elseif key == "D" then
            self.localPlayer:SetMovingRight(true)
        elseif key == "W" then
            self.localPlayer:SetMovingForward(true)
        elseif key == "S" then
            self.localPlayer:SetMovingBackward(true)
        else
            ClientFrame:SetPropagateKeyboardInput(true)
        end
    end

    local function OnKeyUp(f, key)
        ClientFrame:SetPropagateKeyboardInput(false)
        if key == "A" then
            self.localPlayer:SetMovingLeft(false)
        elseif key == "D" then
            self.localPlayer:SetMovingRight(false)
        elseif key == "W" then
            self.localPlayer:SetMovingForward(false)
        elseif key == "S" then
            self.localPlayer:SetMovingBackward(false)
        else
            ClientFrame:SetPropagateKeyboardInput(false)
        end
    end

    ClientFrame:SetScript("OnKeyDown", OnKeyDown)
    ClientFrame:SetScript("OnKeyUp", OnKeyUp)
end

function ClientMessageHandlers:ResetGame()
    self:ResetGame()
end

function ClientMessageHandlers:InitPlayer(playerName, playerID)
    if playerName == UnitName("player") then
        self.localPlayer = self:CreateEntity(PlayerEntityMixin)
        self.localPlayer:SetPlayerID(playerID)
        self.localPlayer:MarkAsLocalPlayer()
        self:BindKeyboardToPlayer(self.localPlayer)
    else
        local remotePlayer = self:CreateEntity(PlayerEntityMixin)
        remotePlayer:SetPlayerID(playerID)

        self.remotePlayers[playerID] = remotePlayer
    end
end

function ClientMessageHandlers:OnMovement(playerID, location, velocity)
    local remotePlayer = self.remotePlayers[playerID]
    if remotePlayer then
        remotePlayer:ApplyRemoveMovement(location, velocity)
    end
end