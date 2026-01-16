require "ai_node_new"
---@class ActionCanMove2Player:AINewNode
_class("ActionCanMove2Player", AINewNode)
ActionCanMove2Player = ActionCanMove2Player

function ActionCanMove2Player:Constructor()
    self._lastRunRound = 0
end


function ActionCanMove2Player:OnUpdate(dt)
    ---@type BattleStatComponent
    local battleCmpt = self._world:BattleStat()
    local curRound = battleCmpt:GetLevelTotalRoundCount()
    if  curRound == self._lastRunRound then
        return AINewNodeStatus.Failure
    end
    local enableAnyPiece = self:GetLogicData(-1) or 0
    self._lastRunRound = curRound
    local entity = self.m_entityOwn
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local movePath,pieceType = utilCalcSvc:GetMonsterMove2PlayerNearestPath(entity,enableAnyPiece==1)
    if pieceType then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
