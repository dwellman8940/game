local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

TextureComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function TextureComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.texture = TexturePool.AcquireTexture()
    self.texture:Show()
end

function TextureComponentMixin:Destroy() -- override
    TexturePool.ReleaseTexture(self.texture)
    self.texture = nil

    GameEntityComponentMixin.Destroy(self)
end

function TextureComponentMixin:Render(delta) -- override
     local offsetX, offsetY = self:GetWorldLocation():GetXY()
     PixelUtil.SetPoint(self.texture, "CENTER", self.texture:GetParent(), "BOTTOMLEFT", offsetX, offsetY)
end

function TextureComponentMixin:SetSize(width, height)
    PixelUtil.SetSize(self.texture, width, height)
end

function TextureComponentMixin:SetColorTexture(r, g, b, a)
    self.texture:SetColorTexture(r, g, b, a)
end