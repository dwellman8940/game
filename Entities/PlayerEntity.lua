local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

PlayerEntityMixin = CreateFromMixins(GameEntityMixin)

function PlayerEntityMixin:Render(delta) -- override
    self:CreateRenderData()
end

function PlayerEntityMixin:CreateRenderData()
    if self.textureComponent then
        return
    end

    self.textureComponent = CreateGameEntityComponent(TextureComponentMixin, self)
    self.textureComponent:SetSize(100, 100)

    local colorTable = {
        {1, 0, 0, 1},
        {0, 1, 0, 1},
        {0, 0, 1, 1},
        {1, 1, 1, 1},
    }

    self.textureComponent:SetColorTexture(unpack(colorTable[self:GetPlayerID()]))
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
        if not self.lastSentLocation or self.lastSentLocation:DistanceSquared(worldLocation) > 1 then
            self.lastSentLocation = worldLocation
            self:GetClient():SendMessageToPeers("OnMovement", self:GetPlayerID(), worldLocation:GetXY())
        end
    end
end

function PlayerEntityMixin:TickServer(delta)

end