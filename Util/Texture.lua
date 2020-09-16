local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

local PixelUtil_SetPoint = PixelUtil.SetPoint

Texture = {}

function Texture.RenderDrawToWidgetLayer(renderLayer)
    if renderLayer < 16 then
        return "BACKGROUND", renderLayer - 8
    elseif renderLayer < 32 then
        return "BORDER", renderLayer - 8 - 16
    elseif renderLayer < 48 then
        return "ARTWORK", renderLayer - 8 - 32
    elseif renderLayer < 64 then
        return "OVERLAY", renderLayer - 8 - 48
    end
end

function Texture.DrawAtWorldPoint(texture, worldPoint, originPoint)
    PixelUtil_SetPoint(texture, originPoint or "CENTER", texture:GetParent(), "CENTER", (worldPoint / texture:GetScale()):GetXY())
end

function Texture.DrawLineAtWorldPoints(line, startPoint, endPoint)
    line:SetStartPoint("CENTER", line:GetParent(), startPoint:GetXY())
    line:SetEndPoint("CENTER", line:GetParent(), endPoint:GetXY())
end