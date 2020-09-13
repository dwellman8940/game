local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

TexturePool = {}

local g_blzTexturePool

function TexturePool.Initialize(renderFrame)
    local function Reset(pool, texture)
        texture:Hide()
        texture:ClearAllPoints()
    end
    g_blzTexturePool = CreateTexturePool(renderFrame, "ARTWORK", -8, nil, Reset)
end

function TexturePool.AcquireTexture()
    return g_blzTexturePool:Acquire()
end

function TexturePool.ReleaseTexture(texture)
    g_blzTexturePool:Release(texture)
end