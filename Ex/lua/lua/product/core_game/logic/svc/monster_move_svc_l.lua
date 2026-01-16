require("base_service")

_class("MonsterMoveServiceLogic", BaseService)
---@class MonsterMoveServiceLogic:BaseService
MonsterMoveServiceLogic = MonsterMoveServiceLogic

function MonsterMoveServiceLogic:Constructor(world)
end

function MonsterMoveServiceLogic:_DoLogicTrapBeforeMonster()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:StartBeforeMainAI()
end

function MonsterMoveServiceLogic:_DoLogicTrapAfterMonster()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionAfterAI()
end

function MonsterMoveServiceLogic:_DoLogicCalcMonsterAction()
    ---@type AIService
    local aiService = self._world:GetService("AI")
    aiService:RunAiLogic_WaitEnd(AILogicPeriodType.Main)
end

