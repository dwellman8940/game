local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

-- FogMaskHardEdge

CameraComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function CameraComponentMixin:Initialize(owningEntity, worldFrame) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.maskTexture = TexturePool.AcquireWorldMaskTexture()
    self.maskTexture:SetAtlas("FogMaskSoftEdge")
    self.maskTexture:SetScale(5)
    self.maskTexture:Show()

    self.fogTexture = TexturePool.AcquireRenderTexture()
    self.fogTexture:SetTexture("Interface/Addons/Game/Assets/Textures/fog")
    self.fogTexture:SetAllPoints(self.fogTexture:GetParent())
    self.fogTexture:SetParent(worldFrame)
    self.fogTexture:SetDrawLayer(Texture.RenderDrawToWidgetLayer(63))
    self.fogTexture:AddMaskTexture(self.maskTexture)
    self.fogTexture:Show()

    self.worldFrame = worldFrame
end

function CameraComponentMixin:Destroy() -- override
    TexturePool.ReleaseWorldMaskTexture(self.maskTexture)
    self.maskTexture = nil

    TexturePool.ReleaseWorldTexture(self.fogTexture)
    self.fogTexture = nil

    GameEntityComponentMixin.Destroy(self)
end

function CameraComponentMixin:SetWorldOffset(offsetX, offsetY)
    local width, height = self.worldFrame:GetWidth(), self.worldFrame:GetHeight()
    self.worldFrame:SetPoint("CENTER", offsetX + width * .5, offsetY + height * .5)
end

function CameraComponentMixin:Render(delta) -- override
    local offsetX, offsetY = self:GetWorldLocation():GetXY()
    local scale = self.maskTexture:GetScale()
    PixelUtil.SetPoint(self.maskTexture, "CENTER", self.maskTexture:GetParent(), "BOTTOMLEFT", offsetX / scale, offsetY / scale)

    self:SetWorldOffset(-offsetX, -offsetY)
end

function CameraComponentMixin:SetSize(width, height)
    PixelUtil.SetSize(self.maskTexture, width, height)
end

function CameraComponentMixin:SetColorTexture(r, g, b, a)
    self.maskTexture:SetColorTexture(r, g, b, a)
end