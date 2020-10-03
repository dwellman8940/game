local addonName, envTable = ...
setfenv(1, envTable)

Background = {}

function Background.AddStandardBackground(parent, borderSize)
    do
        local Background = parent:CreateTexture(nil, "BACKGROUND", nil, -5)
        Background:SetColorTexture(Colors.Swamp:GetRGBA())
        Background:SetAllPoints(parent)
    end

    do
        local Border = parent:CreateTexture(nil, "BACKGROUND", nil, -6)
        Border:SetColorTexture(Colors.Black:GetRGBA())
        borderSize = borderSize or 2
        Border:SetPoint("TOPLEFT", -borderSize, borderSize)
        Border:SetPoint("BOTTOMRIGHT", borderSize, -borderSize)
    end
end

function Background.AddModalUnderlay(parent)
    do
        local Underlay = parent:CreateTexture(nil, "BACKGROUND", nil, -1)
        Underlay:SetColorTexture(Colors.Black:WithAlpha(.75):GetRGBA())
        Underlay:SetAllPoints(parent)
    end
end