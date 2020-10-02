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
    envTable[name] = type(global) == "table" and not type(global[0]) == "userdata" and DeepCopyTable(global) or global
end

local function Allow(name)
    return _G[name]
end

local function Inject(name, value)
    _G[name] = value
end

local GameFrame = CreateFrame("Frame", nil, UIParent)
GameFrame:Hide()
GameFrame:SetAllPoints(UIParent)
envTable.GameFrame = GameFrame

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
Import("tonumber")
Import("unpack")
Import("next")

Import("CreateFrame")
Import("GetTime")
Import("UnitName")
Import("UnitGUID")
Import("IsInGroup")
Import("IsInRaid")
Import("GetCursorPosition")
Import("Ambiguate")
Import("debugprofilestop")
Import("GetFramerate")
Import("GetNetStats")
Import("GetLocale")

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
            local DebugView_GameShown = DebugViews.RegisterView("Client", "Shown")
            DebugView_GameShown:SetOnStateChangedCallback(function(debugView, state) GameFrame:SetShown(state) end)
            
            GameFrame:SetScript("OnShow", function() DebugView_GameShown:SetViewEnabled(true) end)
            GameFrame:SetScript("OnHide", function() DebugView_GameShown:SetViewEnabled(false) end)

            local Game_DebugViews = Allow("Game_DebugViews")
            DebugViews.OnSettingsLoaded(Game_DebugViews)

            local Game_Levels = Allow("Game_Levels")
            Level.RegisterLevelData("SavedData", Game_Levels)

            local SlashCmdList = Allow("SlashCmdList")

            Inject("SLASH_SHOW_GAME1", Localization.GetString("Slash_Show"))
            function SlashCmdList.SHOW_GAME()
                GameFrame:Show()
            end

            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)