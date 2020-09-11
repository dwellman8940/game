local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

PlayerEntityMixin = CreateFromMixins(GameEntityMixin)

function PlayerEntityMixin:Render(delta) -- override
    self:CreateRenderData()

    -- todo: better drawing
    local client = self:GetClient()
    self.renderData.frame:SetPoint("CENTER", client:GetRootFrame(), "BOTTOMLEFT", self:GetWorldLocation():GetXY())
end

function PlayerEntityMixin:CreateRenderData()
    if self.renderData then
        return
    end

    self.renderData = {}

    local client = self:GetClient()
    self.renderData.frame = CreateFrame("Frame", nil, client:GetRootFrame())
    self.renderData.frame:SetWidth(100)
    self.renderData.frame:SetHeight(100)

    self.renderData.texture = self.renderData.frame:CreateTexture(nil, "ARTWORK", -8)

    Print("CreateRenderData", self:GetPlayerID())
    if self:IsLocalPlayer() then
        self.renderData.texture:SetColorTexture(1, 0, 0, 1)
    else
        self.renderData.texture:SetColorTexture(0, 1, 0, 1)
    end
    self.renderData.texture:SetAllPoints(self.renderData.frame)
end

function PlayerEntityMixin:SetPlayerID(playerID)
    self.playerID = playerID
end

function PlayerEntityMixin:GetPlayerID()
    return self.playerID
end

function PlayerEntityMixin:MarkAsLocalPlayer()
    self.isLocalPlayer = true
end

function PlayerEntityMixin:IsLocalPlayer()
    return self.isLocalPlayer
end

function PlayerEntityMixin:TickClient(delta)
    if self:IsLocalPlayer() then
        local client = self:GetClient()
        self:SetRelativeLocation(client:GetCursorLocation())

        
        local worldLocation = self:GetWorldLocation()

        if not self.lastSentLocation or self.lastSentLocation:DistanceSquared(worldLocation) > 5 then
            self.lastSentLocation = worldLocation
            self:GetClient():SendMessage("OnMovement", self:GetPlayerID(), worldLocation:GetXY())
        end
    end
end

function PlayerEntityMixin:TickServer(delta)
    local worldLocation = self:GetWorldLocation()

    if not self.lastSentLocation or self.lastSentLocation:DistanceSquared(worldLocation) > 100 then
        self.lastSentLocation = worldLocation
        self:GetServer():SendMessageToAllClients("OnMovement", self:GetPlayerID(), worldLocation:GetXY())
    end
end