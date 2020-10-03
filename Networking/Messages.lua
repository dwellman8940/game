local addonName, envTable = ...
setfenv(1, envTable)

Messages = {}

Messages.TargetCodes =
{
    AllClients = "A",
    ServerAndPeers = "P",
    Server = "S",
    Lobby = "L",
}

local DebugView_OutgoingMessages = DebugViews.RegisterView("Networking", "Outgoing Messages")
local DebugView_IncomingMessages = DebugViews.RegisterView("Networking", "Incoming Messages")

local MessagesByName = {}
local MessagesByByte = {}

function Messages.GetMessageByName(message)
    return MessagesByName[message]
end

function Messages.GetMessageByByte(messageByte)
    return MessagesByByte[messageByte]
end

local function NoSerialize()
    return ""
end

local function NoDeserialize()
    return ""
end

local AddonChannelEncoding = {
    [0] = "\255",
    [124] = "\176\125",
    [176] = "\176\177",
    [255] = "\176\254",
    [10] = "\176\011",
    [37] = "\176\038",
}

setmetatable(AddonChannelEncoding, {
    __index = function(t, k)
        local c = string.char(k)
        t[k] = c
        return c
    end
})

local EncodeEntireString
do
    local function Encode(char)
		return AddonChannelEncoding[char:byte()]
    end
    function EncodeEntireString(s)
        return s:gsub("[\176\255%z\010\124%%]", Encode)
    end
end

local DecodeEntireString
do
    local AddonChannelDecoding = {
        [254] = "\255",
        [125] = "\124",
        [177] = "\176",
        [11] = "\10",
        [38] = "%",
    }
    local function Decode(char)
	    return AddonChannelDecoding[char:byte()]
    end
    function DecodeEntireString(message)
        return message:gsub("\255", "\000"):gsub("\176([\177\254\011\125\038])", Decode)
    end
end

local function EncodeByte(b)
    return AddonChannelEncoding[b]
end

local function DecodeByte(messageData, byteIndex)
    return messageData:byte(byteIndex, byteIndex)
end

local function EncodeByteString(...)
    local n = select("#", ...)
    local e = ""
    local o = 0
    for i = 1, n do
        local b = select(i, ...) + o

        o = math.floor(b / 256)
        e = e .. EncodeByte(math.floor(b) % 256)
    end
    return e
end

local LoadExp524 = math.ldexp(0.5, 24)
local function EncodeFloat(float)
    local sign = float < 0 and 1 or 0
    if sign == 1 then
        float = -float
    end

    local mantissa, exponent
    if float == 0 then
        mantissa, exponent = 0, 0
    else
        -- special nan, inf, etc?
        mantissa, exponent = math.frexp(float)
        mantissa = mantissa * 2 - 1
        mantissa = mantissa * LoadExp524

        exponent = exponent + 126
    end

    return EncodeByteString(mantissa, 0, exponent * 128, sign * 128)
end

local function DecodeFloat(float)
    local b3 = float:byte(3)
    local b4 = float:byte(4)
    local exponent = math.floor(b3 / 128) + (b4 % 128) * 2
    if exponent == 0 then
        return 0
    end

    local b1 = float:byte(1)
    local b2 = float:byte(2)

    local sign = b4 > 127 and -1 or 1
    local mantissa = (math.ldexp(((b3 % 128) * 256 + b2) * 256 + b1, -23) + 1) * sign

    do return math.ldexp(mantissa, exponent - 127) end
end

function Messages.EncodeLobbyCode(lobbyCode)
    return EncodeEntireString(lobbyCode)
end

function Messages.DecodeLobbyCode(messageData)
    return DecodeEntireString(messageData)
end

local function GetByteOverhead()
    -- Lobby code and message byte
    return 4 + 1
end

