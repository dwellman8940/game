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

local MessagesByName = {}
local MessagesByByte = {}

function GetMessageByName(message)
    return MessagesByName[message]
end

function GetMessageByByte(messageByte)
    return MessagesByByte[messageByte]
end

local function NoSerialize()
    return ""
end

local function NoDeserialize()
    return ""
end

local ByteEncoding = {
    "0","1","2","3","4","5","6","7","8","9",
    "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
}

local g_nextMessageID = 1
local function AddMessage(messageName, serializeFn, deserializeFn)
    local message = 
    {
        MessageName = messageName,
        MessageID = g_nextMessageID,
        MessageByte = ByteEncoding[g_nextMessageID],
        Serialize = serializeFn or NoSerialize,
        Deserialize = deserializeFn or NoDeserialize,
    }

    MessagesByName[messageName] = message
    MessagesByByte[message.MessageByte] = message

    g_nextMessageID = g_nextMessageID + 1
end

AddMessage("ResetGame")

AddMessage(
    "InitPlayer", 

    function(playerName, playerID)
        return ("%s %d"):format(playerName, playerID)
    end,

    function(messageData)
        local playerName, playerID = messageData:match("^(%S-) (%d-)$")
        return playerName, tonumber(playerID)
    end
)

AddMessage(
    "OnMovement", 

    function(playerID, x, y)
        return ("%d %d %d"):format(playerID, x, y)
    end,

    function(messageData)
        local playerID, x, y = messageData:match("^(%d-) (%d-) (%d-)$")
        return tonumber(playerID), tonumber(x), tonumber(y)
    end
)