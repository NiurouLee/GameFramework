--[[
    EachTrapAddBlood = 141, --根据范围内机关数量治疗回血
]]
---@class SkillEffectCalc_EachTrapAddBlood: Object
_class("SkillEffectCalc_EachTrapAddBlood", Object)
SkillEffectCalc_EachTrapAddBlood = SkillEffectCalc_EachTrapAddBlood

function SkillEffectCalc_EachTrapAddBlood:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EachTrapAddBlood:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EachTrapAddBlood:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local entityDefender = self._world:GetEntityByID(defenderEntityID)
    if entityDefender == nil then
        Log.fatal("CalculationForeachTarget defender is null ", defenderEntityID)
        return
    end
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local posTarget = entityDefender:GridLocation():GetGridPos()
    local skillResult =
        SkillEffectResultEachTrapAddBlood:New()

    --禁疗buff
    if entityDefender:HasPetPstID() or entityDefender:HasTeam() then
        local teamEntity = entityDefender
        if entityDefender:HasPet() then
            teamEntity = entityDefender:Pet():GetOwnerTeamEntity()
        end
        if teamEntity:Attributes():GetAttribute("BuffForbidCure") then
            skillResult:SetAddData(defenderEntityID, 0)
            return skillResult
        end
    end

    ---@type SkillEffectParamEachTrapAddBlood
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local tarTrapId = skillEffectParam:GetTrapId()
    --计算目标方块的数量
    --获取攻击范围
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    --local scopeResult = skillEffectResultContainer:GetScopeResult()
    --机关个数
    local trapCount = 0
    --if scopeResult then
        --local array = scopeResult:GetAttackRange()
        local array = skillEffectCalcParam.skillRange
        if array then
            for _, pos in ipairs(array) do
                local traps = utilSvc:GetTrapsAtPos(pos)
                if traps and #traps > 0 then
                    for __, trap in ipairs(traps) do
                        if trap:Trap():GetTrapID() == tarTrapId then
                            trapCount = trapCount + 1
                        end
                    end
                end
            end
        end
    --end
    --计算加的血量
    local nAddData = 0
    local addParam = casterEntity:Attributes():CalcMaxHp()--默认是施法者光灵的总血量
    local oneTrapAddValue = skillEffectParam:GetOneTrapAddValue()
    local baseAddValue = skillEffectParam:GetBaseAddValue()
    if trapCount == 0 then--有机关才有回血
        baseAddValue = 0
    end
    nAddData = nAddData + addParam * (baseAddValue + (oneTrapAddValue * trapCount))
    ---end---

    --回血加成系数
    local rate = entityDefender:Attributes():GetAttribute("AddBloodRate") or 0
    nAddData = nAddData * (1 + rate)
    nAddData = math.floor(nAddData)

    local logger = self._world:GetMatchLogger()
    logger:AddBloodLog(
        casterEntity:GetID(),
        {
            key = "CalcAddBlood",
            desc = "技能加血 攻击者[attacker] 被击者[defender] 加血量[blood]=(血量上限[MaxHP]*(基础加血量[damagePercent]+(每个机关加血量[skillIncreaseParam]*机关数[trapCount])))*(1+回血系数[rate])",
            attacker = casterEntity:GetID(),
            defender = defenderEntityID,
            MaxHP = addParam,
            blood = nAddData,
            skillIncreaseParam = oneTrapAddValue,
            trapCount = trapCount,
            rate = rate,
            damagePercent = baseAddValue
        }
    )
    skillResult:SetAddData(defenderEntityID, nAddData)
    return skillResult
end
