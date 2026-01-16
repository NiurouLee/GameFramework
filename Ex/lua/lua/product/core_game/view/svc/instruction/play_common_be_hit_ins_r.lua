require("base_ins_r")
---@class PlayCommonBeHitInstruction: BaseInstruction
_class("PlayCommonBeHitInstruction", BaseInstruction)
PlayCommonBeHitInstruction = PlayCommonBeHitInstruction

function PlayCommonBeHitInstruction:Constructor(paramList)
    self._hitAnimName = paramList["hitAnimName"]
    self._hitEffectID = tonumber(paramList["hitEffectID"])
    self._turnToTarget = tonumber(paramList["turnToTarget"])
    self._deathClear = tonumber(paramList["deathClear"])
    self._trapNotPlayHitEffect = tonumber(paramList["trapNotPlayHitEffect"]) or 0 --机关不播放被击特效
    self._waitBeHitFinish = tonumber(paramList["waitBeHitFinish"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCommonBeHitInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    if targetEntityID == nil or targetEntityID < 0 then
        return
    end
    local targetEntity = world:GetEntityByID(targetEntityID)
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()

    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)

    local damageResultStageCount = skillEffectResultContainer:GetEffectResultsStageCount(SkillEffectType.Damage)

    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[curDamageIndex]
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
    if not damageInfo then
        Log.fatal("### damageInfo is nil. curDamageIndex, curDamageInfoIndex=", curDamageIndex, curDamageInfoIndex)
        return
    end
    local damageGridPos = damageResult:GetGridPos()

    local playFinalAttack = playSkillService:GetFinalAttack(world, casterEntity, phaseContext)

    local playHitEffectID = self._hitEffectID
    if self._trapNotPlayHitEffect == 1 and targetEntity:TrapID() then
        playHitEffectID = 0
    end

    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
    :SetHandleBeHitParam_CasterEntity(casterEntity)
    :SetHandleBeHitParam_TargetEntity(targetEntity)
    :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
    :SetHandleBeHitParam_HitEffectID(playHitEffectID)
    :SetHandleBeHitParam_DamageInfo(damageInfo)
    :SetHandleBeHitParam_DamagePos(damageGridPos)
    :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
    :SetHandleBeHitParam_DeathClear(self._deathClear)
    :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
    :SetHandleBeHitParam_SkillID(skillID)
    :SetHandleBeHitParam_DamageIndex(curDamageIndex)

    if self._waitBeHitFinish == 1 then
        playSkillService:HandleBeHit(TT, beHitParam)
    else
        local hitBackTaskID = TaskManager:GetInstance():CoreGameStartTask(
            self._HandleBeHitTask,self,playSkillService,beHitParam)
        phaseContext:AddPhaseTask(hitBackTaskID)
    end
end

function PlayCommonBeHitInstruction:_HandleBeHitTask(TT,playSkillService,beHitParam)
    playSkillService:HandleBeHit(TT, beHitParam)
end

---@class TurnToTargetType
local TurnToTargetType = {
    None = 0, --不朝向
    Caster = 1, --施法者
    PickupPos = 2, --拾取点
    Max = 99
}
_enum("TurnToTargetType", TurnToTargetType)
