--[[
    DamageCanRepeat = 121, --普通伤害,目标可以重复
]]
require("calc_base")

_class("SkillEffectCalc_DamageCanRepeat", SkillEffectCalc_Damage)
---@class SkillEffectCalc_DamageCanRepeat: SkillEffectCalc_Damage
SkillEffectCalc_DamageCanRepeat = SkillEffectCalc_DamageCanRepeat

function SkillEffectCalc_DamageCanRepeat:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageCanRepeat:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local skillID = skillEffectCalcParam.skillID
    return self:CalculateEffect(casterEntity, skillEffectCalcParam.skillEffectParam, skillID)
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageCanRepeat:CalculateEffect(casterEntity,skillEffectCalcParam,skillID)
    local results = {}

    ---@type SkillEffectResultContainer
    local skillResult = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillResult:GetScopeResult()
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = self._configService:GetSkillConfigData(skillID, casterEntity)
    local targetType = skillConfigData:GetSkillTargetType()
    ---@type BuffLogicService
    self._buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type SkillDamageCanRepeatEffectParam
    self._effectParam = skillEffectCalcParam
    self._dampMap = {}
    ---先选技能目标
    local targetEntityIDArray =
    self._world:GetSkillScopeTargetSelector():DoSelectSkillTarget(casterEntity, targetType, scopeResult, skillID)
    local skillRange = scopeResult:GetAttackRange()
    local wholeRange = scopeResult:GetWholeGridRange()
    local scopeCenter = scopeResult:GetCenterPos()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    for _, targetGridPos in ipairs(skillRange) do
        if targetGridPos._className == 'Vector2' then
            self:_CalcDamageResult(targetEntityIDArray,targetGridPos,casterEntity,
                    skillEffectCalcParam,skillID,skillRange,
                    scopeCenter,wholeRange,results,skillEffectResultContainer)
        else
            for i, pos in ipairs(targetGridPos) do
                self:_CalcDamageResult(targetEntityIDArray,pos,casterEntity,
                        skillEffectCalcParam,skillID,skillRange,
                        scopeCenter,wholeRange,results,skillEffectResultContainer)
            end
        end

    end
    return results
end

function SkillEffectCalc_DamageCanRepeat:_CalcDamageResult(
        targetEntityIDArray,pos,casterEntity,
        skillEffectCalcParam,skillID,skillRange,
        scopeCenter,wholeRange,results,skillEffectResultContainer)


    local targetID = self:GetTargetIDByPos(targetEntityIDArray,pos)
    if targetID then
        local calcParam =SkillEffectCalcParam:New(
                casterEntity:GetID(),
                {targetID},
                skillEffectCalcParam,
                skillID,
                skillRange,
                casterEntity:GridLocation():GetGridPos(),
                pos,
                scopeCenter,
                wholeRange
        )
        local dampPer =self._effectParam:GetDampPer()
        local dampPerMax = self._effectParam:GetDampMax()
        local finalEffectType = self._effectParam:GetFinalEffectType()
        if finalEffectType then
            if not self._dampMap[targetID] then
                self._dampMap[targetID] = 0
            else
                self._dampMap[targetID] =self._dampMap[targetID] + dampPer
            end
            if self._dampMap[targetID] < dampPerMax then
                self._dampMap[targetID] = dampPerMax
            end
            self._buffLogicSvc:ChangeSkillFinalParam(
                    casterEntity,
                    SkillEffectType.DamageCanRepeat,
                    finalEffectType,
                    self._dampMap[targetID]
            )
        end
        local result = self:_CalculateSingleTarget(calcParam, targetID)
        if finalEffectType then
            self._buffLogicSvc:RemoveSkillFinalParam(casterEntity, SkillEffectType.DamageCanRepeat, finalEffectType)
        end
        if result and result[1] then
            table.appendArray(results, result)
            skillEffectResultContainer:AddEffectResult(result[1])
        end
    end
end

function SkillEffectCalc_DamageCanRepeat:GetTargetIDByPos(targetIDList,pos)
    for i, targetID in ipairs(targetIDList) do
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)
        ---@type Vector2
        local targetPos = targetEntity:GetGridPosition()
        local bodyAreaComponent = targetEntity:BodyArea()
        if bodyAreaComponent then
            local bodyAreaArray = bodyAreaComponent:GetArea()
            for _, areaPos in ipairs(bodyAreaArray) do
                local gridPos = areaPos + targetPos
                if gridPos.x == pos.x and gridPos.y == pos.y then
                    return targetID
                end
            end
        else
            if targetPos.x == pos.x and targetPos.y == pos.y then
                return targetID
            end
        end
    end
    return nil
end