--[[-------------------------------------------
    ActionSelectEndReason 根据AI状态选择AI分支
--]] -------------------------------------------
require "ai_node_new"
---@class ActionSelectEndReason : AINewNode
_class("ActionSelectEndReason", AINewNode)
ActionSelectEndReason = ActionSelectEndReason

function ActionSelectEndReason:Constructor()
end

function ActionSelectEndReason:OnUpdate()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()

    local endReason = AIEndReasonType.NoMobility
    for i = 1, 1 do
        ---行动力检查
        local nMobilityTotal = aiComponent:GetMobilityValid()
        if BattleConst.UseObsoleteAI then
            if nMobilityTotal <= 0 then
                endReason = AIEndReasonType.NoMobility
                break
            end
        end

        ---血量检查：自己
        local bMineDead = AINewNode.IsEntityDead(self.m_entityOwn)
        if bMineDead then
            endReason = AIEndReasonType.SelfDead
            break
        end

        ---血量检查：目标
        local bTargetDead = AINewNode.IsEntityDead(aiComponent:GetTargetEntity())
        if bTargetDead then
            endReason = AIEndReasonType.TargetDead
            break
        end

        ---BUFF状态检查：晕倒
        ---@type BuffComponent
        local buffCmpt = self.m_entityOwn:BuffComponent()
        if buffCmpt then
            local isStun = buffCmpt:HasFlag(BuffFlags.SkipTurn)
            if isStun then
                endReason = AIEndReasonType.SkipTurn
                break
            end
        end

        ---回合数检查
        local isRoundEnd = aiComponent:IsAIRoundEnd()
        if isRoundEnd then
            endReason = AIEndReasonType.RoundEnd
            break
        end
    end

    return AINewNodeStatus.Other + endReason
end
