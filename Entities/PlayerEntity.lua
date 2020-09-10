local addonName, envTable = ...
setmetatable(envTable, {__index = _G})
setfenv(1, envTable)


PlayerEntityMixin = CreateFromMixins(GameEntityMixin)

function PlayerEntityMixin:Render(delta) -- override
    self:CreateRenderData()

    -- todo: better drawing
    local client = self:GetGame():GetClient()
    self.renderData.frame:SetPoint("CENTER", client:GetRootFrame(), "BOTTOMLEFT", self:GetWorldLocation():GetXY())
end

function PlayerEntityMixin:CreateRenderData()
    if self.renderData then
        return
    end

    self.renderData = {}

    local client = self:GetGame():GetClient()
    self.renderData.frame = CreateFrame("Frame", nil, client:GetRootFrame())
    self.renderData.frame:SetWidth(100)
    self.renderData.frame:SetHeight(100)

    self.renderData.texture = self.renderData.frame:CreateTexture(nil, "ARTWORK", -8)

    self.renderData.texture:SetColorTexture(1, 0, 0, 1)
    self.renderData.texture:SetAllPoints(self.renderData.frame)
end

function PlayerEntityMixin:Tick(delta)
    local client = self:GetGame():GetClient()
    if client then
        self:SetRelativeLocation(client:GetCursorLocation())
    end
end