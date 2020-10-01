local addonName, envTable = ...
setfenv(1, envTable)

-- No attempts to prevent sniffing here, don't play with cheaters!

local PREFIX = "GAME"
local NetworkingFrame = CreateFrame("Frame")
NetworkingFrame:RegisterEvent("CHAT_MSG_ADDON")
NetworkingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local g_lobbyConnection
local g_clientConnection = {}
local g_serverConnection = {}
local g_peerConnection = {}

local function AddMesageToPeersAndServer(ambiguatedSender, peerConnection, serverConnection, messageName, ...)
    if peerConnection then
        peerConnection:OnMessageReceived(ambiguatedSender, messageName, ...)
    end
    if serverConnection then
        serverConnection:OnMessageReceived(ambiguatedSender, messageName, ...)
    end
end

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == PREFIX then
            if channel == "PARTY" or channel == "RAID" then
                local targetCode = text:sub(1, 1)
                local ambiguatedSender = Ambiguate(sender, "short")
                if targetCode == TARGET_CODE_LOBBY then
                    if g_lobbyConnection then
                        local messageByte = text:sub(2, 2)
                        local data = text:sub(3)

                        local messageInfo = GetMessageByByte(messageByte)
                        if messageInfo and messageInfo.ValidConnections[TARGET_CODE_LOBBY] then
                            g_lobbyConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                        end
                    end
                else
                    local lobbyCode = DecodeLobbyCode(text:sub(2, 9))
                    local messageByte = text:sub(10, 10)
                    local data = text:sub(11)
                    
                    if targetCode == TARGET_CODE_SERVER then
                        local serverConnection = g_serverConnection[lobbyCode]
                        if serverConnection then
                            local messageInfo = GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[TARGET_CODE_SERVER] then
                                serverConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                            end
                        end
                    elseif targetCode == TARGET_CODE_ALL_CLIENTS then
                        local clientConnection = g_clientConnection[lobbyCode]
                        if clientConnection then
                            local messageInfo = GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[TARGET_CODE_ALL_CLIENTS] then
                                clientConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                            end
                        end
                    elseif targetCode == TARGET_CODE_SERVER_AND_PEERS then
                        local peerConnection = g_peerConnection[lobbyCode]
                        local serverConnection = g_serverConnection[lobbyCode]
                        if peerConnection or serverConnection then
                            local messageInfo = GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[TARGET_CODE_SERVER_AND_PEERS] then
                                AddMesageToPeersAndServer(ambiguatedSender, peerConnection, serverConnection, messageInfo.MessageName, messageInfo.Deserialize(data))
                            end
                        end
                    end
                end
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
end
NetworkingFrame:SetScript("OnEvent", OnEvent)

local function TrySendMessage(lobbyCode, targetCode, messageByte, data)
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage(PREFIX, targetCode .. (lobbyCode and EncodeLobbyCode(lobbyCode) or "") .. messageByte .. data, "RAID")
    elseif IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, targetCode .. (lobbyCode and EncodeLobbyCode(lobbyCode) or "") .. messageByte .. data, "PARTY")
    end
end

local function SendMessageToServer(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, TARGET_CODE_SERVER, messageByte, data)
end

local function SendMessageToLobby(messageByte, data)
    TrySendMessage(nil, TARGET_CODE_LOBBY, messageByte, data)
end

local function SendMessageToAllClients(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, TARGET_CODE_ALL_CLIENTS, messageByte, data)
end

local function SendMessageToPeers(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, TARGET_CODE_SERVER_AND_PEERS, messageByte, data)
end

function CreateLobbyConnection(owningPlayer, onLobbyMessageReceivedCallback)
    assert(g_lobbyConnection == nil)

    local LobbyNetworkConnection = {}

    function LobbyNetworkConnection:SendMessageToLobby(messageName, ...)
        local messageInfo = GetMessageByName(messageName)
        local data = messageInfo.Serialize(...)
        SendMessageToLobby(messageInfo.MessageByte, data)
    end

    function LobbyNetworkConnection:Disconnect()
        g_lobbyConnection = nil
    end

    function LobbyNetworkConnection:OnMessageReceived(fromPlayer, messageName, ...)
        if owningPlayer ~= fromPlayer then
            onLobbyMessageReceivedCallback(messageName, ...)
        end
    end

    g_lobbyConnection = LobbyNetworkConnection

    return LobbyNetworkConnection
end

function CreateClientConnection(owningPlayer, lobbyCode, onLocalServerMessageReceivedCallback, onServerMessageReceivedCallback)
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
        g_clientConnection[lobbyCode] = nil
    end

    function ClientNetworkConnection:OnMessageReceived(fromPlayer, messageName, ...)
        if owningPlayer ~= fromPlayer then
            onServerMessageReceivedCallback(messageName, ...)
        end
    end

    g_clientConnection[lobbyCode] = ClientNetworkConnection

    return ClientNetworkConnection
end

function CreatePeerConnection(owningPlayer, lobbyCode, onLocalServerMessageReceivedCallback, onPeerMessageReceivedCallback)
    local PeerNetworkConnection = {}

    if onLocalServerMessageReceivedCallback then
        function PeerNetworkConnection:SendMessageToPeers(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToPeers(lobbyCode, messageInfo.MessageByte, data)
        end
    else
        function PeerNetworkConnection:SendMessageToPeers(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToPeers(lobbyCode, messageInfo.MessageByte, data)
        end
    end

    function PeerNetworkConnection:Disconnect()
        g_peerConnection[lobbyCode] = nil
    end

    function PeerNetworkConnection:OnMessageReceived(fromPlayer, messageName, ...)
        if owningPlayer ~= fromPlayer then
            onPeerMessageReceivedCallback(messageName, ...)
        end
    end

    g_peerConnection[lobbyCode] = PeerNetworkConnection

    return PeerNetworkConnection
end

function CreateServerConnection(owningPlayer, lobbyCode, onLocalClientMessageReceivedCallback, onClientMessageReceivedCallback)
    local ServerNetworkConnection = {}

    if onLocalClientMessageReceivedCallback then
        function ServerNetworkConnection:SendMessageToAllClients(messageName, ...)
            onLocalClientMessageReceivedCallback(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToAllClients(lobbyCode, messageInfo.MessageByte, data)
        end
    else
        function ServerNetworkConnection:SendMessageToAllClients(messageName, ...)
            local messageInfo = GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToAllClients(lobbyCode, messageInfo.MessageByte, data)
        end
    end

    function ServerNetworkConnection:Disconnect()
        g_serverConnection[lobbyCode] = nil
    end

    function ServerNetworkConnection:OnMessageReceived(fromPlayer, messageName, ...)
        if owningPlayer ~= fromPlayer then
            onClientMessageReceivedCallback(messageName, ...)
        end
    end

    g_serverConnection[lobbyCode] = ServerNetworkConnection

    return ServerNetworkConnection
end