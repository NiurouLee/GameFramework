--[[-------------------------------------------
    ActionForceEnd 加入行为树的结束节点： 强制结束AI逻辑，清空行动力
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionForceEnd : AINewNode
_class("ActionForceEnd", AINewNode)
ActionForceEnd = ActionForceEnd

function ActionForceEnd:OnBegin()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    aiComponent:SetMoveState(AIMoveState.MoveEnd)
    aiComponent:ClearMobilityTotal()
    self:PrintLog(" 强制结束，清空行动力")
end
