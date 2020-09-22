local addonName, envTable = ...
setfenv(1, envTable)

Math = {}

Math.SmallNumber = .0001

function Math.Lerp(startValue, endValue, amount)
	return (1 - amount) * startValue + amount * endValue
end

function Math.LerpOverTime(startValue, endValue, amount, delta)
	return Math.Lerp(startValue, endValue, Math.Saturate(amount * delta * 60))
end

function Math.Clamp(value, min, max)
	if value > max then
		return max
	elseif value < min then
		return min
	end
	return value
end

function Math.Saturate(value)
	return Math.Clamp(value, 0, 1)
end

function Math.PercentageBetween(value, startValue, endValue)
	if startValue == endValue then
		return 0
	end
	return (value - startValue) / (endValue - startValue)
end

function Math.MapRange(fromStart, fromEnd, toStart, toEnd, amount)
    local percent = Math.PercentageBetween(amount, fromStart, fromEnd)
    return Math.Lerp(toStart, toEnd, percent)
end

function Math.MapRangeClamped(fromStart, fromEnd, toStart, toEnd, amount)
    local percent = Math.PercentageBetween(amount, fromStart, fromEnd)
    return Math.Lerp(toStart, toEnd, Math.Saturate(percent))
end

function Math.CalculateRayRayIntersection(start1, end1, start2, end2)
    local s1Y = end1.y - start1.y
    local s2Y = end2.y - start2.y

    local s1X = start1.x - end1.x
    local s2X = start2.x - end2.x

    local determinant = s1Y * s2X - s2Y * s1X

    if math.abs(determinant) > Math.SmallNumber then
        local c1 = s1Y * start1.x + s1X * start1.y
        local c2 = s2Y * start2.x + s2X * start2.y

        local x = (s2X * c1 - s1X * c2) / determinant
        local y = (s1Y * c2 - s2Y * c1) / determinant

        return CreateVector2(x, y)
    end
    return nil
end

function Math.CalculateRayLineIntersection(rayOrigin, rayDirection, segmentStart, segmentEnd)
    local segDirection = segmentEnd - segmentStart

    local determinant = rayDirection.x * segDirection.y - rayDirection.y * segDirection.x
    if math.abs(determinant) > Math.SmallNumber then
        local x = segmentStart.x - rayOrigin.x
        local y = segmentStart.y - rayOrigin.y
        local u = (x * rayDirection.y - y * rayDirection.x) / determinant
        local t = (x * segDirection.y - y * segDirection.x) / determinant

        if u >= 0 and u <= 1 and t >= 0 then
            return rayOrigin + t * rayDirection
        end
    end
end

-- adapted from https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
do
    local function OnSegment(startPoint, endPoint, point)
        return endPoint.x <= math.max(startPoint.x, point.x)
           and endPoint.x >= math.min(startPoint.x, point.x)
           and endPoint.y <= math.max(startPoint.y, point.y)
           and endPoint.y >= math.min(startPoint.y, point.y)
    end

    local function LineSegmentOrientation(startPoint, endPoint, point)
        local val = (endPoint.y - startPoint.y) * (point.x - endPoint.x) - (endPoint.x - startPoint.x) * (point.y - endPoint.y)
        return val == 0 and 0 or val > 0 and 1 or 2
    end

    function Math.DoLineSegmentsIntersect(start1, end1, start2, end2)
        local o1 = LineSegmentOrientation(start1, end1, start2)
        local o2 = LineSegmentOrientation(start1, end1, end2)
        local o3 = LineSegmentOrientation(start2, end2, start1)
        local o4 = LineSegmentOrientation(start2, end2, end1)

        if o1 ~= o2 and o3 ~= o4 then
            return true
        end

        if o1 == 0 and OnSegment(start1, start2, end1) then
            return true
        end

        if o2 == 0 and OnSegment(start1, end2, end1) then
            return true
        end

        if o3 == 0 and OnSegment(start2, start1, end2) then
            return true
        end

        if o4 == 0 and OnSegment(start2, end1, end2) then
            return true
        end

        return false
    end
end

function Math.WrapIndex(index, numValues)
    return (index - 1) % numValues + 1
end