local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

function Print(...)
    local s = ""
    for i = 1, select("#", ...) do
        local e = tostring(select(i, ...))
        s = s .. (#s > 0 and " " or "") .. e
    end
    print(("|cBBBBBBBB%s:|r %s"):format(UnitName("player"), s))
end