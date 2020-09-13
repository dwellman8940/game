local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

-- No attempts to prevent sniffing here, don't play with cheaters!

local PREFIX = "GAME"
local NetworkingFrame = CreateFrame("Frame")
NetworkingFrame:RegisterEvent("CHAT_MSG_ADDON")
NetworkingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local g_clientConnection = {}
local g_serverConnection = {}
local g_peerConnection = {}

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == PREFIX then
            if channel == "PARTY" then
                local targetCode = text:sub(1, 1)
                local lobbyCode = DecodeLobbyCode(text:sub(2, 5))
                local messageByte = text:sub(6, 6)
                local data = text:sub(7)
                local ambiguatedSender = Ambiguate(sender, "short")
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
                    if peerConnection then
                        local messageInfo = GetMessageByByte(messageByte)
                        if messageInfo and messageInfo.ValidConnections[TARGET_CODE_SERVER_AND_PEERS] then
                            peerConnection:OnMessageReceived(ambiguatedSender, messageInfo.MessageName, messageInfo.Deserialize(data))
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
    g_clientConnection = {}
    g_serverConnection = {}
    g_peerConnection = {}
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