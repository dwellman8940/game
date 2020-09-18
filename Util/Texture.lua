local math_ceil = math.ceil

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

function Texture.DrawAtWorldPoint(texture, worldLocation, originPoint)
    PixelUtil_SetPoint(texture, originPoint or "CENTER", texture:GetParent(), "CENTER", (worldLocation / texture:GetScale()):GetXY())
end

function Texture.DrawLineAtWorldPoints(line, startPoint, endPoint)
    line:SetStartPoint("CENTER", line:GetParent(), startPoint:GetXY())
    line:SetEndPoint("CENTER", line:GetParent(), endPoint:GetXY())
end

function Texture.GetNumTexturesRequiredForConvexTriangleMesh(numVertices)
    local numTriangles = numVertices - 2
    local numTextures = math_ceil(numTriangles * .5)
    return numTextures
end


--[[
      1                     3
       ____________________
      |                  /|
      |                /  |
      |              /    |
      |            /      |
      |          /        |
      |        /          |
      |      /            |
      |    /              |
      |  /                |
      |/__________________|
      2                     4
]]

local TRIANGLE_TEXTURE_SIZE = 2
local TRIANGLE_TEXTURE_HALF_SIZE = TRIANGLE_TEXTURE_SIZE * .5
function Texture.DrawConvexTriangleMesh(worldLocation, vertices, textures)
    Debug.DrawWorldVerts(worldLocation, vertices)

    local textureIndex = 1
    local numTriangles = #vertices - 2
    for triangleIndex = 1, numTriangles, 2 do
        local triVert1 = vertices[1]
        local triVert2 = vertices[triangleIndex + 1]
        local triVert3 = vertices[triangleIndex + 2]
        local triVert4 = vertices[triangleIndex + 3]

        local texture = textures[textureIndex]
        textureIndex = textureIndex + 1

        Texture.DrawAtWorldPoint(texture, worldLocation + triVert1)

        texture:SetSize(TRIANGLE_TEXTURE_SIZE, TRIANGLE_TEXTURE_SIZE)
        local vertOffset2 = triVert2 - triVert1
        local vertOffset3 = triVert3 - triVert1
        texture:SetVertexOffset(1, vertOffset2:GetX() + TRIANGLE_TEXTURE_HALF_SIZE, vertOffset2:GetY() - TRIANGLE_TEXTURE_HALF_SIZE)
        texture:SetVertexOffset(2, TRIANGLE_TEXTURE_HALF_SIZE, TRIANGLE_TEXTURE_HALF_SIZE)
        texture:SetVertexOffset(3, vertOffset3:GetX() - TRIANGLE_TEXTURE_HALF_SIZE, vertOffset3:GetY() - TRIANGLE_TEXTURE_HALF_SIZE)
        if triVert4 then
            local vertOffset4 = triVert4 - triVert1
            texture:SetVertexOffset(4, vertOffset4:GetX() - TRIANGLE_TEXTURE_HALF_SIZE, vertOffset4:GetY() + TRIANGLE_TEXTURE_HALF_SIZE)
        else
            texture:SetVertexOffset(4, -TRIANGLE_TEXTURE_HALF_SIZE, TRIANGLE_TEXTURE_HALF_SIZE)
        end

        if drawDebug then
            Debug.DrawDebugLine(worldLocation + triVert1, worldLocation + triVert2, nil, 1, 1, 1, 1, 1, 1)
            Debug.DrawDebugLine(worldLocation + triVert2, worldLocation + triVert3, nil, 1, 0, 1, 1, 0, 1)
            Debug.DrawDebugLine(worldLocation + triVert3, worldLocation + (triVert4 or triVert1), nil, 1, 1, 0, 1, 1, 0)
            if triVert4 then
                Debug.DrawDebugLine(worldLocation + triVert1, worldLocation + triVert3, nil, 0, 1, 1, 0, 1, 1)
                Debug.DrawDebugLine(worldLocation + triVert4, worldLocation + triVert1, nil, 0, 1, 1, 0, 1, 1)
            end
        end
    end
end