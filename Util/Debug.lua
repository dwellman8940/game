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

function Debug.DrawWorldVerts(worldLocation, verts, renderLayer)
    renderLayer = renderLayer or 41
    for i, vert in ipairs(verts) do
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]
        local line = TexturePool.AcquireLineTexture()
        
        Texture.DrawLineAtWorldPoints(line, worldLocation + vert, worldLocation + nextVert)

        line:SetThickness(2)
        line:SetColorTexture(1, 1, 1, 1)
        line:SetDrawLayer(Texture.RenderDrawToWidgetLayer(renderLayer))

        line:Show()

        C_Timer.NewTimer(0, function() TexturePool.ReleaseLineTexture(line) end)
    end
end