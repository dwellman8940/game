local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

-- No attempts to prevent sniffing here, don't play with cheaters!

local PREFIX = "GAME"
local NetworkingFrame = CreateFrame("Frame")
NetworkingFrame:RegisterEvent("CHAT_MSG_ADDON")
NetworkingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

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
    assert(serverConnection)
    g_activeServerConnections[lobbyCode] = serverConnection
end

local function RemoveServerConnection(serverConnection, lobbyCode)
    --g_activeServerConnections[lobbyCode] = nil
end

local function QueueServerMessageToAllClients(clientConnections, messageName, ...)
    for clientConnection in pairs(clientConnections) do
        clientConnection:OnServerMessageReceived(messageName, ...)
    end
end

local function QueuePeerMessageToAll(fromPlayer, serverConnection, clientConnections, messageName, ...)
    if serverConnection then
        serverConnection:OnMessageReceived(messageName, ...)
    end
    if clientConnections then
        for clientConnection in pairs(clientConnections) do
            clientConnection:OnPeerMessageReceived(fromPlayer, messageName, ...)
        end
    end
end

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == PREFIX then
            if channel == "PARTY" then
                local target = text:sub(1, 1)
                local lobbyCode = DecodeLobbyCode(text:sub(2, 5))
                local messageByte = text:sub(6, 6)
                local data = text:sub(7)
                if target == TARGET_CODE_SERVER then
                    local serverConnection = g_activeServerConnections[lobbyCode]
                    if serverConnection then
                        local messageInfo = GetMessageByByte(messageByte)
                        if messageInfo and messageInfo.ValidConnections[TARGET_CODE_SERVER] then
                            serverConnection:OnMessageReceived(messageInfo.MessageName, messageInfo.Deserialize(data))
                        end
                    end
                elseif target == TARGET_CODE_ALL_CLIENTS then
                    local clientConnections = g_activeClientConnections[lobbyCode]
                    if clientConnections then
                        local messageInfo = GetMessageByByte(messageByte)
                        if messageInfo and messageInfo.ValidConnections[TARGET_CODE_ALL_CLIENTS] then
                            QueueServerMessageToAllClients(clientConnections, messageInfo.MessageName, messageInfo.Deserialize(data))
                        end
                    end
                elseif target == TARGET_CODE_SERVER_AND_PEERS then
                    local messageInfo = GetMessageByByte(messageByte)
                    if messageInfo and messageInfo.ValidConnections[TARGET_CODE_SERVER_AND_PEERS] then
                        local serverConnection = g_activeServerConnections[lobbyCode]
                        local clientConnections = g_activeClientConnections[lobbyCode]
                        QueuePeerMessageToAll(Ambiguate(sender, "short"), serverConnection, clientConnections, messageInfo.MessageName, messageInfo.Deserialize(data))
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
        C_ChatInfo.SendAddonMessage(PREFIX, TARGET_CODE_SERVER .. EncodeLobbyCode(lobbyCode) .. messageByte .. data, "PARTY")
    end
end

local function SendMessageToAllClients(lobbyCode, messageByte, data)
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, TARGET_CODE_ALL_CLIENTS .. EncodeLobbyCode(lobbyCode) .. messageByte .. data, "PARTY")
    end
end

local function SendMessageToPeers(lobbyCode, messageByte, data)
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, TARGET_CODE_SERVER_AND_PEERS .. EncodeLobbyCode(lobbyCode) .. messageByte .. data, "PARTY")
    end
end

function CloseAllNetworkConnections()
    g_activeClientConnections = {}
    g_activeServerConnections = {}
end

function CreateClientConnection(owningPlayer, lobbyCode, onLocalServerMessageReceivedCallback, onServerMessageReceivedCallback, onPeerMessageReceivedCallback)
    local ClientNetworkConnection = {}

    if onLocalServerMessageReceivedCallback then
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
        end

        function ClientNetworkConnection:SendMessageToPeers(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToPeers(lobbyCode, messageInfo.MessageByte, data)
        end
    else
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToServer(lobbyCode, messageInfo.MessageByte, data)
        end

        function ClientNetworkConnection:SendMessageToPeers(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToPeers(lobbyCode, messageInfo.MessageByte, data)
        end
    end

    function ClientNetworkConnection:Disconnect()
        RemoveClientConnection(self, lobbyCode)
    end

    function ClientNetworkConnection:OnServerMessageReceived(messageName, ...)
        onServerMessageReceivedCallback(messageName, ...)
    end

    function ClientNetworkConnection:OnPeerMessageReceived(fromPlayer, messageName, ...)
        if owningPlayer ~= fromPlayer then
            onPeerMessageReceivedCallback(messageName, ...)
        end
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

    AddServerConnection(ServerNetworkConnection, lobbyCode)

    return ServerNetworkConnection
end