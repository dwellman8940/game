local addonName, envTable = ...
setfenv(1, envTable)

VarArgs = {}

function VarArgs.Contains(element, ...)
    local n = select("#", ...)
    for i = 1, n do
        if element == select(i, ...) then
            return true
        end
    end
    return false
end

local function ApplyHelper(applyFn, first, ...)
    if first then
        return applyFn(first), ApplyHelper(applyFn, ...)
    end
end
function VarArgs.Apply(applyFn, ...)
    return ApplyHelper(applyFn, ...)
end