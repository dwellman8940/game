local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

Debug = {}

function Debug.Print(...)
    local s = ""
    for i = 1, select("#", ...) do
        local e = tostring(select(i, ...))
        s = s .. (#s > 0 and " " or "") .. e
    end
    print(("|cBBBBBBBB%s:|r %s"):format(UnitName("player"), s))
end

function Debug.DrawDebugLine(startWorldLocation, endWorldLocation, renderLayer, firstR, firstG, firstB, secondR, secondG, secondB)
    local line = TexturePool.AcquireLineTexture()

    Texture.DrawLineAtWorldPoints(line, startWorldLocation, endWorldLocation)

    line:SetThickness(2)
    line:SetColorTexture(1, 1, 1, 1)
    line:SetGradient("HORIZONTAL", firstR or 1, firstG or 0, firstB or 0, secondR or 0, secondG or 1, secondB or 0)
    line:SetDrawLayer(Texture.RenderDrawToWidgetLayer(renderLayer or 41))

    line:Show()

    C_Timer.NewTimer(0, function() TexturePool.ReleaseLineTexture(line) end)
end

function Debug.DrawWorldVerts(worldLocation, verts, renderLayer)
    for i, vert in ipairs(verts) do
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]

        Debug.DrawDebugLine(worldLocation + vert, worldLocation + nextVert, renderLayer)
    end
end