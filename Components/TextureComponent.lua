local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

TextureComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function TextureComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.texture = TexturePool.AcquireWorldTexture()
    self.texture:Show()
end

function TextureComponentMixin:Destroy() -- override
    TexturePool.ReleaseWorldTexture(self.texture)
    self.texture = nil

    GameEntityComponentMixin.Destroy(self)
end

function TextureComponentMixin:Render(delta) -- override
     Texture.DrawAtWorldPoint(self.texture, self:GetWorldLocation())
end

function TextureComponentMixin:SetSize(width, height)
    PixelUtil.SetSize(self.texture, width, height)
end

function TextureComponentMixin:SetColorTexture(r, g, b, a)
    self.texture:SetColorTexture(r, g, b, a)
end

function TextureComponentMixin:SetRenderLayer(renderLayer)
    local drawLayer, subLevel = Texture.RenderDrawToWidgetLayer(renderLayer)
    self.texture:SetDrawLayer(drawLayer, subLevel)
end

function TextureComponentMixin:SetScale(scale)
    self.texture:SetScale(scale)
end