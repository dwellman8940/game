local addonName, envTable = ...
setfenv(1, envTable)

local DebugView_EnableFog = DebugViews.RegisterView("Camera", "Enable Fog", true)

CameraComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function CameraComponentMixin:Initialize(owningEntity, worldFrame) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.maskTexture = Pools.Texture.AcquireWorldMaskTexture()
    self.maskTexture:SetAtlas("FogMaskSoftEdge")
    self.maskTexture:SetScale(7)
    self.maskTexture:Show()

    self.fogTexture = Pools.Texture.AcquireRenderTexture()
    self.fogTexture:SetTexture("Interface/Addons/Game/Assets/Textures/fog")
    self.fogTexture:SetAllPoints(self.fogTexture:GetParent())
    self.fogTexture:SetParent(worldFrame)
    self.fogTexture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(40))
    self.fogTexture:AddMaskTexture(self.maskTexture)
    self.fogTexture:Show()

    self.fogEnabled = true

    self.worldFrame = worldFrame
end

function CameraComponentMixin:Destroy() -- override
    Pools.Texture.ReleaseWorldMaskTexture(self.maskTexture)
    self.maskTexture = nil

    Pools.Texture.ReleaseRenderTexture(self.fogTexture)
    self.fogTexture = nil

    GameEntityComponentMixin.Destroy(self)
end

function CameraComponentMixin:SetFogEnabled(fogEnabled)
    self.fogEnabled = fogEnabled
end

function CameraComponentMixin:IsFogEnabled(fogEnabled)
    return self.fogEnabled
end

function CameraComponentMixin:SetWorldOffset(offset)
    Rendering.DrawAtWorldPoint(self.worldFrame, -offset, "CENTER")
end

function CameraComponentMixin:Render(delta) -- override
    Rendering.DrawAtWorldPoint(self.maskTexture, self:GetWorldLocation())

    self.targetWorldOffset = Math.LerpOverTime(self.targetWorldOffset or self:GetWorldLocation(), self:GetWorldLocation(), .08, delta)
    self:SetWorldOffset(self.targetWorldOffset)

    self.fogTexture:SetShown(self.fogEnabled and DebugView_EnableFog:IsViewEnabled())
end

function CameraComponentMixin:SetSize(width, height)
    self.maskTexture:SetWidth(width)
    self.maskTexture:SetHeight(height)
end

function CameraComponentMixin:SetColorTexture(r, g, b, a)
    self.maskTexture:SetColorTexture(r, g, b, a)
end