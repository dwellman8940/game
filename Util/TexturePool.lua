local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

TexturePool = {}

local g_renderTexturePool
local g_worldTexturePool
local g_maskTexturePool

local MaskTexturePoolMixin = CreateFromMixins(ObjectPoolMixin)

local function TexturePoolFactory(texturePool)
	return texturePool.parent:CreateMaskTexture(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer)
end

function MaskTexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, TexturePoolFactory, resetterFunc)
	self.parent = parent
	self.layer = layer
	self.subLayer = subLayer
	self.textureTemplate = textureTemplate
end

function CreateMaskTexturePool(parent, layer, subLayer, textureTemplate, resetterFunc)
	local textureMaskPool = CreateFromMixins(MaskTexturePoolMixin)
	textureMaskPool:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
	return textureMaskPool
end

function TexturePool.Initialize(worldFrame, renderFrame)
    local function Reset(pool, texture)
        texture:Hide()
        texture:ClearAllPoints()
    end
    g_renderTexturePool = CreateTexturePool(renderFrame, "ARTWORK", -8, nil, Reset)
    g_worldTexturePool = CreateTexturePool(worldFrame, "ARTWORK", -8, nil, Reset)
    g_maskTexturePool = CreateMaskTexturePool(worldFrame, "OVERLAY", 7, nil, Reset)
end

function TexturePool.AcquireRenderTexture()
    return g_renderTexturePool:Acquire()
end

function TexturePool.ReleaseRenderexture(texture)
    g_renderTexturePool:Release(texture)
end

function TexturePool.AcquireWorldTexture()
    return g_worldTexturePool:Acquire()
end

function TexturePool.ReleaseWorldTexture(texture)
    g_worldTexturePool:Release(texture)
end

function TexturePool.AcquireWorldMaskTexture()
    return g_maskTexturePool:Acquire()
end

function TexturePool.ReleaseWorldMaskTexture(texture)
    g_maskTexturePool:Release(texture)
end

-- TODO: Move into new file
Texture = {}
function Texture.RenderDrawToWidgetLayer(renderLayer)
    if renderLayer < 16 then
        return "BACKGROUND", renderLayer - 8
    elseif renderLayer < 32 then
        return "BORDER", renderLayer - 8 - 16
    elseif renderLayer < 48 then
        return "ARTWORK", renderLayer - 8 - 32
    elseif renderLayer < 64 then
        return "OVERLAY", renderLayer - 8 - 48
    end
end