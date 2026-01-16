require "play_skill_phase_base_r"
--@class PlaySkillLRAttackDifferentAnimationPhase: Object
_class("PlaySkillLRAttackDifferentAnimationPhase", PlaySkillPhaseBase)
PlaySkillLRAttackDifferentAnimationPhase = PlaySkillLRAttackDifferentAnimationPhase
--region 左右手不同动作攻击
---@param casterEntity Entity
---@param phaseParam SkillPhaseLRAttackDifferentAnimationParam
function PlaySkillLRAttackDifferentAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    local audioTaskIDArray = self:_PlayLRAttackAudio(phaseParam)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)

    if not damageResultAll then
        return
    end

    local beAttackEntityID = damageResultAll[1]:GetTargetID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(beAttackEntityID)
    if not targetEntity then
        return
    end
    
    --转向目标
    local resvc = self._world:GetService("RenderEntity")
    resvc:AttackTurn(casterEntity, targetEntity)

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --启动攻击者的动画
    local attackAnimName = nil
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local attEffPos = nil

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local frontPos = utilCalcSvc:GetFrontPieces(casterEntity)
    local armBlurEffId = 0
    local blurDelay = 0
    --等待爆点时刻
    local hitPointDelay = phaseParam:GetHitPointDelay()
    --被击者受击特效
    local hitEffectID = phaseParam:GetHitEffectID()
    --等待攻击者整体动画结束
    local overDelay = phaseParam:GetOverDelay()
    if boardServiceRender:IsLeftOrRight(casterEntity, targetEntity) < 0 then
        attackAnimName = phaseParam:GetLAnimationName()
        attEffPos = frontPos[1]
        armBlurEffId = phaseParam:GetLBlurEffectID()
        blurDelay = phaseParam:GetBlurDelay()[1]
        hitPointDelay = phaseParam:GetHitPointDelay()[1]
        hitEffectID = phaseParam:GetHitEffectID()[1]
        overDelay = phaseParam:GetOverDelay()[1]
    else
        attackAnimName = phaseParam:GetRAnimationName()
        attEffPos = frontPos[2]
        armBlurEffId = phaseParam:GetRBlurEffectID()
        blurDelay = phaseParam:GetBlurDelay()[2]
        hitPointDelay = phaseParam:GetHitPointDelay()[2]
        hitEffectID = phaseParam:GetHitEffectID()[2]
        overDelay = phaseParam:GetOverDelay()[2]
    end
    casterEntity:SetAnimatorControllerTriggers({attackAnimName})
    if blurDelay then
        YIELD(TT, blurDelay)
    end
    if armBlurEffId then
        effectService:CreateEffect(armBlurEffId, casterEntity)
    end

    local deltaTimeMS = self._timeService:GetCurrentTimeMs()
    if hitPointDelay > 0 then
        YIELD(TT, hitPointDelay)
    end

    ---目标还在
    if targetEntity ~= nil then
        local hitAnimName = phaseParam:GetHitAnimation()
        local skillID = skillEffectResultContainer:GetSkillID()
        ---调用统一处理被击的逻辑
        ---@type PlaySkillService
        local skillService = self._world:GetService("PlaySkill")
        local taskIDs = {}
        for i = 1, #damageResultAll do
            local damageResult = damageResultAll[i]
            local castDamage = damageResult:GetDamageInfo(1)
            local damagePos = damageResult:GetGridPos()
            local beAttackEntityID = damageResult:GetTargetID()
            local targetEntity = self._world:GetEntityByID(beAttackEntityID)

            ---调用统一处理被击的逻辑
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName(hitAnimName)
                :SetHandleBeHitParam_HitEffectID(hitEffectID)
                :SetHandleBeHitParam_DamageInfo(castDamage)
                :SetHandleBeHitParam_DamagePos(damagePos)
                :SetHandleBeHitParam_HitTurnTarget(TurnToTargetType.None)
                :SetHandleBeHitParam_DeathClear(false)
                :SetHandleBeHitParam_IsFinalHit(false)
                :SetHandleBeHitParam_SkillID(skillID)

            local nTaskID = GameGlobal.TaskManager():CoreGameStartTask(
                skillService.HandleBeHit,
                skillService,
                beHitParam
            )

            if nTaskID > 0 then
                taskIDs[#taskIDs + 1] = nTaskID
            end
        end

        if table.count(taskIDs) > 0 then
            while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
                YIELD(TT)
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(audioTaskIDArray) do
        YIELD(TT)
    end
end

---@param phaseParam SkillPhaseLRAttackDifferentAnimationParam
function PlaySkillLRAttackDifferentAnimationPhase:_PlayLRAttackAudio(phaseParam)
    local audioTaskArray = {}
    local leftAudioID = phaseParam:GetLeftAudioID()
    local leftAudioDelay = phaseParam:GetLeftAudioDelay()
    local rightAudioID = phaseParam:GetRightAudioID()
    local rightAudioDelay = phaseParam:GetRightAudioDelay()

    if leftAudioID ~= nil and leftAudioID > 0 then
        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(self._PlayAttackAudio, self, leftAudioID, leftAudioDelay)
        audioTaskArray[#audioTaskArray + 1] = taskID
    end

    if rightAudioID ~= nil and rightAudioID > 0 then
        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(self._PlayAttackAudio, self, rightAudioID, rightAudioDelay)
        audioTaskArray[#audioTaskArray + 1] = taskID
    end

    return audioTaskArray
end

function PlaySkillLRAttackDifferentAnimationPhase:_PlayAttackAudio(TT, audioID, audioDelay)
    YIELD(TT, audioDelay)
    AudioHelperController.PlayInnerGameSfx(audioID)
end
