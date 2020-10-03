local addonName, envTable = ...
setfenv(1, envTable)

Version = {}

Version.CompareResult =
{
    Same = 1,
    Newer = 2,
    Older = 3,
}

local MAJOR = 1
local MINOR = 1

function Version.GetVersionInfo()
    return MAJOR, MINOR
end

function Version.GetVersionAsString()
    return ("%s.%s"):format(MAJOR, MINOR)
end

function Version.GetVersionFromString(versionString)
    local major, minor = versionString:match("^(%d+)%.(%d+)$")
    if major and minor then
        return tonumber(major), tonumber(minor)
    end
end

function Version.CompareVersions(major, minor)
    if major > MAJOR then
        return Version.CompareResult.Newer
    end

    if major < MAJOR then
        return Version.CompareResult.Older
    end

    if minor > MINOR then
        return Version.CompareResult.Newer
    end

    if minor < MINOR then
        return Version.CompareResult.Older
    end

    return Version.CompareResult.Same
end