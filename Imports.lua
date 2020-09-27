Game_DebugViews = {}

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

local function Allow(name)
    return _G[name]
end

setfenv(1, envTable)

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
Import("unpack")

Import("CreateFrame")
Import("GetTime")
Import("UnitName")
Import("IsInGroup")
Import("GetCursorPosition")
Import("Ambiguate")

Import("C_ChatInfo")
Import("C_Timer")

Import("CreateFromMixins")
Import("ObjectPoolMixin")
Import("CreateFramePool")
Import("CreateTexturePool")
Import("CreateFontStringPool")

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            local Game_DebugViews = Allow("Game_DebugViews")

            DebugViews.OnSettingsLoaded(Game_DebugViews)
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)