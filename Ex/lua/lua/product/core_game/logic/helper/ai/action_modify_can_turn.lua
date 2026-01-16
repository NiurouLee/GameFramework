--[[-------------------------------------
    ActionModifyCanTurn 更改AI上的CanTurn字段
--]] -------------------------------------
require "ai_node_new"

---@class ActionModifyCanTurn : AINewNode
_class("ActionModifyCanTurn", AINewNode)
ActionModifyCanTurn = ActionModifyCanTurn

function ActionModifyCanTurn:Constructor()
    local n = 0
end

function ActionModifyCanTurn:OnBegin()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local canTurn = self:GetLogicData(-1)
    aiComponent:SetCanTurn(canTurn)
end

function ActionModifyCanTurn:OnUpdate(dt)
    return AINewNodeStatus.Success
end
