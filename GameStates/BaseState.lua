local addonName, envTable = ...
setfenv(1, envTable)

GameStateMixin = {}

function GameStateMixin:Begin()
end

function GameStateMixin:End()
end

function GameStateMixin:GetClient()
    return self.client
end

function GameStateMixin:Tick(delta)
end

function GameStateMixin:Render(delta)
end

function GameStateMixin:BeginInternal(client)
    self.client = client
    self:Begin()
end