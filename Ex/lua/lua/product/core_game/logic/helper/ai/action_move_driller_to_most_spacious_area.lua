--[[-------------------------------------
N29 Boss 钻探者 专属 移动到最空旷区域
--]] -------------------------------------
require "action_move_base"
---@class ActionMoveDrillerToMostSpaciousArea:ActionMoveBase
_class("ActionMoveDrillerToMostSpaciousArea", ActionMoveBase)
ActionMoveDrillerToMostSpaciousArea = ActionMoveDrillerToMostSpaciousArea
function ActionMoveDrillerToMostSpaciousArea:Constructor()
    self:_Reset()

    self._targetPosAndRound = {} --每个回合计算一次坐标
end
function ActionMoveDrillerToMostSpaciousArea:Reset()
    ActionMoveSkillTargetCountMost.super.Reset(self)
    self:_Reset()
end
function ActionMoveDrillerToMostSpaciousArea:_Reset()
    self._targetPos = nil
end
--------------------------------
---@param listPosTarget Vector2[]
function ActionMoveDrillerToMostSpaciousArea:InitTargetPosList(listPosTarget)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local levelTotalRoundCount = battleStatCmpt:GetLevelTotalRoundCount()
    local targetPos = self._targetPosAndRound[levelTotalRoundCount]
    if targetPos then
        self._targetPos = targetPos
        return
    end
    local trapID1 = self:GetLogicData(-1)
    local trapID2 = self:GetLogicData(-2)
    local tarTrapIDList = {}
    if trapID1 then
        table.insert(tarTrapIDList,trapID1)
    end
    if trapID2 then
        table.insert(tarTrapIDList,trapID2)
    end
    ---@type Vector2
    local posSelf = self.m_entityOwn:GetGridPosition()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local blockFlag = boardServiceLogic:GetEntityMoveBlockFlag(self.m_entityOwn)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeCalculator_DrillerMoveTargetPos
    local scopeCalc = SkillScopeCalculator_DrillerMoveTargetPos:New(skillCalculater)
    ---@type SkillScopeResult
    local scopeResult =
        scopeCalc:CalcRange(
            SkillScopeType.DrillerMoveTargetPos,
            {trapIDList = tarTrapIDList},
            posSelf,
            self.m_entityOwn:BodyArea():GetArea(),
            self.m_entityOwn:GetGridDirection(),
            SkillTargetType.Board,
            posSelf,
            self.m_entityOwn
        )
    local tarPos = posSelf
    local range = scopeResult:GetAttackRange()
    if range and #range > 0 then
        tarPos = range[1]
    end
    self._targetPos = tarPos
    self._targetPosAndRound[levelTotalRoundCount] = self._targetPos
    --return tarPos
end
function ActionMoveDrillerToMostSpaciousArea:FindNewTargetPos()
    return self._targetPos
end
-- function ActionMoveDrillerToMostSpaciousArea:FindNewTargetPos()
--     local trapID1 = self:GetLogicData(-1)
--     local trapID2 = self:GetLogicData(-2)
--     local tarTrapIDList = {}
--     if trapID1 then
--         table.insert(tarTrapIDList,trapID1)
--     end
--     if trapID2 then
--         table.insert(tarTrapIDList,trapID2)
--     end
--     ---@type Vector2
--     local posSelf = self.m_entityOwn:GetGridPosition()
--     ---@type BoardServiceLogic
--     local boardServiceLogic = self._world:GetService("BoardLogic")
--     local blockFlag = boardServiceLogic:GetEntityMoveBlockFlag(self.m_entityOwn)
--     ---@type UtilScopeCalcServiceShare
--     local utilScopeSvc = self._world:GetService("UtilScopeCalc")
--     local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
--     ---@type SkillScopeCalculator_DrillerMoveTargetPos
--     local scopeCalc = SkillScopeCalculator_DrillerMoveTargetPos:New(skillCalculater)
--     ---@type SkillScopeResult
--     local scopeResult =
--         scopeCalc:CalcRange(
--             SkillScopeType.DrillerMoveTargetPos,
--             {trapIDList = tarTrapIDList},
--             posSelf,
--             self.m_entityOwn:BodyArea():GetArea(),
--             self.m_entityOwn:GetGridDirection(),
--             SkillTargetType.Board,
--             posSelf,
--             self.m_entityOwn
--         )
--     local tarPos = posSelf
--     local range = scopeResult:GetAttackRange()
--     if range and #range > 0 then
--         tarPos = range[1]
--     end
--     return tarPos
-- end
