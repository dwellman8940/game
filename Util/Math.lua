local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

Math = {}

function Math.Lerp(startValue, endValue, amount)
	return (1 - amount) * startValue + amount * endValue
end

function Math.LerpOverTime(startValue, endValue, amount, delta)
	return Math.Lerp(startValue, endValue, Math.Saturate(amount * delta * 60));
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