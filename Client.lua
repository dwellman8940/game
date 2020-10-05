local addonName, envTable = ...
setfenv(1, envTable)

local ClientFrame = CreateFrame("Frame", nil, GameFrame)
ClientFrame:SetWidth(800)
ClientFrame:SetHeight(600)
ClientFrame:SetPoint("CENTER")
ClientFrame:SetScale(1.1)
ClientFrame:EnableMouse(true)

local WindowBackground = ClientFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
WindowBackground:SetAllPoints(ClientFrame)
WindowBackground:SetColorTexture(Colors.DarkGrey:GetRGBA())

local DebugView_ClientClips = DebugViews.RegisterView("Client", "Clip", true)

local RenderFrame = CreateFrame("Frame", nil, ClientFrame)
RenderFrame:SetClipsChildren(true)
RenderFrame:SetAllPoints(ClientFrame)

DebugView_ClientClips:SetOnStateChangedCallback(function(debugView, state) RenderFrame:SetClipsChildren(state) end)

local WorldFrame = CreateFrame("Frame", nil, RenderFrame)
WorldFrame:SetPoint("CENTER")
WorldFrame:SetWidth(1024)
WorldFrame:SetHeight(1024)

--TODO: Should not be here
local Background = WorldFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
Background:SetTexture("Interface/Addons/Game/Assets/Textures/grid", "REPEAT", "REPEAT")
Background:SetHorizTile(true)
Background:SetVertTile(true)
Background:SetAllPoints(WorldFrame)
Background:Show()

UI.Initialize(ClientFrame)
Pools.Initialize(WorldFrame, RenderFrame)

local ClientMixin = {}

function CreateClient()
    local client = Mixin.CreateFromMixins(ClientMixin)
    client:Initialize()

    return client
end

function ClientMixin:Initialize()
    self.elapsed = 0
    self.lastTickTime = GetTime()

    local ticker
    ClientFrame:SetScript("OnShow", function()
        self:SwitchToGameState(MainMenuStateMixin)
        ticker = C_Timer.NewTicker(0, function() self:TryTick() end)
    end)

    ClientFrame:SetScript("OnHide", function()
        if ticker then
            ticker = ticker:Cancel()
            self:SwitchToGameState(nil)
        end
    end)
end

function ClientMixin:SwitchToGameState(gameStateMixin)
    local newGameState = gameStateMixin and Mixin.CreateFromMixins(gameStateMixin) or nil
    if self.gameState then
        self.gameState:End(newGameState)
    end
    self.gameState = newGameState

    if self.gameState then
        self.gameState:BeginInternal(self)
    end

    self:UnbindKeyboard()

    return newGameState
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
    self.gameState:Render(delta)
end

function ClientMixin:Tick(delta)
    self.gameState:Tick(delta)
end

function ClientMixin:GetRootFrame()
    return RenderFrame
end

function ClientMixin:GetWorldFrame()
    return WorldFrame
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

function ClientMixin:GetRenderFrameWorldBounds()
    local rootFrame = self:GetRootFrame()
    local halfWidth = (rootFrame:GetWidth() + 2) * .5
    local halfHeight = (rootFrame:GetHeight() + 2) * .5
    local worldFrameOffset = self:GetWorldFrameOffset()

    return CreateAABB(CreateVector2(-halfWidth, -halfHeight) - worldFrameOffset, CreateVector2(halfWidth, halfHeight) - worldFrameOffset)
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

function ClientMixin:BindKeyboardToPlayer(localPlayer)
    ClientFrame:EnableKeyboard(true)

    local function OnKeyDown(f, key)
        ClientFrame:SetPropagateKeyboardInput(false)
        if key == "A" then
            localPlayer:SetMovingLeft(true)
        elseif key == "D" then
            localPlayer:SetMovingRight(true)
        elseif key == "W" then
            localPlayer:SetMovingForward(true)
        elseif key == "S" then
            localPlayer:SetMovingBackward(true)
        else
            ClientFrame:SetPropagateKeyboardInput(true)
        end
    end

    local function OnKeyUp(f, key)
        ClientFrame:SetPropagateKeyboardInput(false)
        if key == "A" then
            localPlayer:SetMovingLeft(false)
        elseif key == "D" then
            localPlayer:SetMovingRight(false)
        elseif key == "W" then
            localPlayer:SetMovingForward(false)
        elseif key == "S" then
            localPlayer:SetMovingBackward(false)
        else
            ClientFrame:SetPropagateKeyboardInput(false)
        end
    end

    ClientFrame:SetScript("OnKeyDown", OnKeyDown)
    ClientFrame:SetScript("OnKeyUp", OnKeyUp)
end

function ClientMixin:UnbindKeyboard()
    ClientFrame:EnableKeyboard(false)

    ClientFrame:SetScript("OnKeyDown", nil)
    ClientFrame:SetScript("OnKeyUp", nil)
end
