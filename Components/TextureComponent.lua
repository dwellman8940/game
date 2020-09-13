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
     self.texture:SetPoint("CENTER", self.texture:GetParent(), "BOTTOMLEFT", self:GetWorldLocation():GetXY())
end

function TextureComponentMixin:SetSize(width, height)
    self.texture:SetWidth(width)
    self.texture:SetHeight(width)
end

function TextureComponentMixin:SetColorTexture(r, g, b, a)
    self.texture:SetColorTexture(r, g, b, a)
end