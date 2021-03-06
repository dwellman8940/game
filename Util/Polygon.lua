local addonName, envTable = ...
setfenv(1, envTable)

Polygon = {}

local function WrapIndex(i, vertices)
    return vertices[Math.WrapIndex(i, #vertices)]
end

local function Cross(a, b, c)
    return a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)
end

local function ArePointsRightOf(a, b, c)
    return Cross(a, b, c) > 0
end

local function ArePointsRightOrOnOf(a, b, c)
    return Cross(a, b, c) >= 0
end

local function ArePointsLeftOf(a, b, c)
    return Cross(a, b, c) < 0
end

local function ArePointsLeftOrOnOf(a, b, c)
    return Cross(a, b, c) <= 0
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

-- Bayazit's algorithm - https://mpen.ca/406/bayazit
function Polygon.ConcaveDecompose(vertices)
    local list = {}
    local lowerIntersection = CreateVector2()
    local upperIntersection = CreateVector2()

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
                            lowerIntersection = intersection
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
                            upperIntersection = intersection
                            upperIndex = j
                        end
                    end
                end
            end

            if lowerIndex == upperIndex % #vertices + 1 then
                local intersection = (lowerIntersection + upperIntersection) * .5

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

            Table.AppendTable(list, Polygon.ConcaveDecompose(lowerPoly))
            Table.AppendTable(list, Polygon.ConcaveDecompose(upperPoly))
            return list
        end
    end

    if #vertices > 20 then
        lowerPoly = Slice(1, math.floor(#vertices / 2), vertices)
        upperPoly = Slice(math.floor(#vertices / 2), 1, vertices)
        Table.AppendTable(list, Polygon.ConcaveDecompose(lowerPoly))
        Table.AppendTable(list, Polygon.ConcaveDecompose(upperPoly))
    else
        table.insert(list, Polygon.Simplify(vertices))
    end

    return list
end

-- Tries to add a vertex if its not too close to the last vertex
local MIN_DISTANCE_SQ = 1.5 ^ 2
function Polygon.TryAddingVertex(vertices, vertex, distSq)
    if #vertices == 0 or not Polygon.AreVerticesTooClose(vertex, vertices[#vertices], distSq) then
        table.insert(vertices, vertex)
        return true
    end
    return false
end

function Polygon.AreVerticesTooClose(vertexA, vertexB, distSq)
    return vertexA:DistanceSquared(vertexB) < (distSq or MIN_DISTANCE_SQ)
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
    return Polygon.Simplify(outputList)
end

function Polygon.ArePointsNearlyColinear(a, b, c)
    return math.abs(Cross(a, b, c)) < 1
end

function Polygon.Simplify(polygonToSimplify)
    local vertexIndex = #polygonToSimplify
    while vertexIndex > 1 do
        local vertex = polygonToSimplify[vertexIndex]
        local nextVertex = polygonToSimplify[vertexIndex - 1]
        if vertex:DistanceSquared(nextVertex) < MIN_DISTANCE_SQ then
            table.remove(polygonToSimplify, vertexIndex)
            if vertexIndex == #polygonToSimplify + 1 then
                vertexIndex = vertexIndex - 1
            end
        else
            local prevVertex = polygonToSimplify[Math.WrapIndex(vertexIndex + 1, #polygonToSimplify)]
            if Polygon.ArePointsNearlyColinear(prevVertex, vertex, nextVertex) then
                table.remove(polygonToSimplify, vertexIndex)
                if vertexIndex == #polygonToSimplify + 1 then
                    vertexIndex = vertexIndex - 1
                end
            end
            vertexIndex = vertexIndex - 1
        end
    end
    return polygonToSimplify
end

function Polygon.TranslatePolygon(polygon, translation)
    local translated = {}
    for i, vertex in ipairs(polygon) do
        translated[i] = vertex + translation
    end
    return translated
end

function Polygon.CalculateBounds(polygon)
    local aabb
    for i, vertex in ipairs(polygon) do
        if aabb then
            aabb:InlineExpandToContainPoint(vertex)
        else
            aabb = CreateAABB(vertex:Clone(), vertex:Clone())
        end
    end
    return aabb
end

function Polygon.CalculateBoundsFromMultiple(polygons)
    local aabb
    for i, polygon in ipairs(polygons) do
        for j, vertex in ipairs(polygon) do
            if aabb then
                aabb:InlineExpandToContainPoint(vertex)
            else
                aabb = CreateAABB(vertex:Clone(), vertex:Clone())
            end
        end
    end
    return aabb
end

local function CreateClipData(x, y)
    local clip = {
        x = x,
        y = y,

        previous = nil,
        next = nil,

        other = nil,

        isEntry = true,
        hasIntersection = false,
        hasBeenProcessed = false,

        alpha = 0,
    }
    return clip
end

local function CreateClipDataFromIntersection(x, y, alpha)
    local clip = CreateClipData(x, y)
    clip.hasIntersection = true
    clip.isEntry = false
    clip.alpha = alpha
    return clip
end

local function CreateClipDataFromPolygon(polygon)
    local first
    local lastClip
    for i, vertex in ipairs(polygon) do
        local clip = CreateClipData(vertex:GetXY())
        if not first then
            first = clip
        end

        clip.previous = lastClip

        if lastClip then
            lastClip.next = clip
        end

        lastClip = clip
    end
    if lastClip then
        first.previous = lastClip
        lastClip.next = first
    end
    return first
end

local function AreClipVertexEqual(clipA, clipB)
    return clipA == clipB
end

local function InsertIntersection(intersection, from, to)
    while not AreClipVertexEqual(from, to) and from.alpha < intersection.alpha  do
        from = from.next
    end

    intersection.next = from
    local previous = from.previous
    intersection.previous = previous

    previous.next = intersection
    from.previous = intersection
end

local function FindNextNonIntersection(clip)
    while clip.hasIntersection do
        clip = clip.next
    end
    return clip
end

-- https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
local function IsPointInsideLinkedPoly(point, rootVertex)
    local isOdd = false

    local currentVertex = rootVertex
    local nextVertex = currentVertex.next

    local x = point.x
    local y = point.y

    repeat
        if currentVertex.x <= point.x or nextVertex.x <= point.x then
            if currentVertex.y < point.y and nextVertex.y >= point.y or nextVertex.y < point.y and currentVertex.y >= point.y then
               isOdd = isOdd ~= (currentVertex.x + (point.y - currentVertex.y) / (nextVertex.y - currentVertex.y) * (nextVertex.x - currentVertex.x) < point.x)
           end
        end

        currentVertex = nextVertex
        nextVertex = currentVertex.next
    until AreClipVertexEqual(currentVertex, rootVertex)

    return isOdd
end

local function FindNextIntersection(clip)
    local endClip = clip
    repeat
        if clip.hasIntersection and not clip.hasBeenProcessed then
            return clip
        end
        clip = clip.next
    until clip == endClip

    return nil
end

local function MarkProcessed(clip)
    clip.hasBeenProcessed = true
    if clip.other and not clip.other.hasBeenProcessed then
        MarkProcessed(clip.other)
    end
end

-- Greiner-Hormann
-- See https://www.inf.usi.ch/hormann/papers/Greiner.1998.ECO.pdf
-- https://www.habrador.com/tutorials/math/12-cut-polygons
-- https://github.com/helderco/univ-polyclip
-- https://github.com/w8r/GreinerHormann
-- Simplified for just unions
function Polygon.UnionPolygons(polygonA, polygonB)
    Polygon.Simplify(polygonA)
    Polygon.Simplify(polygonB)

    if not polygonA or #polygonA < 3 or not polygonB or #polygonB < 3 then
        return nil
    end
    local sourceRoot = CreateClipDataFromPolygon(polygonA)
    local clipRoot = CreateClipDataFromPolygon(polygonB)

    -- Phase 1: Find intersections
    do
        local sourceVertex = sourceRoot
        local clipVertex = clipRoot
        repeat
            if not sourceVertex.hasIntersection then
                repeat
                    if not clipVertex.hasIntersection then
                        local nextSourceVertex = FindNextNonIntersection(sourceVertex.next)
                        local nextClipVertex = FindNextNonIntersection(clipVertex.next)
                        local hasIntersection, u, t, intersectionX, intersectionY = Math.LineIntersectRaw(sourceVertex, nextSourceVertex, clipVertex, nextClipVertex)
                        if hasIntersection and t > 0 and t < 1 and u > 0 and u < 1 then

                            local sourceIntersection = CreateClipDataFromIntersection(intersectionX, intersectionY, t)
                            local clipIntersection = CreateClipDataFromIntersection(intersectionX, intersectionY, u)

                            sourceIntersection.other = clipIntersection
                            clipIntersection.other = sourceIntersection

                            InsertIntersection(sourceIntersection, sourceVertex, nextSourceVertex)
                            InsertIntersection(clipIntersection, clipVertex, nextClipVertex)
                        end
                    end
                    clipVertex = clipVertex.next
                until AreClipVertexEqual(clipVertex, clipRoot)
            end
            sourceVertex = sourceVertex.next
        until AreClipVertexEqual(sourceVertex, sourceRoot)
    end

    -- Phase 2: Determine entry and exit locations
    local sourceInClip, clipInSource
    do
        do
            local sourceVertex = sourceRoot
            sourceInClip = IsPointInsideLinkedPoly(sourceVertex, clipRoot)
            local isEntry = sourceInClip
            repeat
                if sourceVertex.hasIntersection then
                    sourceVertex.isEntry = isEntry
                    isEntry = not isEntry
                end
                sourceVertex = sourceVertex.next
            until AreClipVertexEqual(sourceVertex, sourceRoot)
        end

        do
            local clipVertex = clipRoot
            clipInSource = IsPointInsideLinkedPoly(clipVertex, sourceRoot)
            local isEntry = clipInSource
            repeat
                if clipVertex.hasIntersection then
                    clipVertex.isEntry = isEntry
                    isEntry = not isEntry
                end
                clipVertex = clipVertex.next
            until AreClipVertexEqual(clipVertex, clipRoot)
        end
    end

    -- Phase 3: Create the clipped polygon
    do
        local current = FindNextIntersection(sourceRoot)
        if not current then
            -- No intersections, just select the right one
            if sourceInClip then
                return polygonB
            elseif clipInSource then
                return polygonA
            end
            return nil
        end
        local result = {}
        repeat
            repeat
                MarkProcessed(current)
                if current.isEntry then
                    repeat
                        current = current.next
                        Polygon.TryAddingVertex(result, CreateVector2(current.x, current.y))
                    until current.hasIntersection
                else
                    repeat
                        current = current.previous
                        Polygon.TryAddingVertex(result, CreateVector2(current.x, current.y))
                    until current.hasIntersection
                end
                current = current.other
            until current.hasBeenProcessed

            current = FindNextIntersection(current.next)
        until not current

        if not sourceInClip then
            Table.ReverseRange(result, 1, #result)
        end
        return Polygon.Simplify(result)
    end
end