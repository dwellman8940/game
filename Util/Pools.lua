local addonName, envTable = ...
setfenv(1, envTable)

Pools = {}
Pools.Texture = {}
Pools.FontString = {}

local g_renderTexturePool
local g_worldTexturePool
local g_worldFontStringPool
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

function Pools.Initialize(worldFrame, renderFrame)
    local function TextureReset(pool, texture)
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
        texture:SetHorizTile(false)
        texture:SetVertTile(false)
        for vertexIndex = 1, 4 do
            texture:SetVertexOffset(vertexIndex, 0, 0)
        end
    end
    local function LineReset(pool, line)
        TextureReset(pool, line)
    end
    function FontStringReset(framePool, fontString)
        fontString:Hide()
        fontString:ClearAllPoints()
    end
    g_renderTexturePool = CreateTexturePool(renderFrame, "ARTWORK", -8, nil, TextureReset)
    g_worldTexturePool = CreateTexturePool(worldFrame, "ARTWORK", -8, nil, TextureReset)
    g_worldFontStringPool = CreateFontStringPool(worldFrame, "OVERLAY", 0, nil, FontStringReset)
    g_maskTexturePool = CreateMaskTexturePool(worldFrame, "OVERLAY", 7, nil, TextureReset)
    g_worldLinePool = CreateLineTexturePool(worldFrame, "OVERLAY", 7, nil, LineReset)
end

function Pools.Texture.AcquireRenderTexture()
    return (g_renderTexturePool:Acquire())
end

function Pools.Texture.ReleaseRenderTexture(texture)
    assert(g_renderTexturePool:Release(texture))
end

function Pools.Texture.AcquireWorldTexture()
    return (g_worldTexturePool:Acquire())
end

function Pools.Texture.AcquireWorldTextureArray(numTextures)
    local textures = {}
    for i = 1, numTextures do
        table.insert(textures, Pools.Texture.AcquireWorldTexture())
    end
    return textures
end

function Pools.Texture.ReleaseWorldTexture(texture)
    assert(g_worldTexturePool:Release(texture))
end

function Pools.Texture.ReleaseWorldTextureArray(textureArray)
    for i, texture in ipairs(textureArray) do
        Pools.Texture.ReleaseWorldTexture(texture)
    end
end

function Pools.Texture.AcquireWorldMaskTexture()
    return g_maskTexturePool:Acquire()
end

function Pools.Texture.ReleaseWorldMaskTexture(texture)
    assert(g_maskTexturePool:Release(texture))
end

function Pools.Texture.AcquireLineTexture()
    return (g_worldLinePool:Acquire())
end

function Pools.Texture.ReleaseLineTexture(texture)
    assert(g_worldLinePool:Release(texture))
end

function Pools.FontString.AcquireWorldFontString()
    return (g_worldFontStringPool:Acquire())
end

function Pools.FontString.ReleaseWorldFontString(fontString)
    assert(g_worldFontStringPool:Release(fontString))
end