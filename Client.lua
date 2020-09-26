local addonName, envTable = ...
setfenv(1, envTable)

local ClientFrame = CreateFrame("Frame")
ClientFrame:SetWidth(800)
ClientFrame:SetHeight(600)
ClientFrame:SetPoint("CENTER")

local RenderFrame = CreateFrame("Frame", nil, ClientFrame)
--RenderFrame:SetClipsChildren(true)
RenderFrame:SetAllPoints(ClientFrame)

local WorldFrame = CreateFrame("Frame", nil, RenderFrame)
WorldFrame:SetPoint("CENTER")
WorldFrame:SetWidth(1024)
WorldFrame:SetHeight(1024)

--TODO: Should not be here
local Background = WorldFrame:CreateTexture(nil, "BACKGROUND", -8)
Background:SetTexture("Interface/Addons/Game/Assets/Textures/grid", "REPEAT", "REPEAT")
Background:SetHorizTile(true)
Background:SetVertTile(true)
Background:SetAllPoints(WorldFrame)
Background:Show()

Pools.Initialize(WorldFrame, RenderFrame)

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
    local offsetX, offsetY = rootFrame:GetCenter()
    local halfWidth = rootFrame:GetWidth() * .5
    local halfHeight = rootFrame:GetHeight() * .5
    local clientX = Math.Clamp(x / scale - offsetX, -halfWidth, halfWidth)
    local clientY = Math.Clamp(y / scale - offsetY, -halfHeight, halfHeight)
    return CreateVector2(clientX, clientY)
end

function ClientMixin:GetWorldCursorLocation()
    return self:GetCursorLocation() - self:GetWorldFrameOffset()
end

function ClientMixin:GetWorldFrameOffset()
    local _, _, _, worldOffsetX, worldOffsetY = WorldFrame:GetPoint(1)
    return CreateVector2(worldOffsetX, worldOffsetY)
end

function ClientMixin:GetRenderFrameWorldBoundVertices()
    local rootFrame = self:GetRootFrame()
    local halfWidth = (rootFrame:GetWidth() + 2) * .5
    local halfHeight = (rootFrame:GetHeight() + 2) * .5
    local worldFrameOffset = self:GetWorldFrameOffset()

    return {
        CreateVector2(-halfWidth, -halfHeight) - worldFrameOffset,
        CreateVector2(-halfWidth, halfHeight) - worldFrameOffset,
        CreateVector2(halfWidth, halfHeight) - worldFrameOffset,
        CreateVector2(halfWidth, -halfHeight) - worldFrameOffset,
    }
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
        self.localPlayer:MarkAsLocalPlayer(WorldFrame)
        self:BindKeyboardToPlayer(self.localPlayer)

        --local testCollision = self:CreateEntity(GameEntityMixin, nil, CreateVector2(-200, 0))
        --local geometryComponent = CreateGameEntityComponent(GeometryComponentMixin, testCollision)
        --self.localPlayer:AddOcclusionGeometry(geometryComponent)

        for i = 1, 2 do
            local testCollision2 = self:CreateEntity(GameEntityMixin, nil, CreateVector2((i - 1) * 150, 0))
            local geometryComponent2 = CreateGameEntityComponent(GeometryComponentMixin, testCollision2)
            self.localPlayer:AddOcclusionGeometry(geometryComponent2)
        end
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