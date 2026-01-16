--[[-------------------------------------------
    ActionAiBeginTrap 启动AI：通过设置aiComponent内的行动力来启动本回合ai逻辑
--]] -------------------------------------------
require "ai_node_new"
---@class ActionAiBeginTrap : AINewNode
_class("ActionAiBeginTrap", AINewNode)
ActionAiBeginTrap = ActionAiBeginTrap

function ActionAiBeginTrap:Constructor()
    self.m_bStartLogic = false
end

function ActionAiBeginTrap:OnBegin()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    if nil == aiComponent then
        return
    end
    -- local posTarget = aiComponent:GetTargetPos()
    local posSelf = self:GetSelfPos()
    local bEnableStart = false
    local stBeginReason = ""
    for i = 1, 1 do
        local nMobilityTotal = aiComponent:GetMobilityValid()
        if BattleConst.UseObsoleteAI then 
            if nMobilityTotal <= 0 then
                break
            end
        end

        local isRoundEnd = aiComponent:IsAIRoundEnd()
        if isRoundEnd then 
            stBeginReason = "AI逻辑<回合已经结束>"
            break
        end

        bEnableStart = true
        break
    end
    self.m_bStartLogic = bEnableStart
    aiComponent:SetMoveState(AIMoveState.MoveEnd)

    local runCount = self:GetRuntimeData("RunRoundCount") or 1
    self:SetRuntimeData("RunRoundCount", runCount + 1)
end

function ActionAiBeginTrap:OnUpdate()
    if self.m_bStartLogic then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
