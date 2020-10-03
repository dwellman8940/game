local addonName, envTable = ...
setfenv(1, envTable)

Button = {}

do
    local function OnMouseDown(self)
        if self:IsEnabled() then
            self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
            self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
            self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
        end
    end

    local function OnMouseUp(self)
        if self:IsEnabled() then
            self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
            self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
            self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        end
    end

    local function OnEnabled(self)
        self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    end

    local function OnDisable(self)
        self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
        self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
        self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
    end

    local function OnShow(self)
        if self:IsEnabled() then
            OnEnabled(self)
        else
            OnDisable(self)
        end
    end

    function Button.CreateStandardButton(parent)
        local StandardButton = CreateFrame("Button", nil, parent)
        StandardButton:SetWidth(100)
        StandardButton:SetHeight(22)

        StandardButton:SetScript("OnMouseDown", OnMouseDown)
        StandardButton:SetScript("OnMouseUp", OnMouseUp)
        StandardButton:SetScript("OnEnable", OnEnabled)
        StandardButton:SetScript("OnDisable", OnDisable)
        StandardButton:SetScript("OnShow", OnShow)

        StandardButton:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]], "ADD")
        StandardButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        StandardButton:SetNormalFontObject("GameFontNormal")
        StandardButton:SetHighlightFontObject("GameFontHighlight")
        StandardButton:SetDisabledFontObject("GameFontDisable")

        local LeftTexture = StandardButton:CreateTexture(nil, "BACKGROUND")
        StandardButton.LeftTexture = LeftTexture
        LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        LeftTexture:SetTexCoord(0, 0.09375, 0, 0.6875)
        LeftTexture:SetWidth(12)
        LeftTexture:SetPoint("TOPLEFT")
        LeftTexture:SetPoint("BOTTOMLEFT")

        local RightTexture = StandardButton:CreateTexture(nil, "BACKGROUND")
        StandardButton.RightTexture = RightTexture
        RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        RightTexture:SetTexCoord(0.53125, 0.625, 0, 0.6875)
        RightTexture:SetWidth(12)
        RightTexture:SetPoint("TOPRIGHT")
        RightTexture:SetPoint("BOTTOMRIGHT")

        local CenterTexture = StandardButton:CreateTexture(nil, "BACKGROUND")
        StandardButton.CenterTexture = CenterTexture
        CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        CenterTexture:SetTexCoord(0.09375, 0.53125, 0, 0.6875)
        CenterTexture:SetPoint("TOPLEFT", LeftTexture, "TOPRIGHT")
        CenterTexture:SetPoint("BOTTOMRIGHT", RightTexture, "BOTTOMLEFT")

        return StandardButton
    end

    function Button.CreateLargeButton(parent)
        local LargeButton = Button.CreateStandardButton(parent)

        LargeButton:SetHeight(40)
        LargeButton:SetWidth(250)
        LargeButton:SetNormalFontObject("GameFontNormalHuge")
        LargeButton:SetHighlightFontObject("GameFontHighlightHuge")
        LargeButton:SetDisabledFontObject("GameFontDisableHuge")

        return LargeButton
    end

    function Button.CreateCloseButton(parent)
        local CloseButton = CreateFrame("Button", nil, parent)
        CloseButton:SetWidth(32)
        CloseButton:SetHeight(32)

        CloseButton:SetDisabledTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Disabled]])
        CloseButton:SetNormalTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
        CloseButton:SetPushedTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Down]])
        CloseButton:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]], "ADD")

        return CloseButton
    end
end