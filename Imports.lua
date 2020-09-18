local addonName, envTable = ...

local function DeepCopyTable(t)
    local n = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            n[k] = DeepCopyTable(v)
        else
            n[k] = v
        end
    end
    return n
end

local function Import(name)
    local global = _G[name]
    envTable[name] = type(global) == "table" and DeepCopyTable(global) or global
end

Import("table")
Import("string")
Import("math")

Import("ipairs")
Import("pairs")
Import("assert")
Import("setmetatable")
Import("type")
Import("print")
Import("select")
Import("tostring")

Import("CreateFrame")

Import("C_ChatInfo")
Import("C_Timer")

Import("CreateFromMixins")
Import("PixelUtil")
Import("ObjectPoolMixin")
Import("CreateTexturePool")