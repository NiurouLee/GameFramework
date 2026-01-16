--[[-------------------------------------------
    ActionSkipPreviousTurns 跳过前几个回合
--]] -------------------------------------------
require "ai_node_new"
---@class ActionSkipPreviousTurns : AINewNode
_class("ActionSkipPreviousTurns", AINewNode)
ActionSkipPreviousTurns = ActionSkipPreviousTurns

function ActionSkipPreviousTurns:Constructor()
    self._skipTurns = 0 ---配置的跳过回合数
    self._curSkipTurns = 0 ---当前回合
    self._SaveRound = 0
end
function ActionSkipPreviousTurns:InitializeNode(cfg, context, logicOwn, configData)
    ActionSkipPreviousTurns.super.InitializeNode(self, cfg, context)
end

function ActionSkipPreviousTurns:OnBegin()
    ---循环阈值
    self._skipTurns = self:GetLogicData(-1)
    local nGameRound = self:_GetGameRountNow()
    if self._SaveRound ~= nGameRound then
        self._curSkipTurns = self._curSkipTurns + 1
        self._SaveRound = nGameRound
    end
end

function ActionSkipPreviousTurns:OnUpdate()
    if self._curSkipTurns <= self._skipTurns then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end

function ActionSkipPreviousTurns:_GetGameRountNow()
    local boardEntity = self._world:GetBoardEntity()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    local round = battleStatCmpt:GetCurWaveTotalRoundCount()
    return round
end
