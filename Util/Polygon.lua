local addonName, envTable = ...
setfenv(1, envTable)

Polygon = {}

local function WrapIndex(i, vertices)
    return vertices[Math.WrapIndex(i, #vertices)]
end

local function ArePointsRightOf(a, b, c)
    local ab = a - b
    local ac = a - c

    return ab:IsRightOf(ac)
end

local function ArePointsRightOrOnOf(a, b, c)
    local ab = a - b
    local ac = a - c

    return ab:IsRightOrOnOf(ac)
end

local function ArePointsLeftOf(a, b, c)
    local ab = a - b
    local ac = a - c

    return ab:IsLeftOf(ac)
end

local function ArePointsLeftOrOnOf(a, b, c)
    local ab = a - b
    local ac = a - c

    return ab:IsLeftOrOnOf(ac)
end

local function IsReflex(i, vertices)
    local a = WrapIndex(i - 1, vertices)
    local b = WrapIndex(i, vertices)
    local c = WrapIndex(i + 1, vertices)

    return ArePointsRightOf(a, b, c)
end

local function Slice(startIndex, endIndex, vertices)
    while endIndex < startIndex do
        endIndex = endIndex + #vertices
    end

    local slice = {}
    while startIndex <= endIndex do
        table.insert(slice, WrapIndex(startIndex, vertices))
        startIndex = startIndex + 1
    end
    return slice
end

local function IsReachable(i, j, vertices)
    if IsReflex(i, vertices) then
        if ArePointsLeftOrOnOf(WrapIndex(i, vertices), WrapIndex(i - 1, vertices), WrapIndex(j, vertices)) and ArePointsRightOrOnOf(WrapIndex(i, vertices), WrapIndex(i + 1, vertices), WrapIndex(j, vertices)) then
            return false
        end
    else
        if ArePointsRightOrOnOf(WrapIndex(i, vertices), WrapIndex(i + 1, vertices), WrapIndex(j, vertices)) or ArePointsLeftOrOnOf(WrapIndex(i, vertices), WrapIndex(i - 1, vertices), WrapIndex(j, vertices)) then
            return false
        end
    end
    if IsReflex(j, vertices) then
        if ArePointsLeftOrOnOf(WrapIndex(j, vertices), WrapIndex(j - 1, vertices), WrapIndex(i, vertices)) and ArePointsRightOrOnOf(WrapIndex(j, vertices), WrapIndex(j + 1, vertices), WrapIndex(i, vertices)) then
            return false
        end
    else
        if ArePointsRightOrOnOf(WrapIndex(j, vertices), WrapIndex(j + 1, vertices), WrapIndex(i, vertices)) or ArePointsLeftOrOnOf(WrapIndex(j, vertices), WrapIndex(j - 1, vertices), WrapIndex(i, vertices)) then
            return false
        end
    end

    for k = 1, #vertices do
        if k ~= i and k ~= j and k % #vertices + 1 ~= i and k % #vertices + 1 ~= j  then
            if Math.DoLineSegmentsIntersect(WrapIndex(i, vertices), WrapIndex(j, vertices), WrapIndex(k, vertices), WrapIndex(k + 1, vertices)) then
                return false
            end
        end
    end
    return true
end

local function ConcatTables(listDest, listSource)
    for i, v in ipairs(listSource) do
        table.insert(listDest, v)
    end
end

-- Bayazit's algorithm - https://mpen.ca/406/bayazit
function Polygon.ConcaveDecompose(vertices)
    local list = {}
    local lowerPoint = CreateVector2(0, 0)
    local upperPoint = CreateVector2(0, 0)

    local lowerIndex = 1
    local upperIndex = 1

    local lowerPoly
    local upperPoly

    for i = 1, #vertices do
        if IsReflex(i, vertices) then
            local upperDist = math.huge
            local lowerDist = math.huge
            for j = 1, #vertices do
                if ArePointsLeftOf(WrapIndex(i - 1, vertices), WrapIndex(i, vertices), WrapIndex(j, vertices)) and ArePointsRightOrOnOf(WrapIndex(i - 1, vertices), WrapIndex(i, vertices), WrapIndex(j - 1, vertices)) then
                    local intersection = Math.CalculateRayRayIntersection(WrapIndex(i - 1, vertices), WrapIndex(i, vertices), WrapIndex(j, vertices), WrapIndex(j - 1, vertices))

                    if intersection and ArePointsRightOf(WrapIndex(i + 1, vertices), WrapIndex(i, vertices), intersection) then
                        local distanceSquared = WrapIndex(i, vertices):DistanceSquared(intersection)
                        if distanceSquared < lowerDist then
                            lowerDist = distanceSquared
                            lowerPoint = intersection
                            lowerIndex = j
                        end
                    end
                end

                if ArePointsLeftOf(WrapIndex(i + 1, vertices), WrapIndex(i, vertices), WrapIndex(j + 1, vertices)) and ArePointsRightOrOnOf(WrapIndex(i + 1, vertices), WrapIndex(i, vertices), WrapIndex(j, vertices)) then
                    local intersection = Math.CalculateRayRayIntersection(WrapIndex(i + 1, vertices), WrapIndex(i, vertices), WrapIndex(j, vertices), WrapIndex(j + 1, vertices))
                    if intersection and ArePointsLeftOf(WrapIndex(i + 1, vertices), WrapIndex(i, vertices), intersection) then
                        local distanceSquared = WrapIndex(i, vertices):DistanceSquared(intersection)
                        if distanceSquared < upperDist then
                            upperDist = distanceSquared
                            upperPoint = intersection
                            upperIndex = j
                        end
                    end
                end
            end

            if lowerIndex == upperIndex % #vertices + 1 then
                local intersection = (lowerPoint + upperPoint) / 2

                lowerPoly = Slice(i, upperIndex, vertices)
                table.insert(lowerPoly, intersection)
                upperPoly = Slice(lowerIndex, i, vertices)
                table.insert(upperPoly, intersection)
            else
                local highestScore = 0
                local bestIndex = lowerIndex

                while upperIndex < lowerIndex do
                    upperIndex = upperIndex + #vertices
                end

                for j = lowerIndex, upperIndex do
                    if IsReachable(i, j, vertices) then
                        local score = 1 / (WrapIndex(i, vertices):DistanceSquared(WrapIndex(j, vertices)) + 1)
                        if IsReflex(j, vertices) then
                            if (ArePointsRightOrOnOf(WrapIndex(j - 1, vertices), WrapIndex(j, vertices), WrapIndex(i, vertices)) and ArePointsLeftOrOnOf(WrapIndex(j + 1, vertices), WrapIndex(j, vertices), WrapIndex(i, vertices))) then
                                score = score + 3
                            else
                                score = score + 2
                            end
                        else
                            score = score + 1
                        end
                        if score > highestScore then
                            bestIndex = j
                            highestScore = score
                        end
                    end
                end
                lowerPoly = Slice(i, bestIndex, vertices)
                upperPoly = Slice(bestIndex, i, vertices)
            end

            ConcatTables(list, Polygon.ConcaveDecompose(lowerPoly))
            ConcatTables(list, Polygon.ConcaveDecompose(upperPoly))
            return list
        end
    end

    if #vertices > 20 then
        lowerPoly = Slice(1, math.floor(#vertices / 2), vertices)
        upperPoly = Slice(math.floor(#vertices / 2), 1, vertices)
        ConcatTables(list, Polygon.ConcaveDecompose(lowerPoly))
        ConcatTables(list, Polygon.ConcaveDecompose(upperPoly))
    else
        table.insert(list, vertices)
    end

    return list
end

-- Sutherland-Hodgman
function Polygon.ClipPolygon(polygonToClip, polygonToClipBy)
    local outputList = polygonToClip
    local clipVert1 = polygonToClipBy[#polygonToClipBy]
    for i, clipVert2 in ipairs(polygonToClipBy) do
        local inputList = outputList
        outputList = {}
        local startPoint = inputList[#inputList]
        for j, endPoint in ipairs(inputList) do
            if ArePointsLeftOrOnOf(endPoint, clipVert1, clipVert2) then
                if ArePointsRightOf(startPoint, clipVert1, clipVert2) then
                    local intersection = Math.CalculateRayRayIntersection(clipVert1, clipVert2, startPoint, endPoint)
                    if intersection then
                        table.insert(outputList, intersection)
                    end
                end
                table.insert(outputList, endPoint)
            elseif ArePointsLeftOrOnOf(startPoint, clipVert1, clipVert2) then
                local intersection = Math.CalculateRayRayIntersection(clipVert1, clipVert2, startPoint, endPoint)
                if intersection then
                    table.insert(outputList, intersection)
                end
            end
            startPoint = endPoint
        end
        clipVert1 = clipVert2
    end
    return outputList
end

function Polygon.TranslatePolygon(polygon, translation)
    local translated = {}
    for i, vertex in ipairs(polygon) do
        translated[i] = vertex + translation
    end
    return translated
end