require("base_ins_r")
---@class PlayTargetBeHitAnimationInstruction: BaseInstruction
_class("PlayTargetBeHitAnimationInstruction", BaseInstruction)
PlayTargetBeHitAnimationInstruction = PlayTargetBeHitAnimationInstruction

function PlayTargetBeHitAnimationInstruction:Constructor(paramList)
    self._hitAnimName = paramList["hitAnimName"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetBeHitAnimationInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
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

    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)

    ---最后一击在这里处理
    ---检查是不是最后一个Stage
    local damageResultStageCount = skillEffectResultContainer:GetEffectResultsStageCount(SkillEffectType.Damage)
    if
        skillEffectResultContainer:IsFinalAttack() and curDamageIndex == #damageResultArray and
            curDamageResultStageIndex == damageResultStageCount
     then
        playSkillService:FreezeFrame(targetEntity)
    end

    if not targetEntity then
        Log.fatal("TargetEntity is nil  SkillID:", skillID, "TargetID:", targetEntityID)
        return
    end

    local guard = damageInfo:GetDamageType() == DamageType.Guard
    local miss = damageInfo:GetDamageType() == DamageType.Miss
    if not guard and not miss and self._hitAnimName and not damageInfo:IsHPShieldGuard() then
        targetEntity:SetAnimatorControllerTriggers({self._hitAnimName})
    end

    ---处理受击及击退效果
    ---@type SkillHitBackEffectResult
    local result = skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.HitBack, targetEntity:GetID())
    local processHitTaskID = nil
    if result then
        local hitbackCalcType = result:GetCalcType()
        if hitbackCalcType and hitbackCalcType == HitBackCalcType.Instant then
            processHitTaskID = playSkillService:ProcessHit(casterEntity, targetEntity, result, 10) --10默认击退速度
        end
    end

    if processHitTaskID ~= nil then
        phaseContext:AddPhaseTask(processHitTaskID)
    end

    -- --buff通知
    -- local pos = targetEntity:GridLocation():GetGridPos()
    local scopeResult = damageResult:GetSkillEffectScopeResult()
    -- local attackPos = scopeResult:GetCenterPos()
    local attackPos = casterEntity:GetRenderGridPosition()
    local beAttackPos = damageResult:GetGridPos()

    ---@type PlayBuffService
    local playBuffSvc = world:GetService("PlayBuff")
    playBuffSvc:_OnAttackEnd(TT, skillID, casterEntity, targetEntity, attackPos, beAttackPos,damageInfo)

    playSkillService:PlayHitTrap(TT, casterEntity, targetEntity)
end
