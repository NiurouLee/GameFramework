--[[-------------------------------------------
    ActionSetAIState 设置AI状态
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionSetAIState : AINewNode
_class("ActionSetAIState", AINewNode)
ActionSetAIState = ActionSetAIState

function ActionSetAIState:OnBegin()
    local state = self:GetLogicData(-1)

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    aiCmpt:SetAITreeState(state)

    self:PrintLog('state=',state)
end
----------------------------------------------------------------
