local addonName, envTable = ...
setfenv(1, envTable)

Localization = {}

local DEFAULT_LOCALE = "enUS"

local DefaultLocalization
local ActiveLocalization

function Localization.GetString(tag)
    return (ActiveLocalization and ActiveLocalization[tag]) or (DefaultLocalization and DefaultLocalization[tag]) or tag
end

function Localization.RegisterLocalizations(locale, localization)
    if locale == DEFAULT_LOCALE then
        assert(DefaultLocalization == nil)
        DefaultLocalization = localization
    end

    if locale == GetLocale() then
        assert(ActiveLocalization == nil)
        ActiveLocalization = localization
    end
end