local addonName, envTable = ...
setfenv(1, envTable)

DebugViews = {}

DebugViews.ViewType = {
    Toggle = 1,
    TimedProfile = 2,
}

local RebuildUI

local debugViews = {}
local categoriesToViews = {}
local savedSettings = {}

local ViewProto = {}
local ViewMetatable = { __index = ViewProto }

function ViewProto:SetViewEnabled(enabledState)
    local newEnabledState = not not enabledState
    local isInitialState = self.enabledState == nil
    if isInitialState then
        self.isInitialState = newEnabledState
    end
    if newEnabledState ~= self.enabledState then
        self.enabledState = newEnabledState
        if savedSettings then
            if self.isInitialState == newEnabledState then
                if savedSettings[self:GetCategoryName()] then
                    savedSettings[self:GetCategoryName()][self:GetViewName()] = nil
                    if not next(savedSettings[self:GetCategoryName()]) then
                        savedSettings[self:GetCategoryName()] = nil
                    end
                end
            else
                if not savedSettings[self:GetCategoryName()] then
                    savedSettings[self:GetCategoryName()] = {}
                end
                savedSettings[self:GetCategoryName()][self:GetViewName()] = self:IsViewEnabled()
            end
        end
        if RebuildUI then
            RebuildUI()
        end
        if self.OnStateChangedCallback then
            self.OnStateChangedCallback(self, self.enabledState)
        end
    end
end

function ViewProto:IsViewEnabled()
    return self.enabledState
end

function ViewProto:GetCategoryName()
    return self.categoryName
end

function ViewProto:GetViewName()
    return self.viewName
end

function ViewProto:GetViewType()
    return self.viewType
end

function ViewProto:StartProfileCapture()
    assert(self.viewType == DebugViews.ViewType.TimedProfile)
    self.startedProfileTime = debugprofilestop()
end

function ViewProto:EndProfileCapture()
    assert(self.viewType == DebugViews.ViewType.TimedProfile)
    assert(self.startedProfileTime)
    self.accumulatedProfileTime = (self.accumulatedProfileTime or 0) + debugprofilestop() - self.startedProfileTime
    self.startedProfileTime = nil
end

function ViewProto:ResetProfile()
    if self.viewType == DebugViews.ViewType.TimedProfile then
        local alpha = .01
        self.averagedProfileTime = (self.accumulatedProfileTime or 0) * alpha + (1 - alpha) * (self.averagedProfileTime or 0)
        self.accumulatedProfileTime = nil
    end
end

function ViewProto:GetProfileTime()
    return self.accumulatedProfileTime or 0
end

function ViewProto:GetAveragedProfileTime()
    return self.averagedProfileTime or 0
end

function ViewProto:SetOnStateChangedCallback(callback)
    self.OnStateChangedCallback = callback
end

local function CreateView(categoryName, viewName, viewType)
    assert(debugViews[viewName] == nil, viewName)

    local category = categoriesToViews[categoryName]
    if not category then
        category = {}
        categoriesToViews[categoryName] = category
    end

    local debugView = setmetatable( {categoryName = categoryName, viewName = viewName, viewType = viewType }, ViewMetatable)
    table.insert(category, debugView)
    debugViews[viewName] = debugView

    return debugView
end

local function ResetProfiles()
    for viewName, debugView in pairs(debugViews) do
        debugView:ResetProfile()
    end
end

C_Timer.NewTicker(0, ResetProfiles)

function DebugViews.RegisterView(categoryName, viewName, enabledState)
    local debugView = CreateView(categoryName, viewName, DebugViews.ViewType.Toggle)
    debugView:SetViewEnabled(enabledState)
    return debugView
end

function DebugViews.RegisterProfileStatistic(categoryName, viewName)
    local debugView = CreateView(categoryName, viewName, DebugViews.ViewType.TimedProfile)
    return debugView
end

function DebugViews.FindDebugView(categoryName, viewName)
    local category = categoriesToViews[categoryName]
    if category then
        for i, debugView in ipairs(category) do
            if debugView:GetViewName() == viewName then
                return debugView
            end
        end
    end
    return nil
end

function DebugViews.EnumerateViewsByCategory()
    return pairs(categoriesToViews)
end

function DebugViews.OnSettingsLoaded(settings)
    savedSettings = settings

    for categoryName, savedDebugViews in pairs(savedSettings) do
        for debugViewName, debugViewState in pairs(savedDebugViews) do
            local debugView = DebugViews.FindDebugView(categoryName, debugViewName)
            if debugView then
                debugView:SetViewEnabled(debugViewState)
            end
        end
    end

    do
        local debugViewUI = UI.DebugViewUI.CreateDebugViewPane()
        function RebuildUI()
            debugViewUI:RebuildUI()
        end
    end

    RebuildUI()
end