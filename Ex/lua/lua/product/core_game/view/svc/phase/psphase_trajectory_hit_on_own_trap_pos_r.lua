--符文刺客 攻击技能
require "play_skill_phase_base_r"
---@class PlaySkillTrajectoryHitOnOwnTrapPosPhase: PlaySkillPhaseBase
_class("PlaySkillTrajectoryHitOnOwnTrapPosPhase", PlaySkillPhaseBase)
PlaySkillTrajectoryHitOnOwnTrapPosPhase = PlaySkillTrajectoryHitOnOwnTrapPosPhase

---@param phaseParam SkillPhaseTrajectoryHitOnOwnTrapPosParam
function PlaySkillTrajectoryHitOnOwnTrapPosPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillDamageEffectResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.Damage)
    if not result then
        return
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local ownTrapEntity = nil--符文刺客 的 符文机关 只有一个
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if e:HasSummoner() then
            if e:Summoner():GetSummonerEntityID() == casterEntity:GetID() then
                ownTrapEntity = e
                break
            end
        else
        end
    end
    if not ownTrapEntity then
        return
    end
    local targetEntityID = result:GetTargetID()--队伍
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if not targetEntity then
        return
    end

    --模型位置
    ---@type UnityEngine.GameObject
    local casterGO = casterEntity:View():GetGameObject()
    ---@type  Vector2
    local oldCasterPos = casterEntity:GetGridPosition()
    local oldCasterPosition = casterGO.transform.position
    local oldForward = casterGO.transform.forward
    local trapEntityPos = ownTrapEntity:GetGridPosition()
    local trapRenderPos = boardServiceRender:GridPos2RenderPos(trapEntityPos)
    local targetEntityPos = targetEntity:GetGridPosition()
    local attackDir = targetEntityPos - trapEntityPos
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --施法表现
    --怪模型移到机关位置 朝向目标
    casterGO.transform.position = trapRenderPos
    casterGO.transform.forward = Vector3(attackDir.x, 0, attackDir.y)

    local waitTaskIDs = {}
    local monsterAnimTask = GameGlobal.TaskManager():CoreGameStartTask(self._DoMonsterAnim, self,casterEntity,ownTrapEntity,phaseParam)
    table.insert(waitTaskIDs,monsterAnimTask)
    local bulletTask = GameGlobal.TaskManager():CoreGameStartTask(self._DoBullet, self,casterEntity,targetEntity,phaseParam)
    table.insert(waitTaskIDs,bulletTask)
    local beHitTask = GameGlobal.TaskManager():CoreGameStartTask(self._DoBeHit, self,casterEntity,phaseParam)
    table.insert(waitTaskIDs,beHitTask)
    while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskIDs) do
        YIELD(TT)
    end
    --怪模型移回原位
    casterGO.transform.position = oldCasterPosition
    casterGO.transform.forward = oldForward
end

---@param phaseParam SkillPhaseTrajectoryHitOnOwnTrapPosParam
function PlaySkillTrajectoryHitOnOwnTrapPosPhase:_DoMonsterAnim(TT,casterEntity,ownTrapEntity,phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --施法动作
    casterEntity:SetAnimatorControllerTriggers({phaseParam:GetCasterAnim()})
    --施法特效
    local casterEffectID = phaseParam:GetCasterEffectID()
    if casterEffectID then
        effectService:CreateEffect(phaseParam:GetCasterEffectID(), casterEntity)
    end
    YIELD(TT, phaseParam:GetTotalTime())
end
---@param phaseParam SkillPhaseTrajectoryHitOnOwnTrapPosParam
function PlaySkillTrajectoryHitOnOwnTrapPosPhase:_DoBullet(TT,casterEntity,targetEntity,phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type PlaySkillService
    local playSkillService = self:SkillService()
    local bulletDelayTime = phaseParam:GetBulletStartDelay()
    YIELD(TT,bulletDelayTime)

    local casterBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(casterEntity, phaseParam:GetBulletBeginBindBone())
    local casterPos = casterBoneTransform.position
    local targetBoneTransform = playSkillService:GetEntityRenderSelectBoneTransform(targetEntity, phaseParam:GetBulletEndBindBone())
    local targetPos = targetBoneTransform.position
    --弹道
    local bulletFlyTime = phaseParam:GetBulletFlyTotalTime()
    local bulletEffectID = phaseParam:GetBulletEffectID()
    local bowlderEffectEntity = effectService:CreatePositionEffect(bulletEffectID, casterPos)
    
    YIELD(TT)
    ---@type ViewComponent
    local effectViewCmpt = bowlderEffectEntity:View()
    if effectViewCmpt then
        ---@type UnityEngine.GameObject
        local effectObject = effectViewCmpt:GetGameObject()
        local posEffect = effectObject.transform.position
        local transWork = effectObject.transform
        transWork:DOMove(targetPos, bulletFlyTime/1000, false)
    end

    YIELD(TT, bulletFlyTime)
end
---@param phaseParam SkillPhaseTrajectoryHitOnOwnTrapPosParam
function PlaySkillTrajectoryHitOnOwnTrapPosPhase:_DoBeHit(TT,casterEntity,phaseParam)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillDamageEffectResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.Damage)
    if not result then
        return
    end
    local delayTime = phaseParam:GetHitDelayTime()
    YIELD(TT,delayTime)
    --伤害
    local hitAnimName = phaseParam:GetHitAnim()
    local hitFxID = phaseParam:GetHitEffectID()
    ---@type PlaySkillService
    local skillService = self:SkillService()

    local isFinalHit = routineComponent:IsFinalAttack()
    local skillID = routineComponent:GetSkillID()
    local damageResult = result
    --for _, damageResult in ipairs(damageResultArray) do
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        local damageInfoArray = damageResult:GetDamageInfoArray()
        local posTarget = self:_GetEntityBasePos(targetEntity)
        for __, damageInfo in ipairs(damageInfoArray) do
            ---调用统一处理被击的逻辑
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName(hitAnimName)
                :SetHandleBeHitParam_HitEffectID(hitFxID)
                :SetHandleBeHitParam_DamageInfo(damageInfo)
                :SetHandleBeHitParam_DamagePos(posTarget)
                :SetHandleBeHitParam_DeathClear(false)
                :SetHandleBeHitParam_IsFinalHit(isFinalHit)
                :SetHandleBeHitParam_SkillID(skillID)

            skillService:HandleBeHit(TT, beHitParam)
        end
    --end
end