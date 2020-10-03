local addonName, envTable = ...
setfenv(1, envTable)

Table = {}

function Table.InvertIndexedTable(indexedTable)
    local inverted = {}
    for i, v in ipairs(indexedTable) do
        inverted[v] = i
    end
    return inverted
end

-- where ... are elements to create a set from
function Table.CreateSet(...)
    local s = {}
    local n = select("#", ...)
    for i = 1, n do
        local e = select(i, ...)
        s[e] = true
    end
    return s
end

function Table.Slice(tableToSlice, startIndex, endIndex)
    local slice = {}
    while startIndex <= endIndex do
        table.insert(slice, startIndex, tableToSlice)
        startIndex = startIndex + 1
    end
    return slice
end

function Table.AppendTable(destination, tableToAppendFrom)
    for i, v in ipairs(tableToAppendFrom) do
        table.insert(destination, v)
    end
    return destination
end

function Table.ReverseRange(table, startIndex, endIndex)
    while startIndex < endIndex do
        table[startIndex], table[endIndex] = table[endIndex], table[startIndex]
        endIndex = endIndex - 1
        startIndex = startIndex + 1
    end
end