--[[-------------------------------------------
    ActionRoundEnd ：AI在本回合的行为结束
--]] -------------------------------------------
require "ai_node_new"

----------------------------------------------------------------
---@class ActionRoundEnd : AINewNode
_class("ActionRoundEnd", AINewNode)
ActionRoundEnd = ActionRoundEnd

function ActionRoundEnd:OnBegin()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    if aiCmpt then 
        aiCmpt:SetAIRoundEnd(true)
        aiCmpt:SetMoveState(AIMoveState.MoveEnd)
        self:PrintLog(" 本次回合结束")
    end
end

----------------------------------------------------------------
