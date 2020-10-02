local addonName, envTable = ...
setfenv(1, envTable)

NetworkedGameStateMixin = CreateFromMixins(GameStateMixin)

function NetworkedGameStateMixin:Begin() -- override
    self.messageQueue = {}
end

function NetworkedGameStateMixin:End()  -- override
    if self.clientNetworkConnection then
        self.clientNetworkConnection:Disconnect()
    end
    if self.peerNetworkConnection then
        self.peerNetworkConnection:Disconnect()
    end
    if self.lobbyNetworkConnection then
        self.lobbyNetworkConnection:Disconnect()
    end

    self.messageQueue = nil
end

function NetworkedGameStateMixin:CreatePeerToPeerConnection(lobbyCode, peerToPeerHandlers, localServer)
    local function OnPeerToPeerMessageReceived(messageName, ...)
        self:AddMessageToQueue(peerToPeerHandlers, messageName, ...)
    end

    local localServerOnMessageReceived = localServer and function(messageName, ...) localServer:AddMessageToQueue(messageName, ...) end or nil

    self.peerNetworkConnection = CreatePeerConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, OnPeerToPeerMessageReceived)
end

function NetworkedGameStateMixin:CreateClientNetworkConnection(lobbyCode, clientHandlers, localServer)
    local localServerOnMessageReceived = localServer and function(messageName, ...) localServer:AddMessageToQueue(messageName, ...) end or nil

    local function OnClientMessageReceived(messageName, ...)
        self:AddMessageToQueue(clientHandlers, messageName, ...)
    end

    self.clientNetworkConnection = CreateClientConnection(UnitName("player"), lobbyCode, localServerOnMessageReceived, OnClientMessageReceived)
end

function NetworkedGameStateMixin:CreateLobbyConnection(lobbyHandlers)
    local function OnLobbyMessageReceived(messageName, ...)
        self:AddMessageToQueue(lobbyHandlers, messageName, ...)
    end

    self.lobbyNetworkConnection = CreateLobbyConnection(UnitName("player"), OnLobbyMessageReceived)
end

function NetworkedGameStateMixin:AddMessageToQueue(handlers, messageName, ...)
    table.insert(self.messageQueue, { handlers, messageName, ... })
end

function NetworkedGameStateMixin:ProcessMessages()
    if #self.messageQueue > 0 then
        for i, messageData in ipairs(self.messageQueue) do
            local handlers = messageData[1]
            local messageName = messageData[2]
            local handler = handlers[messageName]
            if handler then
                handler(self, unpack(messageData, 3))
            end

            if not self.messageQueue then
                -- A message caused us to switch states, not possible to keep processing messages
                return
            end
        end
        self.messageQueue = {}
    end
end

function NetworkedGameStateMixin:Tick(delta) -- override
    self:ProcessMessages()
end

function NetworkedGameStateMixin:SendServerMessage(messageName, ...)
    self.clientNetworkConnection:SendMessageToServer(messageName, ...)
end

function NetworkedGameStateMixin:SendMessageToPeers(messageName, ...)
    self.peerNetworkConnection:SendMessageToPeers(messageName, ...)
end
function NetworkedGameStateMixin:SendLobbyMessage(messageName, ...)
    self.lobbyNetworkConnection:SendMessageToLobby(messageName, ...)
end