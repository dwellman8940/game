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
    self.textureComponent:SetSize(40, 70)

    local colorTable = {
        {1, 0, 0, 1},
        {0, 1, 0, 1},
        {0, 0, 1, 1},
        {1, 1, 1, 1},
    }

    self.textureComponent:SetColorTexture(unpack(colorTable[self:GetPlayerID()]))
end

function PlayerEntityMixin:SetMovingLeft(isMovingLeft)
    self.isMovingLeft = isMovingLeft
end

function PlayerEntityMixin:SetMovingRight(isMovingRight)
    self.isMovingRight = isMovingRight
end

function PlayerEntityMixin:SetMovingForward(isMovingForward)
    self.isMovingForward = isMovingForward
end

function PlayerEntityMixin:SetMovingBackward(isMovingBackward)
    self.isMovingBackward = isMovingBackward
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

function PlayerEntityMixin:ProcessPendingMovement(delta)
    local x = 0
    if self.isMovingRight then
        x = x + 1
    end
    if self.isMovingLeft then
        x = x - 1
    end

    local y = 0
    if self.isMovingForward then
        y = y + 1
    end
    if self.isMovingBackward then
        y = y - 1
    end

    local playerSpeed = 8000 * delta
    self.velocity = CreateVector2(x * playerSpeed, y * playerSpeed)
end

function PlayerEntityMixin:TickClient(delta)
    if self:IsLocalPlayer() then
        self:ProcessPendingMovement(delta)

        self:SetWorldLocation(self:GetWorldLocation() + self.velocity * delta)

        local worldLocation = self:GetWorldLocation()
        if not self.lastSentVelocity or self.lastSentVelocity ~= self.velocity then
            self.lastSentVelocity = self.velocity
            self:GetClient():SendMessageToPeers("OnMovement", self:GetPlayerID(), worldLocation, self.velocity)
        end
    else
        if self.remoteVelocity then
            local remoteDelta = GetTime() - self.remoteTimestamp
            local lerpAmount = Math.MapRangeClamped(0, 1, .08, .2, remoteDelta)

            self.remoteLocation = self.remoteLocation + self.remoteVelocity * delta
            local desiredLocation = Math.LerpOverTime(self:GetWorldLocation(), self.remoteLocation, lerpAmount, delta)
            self:SetWorldLocation(desiredLocation)
        end
    end
end

function PlayerEntityMixin:TickServer(delta)
    if self.remoteVelocity then
        self.remoteLocation = self.remoteLocation + self.remoteVelocity * delta
        self:SetWorldLocation(self.remoteLocation)
    end
end

function PlayerEntityMixin:ApplyRemoveMovement(location, velocity)
    self.remoteTimestamp = GetTime()
    self.remoteLocation = location
    self.remoteVelocity = velocity
end