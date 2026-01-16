--[[
    精英化怪物：扣除剩余回合
]]

_class("BuffLogicSubSupplementRound", BuffLogicBase)
---@class BuffLogicSubSupplementRound : BuffLogicBase
BuffLogicSubSupplementRound = BuffLogicSubSupplementRound

function BuffLogicSubSupplementRound:Constructor(buffInstance, logicParam)
    self._levelRound = logicParam.levelRound
end

function BuffLogicSubSupplementRound:DoLogic(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SubCurWaveRoundByEffect(self._levelRound)
    return true
end
