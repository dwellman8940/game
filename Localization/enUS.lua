local addonName, envTable = ...
setfenv(1, envTable)

local enUS = {
    Slash_Show = [[/game]],
    HostGame = [[Host Game]],
    JoinGame = [[Join Game]],
    Options = [[Options]],
    Exit = [[Exit]],
    LevelEditor = [[Level Editor]],
    PartyRequired = [[Join a party or raid to host and join games!]],
}

Localization.RegisterLocalizations("enUS", enUS)