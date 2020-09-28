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

function Debug.DrawDebugLine(startWorldLocation, endWorldLocation, renderLayer, startColor, endColor)
    local line = Pools.Texture.AcquireLineTexture()

    Rendering.DrawLineAtWorldPoints(line, startWorldLocation, endWorldLocation)

    line:SetThickness(2)
    line:SetColorTexture(1, 1, 1, 1)
    local firstR, firstG, firstB = (startColor or Colors.Red):GetRGB()
    local secondR, secondG, secondB = (endColor or Colors.Green):GetRGB()

    line:SetGradient("HORIZONTAL", firstR, firstG, firstB, secondR, secondG, secondB)
    line:SetDrawLayer(Rendering.RenderDrawToWidgetLayer(renderLayer or 41))

    line:Show()

    C_Timer.NewTimer(0, function() Pools.Texture.ReleaseLineTexture(line) end)
end

function Debug.DrawWorldVerts(worldLocation, verts, renderLayer, firstColor, secondColor)
    for i, vert in ipairs(verts) do
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]

        Debug.DrawDebugLine(worldLocation + vert, worldLocation + nextVert, renderLayer, firstColor, secondColor)
    end
end

function Debug.DrawWorldVertsWithIndices(worldLocation, verts, renderLayer, firstColor, secondColor)
    for i, vert in ipairs(verts) do
        local prevVert = i ~= 1 and verts[i - 1] or verts[#verts]
        local nextVert = i ~= #vert and verts[i + 1] or verts[1]

        Debug.DrawDebugLine(worldLocation + vert, worldLocation + nextVert, renderLayer, firstColor, secondColor)

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


function Debug.DrawDebugAABB(worldLocation, aabb, renderLayer, minColor, maxColor, otherColor)
    local minPoint = worldLocation + aabb:GetMinPoint()
    local maxPoint = worldLocation + aabb:GetMaxPoint()

    minColor = minColor or Colors.BayLeaf
    maxColor = maxColor or Colors.Bouquet
    otherColor = otherColor or Colors.Goblin

    Debug.DrawWorldPoint(minPoint, nil, renderLayer, minColor)
    Debug.DrawWorldPoint(maxPoint, nil, renderLayer, maxColor)

    local upperLeft = CreateVector2(minPoint.x, maxPoint.y)
    local bottomRight = CreateVector2(maxPoint.x, minPoint.y)
    Debug.DrawDebugLine(minPoint, upperLeft, renderLayer, minColor, otherColor)
    Debug.DrawDebugLine(upperLeft, maxPoint, renderLayer, otherColor, maxColor)
    Debug.DrawDebugLine(maxPoint, bottomRight, renderLayer, maxColor, otherColor)
    Debug.DrawDebugLine(bottomRight, minPoint, renderLayer, otherColor, minColor)
end


function Debug.DrawConvexTriangleMesh(worldLocation, vertices)
    local numTriangles = #vertices - 2
    for triangleIndex = 1, numTriangles do
        local triVert1 = vertices[1]
        local triVert2 = vertices[triangleIndex + 1]
        local triVert3 = vertices[triangleIndex + 2]

        Debug.DrawDebugLine(worldLocation + triVert1, worldLocation + triVert2, nil, Colors.White, Colors.White)
        Debug.DrawDebugLine(worldLocation + triVert2, worldLocation + triVert3, nil, Colors.Magenta, Colors.Magenta)
        Debug.DrawDebugLine(worldLocation + triVert3, worldLocation + triVert1, nil, Colors.Yellow, Colors.Yellow)
    end
end

function Debug.DrawWorldPoint(worldLocation, pointSize, renderLayer, color)
    local pointTexture = Pools.Texture.AcquireWorldTexture()
    pointTexture:SetColorTexture((color or Colors.Magenta):GetRGBA())
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