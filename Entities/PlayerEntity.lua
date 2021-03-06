local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_EnableCollision = DebugViews.RegisterView("Player", "Enable Collision", true)
local DebugView_ReplicateServerAABB = DebugViews.RegisterView("Player", "Replicate Server AABB")
local DebugView_RemoteInterpolation = DebugViews.RegisterView("Player", "Remote Interpolation", true)

PlayerEntityMixin = Mixin.CreateFromMixins(GameEntityMixin)

local PLAYER_WIDTH = 40
local PLAYER_HEIGHT = 70

function PlayerEntityMixin:Initialize(parentEntity, relativeLocation, playerName)
    GameEntityMixin.Initialize(self, parentEntity, relativeLocation)
    self.playerName = playerName
    self.velocity = CreateVector2()

    local PLAYER_WIDTH_HALF = PLAYER_WIDTH * .5
    local PLAYER_HEIGHT_HALF = PLAYER_HEIGHT * .5
    local vertices = {
        CreateVector2(-PLAYER_WIDTH_HALF, -PLAYER_HEIGHT_HALF),
        CreateVector2(-PLAYER_WIDTH_HALF, PLAYER_HEIGHT_HALF),
        CreateVector2(PLAYER_WIDTH_HALF, PLAYER_HEIGHT_HALF),
        CreateVector2(PLAYER_WIDTH_HALF, -PLAYER_HEIGHT_HALF),
    }

    self.geometryComponent = CreateGameEntityComponent(GeometryComponentMixin, self, vertices, GeometryType.Dynamic, GeometryOcclusion.Ignored)

    self:MarkPlayerActivity()
end

function PlayerEntityMixin:Render(delta) -- override
    self:CreateRenderData()
end

function PlayerEntityMixin:GetPlayerName()
    return self.playerName
end

function PlayerEntityMixin:MarkPlayerActivity()
    self.lastPlayerActivity = GetTime()
end

function PlayerEntityMixin:HasBeenActiveRecently(timeout)
    local lastActivityDelta = GetTime() - self.lastPlayerActivity
    return lastActivityDelta <= timeout
end

function PlayerEntityMixin:CreateRenderData()
    if self.textureComponent then
        return
    end

    self.textureComponent = CreateGameEntityComponent(TextureComponentMixin, self)
    self.textureComponent:SetSize(PLAYER_WIDTH, PLAYER_HEIGHT)
    self.textureComponent:SetRenderLayer(self:IsLocalPlayer() and 32 or 31)

    -- TODO: real color system
    self.textureComponent:SetColorTexture(CreateRandomStream(self:GetPlayerID()):GetNextColor():GetRGBA())
end

function PlayerEntityMixin:GetName()
    return "Player" .. (self:GetPlayerID() or -1)
end

function PlayerEntityMixin:SetMovingLeft(isMovingLeft)
    self.isMovingLeft = isMovingLeft
    self:MarkPlayerActivity()
end

function PlayerEntityMixin:SetMovingRight(isMovingRight)
    self.isMovingRight = isMovingRight
    self:MarkPlayerActivity()
end

function PlayerEntityMixin:SetMovingForward(isMovingForward)
    self.isMovingForward = isMovingForward
    self:MarkPlayerActivity()
end

function PlayerEntityMixin:SetMovingBackward(isMovingBackward)
    self.isMovingBackward = isMovingBackward
    self:MarkPlayerActivity()
end

function PlayerEntityMixin:SetIsLobby(isLobby)
    self.isLobby = isLobby
end

function PlayerEntityMixin:IsLobby()
    return self.isLobby
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
    self.cameraComponent:SetFogEnabled(not self:IsLobby())
    self.occlusionComponent = CreateGameEntityComponent(OcclusionComponentMixin, self, worldFrame)
    self.occlusionComponent:SetOcclusionEnabled(not self:IsLobby())
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

    self.velocity:SetXY(x, y)
end

function PlayerEntityMixin:GetVelocity()
    return self.velocity
end

local PlayerSpeed = 200
function PlayerEntityMixin:TickClient(delta)
    if self:IsLocalPlayer() then
        self:ProcessPendingMovement()

        local targetLocation = self:GetWorldLocation() + self.velocity:GetSafeNormal() * PlayerSpeed * delta
        local adjustedLocation = DebugView_EnableCollision:IsViewEnabled() and self.geometryComponent:CollideWithStatic(targetLocation) or targetLocation

        self:SetWorldLocation(adjustedLocation)
        
        local worldLocation = self:GetWorldLocation()
        if not self.lastSentVelocity or self.lastSentVelocity ~= self.velocity then
            if self.lastSentVelocity then
                self.lastSentVelocity:SetXY(self.velocity:GetXY())
            else
                self.lastSentVelocity = self.velocity:Clone()
            end
         
            self:GetGameState():SendMessageToPeers("OnMovement", self:GetPlayerID(), worldLocation, self.velocity)
        end
    else
        if self.remoteVelocity then
            local remoteDelta = GetTime() - self.remoteTimestamp
            local lerpAmount = DebugView_RemoteInterpolation:IsViewEnabled() and Math.MapRangeClamped(0, 5, .08, .2, remoteDelta) or 1

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
        local targetLocation = self.remoteLocation + self.remoteVelocity:GetSafeNormal() * PlayerSpeed * delta
        local adjustedLocation = self.geometryComponent:CollideWithStatic(targetLocation)
        self.remoteLocation = adjustedLocation
        self:SetWorldLocation(adjustedLocation)

        if DebugView_ReplicateServerAABB:IsViewEnabled() then
            self:GetServer():SendMessageToAllClients("Debug_ReplicateAABB", self.geometryComponent:GetBounds():Translate(adjustedLocation))
        end
    end
end

function PlayerEntityMixin:ApplyRemoveMovement(location, velocity)
    self.remoteTimestamp = GetTime()
    self.remoteLocation = location
    self.remoteVelocity = velocity

    self:MarkPlayerActivity()
end