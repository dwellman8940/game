local addonName, envTable = ...
setfenv(1, envTable)

local enUS = {
    Slash_Show = [[/game]],
    HostGame = [[Host Game]],
    JoinGame = [[Join Game]],
    JoinLobby = [[Join Lobby]],
    Options = [[Options]],
    Exit = [[Exit]],
    LevelEditor = [[Level Editor]],
    PartyRequired = [[Join a party or raid to host and join games!]],
    ButtonOK = [[Okay]],
    JoinLobbyTitle = [[Join Lobby]],
    SearchingForHosted = [[Searching for hosted games...]],
    StartGame = [[Start Game]],
    NumPlayersOnLobby = [[%s/%s players]],

    LobbyFullTooltip = [[Lobby is full.]],
    LobbyStartingTooltip = [[Game has already started.]],
    LobbyNewerVersionTooltip = [[This lobby has a newer version than you.|nUpgrade your game to version %s to be able to join!]],
    LobbyOlderVersionTooltip = [[This lobby has an older version than you.|nEncourage the host to upgrade to the latest version!]],

    UnableToConnectToLobby = [[Unable to connect to lobby.]],
    UnableToConnectToLobby_Full = [[Lobby is full.]],

    LoadingScreen_JoiningLobby = [[Connecting to %s's Lobby...]],
    LoadingScreen_GameStarting = [[Game starting...]],

    DisconnectedReason_TimedOut = [[Connection to host timed out.]],
    DisconnectedReason_HostLeft = [[The host left the game.]],
    DisconnectedReason_Kicked = [[You were kicked from the game.]],
}

Localization.RegisterLocalizations("enUS", enUS)