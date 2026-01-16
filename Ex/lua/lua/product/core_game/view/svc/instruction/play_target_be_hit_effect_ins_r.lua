require("base_ins_r")
---@class PlayTargetBeHitEffectInstruction: BaseInstruction
_class("PlayTargetBeHitEffectInstruction", BaseInstruction)
PlayTargetBeHitEffectInstruction = PlayTargetBeHitEffectInstruction

function PlayTargetBeHitEffectInstruction:Constructor(paramList)
    self._hitEffectID = tonumber(paramList["hitEffectID"])

    self._randomDir = paramList.randomDir ~= nil
    self._randomMin = tonumber(paramList.randomMin)
    self._randomMax = tonumber(paramList.randomMax)

    self._targetHitOffsetMin = tonumber(paramList.targetHitOffsetMin) or 0   --目标偏移坐标
    self._targetHitOffsetMax = tonumber(paramList.targetHitOffsetMax)   --目标偏移坐标
end

function PlayTargetBeHitEffectInstruction:GetCacheResource()
    local t = {}
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._hitEffectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetBeHitEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self._randomDir then
        if not phaseContext.__PlayTargetBeHitEffect_RandTime then
            phaseContext.__PlayTargetBeHitEffect_RandTime = 0
        end
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")
    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)

    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()

    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)

    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[curDamageIndex]
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
    if not damageInfo then
        Log.fatal(
            "### PlayTargetBeHitAnimation DamageInfo is nil. curDamageIndex, curDamageInfoIndex=",
            curDamageIndex,
            curDamageInfoIndex
        )
        return
    end
    local damageGridPos = damageResult:GetGridPos()
    local guard = damageInfo:GetDamageType() == DamageType.Guard

    local damageShowType = playDamageService:SingleOrGrid(skillID)
    -- if guard then
    --     -- effectService:CreateEffect(BattleConst.ShieldHitEffect, targetEntity)
    -- elseif self._hitEffectID and self._hitEffectID > 0 then
    if self._hitEffectID and self._hitEffectID > 0 then
        local beHitEffectEntity =
            effectService:CreateBeHitEffect(self._hitEffectID, targetEntity, damageShowType, damageGridPos)
        if beHitEffectEntity ~= nil then
            ---@type EffectControllerComponent
            local effectCtrl = beHitEffectEntity:EffectController()
            if effectCtrl ~= nil and casterEntity ~= nil then
                effectCtrl:SetEffectCasterID(casterEntity:GetID())
            end

            if self._randomDir then
                effectCtrl:SetNoResetRotationOnCreated(true)

                local rand = math.random(self._randomMin, self._randomMax)
                local v3 = Vector3.up * rand * phaseContext.__PlayTargetBeHitEffect_RandTime
                ---@type UnityEngine.Transform
                local trans = beHitEffectEntity:View():GetGameObject().transform
                trans.rotation = Quaternion.identity
                trans:Rotate(v3)

                phaseContext.__PlayTargetBeHitEffect_RandTime = phaseContext.__PlayTargetBeHitEffect_RandTime + 1
            end

            if self._targetHitOffsetMax then
                local targetHitOffset = math.random(self._targetHitOffsetMin * 1000, self._targetHitOffsetMax * 1000) / 1000

                ---@type PlaySkillService
                local playSkillService = world:GetService("PlaySkill")
                local targetBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(targetEntity, "Hit")
                local targetPos = targetBoneTransform.position + (UnityEngine.Random.onUnitSphere * targetHitOffset)

                beHitEffectEntity:SetPosition(targetPos)
            end
        end
    end
end
