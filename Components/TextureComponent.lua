local addonName, envTable = ...
setfenv(1, envTable)

TextureComponentMixin = CreateFromMixins(GameEntityComponentMixin)

function TextureComponentMixin:Initialize(owningEntity) -- override
    GameEntityComponentMixin.Initialize(self, owningEntity)

    self.texture = Pools.Texture.AcquireWorldTexture()
    self.texture:Show()
end

function TextureComponentMixin:Destroy() -- override
    Pools.Texture.ReleaseWorldTexture(self.texture)
    self.texture = nil

    GameEntityComponentMixin.Destroy(self)
end

function TextureComponentMixin:Render(delta) -- override
     Rendering.DrawAtWorldPoint(self.texture, self:GetWorldLocation())
end

function TextureComponentMixin:SetSize(width, height)
    PixelUtil.SetSize(self.texture, width, height)
end

function TextureComponentMixin:SetColorTexture(r, g, b, a)
    self.texture:SetColorTexture(r, g, b, a)
end

function TextureComponentMixin:SetRenderLayer(renderLayer)
    local drawLayer, subLevel = Rendering.RenderDrawToWidgetLayer(renderLayer)
    self.texture:SetDrawLayer(drawLayer, subLevel)
end

function TextureComponentMixin:SetScale(scale)
    self.texture:SetScale(scale)
end