local UIParent = UIParent

local addonName, envTable = ...
setfenv(1, envTable)

DebugViews = {}

local RebuildDebugUI

local debugViews = {}
local categoriesToViews = {}

local ViewProto = {}
local ViewMetatable = { __index = ViewProto }

function ViewProto:SetViewEnabled(enabledState)
    local newEnabledState = not not enabledState
    if newEnabledState ~= self.enabledState then
        self.enabledState = newEnabledState
        RebuildDebugUI()
    end
end

function ViewProto:IsViewEnabled()
    return self.enabledState
end

function ViewProto:GetViewEnabled()
    return self.enabledState
end

function ViewProto:GetViewName()
    return self.viewName
end

function DebugViews.RegisterView(categoryName, viewName, enabledState)
    assert(debugViews[viewName] == nil)

    local category = categoriesToViews[categoryName]
    if not category then
        category = {}
        categoriesToViews[categoryName] = category
    end

    local debugView = setmetatable({viewName = viewName}, ViewMetatable)
    table.insert(category, debugView)
    debugViews[viewName] = debugView
    debugView:SetViewEnabled(enabledState)

    return debugView
end

function DebugViews.SetDebugViewEnabled(viewName, enabledState)
    assert(debugViews[viewName] ~= nil)

    debugViews[viewName]:SetViewEnabled(enabledState)
end

function DebugViews.IsDebugViewEnabled(viewName)
    local debugView = debugViews[viewName]
    return debugView and debugView:IsViewEnabled()
end

local DebugViewPane = CreateFrame("Frame", nil, UIParent)
DebugViewPane:SetWidth(200)
DebugViewPane:SetHeight(500)
DebugViewPane:SetPoint("RIGHT")
DebugViewPane:SetToplevel(true)
DebugViewPane:SetFrameStrata("HIGH")

do
    local Background = DebugViewPane:CreateTexture(nil, "BACKGROUND")
    Background:SetColorTexture(0, 0, 0, 1)
    Background:SetAllPoints(DebugViewPane)
end

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


            function frame:AsRow(debugView)
                self.CheckButton:SetChecked(debugView:IsViewEnabled())
                self.Label:SetPoint("LEFT", self.CheckButton, "RIGHT", 2, 0)
                self.CheckButton:Show()
                self.Label:SetText(debugView:GetViewName())

                self.CheckButton:SetScript("OnClick", function(self)
                    debugView:SetViewEnabled(self:GetChecked())
                end)

                self:Show()
            end

            function frame:AsHeader(categoryName)
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
        
        local yPadding = 0
        local previousRow
        for categoryName, categoricalDebugViews in pairs(categoriesToViews) do
            local header = rowPool:Acquire()
            if previousRow then
                header:SetPoint("TOP", previousRow, "BOTTOM", 0, yPadding)
            else
                header:SetPoint("TOP", DebugViewPane, "TOP", 0, yPadding)
            end
            header:AsHeader(categoryName)
            previousRow = header
            for i, debugView in ipairs(categoricalDebugViews) do
                local row = rowPool:Acquire()
                if previousRow then
                    row:SetPoint("TOP", previousRow, "BOTTOM", 0, yPadding)
                else
                    row:SetPoint("TOP", DebugViewPane, "TOP", 0, yPadding)
                end

                row:AsRow(debugView)

                previousRow = row
            end
        end
    end
end