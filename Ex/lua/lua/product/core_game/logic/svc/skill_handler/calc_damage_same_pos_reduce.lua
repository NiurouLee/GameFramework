--[[
    StampDamage = 17, ---龙之印记伤害
]]
---@class SkillEffectCalcDamageSamePosReduce: Object
_class("SkillEffectCalcDamageSamePosReduce", Object)
SkillEffectCalcDamageSamePosReduce = SkillEffectCalcDamageSamePosReduce

function SkillEffectCalcDamageSamePosReduce:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcDamageSamePosReduce:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamDamageSamePosReduce
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    ---@type Vector2[]
    local range = skillEffectCalcParam.skillRange
    local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
    if #targetIDs == 1 and targetIDs[1] == -1 then
        local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, damageStageIndex)
        return {skillResult}
    end
    local casterID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterID)
    local reduce = skillDamageParam:GetDampPercent()
    local posReduce = {}
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
    local attackPos = casterEntity:GetGridPosition()
    local retResult = {}
    local buffLogicService =self._world:GetService("BuffLogic")
    local finalEffectType = skillDamageParam:GetFinalEffectType()
    for i, pos in ipairs(range) do
        local targetID = self:GetTargetIDByPos(targetIDs,pos)
        if targetID then
            local targetEntity = self._world:GetEntityByID(targetID)
            local targetPos = pos
            local targetPosIndex = Vector2.Pos2Index(pos)
            if not posReduce[targetPosIndex] then
                posReduce[targetPosIndex] =0
            end
            buffLogicService:ChangeSkillFinalParam(
                    casterEntity,
                    SkillEffectType.DamageSamePosReduce,
                    finalEffectType,
                    posReduce[targetPosIndex]
            )
            local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
                    casterEntity,
                    attackPos,
                    targetEntity,
                    targetPos,
                    skillEffectCalcParam.skillID,
                    skillDamageParam,
                    SkillEffectType.DamageSamePosReduce,
                    damageStageIndex
            )

            local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
                    targetPos,
                    targetEntity:GetID(),
                    nTotalDamage,
                    listDamageInfo,
                    damageStageIndex
            )
            buffLogicService:RemoveSkillFinalParam(casterEntity, SkillEffectType.DamageSamePosReduce, finalEffectType)
            posReduce[targetPosIndex] = posReduce[targetPosIndex]-reduce
            table.insert(retResult,skillResult)
        end
    end
    return retResult
end

function SkillEffectCalcDamageSamePosReduce:GetTargetIDByPos(targetIDs,pos)
    for i, targetID in ipairs(targetIDs) do
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)
        local targetPos = targetEntity:GetGridPosition()
        local areCmpt = targetEntity:BodyArea()
        local bodyArea = areCmpt:GetArea()
        for i, v in ipairs(bodyArea) do
            local newPos = v+targetPos
            if newPos.x == pos.x and newPos.y == pos.y then
                return targetID
            end
        end
    end
end