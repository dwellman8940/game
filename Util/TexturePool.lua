local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

TexturePool = {}

local g_renderTexturePool
local g_worldTexturePool
local g_maskTexturePool
local g_worldLinePool

local CreateMaskTexturePool
do
    local MaskTexturePoolMixin = CreateFromMixins(ObjectPoolMixin)

    local function MaskTexturePoolFactory(texturePool)
        return texturePool.parent:CreateMaskTexture(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer)
    end

    function MaskTexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
        ObjectPoolMixin.OnLoad(self, MaskTexturePoolFactory, resetterFunc)
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
end

local CreateLineTexturePool
do
    local LineTexturePoolMixin = CreateFromMixins(ObjectPoolMixin)

    local function LineTexturePoolFactory(texturePool)
        return texturePool.parent:CreateLine(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer)
    end

    function LineTexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
        ObjectPoolMixin.OnLoad(self, LineTexturePoolFactory, resetterFunc)
        self.parent = parent
        self.layer = layer
        self.subLayer = subLayer
        self.textureTemplate = textureTemplate
    end

    function CreateLineTexturePool(parent, layer, subLayer, textureTemplate, resetterFunc)
        local textureMaskPool = CreateFromMixins(LineTexturePoolMixin)
        textureMaskPool:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
        return textureMaskPool
    end
end

function TexturePool.Initialize(worldFrame, renderFrame)
    local function Reset(pool, texture)
        texture:Hide()
        texture:ClearAllPoints()
    end
    g_renderTexturePool = CreateTexturePool(renderFrame, "ARTWORK", -8, nil, Reset)
    g_worldTexturePool = CreateTexturePool(worldFrame, "ARTWORK", -8, nil, Reset)
    g_maskTexturePool = CreateMaskTexturePool(worldFrame, "OVERLAY", 7, nil, Reset)
    g_worldLinePool = CreateLineTexturePool(worldFrame, "OVERLAY", 7, nil, Reset)
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

function TexturePool.AcquireLineTexture()
    return g_worldLinePool:Acquire()
end

function TexturePool.ReleaseLineTexture(texture)
    g_worldLinePool:Release(texture)
end