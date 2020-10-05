local UIParent = UIParent

local addonName, envTable = ...
setfenv(1, envTable)

UI.DebugViewUI = {}

local DebugViewRowMixin = {}

function DebugViewRowMixin:Reset()
    self:SetScript("OnUpdate", nil)

    self:SetWidth(200)
    self:SetHeight(20)
    self:ClearAllPoints()
    self:Hide()
end

function DebugViewRowMixin:AsToggle(debugView)
    self.CheckButton:SetChecked(debugView:IsViewEnabled())
    self.Label:SetPoint("LEFT", self.CheckButton, "RIGHT", 2, 0)
    self.CheckButton:Show()
    self.Label:SetText(debugView:GetViewName())

    self.CheckButton:SetScript("OnClick", function(self)
        debugView:SetViewEnabled(self:GetChecked())
    end)

    self:Show()
end

function DebugViewRowMixin:AsProfile(debugView)
    self.CheckButton:Hide()
    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
    self:SetScript("OnUpdate", function()
        self.Label:SetFormattedText("%s: %.2fms", debugView:GetViewName(), debugView:GetAveragedProfileTime())
    end)
    self:Show()
end

function DebugViewRowMixin:AsFramerate()
    self.CheckButton:Hide()
    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
    self:SetScript("OnUpdate", function()
        self.Label:SetFormattedText("FPS: %.1f", GetFramerate())
    end)
    self:Show()
end

function DebugViewRowMixin:AsNetStats()
    self.CheckButton:Hide()
    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
    self:SetScript("OnUpdate", function()
        local bandwidthIn, bandwidthOut, homeLatency, worldLatency = GetNetStats()
        self.Label:SetFormattedText("I:%.1fKBs O:%.1fKBs", bandwidthIn, bandwidthOut)
    end)
    self:Show()
end

function DebugViewRowMixin:AsLatency()
    self.CheckButton:Hide()
    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 25, 0)
    self:SetScript("OnUpdate", function()
        local bandwidthIn, bandwidthOut, homeLatency, worldLatency = GetNetStats()
        self.Label:SetFormattedText("H:%sms W:%sms", homeLatency, worldLatency)
    end)
    self:Show()
end

function DebugViewRowMixin:AsHeader(categoryName)
    self.CheckButton:Hide()
    self.Label:SetPoint("LEFT", self.CheckButton, "LEFT", 0, 0)
    self.Label:SetText(categoryName)
    self:Show()
end

local function ResetDebugViewRow(pool, frame)
    if not frame.CheckButton then
        Mixin.MixinInto(frame, DebugViewRowMixin)

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
    end

    frame:Reset()
end

function UI.DebugViewUI.CreateDebugViewPane()
    local DebugViewPane = CreateFrame("Frame", nil, UIParent)
    DebugViewPane:SetWidth(220)
    DebugViewPane:SetHeight(700)
    DebugViewPane:SetPoint("RIGHT", -2, 0)
    DebugViewPane:SetToplevel(true)
    DebugViewPane:SetFrameStrata("HIGH")

    Background.AddStandardBackground(DebugViewPane)

    local rowPool = CreateFramePool("Frame", DebugViewPane, nil, ResetDebugViewRow)

    function DebugViewPane:RebuildUI()
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

        for categoryName, debugViews in DebugViews.EnumerateViewsByCategory() do
            local header = GetRow()
            header:AsHeader(categoryName)

            for i, debugView in ipairs(debugViews) do
                local row = GetRow()

                if debugView:GetViewType() == DebugViews.ViewType.Toggle then
                    row:AsToggle(debugView)
                elseif debugView:GetViewType() == DebugViews.ViewType.TimedProfile then
                    row:AsProfile(debugView)
                end
            end
        end

        DebugViewPane:SetHeight(panelHeight)
    end

    return DebugViewPane
end