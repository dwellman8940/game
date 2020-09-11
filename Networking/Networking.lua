local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

-- No attempts to prevent sniffing here, don't play with cheaters!

local PREFIX = "GAME"
local NetworkingFrame = CreateFrame("Frame")
NetworkingFrame:RegisterEvent("CHAT_MSG_ADDON")
NetworkingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local LobbyCodeLength = 4

local g_activeClientConnections = {}

local function AddClientConnection(clientConnection, lobbyCode)
    if not g_activeClientConnections[lobbyCode] then
        g_activeClientConnections[lobbyCode] = {}
    end
    g_activeClientConnections[lobbyCode][clientConnection] = true
end

local function RemoveClientConnection(clientConnection, lobbyCode)
    if g_activeClientConnections[lobbyCode] then
        g_activeClientConnections[lobbyCode][clientConnection] = nil
        if not next(g_activeClientConnections[lobbyCode]) then
            g_activeClientConnections[lobbyCode] = nil
        end
    end
end

local g_activeServerConnections = {}

local function AddServerConnection(serverConnection, lobbyCode)
    g_activeServerConnections[lobbyCode] = {}
    g_activeServerConnections[lobbyCode][serverConnection] = true
end

local function RemoveServerConnection(clientConnection, lobbyCode)
    g_activeServerConnections[lobbyCode] = nil
end

local function QueueMessageToAllClients(clientConnections, messageName, ...)
    for clientConnection in pairs(clientConnections) do
        clientConnection:OnMessageReceived(messageName, ...)
    end
end

--^(%u)(%u%u%u%u)(%s-)|(%s-)$

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == PREFIX then
            if channel == "PARTY" then
                --Print(("%s: %s"):format(sender, text))
                local target, lobbyCode, messageByte, data = text:match("^(%u)(%u%u%u%u)(.)(.-)$")
                --Print(target, lobbyCode, messageByte, GetMessageByByte(messageByte) and GetMessageByByte(messageByte).MessageName or "error", data)
                if target == "S" then
                    local serverConnection = g_activeServerConnections[lobbyCode]
                    if serverConnection then
                        local messageInfo = GetMessageByByte(messageByte)
                        serverConnection:OnMessageReceived(messageInfo.MessageName, messageInfo.Deserialize(data))
                    end
                elseif target == "A" then
                    local clientConnections = g_activeClientConnections[lobbyCode]
                    if clientConnections then
                        local messageInfo = GetMessageByByte(messageByte)
                        QueueMessageToAllClients(clientConnections, messageInfo.MessageName, messageInfo.Deserialize(data))
                    end
                end
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
end
NetworkingFrame:SetScript("OnEvent", OnEvent)

local function SendMessageToServer(lobbyCode, messageByte, data)
    if IsInGroup() then
        --ChatThrottleLib:SendAddonMessage("ALERT", PREFIX, "S" .. lobbyCode .. messageByte .. data, "PARTY")
        C_ChatInfo.SendAddonMessage(PREFIX, "S" .. lobbyCode .. messageByte .. data, "PARTY")
    end
end

local function SendMessageToAllClients(lobbyCode, messageByte, data)
    if IsInGroup() then
        --ChatThrottleLib:SendAddonMessage("ALERT", PREFIX, "A" .. lobbyCode .. messageByte .. data, "PARTY")
        C_ChatInfo.SendAddonMessage(PREFIX, "A" .. lobbyCode .. messageByte .. data, "PARTY")
    end
end

function CloseAllNetworkConnections()
    g_activeConnections = {}
end

function CreateClientConnection(lobbyCode, onLocalServerMessageReceivedCallback, onMessageReceivedCallback)
    local ClientNetworkConnection = {}

    if onLocalServerMessageReceivedCallback then
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
        end
    else
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToServer(lobbyCode, messageInfo.MessageByte, data)
        end
    end

    function ClientNetworkConnection:Disconnect()
        RemoveClientConnection(self, lobbyCode)
    end

    function ClientNetworkConnection:OnMessageReceived(messageName, ...)
        onMessageReceivedCallback(messageName, ...)
    end

    AddClientConnection(ClientNetworkConnection, lobbyCode)

    return ClientNetworkConnection
end

function CreateServerConnection(lobbyCode, onMessageReceivedCallback)
    local ServerNetworkConnection = {}

    function ServerNetworkConnection:SendMessageToAllClients(messageName, ...)
        local messageInfo = GetMessageByName(messageName)
        local data = messageInfo.Serialize(...)
        SendMessageToAllClients(lobbyCode, messageInfo.MessageByte, data)
    end

    function ServerNetworkConnection:Disconnect()
        RemoveServerConnection(self, lobbyCode)
    end

    function ServerNetworkConnection:OnMessageReceived(messageName, ...)
        onMessageReceivedCallback(messageName, ...)
    end

    AddServerConnection(lobbyCode, ServerNetworkConnection)

    return ServerNetworkConnection
end