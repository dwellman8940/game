local addonName, envTable = ...
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
    local line = Pools.Texture.AcquireLineTexture()

    Rendering.DrawLineAtWorldPoints(line, startWorldLocation, endWorldLocation)

    line:SetThickness(2)
    line:SetColorTexture(1, 1, 1, 1)
    line:SetGradient("HORIZONTAL", firstR or 1, firstG or 0, firstB or 0, secondR or 0, secondG or 1, secondB or 0)
    line:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(renderLayer or 41))

    line:Show()

    C_Timer.NewTimer(0, function() Pools.Texture.ReleaseLineTexture(line) end)
end

function Debug.DrawWorldVerts(worldLocation, verts, renderLayer, firstR, firstG, firstB, secondR, secondG, secondB)
    for i, vert in ipairs(verts) do
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]

        Debug.DrawDebugLine(worldLocation + vert, worldLocation + nextVert, renderLayer, firstR, firstG, firstB, secondR, secondG, secondB)
    end
end

function Debug.DrawWorldVertsWithIndices(worldLocation, verts, renderLayer, firstR, firstG, firstB, secondR, secondG, secondB)
    for i, vert in ipairs(verts) do
        local prevVert = i ~= 1 and verts[i - 1] or verts[#verts]
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]

        Debug.DrawDebugLine(worldLocation + vert, worldLocation + nextVert, renderLayer, firstR, firstG, firstB, secondR, secondG, secondB)

        if prevVert == vert or nextVert == vert then
            Debug.DrawWorldString(worldLocation + vert, i, renderLayer)
        else
            local a = (prevVert - vert):GetNormal()
            local b = (nextVert - vert):GetNormal()
            local dir = (a + b):GetNormal() * (i % 2 == 0 and -1 or 1)
            Debug.DrawWorldString(worldLocation + vert + dir * 10, i, renderLayer)
        end
    end
end

function Debug.DrawConvexTriangleMesh(worldLocation, vertices)
    --Debug.DrawWorldVerts(worldLocation, vertices)

    local numTriangles = #vertices - 2
    for triangleIndex = 1, numTriangles do
        local triVert1 = vertices[1]
        local triVert2 = vertices[triangleIndex + 1]
        local triVert3 = vertices[triangleIndex + 2]

        Debug.DrawDebugLine(worldLocation + triVert1, worldLocation + triVert2, nil, 1, 1, 1, 1, 1, 1)
        Debug.DrawDebugLine(worldLocation + triVert2, worldLocation + triVert3, nil, 1, 0, 1, 1, 0, 1)
        Debug.DrawDebugLine(worldLocation + triVert3, worldLocation + triVert1, nil, 1, 1, 0, 1, 1, 0)
    end
end

function Debug.DrawWorldPoint(worldLocation, pointSize, renderLayer, r, g, b, a)
    local pointTexture = Pools.Texture.AcquireWorldTexture()
    pointTexture:SetColorTexture(r or 1, g or 0, b or 1, a or 1)
    pointTexture:SetWidth(pointSize or 5)
    pointTexture:SetHeight(pointSize or 5)
    pointTexture:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(renderLayer or 41))
    Rendering.DrawAtWorldPoint(pointTexture, worldLocation)
    pointTexture:Show()

    C_Timer.NewTimer(0, function() Pools.Texture.ReleaseWorldTexture(pointTexture) end)
end

function Debug.DrawWorldString(worldLocation, message, renderLayer)
    local fontString = Pools.FontString.AcquireWorldFontString()
    fontString:SetFontObject("GameFontWhiteSmall")
    fontString:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(renderLayer or 41))
    Rendering.DrawAtWorldPoint(fontString, worldLocation)
    fontString:SetText(message)
    fontString:Show()

    C_Timer.NewTimer(0, function() Pools.FontString.ReleaseWorldFontString(fontString) end)
end