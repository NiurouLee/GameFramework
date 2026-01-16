require "play_skill_phase_base_r"

---@class PlaySkillDrillerSacrificeTrapAndDamagePhase: PlaySkillPhaseBase
_class("PlaySkillDrillerSacrificeTrapAndDamagePhase", PlaySkillPhaseBase)
PlaySkillDrillerSacrificeTrapAndDamagePhase = PlaySkillDrillerSacrificeTrapAndDamagePhase

---@param phaseParam SkillPhaseDrillerSacrificeTrapAndDamageParam
---@param casterEntity Entity
function PlaySkillDrillerSacrificeTrapAndDamagePhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSacrificeTargetNearestTrapsAndDamageResult
    local skillResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.SacrificeTargetNearestTrapsAndDamage)
    if not skillResult then
        return
    end
    local sacrificeTrapEntityIDs = skillResult:GetTrapIDArray()
    local damageResults = skillResult:GetDamageResultArray()
    -- if sacrificeTrapEntityIDs and #sacrificeTrapEntityIDs > 0 then
    -- else
    --     return
    -- end
    if not sacrificeTrapEntityIDs then
        sacrificeTrapEntityIDs = {}
    end

    local startAction = phaseParam:GetStartAction()
    casterEntity:SetAnimatorControllerTriggers({startAction})
    local startEffectID = phaseParam:GetStartEffectID()
    if (startEffectID) and (startEffectID ~= 0) then
        effectService:CreateEffect(startEffectID, casterEntity)
    end

    local lineDelayMs = phaseParam:GetLineDelayMs()
    YIELD(TT,lineDelayMs)
    local trapEntitys = {}
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = self._world:GetService("PlaySkillInstruction")
    for index, trapEntityID in ipairs(sacrificeTrapEntityIDs) do
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        if trapEntity and not trapEntity:HasDeadFlag() then
             table.insert(trapEntitys,trapEntity)
        end
    end
    local mainLineEffectID = phaseParam:GetMainLineEffectID()
    local mainLineMonsterBone = phaseParam:GetMainLineMonsterBone()
    local mainLinePetBone = phaseParam:GetMainLinePetBone()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamLeaderEntity = nil
    if teamEntity then
        teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
    end
    local monsterLineOff = phaseParam:GetMonsterLineOff()
    effectService:CreateLineEffects(TT,mainLineEffectID,teamLeaderEntity,mainLinePetBone,{casterEntity},mainLineMonsterBone,nil,monsterLineOff)

    local trapPosEffectID = phaseParam:GetTrapPosEffectID()
    for index, trapEntity in ipairs(trapEntitys) do
        local trapPos = trapEntity:GetGridPosition()
        effectService:CreateCommonGridEffect(trapPosEffectID,trapPos)
    end
    local subLineEffectID = phaseParam:GetSubLineEffectID()
    local subLinePetBone = phaseParam:GetSubLinePetBone()
    local subLineTrapBone = phaseParam:GetSubLineTrapBone()
    effectService:CreateLineEffects(TT,subLineEffectID,teamLeaderEntity,subLinePetBone,trapEntitys,subLineTrapBone)
    for index, eTrap in ipairs(trapEntitys) do
        local donotPlayDie = false
        --trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
        GameGlobal.TaskManager():CoreGameStartTask(
            function()
                trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
            end
        )
    end
    local hitDelayMs = phaseParam:GetHitDelayMs()
    YIELD(TT,hitDelayMs)

    local hitAnim = phaseParam:GetHitAnim()
    local hitEffectID = phaseParam:GetHitEffectID()
    local hitPos = teamLeaderEntity:GetGridPosition()
    local skillID = skillEffectResultContainer:GetSkillID()
    local hitTurnToTarget = false
    --伤害
    for index, damageResult in ipairs(damageResults) do
        if damageResult then
            self:_ShowDamage(
                damageResult,
                skillEffectResultContainer,
                hitAnim,
                hitEffectID,
                casterEntity,
                hitPos,
                hitTurnToTarget,
                skillID
            )
        end
    end

    local trapDieDelayMs = phaseParam:GetTrapDieDelayMs()
    YIELD(TT,trapDieDelayMs)

    
    --local doNotPlayTrapDie = false
    --trapServiceRender:PlayTrapDieSkill(TT, trapEntitys, doNotPlayTrapDie)
    YIELD(TT,100)
end
function PlaySkillDrillerSacrificeTrapAndDamagePhase:_ShowDamage(
    damageResult,
    skillEffectResultContainer,
    hitAnimName,
    hitEffectID,
    casterEntity,
    gridPos,
    hitTurnToTarget,
    skillID)
    local targetEntityID = damageResult:GetTargetID()
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if targetEntity ~= nil then
        ---@type PlaySkillService
        local skillService = self:SkillService()
        local targetDamage = damageResult:GetDamageInfo(1)

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(targetDamage)
            :SetHandleBeHitParam_DamagePos(gridPos)
            :SetHandleBeHitParam_HitTurnTarget(hitTurnToTarget)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(skillEffectResultContainer:IsFinalAttack())
            :SetHandleBeHitParam_SkillID(skillID)

        GameGlobal.TaskManager():CoreGameStartTask(
            skillService.HandleBeHit,
            skillService,
            beHitParam
        )
    end
end