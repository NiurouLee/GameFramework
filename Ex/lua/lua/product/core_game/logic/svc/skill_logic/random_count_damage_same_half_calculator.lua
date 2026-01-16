--[[
    RandomCountDamageSameHalf = 173, ---对目标造成随机数量的伤害,重复打击的敌人伤害逐次减半,和89的区别是，89是连锁技在用，是把所有目标统一传进去计算。如果89放到主动技，会造成有几个目标就算几次效果
]]
---@class RandomCountDamageSameHalfCalculator: Object
_class("RandomCountDamageSameHalfCalculator", Object)
RandomCountDamageSameHalfCalculator = RandomCountDamageSameHalfCalculator

function RandomCountDamageSameHalfCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param casterEntity Entity
---@param skillEffectCalcParam SkillEffectParamRandomCountDamageSameHalf
---@param finalScopeFilterParam SkillScopeFilterParam
---@return table
function RandomCountDamageSameHalfCalculator:Calculate(casterEntity, skillEffectCalcParam, finalScopeFilterParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()

    local targetIDs = scopeResult:GetTargetIDs()

    if not targetIDs or table.count(targetIDs) == 0 then
        return
    end

    local results = {}
    local damageDampList = {}
    local percents = skillEffectCalcParam:GetDamagePercent()
    local damageFormulaID = skillEffectCalcParam:GetDamageFormulaID()

    ---每次重复攻击衰减百分比
    local dampPer = skillEffectCalcParam:GetDampPercent()
    local percentAddParam = skillEffectCalcParam:GetPercentAdd()
    local isSelTargetLoop = skillEffectCalcParam:GetIsSelTargetLoop()
    --是否循环选敌 默认是随机
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    ---@type CalcDamageService
    local svcCalcDamage = self._world:GetService("CalcDamage")
    local curDamageIndex = 1
    local lastIndex = 0

    --如果是配置随机攻击次数，从配置的2个参数区间中随机作为攻击次数
    local damageRandomCount = skillEffectCalcParam:GetDamageRandomCount()
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local damageCount = randomSvc:LogicRand(damageRandomCount[1], damageRandomCount[2])

    while #results < damageCount do
        local index
        if isSelTargetLoop then
            index = lastIndex + 1
            if index > #targetIDs then
                index = 1
            end
            lastIndex = index
        else
            index = randomSvc:LogicRand(1, #targetIDs)
        end
        local targetID = targetIDs[index]
        if not damageDampList[targetID] then
            damageDampList[targetID] = 1
        end
        local multiDamageInfo = {}
        local totalDamage = 0
        ---@type Entity
        local target = self._world:GetEntityByID(targetID)
        local targetPos = target:GridLocation():GetGridPos()
        for _, percent in ipairs(percents) do
            self._skillEffectService:NotifyDamageBegin(
                casterEntity,
                target,
                casterEntity:GetGridPosition(),
                targetPos,
                skillID,
                nil,
                nil,
                curDamageIndex
            )
            ---@type DamageInfo
            local damageInfo =
                svcCalcDamage:DoCalcDamage(
                casterEntity,
                target,
                {
                    percent = (percent + percentAddParam) * damageDampList[targetID],
                    skillID = skillID,
                    formulaID = damageFormulaID,
                    critProb = skillEffectCalcParam.critProb,
                    crit = skillEffectCalcParam.crit
                }
            )
            damageInfo:SetRandHalfDamageIndex(curDamageIndex)
            curDamageIndex = curDamageIndex + 1
            ---下次再被打要衰减
            damageDampList[targetID] = damageDampList[targetID] * dampPer
            totalDamage = totalDamage + damageInfo:GetDamageValue()
            table.insert(multiDamageInfo, damageInfo)
            self._skillEffectService:NotifyDamageEnd(
                casterEntity,
                target,
                casterEntity:GetGridPosition(),
                targetPos,
                skillID,
                damageInfo
            )
        end

        local skillResult = SkillDamageEffectResult:New(targetPos, targetID, totalDamage, multiDamageInfo)
        results[#results + 1] = skillResult
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    for _, v in ipairs(results) do
        skillEffectResultContainer:AddEffectResult(v)
    end
    return results
end
