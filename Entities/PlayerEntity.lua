local addonName, envTable = ...
setfenv(1, envTable)

PlayerEntityMixin = CreateFromMixins(GameEntityMixin)

local PLAYER_WIDTH = 40
local PLAYER_HEIGHT = 70

function PlayerEntityMixin:Initialize(parentEntity, relativeLocation)
    GameEntityMixin.Initialize(self, parentEntity, relativeLocation)

    local PLAYER_WIDTH_HALF = PLAYER_WIDTH * .5
    local PLAYER_HEIGHT_HALF = PLAYER_HEIGHT * .5
    local vertices = {
        CreateVector2(-PLAYER_WIDTH_HALF, -PLAYER_HEIGHT_HALF),
        CreateVector2(-PLAYER_WIDTH_HALF, PLAYER_HEIGHT_HALF),
        CreateVector2(PLAYER_WIDTH_HALF, PLAYER_HEIGHT_HALF),
        CreateVector2(PLAYER_WIDTH_HALF, -PLAYER_HEIGHT_HALF),
    }

    local dynamicPhysics = true
    self.geometryComponent = CreateGameEntityComponent(GeometryComponentMixin, self, vertices, dynamicPhysics)
end

function PlayerEntityMixin:Render(delta) -- override
    self:CreateRenderData()
end

function PlayerEntityMixin:CreateRenderData()
    if self.textureComponent then
        return
    end

    self.textureComponent = CreateGameEntityComponent(TextureComponentMixin, self)
    self.textureComponent:SetSize(PLAYER_WIDTH, PLAYER_HEIGHT)
    self.textureComponent:SetRenderLayer(self:IsLocalPlayer() and 32 or 31)

    local colorTable = {
        {1, 0, 0, .5},
        {0, 1, 0, .5},
        {0, 0, 1, .5},
        {1, 1, 1, .5},
    }

    self.textureComponent:SetColorTexture(unpack(colorTable[self:GetPlayerID()]))
end

function PlayerEntityMixin:GetName()
    return "Player" .. (self:GetPlayerID() or -1)
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

function PlayerEntityMixin:MarkAsLocalPlayer(worldFrame)
    self.isLocalPlayer = true
    self.cameraComponent = CreateGameEntityComponent(CameraComponentMixin, self, worldFrame)
    self.occlusionComponent = CreateGameEntityComponent(OcclusionComponentMixin, self, worldFrame)
end

-- TODO: Handle this separate from the player
function PlayerEntityMixin:AddOcclusionGeometry(geometryComponent)
    self.occlusionComponent:AddGeometry(geometryComponent)
end

function PlayerEntityMixin:IsLocalPlayer()
    return self.isLocalPlayer
end

function PlayerEntityMixin:ProcessPendingMovement()
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

    if self.velocity then
        self.velocity:SetXY(x, y)
    else
        self.velocity = CreateVector2(x, y)
    end
end

local PlayerSpeed = 200
function PlayerEntityMixin:TickClient(delta)
    if self:IsLocalPlayer() then
        self:ProcessPendingMovement()

        local targetLocation = self:GetWorldLocation() + self.velocity:GetSafeNormal() * PlayerSpeed * delta
        local adjustedLocation = self.geometryComponent:CollideWithStatic(targetLocation)

        self:SetWorldLocation(adjustedLocation)
        
        local worldLocation = self:GetWorldLocation()
        if not self.lastSentVelocity or self.lastSentVelocity ~= self.velocity then
            if self.lastSentVelocity then
                self.lastSentVelocity:SetXY(self.velocity:GetXY())
            else
                self.lastSentVelocity = self.velocity:Clone()
            end
           
            self:GetClient():SendMessageToPeers("OnMovement", self:GetPlayerID(), worldLocation, self.velocity)
        end
    else
        if self.remoteVelocity then
            local remoteDelta = GetTime() - self.remoteTimestamp
            local lerpAmount = Math.MapRangeClamped(0, 5, .08, .2, remoteDelta)

            local targetLocation = self.remoteLocation + self.remoteVelocity:GetSafeNormal() * PlayerSpeed * delta
            local adjustedLocation = self.geometryComponent:CollideWithStatic(targetLocation)
            self.remoteLocation = adjustedLocation
            local desiredLocation = Math.LerpOverTime(self:GetWorldLocation(), self.remoteLocation, lerpAmount, delta)
            self:SetWorldLocation(desiredLocation)
        end
    end
end

function PlayerEntityMixin:TickServer(delta)
    if self.remoteVelocity then
        self.remoteLocation = self.remoteLocation + self.remoteVelocity * PlayerSpeed * delta
        self:SetWorldLocation(self.remoteLocation)
    end
end

function PlayerEntityMixin:ApplyRemoveMovement(location, velocity)
    self.remoteTimestamp = GetTime()
    self.remoteLocation = location
    self.remoteVelocity = velocity
end