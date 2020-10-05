local addonName, envTable = ...
setfenv(1, envTable)

Networking = {}

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
                if targetCode == Messages.TargetCodes.Lobby then
                    if g_lobbyConnection then
                        local messageByte = text:sub(2, 2)
                        local data = text:sub(3)

                        local messageInfo = Messages.GetMessageByByte(messageByte)
                        if messageInfo and messageInfo.ValidConnections[Messages.TargetCodes.Lobby] then
                            g_lobbyConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                        end
                    end
                else
                    local lobbyCode = Messages.DecodeLobbyCode(text:sub(2, 5))
                    local messageByte = text:sub(6, 6)
                    local data = text:sub(7)
                    
                    if targetCode == Messages.TargetCodes.Server then
                        local serverConnection = g_serverConnection[lobbyCode]
                        if serverConnection then
                            local messageInfo = Messages.GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[Messages.TargetCodes.Server] then
                                serverConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                            end
                        end
                    elseif targetCode == Messages.TargetCodes.AllClients then
                        local clientConnection = g_clientConnection[lobbyCode]
                        if clientConnection then
                            local messageInfo = Messages.GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[Messages.TargetCodes.AllClients] then
                                clientConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
                            end
                        end
                    elseif targetCode == Messages.TargetCodes.ServerAndPeers then
                        local peerConnection = g_peerConnection[lobbyCode]
                        local serverConnection = g_serverConnection[lobbyCode]
                        if peerConnection or serverConnection then
                            local messageInfo = Messages.GetMessageByByte(messageByte)
                            if messageInfo and messageInfo.ValidConnections[Messages.TargetCodes.ServerAndPeers] then
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
        C_ChatInfo.SendAddonMessage(PREFIX, targetCode .. (lobbyCode and Messages.EncodeLobbyCode(lobbyCode) or "") .. messageByte .. data, "RAID")
    elseif IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, targetCode .. (lobbyCode and Messages.EncodeLobbyCode(lobbyCode) or "") .. messageByte .. data, "PARTY")
    end
end

local function SendMessageToServer(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, Messages.TargetCodes.Server, messageByte, data)
end

local function SendMessageToLobby(messageByte, data)
    TrySendMessage(nil, Messages.TargetCodes.Lobby, messageByte, data)
end

local function SendMessageToAllClients(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, Messages.TargetCodes.AllClients, messageByte, data)
end

local function SendMessageToPeers(lobbyCode, messageByte, data)
    TrySendMessage(lobbyCode, Messages.TargetCodes.ServerAndPeers, messageByte, data)
end

function Networking.CreateLobbyConnection(owningPlayer, onLobbyMessageReceivedCallback)
    assert(g_lobbyConnection == nil)

    local LobbyNetworkConnection = {}

    function LobbyNetworkConnection:SendMessageToLobby(messageName, ...)
        local messageInfo = Messages.GetMessageByName(messageName)
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

function Networking.CreateClientConnection(owningPlayer, lobbyCode, onLocalServerMessageReceivedCallback, onServerMessageReceivedCallback)
    local ClientNetworkConnection = {}

    if onLocalServerMessageReceivedCallback then
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
        end
    else
        function ClientNetworkConnection:SendMessageToServer(messageName, ...)
            local messageInfo = Messages.GetMessageByName(messageName)
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

function Networking.CreatePeerConnection(owningPlayer, lobbyCode, onLocalServerMessageReceivedCallback, onPeerMessageReceivedCallback)
    local PeerNetworkConnection = {}

    if onLocalServerMessageReceivedCallback then
        function PeerNetworkConnection:SendMessageToPeers(messageName, ...)
            onLocalServerMessageReceivedCallback(messageName, ...)
            local messageInfo = Messages.GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToPeers(lobbyCode, messageInfo.MessageByte, data)
        end
    else
        function PeerNetworkConnection:SendMessageToPeers(messageName, ...)
            local messageInfo = Messages.GetMessageByName(messageName)
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

function Networking.CreateServerConnection(owningPlayer, lobbyCode, onLocalClientMessageReceivedCallback, onClientMessageReceivedCallback)
    local ServerNetworkConnection = {}

    if onLocalClientMessageReceivedCallback then
        function ServerNetworkConnection:SendMessageToAllClients(messageName, ...)
            onLocalClientMessageReceivedCallback(messageName, ...)
            local messageInfo = Messages.GetMessageByName(messageName)
            local data = messageInfo.Serialize(...)
            SendMessageToAllClients(lobbyCode, messageInfo.MessageByte, data)
        end
    else
        function ServerNetworkConnection:SendMessageToAllClients(messageName, ...)
            local messageInfo = Messages.GetMessageByName(messageName)
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

function Networking.GetPing()
    return (select(3, GetNetStats()))
end

function Networking.GetPingSeconds()
    return Networking.GetPing() / 1000
end