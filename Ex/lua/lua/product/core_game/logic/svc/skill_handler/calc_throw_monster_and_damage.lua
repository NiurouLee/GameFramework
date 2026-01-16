--[[
    ThrowMonsterAndDamage = 195, --N26Boss：主动技2，收集困字小怪并将困字小怪扔向玩家造成伤害贝塔进行攻击并击退或击晕光灵
]]
---@class SkillEffectCalc_ThrowMonsterAndDamage: Object
_class("SkillEffectCalc_ThrowMonsterAndDamage", Object)
SkillEffectCalc_ThrowMonsterAndDamage = SkillEffectCalc_ThrowMonsterAndDamage

function SkillEffectCalc_ThrowMonsterAndDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ThrowMonsterAndDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    --召集怪物
    local monsterEntityIDs = self:GatherMonsterEntityIDs(skillEffectCalcParam)
    if #monsterEntityIDs == 0 then
        return
    end

    --伤害计算
    local damageRes = self:CalculateDamageResult(skillEffectCalcParam, monsterEntityIDs)


    local result = SkillEffectThrowMonsterAndDamageResult:New(monsterEntityIDs, damageRes)
    return { result }
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ThrowMonsterAndDamage:GatherMonsterEntityIDs(skillEffectCalcParam)
    ---@type SkillEffectThrowMonsterAndDamageParam
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()
    local monsterClassID = effectParam:GetMonsterClassID()

    --检测怪物，存在的话，放入返回列表
    local monsterEntityIDs = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        ---@type MonsterIDComponent
        local monsterIDCmpt = monsterEntity:MonsterID()
        if monsterIDCmpt and
            monsterClassID == monsterIDCmpt:GetMonsterClassID() and
            not monsterEntity:HasDeadMark()
        then
            table.insert(monsterEntityIDs, monsterEntity:GetID())
        end
    end

    return monsterEntityIDs
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param monsterEntityIDs number[]
---@return SkillDamageEffectResult
function SkillEffectCalc_ThrowMonsterAndDamage:CalculateDamageResult(skillEffectCalcParam, monsterEntityIDs)
    if #monsterEntityIDs == 0 then
        return nil
    end

    ---@type SkillEffectThrowMonsterAndDamageParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local basePercent = param:GetBasePercent()
    local addPercent = param:GetAddPercent()
    local curFormulaID = param:GetFormulaID()
    if curFormulaID == nil then
        curFormulaID = 2
    end

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local casterPos = casterEntity:GetGridPosition()
    ---@type Entity
    local defenderEntity = self._world:Player():GetLocalTeamEntity()
    local defenderPos = defenderEntity:GetGridPosition()

    --攻击次数
    local attackCount = #monsterEntityIDs
    local percentList = { basePercent + addPercent * attackCount }
    local skillDamageParam = SkillDamageEffectParam:New(
        {
            percent = percentList,
            formulaID = curFormulaID,
            damageStageIndex = 1
        }
    )

    local nTotalDamage, listDamageInfo = self._skillEffectService:ComputeSkillDamage(
        casterEntity,
        casterPos,
        defenderEntity,
        defenderPos,
        skillEffectCalcParam:GetSkillID(),
        skillDamageParam,
        SkillEffectType.ThrowMonsterAndDamage,
        1
    )

    local damageRes = self._skillEffectService:NewSkillDamageEffectResult(
        defenderPos,
        defenderEntity:GetID(),
        nTotalDamage,
        listDamageInfo
    )
    return damageRes
end
