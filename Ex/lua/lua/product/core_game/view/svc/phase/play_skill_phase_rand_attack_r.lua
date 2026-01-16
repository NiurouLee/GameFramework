--[[------------------------------------------------------------------------------------------
    2020-02-19 韩玉信添加
    PlaySkillPhase_RandAttack : 随机打击
]] --------------------------------------------------------------------------------------------
require "play_skill_phase_base_r"

---@class PlaySkillPhase_RandAttack: PlaySkillPhaseBase
_class("PlaySkillPhase_RandAttack", PlaySkillPhaseBase)
PlaySkillPhase_RandAttack = PlaySkillPhase_RandAttack

function PlaySkillPhase_RandAttack:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParam_RandAttack
    local param = phaseParam
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_RandAttack
    local results = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RandAttack)
    ---@type BuffViewComponent
    local buffView = casterEntity:BuffView()
    local soulCount = buffView:GetBuffValue("SoulCount") or 0

    if soulCount > 0 and results:GetListAliveCount() > 0 then
        self:_DelayTime(TT, param:GetTargetWaitTime())
        local isFinalHit = skillEffectResultContainer:IsFinalAttack()
        local attackIntervalTime = param:GetAttackIntervalTime()
        local nDefenterCount = results:GetListDefenderCount()
        local nSkillID = skillEffectResultContainer:GetSkillID()
        --开始给目标每一个挂被击动作和特效
        for i = 1, nDefenterCount do
            ---@type SkillEffectResult_RandAttackData
            local randAttackData = results:GetDefenderData(i)
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(randAttackData.m_entityDefenter)
            if targetEntity then
                if isFinalHit and i == nDefenterCount then
                    skillEffectResultContainer:SetFinalAttackEntityID(targetEntity:GetID())
                end

                self:_PlayHitEffect(
                    TT,
                    casterEntity,
                    targetEntity,
                    phaseParam,
                    randAttackData.m_damageData,
                    isFinalHit,
                    nSkillID
                )
                self:_DelayTime(TT, attackIntervalTime)
            end
        end
        self:_DelayTime(TT, param:GetFinishDelayTime())
    end
end

---@param phaseParam SkillPhaseParam_RandAttack
function PlaySkillPhase_RandAttack:_PlayHitEffect(
    TT,
    entityCast,
    entityTarget,
    phaseParam,
    damageData,
    isFinalHit,
    nSkillID)
    local posCast = self:_GetEntityBasePos(entityCast)
    local posTarget = self:_GetEntityBasePos(entityTarget)
    local hitAnimationName = phaseParam:GetHitAnimation()
    local hitEffectID = phaseParam:GetHitEffectID()
    local attackPos = entityCast:GridLocation():GetGridPos()
    local beAttackPos = entityTarget:GridLocation():GetGridPos()
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, NTRandAttackEnd:New(entityCast, entityTarget, attackPos, beAttackPos))
    GameGlobal.TaskManager():CoreGameStartTask(
        self._skillService.PlayCastAudio,
        self._skillService,
        phaseParam:GetAudioID(),
        phaseParam:GetAudioWaitTime()
    )

    ---@type PlaySkillService
    local skillService = self:SkillService()

    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(entityCast)
        :SetHandleBeHitParam_TargetEntity(entityTarget)
        :SetHandleBeHitParam_HitAnimName(hitAnimationName)
        :SetHandleBeHitParam_HitEffectID(hitEffectID)
        :SetHandleBeHitParam_DamageInfo(damageData)
        :SetHandleBeHitParam_DamagePos(posTarget)
        :SetHandleBeHitParam_DeathClear(false)
        :SetHandleBeHitParam_IsFinalHit(isFinalHit)
        :SetHandleBeHitParam_SkillID(nSkillID)

    skillService:HandleBeHit(TT, beHitParam)
end
