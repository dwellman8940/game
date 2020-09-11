local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)

-- No attempts to prevent sniffing here, don't play with cheaters!

local PREFIX = "GAME"
local NetworkingFrame = CreateFrame("Frame")
NetworkingFrame:RegisterEvent("CHAT_MSG_ADDON")
NetworkingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local g_activeConnections = {}

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...;
        if prefix == PREFIX then
            if channel == "RAID" then
                print(("%s: %s"):format(sender, text))
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
end
NetworkingFrame:SetScript("OnEvent", OnEvent)

function CloseAllNetworkConnections()
    g_activeConnections = {}
end

function CreateConnectionToServer(serverAddress, localServer)
    local ServerNetworkConnection = {}

    if localClient then
        function ServerNetworkConnection:SendMessageToServer(message)
            localClient:AddMessageToQueue()
        end
    else
        function ServerNetworkConnection:SendMessageToServer(message)

        end
    end

    function ServerNetworkConnection:Disconnect()
        g_activeConnections[self] = nil
    end


    g_activeConnections[ServerNetworkConnection] = true

    return ServerNetworkConnection
end