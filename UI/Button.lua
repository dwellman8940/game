local addonName, envTable = ...
setfenv(1, envTable)

Button = {}

do
    local function OnMouseDown(self)
        self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
        self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
        self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Down]])
    end

    local function OnMouseUp(self)
        self.LeftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.RightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
        self.CenterTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    end

    function Button.CreateStandardButton(parent)
        local StandardButton = CreateFrame("Button", nil, parent)
        StandardButton:SetWidth(100)
        StandardButton:SetHeight(22)

        StandardButton:SetScript("OnMouseDown", OnMouseDown)
        StandardButton:SetScript("OnMouseUp", OnMouseUp)

        StandardButton:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]], "ADD")
        StandardButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        StandardButton:SetNormalFontObject("GameFontNormal")
        StandardButton:SetHighlightFontObject("GameFontHighlight")

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

        return LargeButton
    end
end