--[[-------------------------------------------
    ActionSetMoveEnd 设置移动结束状态
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionSetMoveEnd : AINewNode
_class("ActionSetMoveEnd", AINewNode)
ActionSetMoveEnd = ActionSetMoveEnd


function ActionSetMoveEnd:OnBegin()
    local state = self:GetLogicData(-1)

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    aiCmpt:SetMoveState(AIMoveState.MoveEnd)

    self:PrintLog("无移动行为，设置为移动结束状态")
end
----------------------------------------------------------------
