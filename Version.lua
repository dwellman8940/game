local addonName, envTable = ...
setfenv(1, envTable)

Version = {}

local MAJOR = 1
local MINOR = 1

function Version.GetVersionInfo()
    return MAJOR, MINOR
end