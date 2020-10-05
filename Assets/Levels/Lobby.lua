local addonName, envTable = ...
setfenv(1, envTable)

local WIDTH = 50
local HEIGHT = 50

local BoxVertices = {
    CreateVector2(-WIDTH, -HEIGHT),
    CreateVector2(-WIDTH, HEIGHT),
    CreateVector2(WIDTH, HEIGHT),
    CreateVector2(WIDTH, -HEIGHT),
}

local DiagonalVertices = {
    CreateVector2(-WIDTH, -HEIGHT * 3),
    CreateVector2(WIDTH, HEIGHT * 3),
    CreateVector2(WIDTH * 2, HEIGHT * 3),
    CreateVector2(0, -HEIGHT * 3),
}

local LEVEL_HALF_SIZE = 5
local LEVEL_HALF_WIDTH = 256
local LEVEL_HALF_HEIGHT = 256
local LevelBoundsV = {
    CreateVector2(-LEVEL_HALF_SIZE , -LEVEL_HALF_HEIGHT),
    CreateVector2(-LEVEL_HALF_SIZE, LEVEL_HALF_HEIGHT),
    CreateVector2(LEVEL_HALF_SIZE, LEVEL_HALF_HEIGHT),
    CreateVector2(LEVEL_HALF_SIZE, -LEVEL_HALF_HEIGHT),
}

local LevelBoundsH = {
    CreateVector2(-LEVEL_HALF_WIDTH - LEVEL_HALF_SIZE * 2, -LEVEL_HALF_SIZE),
    CreateVector2(-LEVEL_HALF_WIDTH - LEVEL_HALF_SIZE * 2, LEVEL_HALF_SIZE),
    CreateVector2(LEVEL_HALF_WIDTH + LEVEL_HALF_SIZE * 2, LEVEL_HALF_SIZE),
    CreateVector2(LEVEL_HALF_WIDTH + LEVEL_HALF_SIZE * 2, -LEVEL_HALF_SIZE),
}

local LevelData = {
    Geometry = {
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = BoxVertices,
            WorldLocation = {
                x = 90,
                y = 125,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = BoxVertices,
            WorldLocation = {
                x = -150,
                y = -125,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = DiagonalVertices,
            WorldLocation = {
                x = 150,
                y = -105,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsV,
            WorldLocation = {
                x = 256 + LEVEL_HALF_SIZE,
                y = 0,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsV,
            WorldLocation = {
                x = -256 - LEVEL_HALF_SIZE,
                y = 0,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsH,
            WorldLocation = {
                x = 0,
                y = 256 + LEVEL_HALF_SIZE,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsH,
            WorldLocation = {
                x = 0,
                y = -256 - LEVEL_HALF_SIZE,
            }
        },
    },
}

Level.RegisterLevelData("Lobby", LevelData)