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
    local hasIntersection, u, t, intersectionX, intersectionY = Math.LineIntersectRaw(start1, end1, start2, end2)
    return hasIntersection and CreateVector2(intersectionX, intersectionY) or nil
end

function Math.CalculateRayLineIntersection(rayOrigin, rayDirection, segmentStart, segmentEnd)
    local hasIntersection, u, t, intersectionX, intersectionY = Math.LineIntersectRaw(rayOrigin, rayOrigin + rayDirection, segmentStart, segmentEnd)
    return hasIntersection and u >= 0 and u <= 1 and t >= 0 and CreateVector2(intersectionX, intersectionY) or nil
end

function Math.LineIntersectRaw(start1, end1, start2, end2)
    local segment1X = end1.x - start1.x
    local segment1Y = end1.y - start1.y
  
    local segment2X = end2.x - start2.x
    local segment2Y = end2.y - start2.y

    local determinant = segment1X * segment2Y - segment1Y * segment2X
    if math.abs(determinant) > Math.SmallNumber then
        local dx = start2.x - start1.x
        local dy = start2.y - start1.y
        local u = (dx * segment1Y - dy * segment1X) / determinant
        local t = (dx * segment2Y - dy * segment2X) / determinant

        return true, u, t, start1.x + t * segment1X, start1.y + t * segment1Y, segment1X, segment1Y
    end
    return false
end


function Math.DoLineSegmentsIntersect(start1, end1, start2, end2)
    local hasIntersection, u, t = Math.LineIntersectRaw(start1, end1, start2, end2)
    return hasIntersection and u >= 0 and u <= 1 and t >= 0 and t <= 1
end

function Math.WrapIndex(index, numValues)
    return (index - 1) % numValues + 1
end