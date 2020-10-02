local UIParent = UIParent

local addonName, envTable = ...
setfenv(1, envTable)

DebugViews = {}

local ViewType = {
    Toggle = 1,
    TimedProfile = 2,
}

local RebuildDebugUI

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
        if RebuildDebugUI then
            RebuildDebugUI()
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
    assert(self.viewType == ViewType.TimedProfile)
    self.startedProfileTime = debugprofilestop()
end

function ViewProto:EndProfileCapture()
    assert(self.viewType == ViewType.TimedProfile)
    assert(self.startedProfileTime)
    self.accumulatedProfileTime = (self.accumulatedProfileTime or 0) + debugprofilestop() - self.startedProfileTime
    self.startedProfileTime = nil
end

function ViewProto:ResetProfile()
    if self.viewType == ViewType.TimedProfile then
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
    local debugView = CreateView(categoryName, viewName, ViewType.Toggle)
    debugView:SetViewEnabled(enabledState)
    return debugView
end

function DebugViews.RegisterProfileStatistic(categoryName, viewName)
    local debugView = CreateView(categoryName, viewName, ViewType.TimedProfile)
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

local CreateDebugViewPane
function DebugViews.OnSettingsLoaded(settings)
    savedSettings = settings

    for categoryName, debugViews in pairs(savedSettings) do
        for debugViewName, debugViewState in pairs(debugViews) do
            local debugView = DebugViews.FindDebugView(categoryName, debugViewName)
            if debugView then
                debugView:SetViewEnabled(debugViewState)
            end
        end
    end

    CreateDebugViewPane()
end

function CreateDebugViewPane()
    local DebugViewPane = CreateFrame("Frame", nil, UIParent)
    DebugViewPane:SetWidth(250)
    DebugViewPane:SetHeight(700)
    DebugViewPane:SetPoint("RIGHT", -2, 0)
    DebugViewPane:SetToplevel(true)
    DebugViewPane:SetFrameStrata("HIGH")

    Background.AddStandardBackground(DebugViewPane)

    do
        local function Reset(pool, frame)
            frame:SetWidth(200)
            frame:SetHeight(20)
            frame:ClearAllPoints()
            frame:Hide()

            if not frame.CheckButton then
                frame.CheckButton = CreateFrame("CheckButton", nil, frame)
                frame.CheckButton:SetWidth(20)
                frame.CheckButton:SetHeight(20)
                frame.CheckButton:SetPoint("LEFT", frame, "LEFT", 10, 0)
                frame.CheckButton:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
                frame.CheckButton:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
                frame.CheckButton:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]])
                frame.CheckButton:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])
                frame.CheckButton:SetHitRectInsets(0, -160, 0, 0)

                frame.Label = frame:CreateFontString()
                frame.Label:SetFontObject("GameFontWhite")
                frame.Label:SetJustifyH("LEFT")

                function frame:AsToggle(debugView)
                    self:SetScript("OnUpdate", nil)

                    self.CheckButton:SetChecked(debugView:IsViewEnabled())
                    self.Label:SetPoint("LEFT", self.CheckButton, "RIGHT", 2, 0)
                    self.CheckButton:Show()
                    self.Label:SetText(debugView:GetViewName())

                    self.CheckButton:SetScript("OnClick", function(self)
                        debugView:SetViewEnabled(self:GetChecked())
                    end)

                    self:Show()
                end

                function frame:AsProfile(debugView)
                    self.CheckButton:Hide()
                    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
                    self:SetScript("OnUpdate", function()
                        self.Label:SetFormattedText("%s: %.2fms", debugView:GetViewName(), debugView:GetAveragedProfileTime())
                    end)
                    self:Show()
                end

                function frame:AsFramerate()
                    self.CheckButton:Hide()
                    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
                    self:SetScript("OnUpdate", function()
                        self.Label:SetFormattedText("FPS: %.1f", GetFramerate())
                    end)
                    self:Show()
                end

                function frame:AsNetStats()
                    self.CheckButton:Hide()
                    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
                    self:SetScript("OnUpdate", function()
                        local bandwidthIn, bandwidthOut, homeLatency, worldLatency = GetNetStats()
                        self.Label:SetFormattedText("I:%.1fKBs O:%.1fKBs", bandwidthIn, bandwidthOut)
                    end)
                    self:Show()
                end

                function frame:AsLatency()
                    self.CheckButton:Hide()
                    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
                    self:SetScript("OnUpdate", function()
                        local bandwidthIn, bandwidthOut, homeLatency, worldLatency = GetNetStats()
                        self.Label:SetFormattedText("H:%sms W:%sms", homeLatency, worldLatency)
                    end)
                    self:Show()
                end

                function frame:AsHeader(categoryName)
                    self:SetScript("OnUpdate", nil)

                    self.CheckButton:Hide()
                    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 0, 0)
                    self.Label:SetText(categoryName)
                    self:Show()
                end
            end
        end

        local rowPool = CreateFramePool("Frame", DebugViewPane, nil, Reset)

        function RebuildDebugUI()
            rowPool:ReleaseAll()

            local panelHeight = 0
            local yPadding = 0
            local previousRow

            local function GetRow()
                local row = rowPool:Acquire()
                if previousRow then
                    row:SetPoint("TOP", previousRow, "BOTTOM", 0, yPadding)
                else
                    row:SetPoint("TOP", DebugViewPane, "TOP", 0, yPadding)
                end

                panelHeight = panelHeight + row:GetHeight() + yPadding
                previousRow = row
                return row
            end

            do
                local header = GetRow()
                header:AsHeader("Debug Info")
                GetRow():AsFramerate()
                GetRow():AsNetStats()
                GetRow():AsLatency()
            end

            for categoryName, categoricalDebugViews in pairs(categoriesToViews) do
                local header = GetRow()
                header:AsHeader(categoryName)

                for i, debugView in ipairs(categoricalDebugViews) do
                    local row = GetRow()

                    if debugView:GetViewType() == ViewType.Toggle then
                        row:AsToggle(debugView)
                    elseif debugView:GetViewType() == ViewType.TimedProfile then
                        row:AsProfile(debugView)
                    end
                end
            end

            DebugViewPane:SetHeight(panelHeight)
        end
    end

    RebuildDebugUI()
end