--[[-------------------------------------------
    ActionSetCastState 设置施法状态
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionSetCastState : AINewNode
_class("ActionSetCastState", AINewNode)
ActionSetCastState = ActionSetCastState


function ActionSetCastState:OnBegin()
    local state = self:GetLogicData(-1)

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    aiCmpt:SetCastState(state)

    self:PrintLog(state)
end
----------------------------------------------------------------
