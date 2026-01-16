--[[
    修改关卡回合
]]
_class("BuffLogicLevelSupplementRound", BuffLogicBase)
---@class BuffLogicLevelSupplementRound:BuffLogicBase
BuffLogicLevelSupplementRound = BuffLogicLevelSupplementRound

function BuffLogicLevelSupplementRound:Constructor(buffInstance, logicParam)
    self._levelRound = logicParam.levelRound
end

function BuffLogicLevelSupplementRound:DoLogic(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetLevelSupplementRoundCount(self._levelRound)
    return true
end
