require "ai_node_new"
--[[
    判断本回合是否解除过锁血状态
]]
---@class ActionIsUnlockHPRound : AINewNode
_class("ActionIsUnlockHPRound", AINewNode)
ActionIsUnlockHPRound = ActionIsUnlockHPRound

function ActionIsUnlockHPRound:Constructor()
end

function ActionIsUnlockHPRound:OnUpdate(dt)
    local battleStatCmpt = self._world:BattleStat()
    local round = battleStatCmpt:GetCurWaveTotalRoundCount()
    ---@type BuffComponent
    local buffCmpt = self.m_entityOwn:BuffComponent()
    local unlockRound = buffCmpt:GetLastUnlockHPRound()

    if round == unlockRound then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