local function CreateSerializeClosure(messageName, serializeFn)
    return function(...)
        local messageData = serializeFn(...)
        if DebugView_OutgoingMessages:IsViewEnabled() then
            Debug.Print("Outgoing message:", (#messageData + GetByteOverhead()) .. "b", messageName, ...)
        end
        return messageData
    end
end

local function DeserializeHelper(messageName, bytes, ...)
    if DebugView_IncomingMessages:IsViewEnabled() then
        Debug.Print("Incoming message:", (bytes + GetByteOverhead()) .. "b", messageName, ...)
    end
    return ...
end

local function CreateDeserializeClosure(messageName, deserializeFn)
    return function(messageData)
        return DeserializeHelper(messageName, #messageData, deserializeFn(messageData))
    end
end

local AddMessage
do
    local MessageByteEncoding = String.GetPrintableCharacters()
    local g_nextMessageID = 1
    function AddMessage(messageName, serializeFn, deserializeFn, ...)
        local message =
        {
            MessageName = messageName,
            MessageID = g_nextMessageID,
            MessageByte = MessageByteEncoding[g_nextMessageID],
            Serialize = CreateSerializeClosure(messageName, serializeFn or NoSerialize),
            Deserialize = CreateDeserializeClosure(messageName, deserializeFn and function(messageData) return deserializeFn(DecodeEntireString(messageData)) end or NoDeserialize),
            ValidConnections = Table.CreateSet(...)
        }

        MessagesByName[messageName] = message
        MessagesByByte[message.MessageByte] = message

        g_nextMessageID = g_nextMessageID + 1
    end
end

local PAYLOAD_SEPARATOR = " "
local workingPayload = {}
local function JoinPayload(...)
    local n = select("#", ...)
    for i = 1, n do
        workingPayload[i] = select(i, ...)
    end
    return table.concat(workingPayload, PAYLOAD_SEPARATOR, 1, n)
end

local function EncodeAndJoinPayload(encodeFn, ...)
    return JoinPayload(VarArgs.Apply(encodeFn, ...))
end

local function SplitPayload(messageData)
    return string.split(PAYLOAD_SEPARATOR, messageData)
end

local function SplitAndDecodePayload(decodeFn, messageData)
    return VarArgs.Apply(decodeFn, string.split(PAYLOAD_SEPARATOR, messageData))
end

AddMessage(
    "BroadcastLobby",

    function(lobbyCode, hostPlayer, numPlayers, maxPlayers, versionString)
        return JoinPayload(lobbyCode, hostPlayer, EncodeByte(numPlayers), EncodeByte(maxPlayers), versionString)
    end,

    function(messageData)
        local lobbyCode, hostPlayer, numPlayers, maxPlayers, versionString = SplitPayload(messageData)
        return lobbyCode, hostPlayer, DecodeByte(numPlayers), DecodeByte(maxPlayers), versionString
    end,

    Messages.TargetCodes.Lobby
)

AddMessage(
    "CloseLobby",

    function(lobbyCode)
        return lobbyCode
    end,

    function(messageData)
        local lobbyCode = messageData
        return lobbyCode
    end,

    Messages.TargetCodes.Lobby
)

AddMessage(
    "JoinLobby",

    function(lobbyCode, playerName)
        return lobbyCode .. playerName
    end,

    function(messageData)
        local lobbyCode = messageData:sub(1, 4)
        local playerName = messageData:sub(5)
        return lobbyCode, playerName
    end,

    Messages.TargetCodes.Lobby
)

AddMessage(
    "JoinLobbyResponse",

    function(lobbyCode, targetPlayer, response)
        return JoinPayload(lobbyCode, targetPlayer, response)
    end,

    function(messageData)
         local lobbyCode, targetPlayer, response = SplitPayload(messageData)
        return lobbyCode, targetPlayer, tonumber(response)
    end,

    Messages.TargetCodes.Lobby
)

AddMessage(
    "LoadLevel",

    function(levelName)
        return levelName
    end,

    function(messageData)
        local levelName = messageData
        return levelName
    end,

    Messages.TargetCodes.AllClients
)

AddMessage(
    "PlayerReady",

    function(playerName)
        return playerName
    end,

    function(messageData)
        local playerName = messageData
        return playerName
    end,

    Messages.TargetCodes.Server
)

AddMessage(
    "PlayerLeaving",

    function(playerID)
        return EncodeByte(playerID)
    end,

    function(messageData)
        local playerID = DecodeByte(messageData, 1)
        return playerID
    end,

    Messages.TargetCodes.Server
)

AddMessage(
    "InitPlayer",

    function(playerName, playerID, location, velocity)
        return EncodeByte(playerID) .. EncodeFloat(location:GetX()) .. EncodeFloat(location:GetY()) .. EncodeByte(velocity:GetX() + 1) .. EncodeByte(velocity:GetY() + 1) .. playerName
    end,

    function(messageData)
        local playerID = DecodeByte(messageData, 1)
        local locationX = messageData:sub(2, 5)
        local locationY = messageData:sub(6, 9)
        local velocityX = DecodeByte(messageData, 10)
        local velocityY = DecodeByte(messageData, 11)
        local playerName = messageData:sub(12)
        return playerName, playerID, CreateVector2(DecodeFloat(locationX), DecodeFloat(locationY)), CreateVector2(velocityX - 1, velocityY - 1)
    end,

    Messages.TargetCodes.AllClients
)

AddMessage(
    "RemovePlayer",

    function(playerID)
        return EncodeByte(playerID)
    end,

    function(messageData)
        local playerID = DecodeByte(messageData, 1)
        return playerID
    end,

    Messages.TargetCodes.AllClients
)

AddMessage(
    "OnMovement",

    function(playerID, location, velocity)
        return EncodeByte(playerID) .. EncodeFloat(location:GetX()) .. EncodeFloat(location:GetY()) .. EncodeByte(velocity:GetX() + 1) .. EncodeByte(velocity:GetY() + 1)
    end,

    function(messageData)
        local playerID = DecodeByte(messageData, 1)
        local locationX = messageData:sub(2, 5)
        local locationY = messageData:sub(6, 9)
        local velocityX = DecodeByte(messageData, 10)
        local velocityY = DecodeByte(messageData, 11)
        return playerID, CreateVector2(DecodeFloat(locationX), DecodeFloat(locationY)), CreateVector2(velocityX - 1, velocityY - 1)
    end,

    Messages.TargetCodes.ServerAndPeers
)

AddMessage(
    "Debug_ReplicateAABB",

    function(aabb)
        return EncodeFloat(aabb:GetMinPoint():GetX()) .. EncodeFloat(aabb:GetMinPoint():GetY()) .. EncodeFloat(aabb:GetMaxPoint():GetX()) .. EncodeFloat(aabb:GetMaxPoint():GetX())
    end,

    function(messageData)
        local minX = messageData:sub(1, 4)
        local minY = messageData:sub(5, 8)
        local maxX = messageData:sub(9, 12)
        local maxY = messageData:sub(13, 16)
        return CreateAABB(CreateVector2(DecodeFloat(minX), DecodeFloat(minY)), CreateVector2(DecodeFloat(maxX), DecodeFloat(maxY)))
    end,

    Messages.TargetCodes.AllClients
)

AddMessage(
    "Ping",

    function(...)
        return EncodeAndJoinPayload(EncodeByte, ...)
    end,

    function(messageData)
        return SplitAndDecodePayload(DecodeByte, messageData)
    end,

    Messages.TargetCodes.AllClients
)

AddMessage(
    "Pong",

    function(playerID)
        return EncodeByte(playerID)
    end,

    function(messageData)
        local playerID = DecodeByte(messageData, 1)
        return playerID
    end,

    Messages.TargetCodes.Server
)