local addonName, envTable = ...
setfenv(1, envTable)

Rendering = {}

function Rendering.RenderDrawToWidgetLayer(renderLayer)
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

function Rendering.DrawAtWorldPoint(region, worldLocation, originPoint)
    PixelUtil.SetPoint(region, originPoint or "CENTER", region:GetParent(), "CENTER", (worldLocation / region:GetScale()):GetXY())
end

function Rendering.DrawLineAtWorldPoints(line, startPoint, endPoint)
    line:SetStartPoint("CENTER", line:GetParent(), startPoint:GetXY())
    line:SetEndPoint("CENTER", line:GetParent(), endPoint:GetXY())
end

function Rendering.GetNumTexturesRequiredForConvexTriangleMesh(numVertices)
    local numTriangles = numVertices - 2
    local numTextures = math.ceil(numTriangles * .5)
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
function Rendering.DrawConvexTriangleMesh(worldLocation, vertices, textures)
    --Debug.DrawConvexTriangleMesh(worldLocation, vertices)

    local textureIndex = 1
    local numTriangles = #vertices - 2
    for triangleIndex = 1, numTriangles, 2 do
        local triVert1 = vertices[1]
        local triVert2 = vertices[triangleIndex + 1]
        local triVert3 = vertices[triangleIndex + 2]
        local triVert4 = vertices[triangleIndex + 3]

        local texture = textures[textureIndex]
        textureIndex = textureIndex + 1

        Rendering.DrawAtWorldPoint(texture, worldLocation + triVert1)

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
    end
end