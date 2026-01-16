--[[-------------------------------------
移动到Data里配置的技能目标最多的位置
--]] -------------------------------------
require "action_move_base"
---@class ActionMoveSkillTargetCountMost:ActionMoveBase
_class("ActionMoveSkillTargetCountMost", ActionMoveBase)
ActionMoveSkillTargetCountMost = ActionMoveSkillTargetCountMost

--------------------------------
function ActionMoveSkillTargetCountMost:Constructor()
    self:_Reset()

    self._targetPosAndRound = {} --每个回合计算一次坐标
end
function ActionMoveSkillTargetCountMost:Reset()
    ActionMoveSkillTargetCountMost.super.Reset(self)
    self:_Reset()
end
function ActionMoveSkillTargetCountMost:_Reset()
    self._targetPos = nil
end

function ActionMoveSkillTargetCountMost:InitTargetPosList(listPosTarget)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local levelTotalRoundCount = battleStatCmpt:GetLevelTotalRoundCount()
    local targetPos = self._targetPosAndRound[levelTotalRoundCount]
    if targetPos then
        self._targetPos = targetPos
        return
    end

    --第二次要取第一只的
    local monsterClassID = self.m_entityOwn:MonsterID():GetMonsterClassID()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        if not monsterEntity:HasDeadMark() then
            local targetMonsterClassID = monsterEntity:MonsterID():GetMonsterClassID()
            if targetMonsterClassID == monsterClassID then
                ---@type BuffComponent
                local buffCmpt = monsterEntity:BuffComponent()
                local targetPosAndRound = buffCmpt:GetBuffValue("ActionMoveSkillTargetCountMost") or {}
                local targetPos = targetPosAndRound[levelTotalRoundCount]
                if targetPos then
                    self._targetPos = targetPos

                    self._targetPosAndRound[levelTotalRoundCount] = self._targetPos
                    return
                end
            end
        end
    end

    --获取技能ID
    local skillID = self:GetLogicData(-1)
    if skillID == 0 then
        return
    end

    ---@type Vector2
    local posSelf = self.m_entityOwn:GetGridPosition()

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local remainMobility = aiCmpt:GetMobilityValid()
    if remainMobility <= 0 then
        self._targetPos = posSelf
        return
    end

    --在行动力可以移动的范围内找点还不够 如果目标在行动力范围外 怪物就不会走了
    -- local targetPosList = self:ComputeWalkRange(posSelf, remainMobility, true)

    --重新计算一下全屏范围可以走的点
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local blockFlag = boardServiceLogic:GetEntityMoveBlockFlag(self.m_entityOwn)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local fullScreenCalc = SkillScopeCalculator_FullScreen:New(skillCalculater)
    ---@type SkillScopeResult
    local scopeResult =
        fullScreenCalc:CalcRange(
        SkillScopeType.FullScreen,
        1, -- bExcludeSelf
        posSelf,
        self.m_entityOwn:BodyArea():GetArea(),
        self.m_entityOwn:GetGridDirection(),
        SkillTargetType.Board,
        posSelf
    )

    local targetPosList = {}
    for _, pos in ipairs(scopeResult:GetAttackRange()) do
        local isBlock = boardServiceLogic:IsPosBlock(pos, blockFlag)
        if not isBlock then
            table.insert(targetPosList, pos)
        end
    end
    if not table.intable(targetPosList, posSelf) then
        table.insert(targetPosList, posSelf)
    end

    local bodyArea = self.m_entityOwn:BodyArea():GetArea()
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local targetSelector = self._world:GetSkillScopeTargetSelector()

    local posAndTargrtCount = {}
    --找出所有可以走的点
    for _, pos in ipairs(targetPosList) do
        ---@type SkillScopeResult
        local skillResult = skillCalculater:CalcSkillScope(skillConfigData, pos, Vector2(0, 1), bodyArea)
        local targetType = skillConfigData:GetSkillTargetType()

        local targetArray = targetSelector:DoSelectSkillTarget(self.m_entityOwn, targetType, skillResult, skillID) or {}
        if targetArray and table.count(targetArray) > 0 then
            table.insert(posAndTargrtCount, {pos = pos, targetCount = table.count(targetArray)})
        end
    end

    if table.count(posAndTargrtCount) == 0 then
        self._targetPos = posSelf
        return
    end

    table.sort(
        posAndTargrtCount,
        function(a, b)
            return a.targetCount > b.targetCount
        end
    )

    local posAndTargrtCountSecend = {}
    if table.count(posAndTargrtCount) > 0 then
        local targetCount = posAndTargrtCount[1].targetCount
        for _, v in ipairs(posAndTargrtCount) do
            if v.targetCount == targetCount then
                table.insert(posAndTargrtCountSecend, v)
            end
        end
    end

    table.sort(
        posAndTargrtCountSecend,
        function(a, b)
            local disA = Vector2.Distance(a.pos, posSelf)
            local disB = Vector2.Distance(b.pos, posSelf)
            return disA < disB
        end
    )

    if table.count(posAndTargrtCountSecend) > 0 then
        self._targetPos = posAndTargrtCountSecend[1].pos
        if table.intable(posAndTargrtCountSecend, posSelf) then
            self._targetPos = posSelf
        end
    end

    self._targetPosAndRound[levelTotalRoundCount] = self._targetPos

    ---@type BuffComponent
    local curBuffCmpt = self.m_entityOwn:BuffComponent()
    curBuffCmpt:SetBuffValue("ActionMoveSkillTargetCountMost", self._targetPosAndRound)
end

function ActionMoveSkillTargetCountMost:FindNewTargetPos()
    return self._targetPos
end
