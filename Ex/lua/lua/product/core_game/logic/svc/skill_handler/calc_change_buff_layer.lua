--[[
    ChangeBuffLayer = 116, --修改buff层数
]]
---@class SkillEffectCalc_ChangeBuffLayer: Object
_class("SkillEffectCalc_ChangeBuffLayer", Object)
SkillEffectCalc_ChangeBuffLayer = SkillEffectCalc_ChangeBuffLayer

function SkillEffectCalc_ChangeBuffLayer:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ChangeBuffLayer:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    ---@type SkillEffectParamChangeBuffLayer
    local addBuffParam = skillEffectCalcParam.skillEffectParam
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    --1 判断本次计算是否需要判断伤害结果
    local addToNonMissDamageTarget = addBuffParam:CanAddToNonMissDamageTarget()
    --这里有所不同，对敌人是否有造成伤害，决定是否给目标修改buff。
    --伤害结果的目标和技能的目标可能不是同一个，所以不能用技能目标在伤害结果里检索
    if addToNonMissDamageTarget == 1 then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
        local stageIndex = addBuffParam:GetCheckDamageEffectResultWithStageIndex() or 1
        ---@type SkillDamageEffectResult
        local skillResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, stageIndex)

        ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
        if not skillResultArray or table.count(skillResultArray) == 0 then
            return {}
        end
        local targetEntityList = {}
        for _, v in ipairs(skillResultArray) do
            ---@type SkillDamageEffectResult
            local damageResult = v
            local targetEntityID = damageResult:GetTargetID()
            local targetEntity = self._world:GetEntityByID(targetEntityID)

            local hasDamage = true
            local damageInfoArray = damageResult:GetDamageInfoArray()
            --如果对目标造成了miss，则不计算
            if damageInfoArray then
                for _, damageInfo in ipairs(damageInfoArray) do
                    if damageInfo:GetDamageType() == DamageType.Miss then
                        hasDamage = false
                        break
                    end
                end
            end

            --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
            if
                hasDamage and targetEntity and targetEntity:HasMonsterID() and
                    not table.icontains(targetEntityList, targetEntity)
             then
                table.insert(targetEntityList, targetEntity)
            end
        end

        if not targetEntityList or table.count(targetEntityList) == 0 then
            return {}
        end
    end

    --2 判断本次计算是否需要根据点选结果执行
    local needPickUpDir = addBuffParam:IsNeedPickUpDir()
    if needPickUpDir then
        ---@type HitBackDirectionType[]
        local dirList = {}
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            dirList = activeSkillPickUpComponent:GetAllDirection()
        end

        ---未点选方向，则不修改Buff
        if #dirList == 0 then
            return {}
        end
    end

    --3 计算目标
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local buffTargetType = addBuffParam:GetBuffTargetType()
    local buffTargetParam = addBuffParam:GetBuffTargetParam()

    ---这里需要注意！ 这个公用方法并不包含所有的buffTargetType
    ---@type Entity[]
    local es = {}
    if buffTargetType == BuffTargetType.Self then
        es[#es + 1] = casterEntity
    elseif (buffTargetType == BuffTargetType.SkillTarget or buffTargetType == BuffTargetType.SkillTargetSelectBuffByLayer or
        buffTargetType == BuffTargetType.SkillTargetRandomBuff)
    then
        local targets = skillEffectCalcParam:GetTargetEntityIDs()
        for _, id in ipairs(targets) do
            local e = self._world:GetEntityByID(id)
            if e == nil then
                Log.warn("addbuff defender is nil entityid=", id)
            end
            --无敌、魔免不挂buff
            if e and buffLogicService:CheckCanAddBuff(casterEntity, e) then
                es[#es + 1] = e
            end
        end
    else
        es = buffLogicService:CalcBuffTargetEntities(buffTargetType, buffTargetParam, casterEntity)
    end

    --4修改层数
    local buffID = addBuffParam:GetBuffID()
    local buffEffectType = addBuffParam:GetBuffEffectType()
    -- local changeBuffLayerType = addBuffParam:GetChangeBuffLayerType() or BuffTargetType.Count --现在只用了count类型
    local changeBuffLayerParam = addBuffParam:GetChangeBuffLayerParam()
    local unloadZeroLayer = addBuffParam:GetUnloadZeroLayer()

    for i, e in ipairs(es) do
        local defenderBuffComp = e:BuffComponent()
        local targetBuff
        if buffID then
            targetBuff = defenderBuffComp:GetBuffById(buffID)
        end
        if buffEffectType then
            targetBuff = defenderBuffComp:GetSingleBuffByBuffEffect(buffEffectType)
        end

        if targetBuff then
            local targetBuffSeq = targetBuff:BuffSeq()
            local targetEffectType = targetBuff:GetBuffEffectType()
            local beforeLayer = buffLogicService:GetBuffLayer(e, targetEffectType) or 0
            local layer = beforeLayer
            local changeLayer = 0
            local isUnload = false
            --现在只用了count类型
            -- if changeBuffLayerType == ChangeBuffLayerType.Count then
            layer = beforeLayer + changeBuffLayerParam
            changeLayer = layer - beforeLayer
            -- end

            if layer <= 0 then
                layer = 0
                if unloadZeroLayer == 1 then
                    isUnload = true
                end
            end

            --有层数变化才有技能结果，如果是0变0这种不变的，不存结果
            if changeLayer ~= 0 then
                ---@type SkillEffectResultChangeBuffLayer
                local result =
                    SkillEffectResultChangeBuffLayer:New(e:GetID(), targetBuffSeq, targetEffectType, layer, isUnload)
                table.insert(results, result)
            end
        end
    end

    return results
end
