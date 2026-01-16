require("calc_base")

_class("SkillEffectCalc_CoffinMusumeCandle", SkillEffectCalc_Base)
---@class SkillEffectCalc_CoffinMusumeCandle: SkillEffectCalc_Base
SkillEffectCalc_CoffinMusumeCandle = SkillEffectCalc_CoffinMusumeCandle

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_CoffinMusumeCandle:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_CoffinMusumeCandle
    local sep = skillEffectCalcParam.skillEffectParam
    local trapID = sep:GetTrapID()

    local lightsOff = {}
    local lightCount = 0
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(globalTrapEntities) do
        if (not e:HasBuff()) or (e:Trap():GetTrapID() ~= trapID) then
            goto CONTINUE
        end

        if e:BuffComponent():GetBuffValue(BattleConst.CandleLightKey) == 1 then
            lightCount = lightCount + 1
        else
            table.insert(lightsOff, e)
        end

        ::CONTINUE::
    end

    local stage1Count = sep:GetStage1Count()
    local stage1Param = sep:GetStage1Param()

    local stage2Count = sep:GetStage2Count()
    local stage2Param = sep:GetStage2Param()

    local stage3Param = sep:GetStage3Param()

    local selectedLights = {}
    ---@type SkillEffectResult_AddBlood|nil
    local addHPResult -- what the **** is "add blood"
    ---@type SkillDamageEffectResult
    local damageResult
    ---@type SkillDamageEffectParam
    local damageParam
    if lightCount <= stage1Count then
        ---1档效果：点亮指定数量的灯
        local max = math.min(#lightsOff, stage1Param)
        ---@type RandomServiceLogic
        local randsvc = self._world:GetService("RandomLogic")
        for i = 1, max do
            local rand = randsvc:LogicRand(1, #lightsOff)
            local eLuckyTrap = table.remove(lightsOff, rand)
            table.insert(selectedLights, eLuckyTrap:GetID())
        end

        damageParam = sep:GetStage1DamageParam()
        if damageParam then
            local playerTeamEntity = self._world:Player():GetLocalTeamEntity()
            ---@type SkillEffectCalc_Damage
            local damageCalc = SkillEffectCalc_Damage:New(self._world)
            local damageCalcParam = SkillEffectCalcParam:New(
                    skillEffectCalcParam:GetCasterEntityID(),
                    {playerTeamEntity:GetID()},
                    damageParam,
                    skillEffectCalcParam:GetSkillID(),
                    skillEffectCalcParam:GetSkillRange(),
                    skillEffectCalcParam:GetAttackPos(),
                    skillEffectCalcParam:GetGridPos(),
                    skillEffectCalcParam:GetCenterPos(),
                    skillEffectCalcParam:GetWholeRange()
            )
            local tDamageResults = damageCalc:DoSkillEffectCalculator(damageCalcParam)
            damageResult = tDamageResults[1]
        end
    elseif lightCount <= stage2Count then
        ---2档效果：点亮指定数量的灯（注释没错）
        local max = math.min(#lightsOff, stage2Param)
        ---@type RandomServiceLogic
        local randsvc = self._world:GetService("RandomLogic")
        for i = 1, max do
            local rand = randsvc:LogicRand(1, #lightsOff)
            local eLuckyTrap = table.remove(lightsOff, rand)
            table.insert(selectedLights, eLuckyTrap:GetID())
        end

        damageParam = sep:GetStage2DamageParam()
        if damageParam then
            local playerTeamEntity = self._world:Player():GetLocalTeamEntity()
            ---@type SkillEffectCalc_Damage
            local damageCalc = SkillEffectCalc_Damage:New(self._world)
            local damageCalcParam = SkillEffectCalcParam:New(
                    skillEffectCalcParam:GetCasterEntityID(),
                    {playerTeamEntity:GetID()},
                    damageParam,
                    skillEffectCalcParam:GetSkillID(),
                    skillEffectCalcParam:GetSkillRange(),
                    skillEffectCalcParam:GetAttackPos(),
                    skillEffectCalcParam:GetGridPos(),
                    skillEffectCalcParam:GetCenterPos(),
                    skillEffectCalcParam:GetWholeRange()
            )
            local tDamageResults = damageCalc:DoSkillEffectCalculator(damageCalcParam)
            damageResult = tDamageResults[1]
        end
    else
        damageParam = sep:GetStage3DamageParam()
        if damageParam then
            local playerTeamEntity = self._world:Player():GetLocalTeamEntity()
            ---@type SkillEffectCalc_Damage
            local damageCalc = SkillEffectCalc_Damage:New(self._world)
            local damageCalcParam = SkillEffectCalcParam:New(
                    skillEffectCalcParam:GetCasterEntityID(),
                    {playerTeamEntity:GetID()},
                    damageParam,
                    skillEffectCalcParam:GetSkillID(),
                    skillEffectCalcParam:GetSkillRange(),
                    skillEffectCalcParam:GetAttackPos(),
                    skillEffectCalcParam:GetGridPos(),
                    skillEffectCalcParam:GetCenterPos(),
                    skillEffectCalcParam:GetWholeRange()
            )
            local tDamageResults = damageCalc:DoSkillEffectCalculator(damageCalcParam)
            damageResult = tDamageResults[1]
        else
            ---3档效果：按最大生命值百分比恢复生命值
            local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
            addHPResult = SkillEffectResult_AddBlood:New(
                    AddBlood_Type.Percent, stage3Param,
                    casterEntity:GetGridPosition(),
                    skillEffectCalcParam.skillEffectParam:GetSkillEffectDamageStageIndex()
            )
            ---@type AttributesComponent
            local cAttributes = casterEntity:Attributes()
            local maxHP = cAttributes:CalcMaxHp()
            local val = math.floor(maxHP * stage3Param)
            addHPResult:SetAddData(skillEffectCalcParam.casterEntityID, val)

            local logger = self._world:GetMatchLogger()
            logger:AddBloodLog(casterEntity:GetID(),{
                key = "CalcAddBlood",
                desc = "棺材娘专属【CoffinMusumeCandle】技能加血 受益者[attacker] 最大生命值[maxHP] * 系数[stage3Param] = 增加值[val] => 取整[floorVal]",
                attacker = skillEffectCalcParam.casterEntityID,
                maxHP = maxHP,
                stage3Param = stage3Param,
                val = maxHP * stage3Param,
                floorVal = val
            })
        end
    end

    return { SkillEffectResult_CoffinMusumeCandle:New(selectedLights, addHPResult, damageResult, damageParam)}
end
