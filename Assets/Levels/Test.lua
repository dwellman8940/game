local addonName, envTable = ...
setfenv(1, envTable)

local WIDTH = 50
local HEIGHT = 50
local TestVertices = {
    CreateVector2(-WIDTH, -HEIGHT),
    CreateVector2(-WIDTH * 2, 0),
    CreateVector2(-WIDTH, HEIGHT),
    CreateVector2(-WIDTH, HEIGHT * 5),
    CreateVector2(WIDTH * 2, HEIGHT * 5),
    CreateVector2(0, WIDTH * 1.5),
    CreateVector2(WIDTH, HEIGHT),
    CreateVector2(WIDTH, -HEIGHT),
}

local BoxVertices = {
    CreateVector2(-WIDTH, -HEIGHT),
    CreateVector2(-WIDTH, HEIGHT),
    CreateVector2(WIDTH, HEIGHT),
    CreateVector2(WIDTH, -HEIGHT),
}

local LongBoxVertices = {
    CreateVector2(-WIDTH * 4, -HEIGHT * .2),
    CreateVector2(-WIDTH * 4, HEIGHT * .2),
    CreateVector2(WIDTH * 4, HEIGHT * .2),
    CreateVector2(WIDTH * 4, -HEIGHT * .2),
}

local TallBoxVertices = {
    CreateVector2(-WIDTH * .2, -HEIGHT * 4),
    CreateVector2(-WIDTH * .2, HEIGHT * 4),
    CreateVector2(WIDTH * .2, HEIGHT * 4),
    CreateVector2(WIDTH * .2, -HEIGHT * 4),
}

local DiagonalVertices = {
    CreateVector2(-WIDTH, -HEIGHT * 3),
    CreateVector2(WIDTH, HEIGHT * 3),
    CreateVector2(WIDTH * 2, HEIGHT * 3),
    CreateVector2(WIDTH, -HEIGHT * 3),
}

local LEVEL_HALF_SIZE = 5
local LEVEL_HALF_WIDTH = 512
local LEVEL_HALF_HEIGHT = 512
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
            Vertices = TestVertices,
            WorldLocation = {
                x = -100,
                y = 0,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = BoxVertices,
            WorldLocation = {
                x = 250,
                y = 250,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = LongBoxVertices,
            WorldLocation = {
                x = -350,
                y = -250,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = TallBoxVertices,
            WorldLocation = {
                x = -350,
                y = -150,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = TallBoxVertices,
            WorldLocation = {
                x = -250,
                y = -120,
            }
        },
        {
            Mobility = 1,
            Occlusion = 1,
            Vertices = DiagonalVertices,
            WorldLocation = {
                x = 250,
                y = -250,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsV,
            WorldLocation = {
                x = 512 + LEVEL_HALF_SIZE,
                y = 0,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsV,
            WorldLocation = {
                x = -512 - LEVEL_HALF_SIZE,
                y = 0,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsH,
            WorldLocation = {
                x = 0,
                y = 512 + LEVEL_HALF_SIZE,
            }
        },
        {
            Mobility = 1,
            Occlusion = 2,
            Vertices = LevelBoundsH,
            WorldLocation = {
                x = 0,
                y = -512 - LEVEL_HALF_SIZE,
            }
        },
    },
}

Level.RegisterLevelData("Test", LevelData)