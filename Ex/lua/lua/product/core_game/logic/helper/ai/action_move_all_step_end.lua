--[[-------------------------------------------
    ActionMoveAllStepEnd ： 本回合清空移动力，移动结束
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionMoveAllStepEnd : AINewNode
_class("ActionMoveAllStepEnd", AINewNode)
ActionMoveAllStepEnd = ActionMoveAllStepEnd

function ActionMoveAllStepEnd:OnBegin()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    if aiCmpt then 
        aiCmpt:ClearMobilityTotal()
        ---移动终止
        aiCmpt:SetMoveState(AIMoveState.MoveEnd)
        self:PrintLog(" 强制结束，清空行动力")
    end
end
----------------------------------------------------------------
