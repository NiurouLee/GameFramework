require "play_skill_phase_base_r"
--@class PlaySkillLRAttackAnimationPhase: Object
_class("PlaySkillLRAttackAnimationPhase", PlaySkillPhaseBase)
PlaySkillLRAttackAnimationPhase = PlaySkillLRAttackAnimationPhase
--region 左右手攻击
---@param casterEntity Entity
---@param phaseParam SkillPhaseLRAttackAnimationParam
function PlaySkillLRAttackAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local res = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Damage)
    local beAttackEntityID = res:GetTargetID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(beAttackEntityID)
    if not targetEntity then
        return
    end
    --转向目标
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    resvc:TurnToTarget(casterEntity, targetEntity)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    --启动攻击者的动画
    local attackAnimName = nil
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type GridLocationComponent
    local casterGridLocation, targetGridLocation = casterEntity:GridLocation(), targetEntity:GridLocation()
    local attEffPos = nil
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local frontPos = utilCalcSvc:GetFrontPieces(casterEntity)
    local armBlurEffId = 0
    if boardServiceRender:IsLeftOrRight(casterEntity, targetEntity) < 0 then
        attackAnimName = phaseParam:GetLAnimationName()
        attEffPos = frontPos[1]
        armBlurEffId = phaseParam:GetLBlurEffectID()
    else
        attackAnimName = phaseParam:GetRAnimationName()
        attEffPos = frontPos[2]
        armBlurEffId = phaseParam:GetRBlurEffectID()
    end
    casterEntity:SetAnimatorControllerTriggers({attackAnimName})
    local blurDelay = phaseParam:GetBlurDelay()
    if blurDelay then
        YIELD(TT, blurDelay)
    end
    if armBlurEffId then
        effectService:CreateEffect(armBlurEffId, casterEntity)
    end

    local deltaTimeMS = self._timeService:GetCurrentTimeMs()
    --等待爆点时刻
    local hitPointDelay = phaseParam:GetHitPointDelay()
    if hitPointDelay > 0 then
        YIELD(TT, hitPointDelay)
    end
    --启动攻击特效播放
    local attackEffectID = phaseParam:GetCastEffectID()
    ---@type Vector3
    local renderDir = casterEntity:GetDirection()
    effectService:CreateWorldPositionDirectionEffect(attackEffectID, attEffPos, Vector2(renderDir.x, renderDir.z))
    --被击者转向攻击者
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    resvc:TurnToTarget(targetEntity, casterEntity)

    --被击者受击动画
    local hitAnimName = phaseParam:GetHitAnimation()
    targetEntity:SetAnimatorControllerTriggers({hitAnimName})
    --被击者受击特效
    local hitEffectID = phaseParam:GetHitEffectID()
    effectService:CreateEffect(hitEffectID, targetEntity)

    ---@type SkillHitBackEffectResult
    local hitBackData = skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.HitBack, beAttackEntityID)

    ---处理击退效果
    local processHitTaskID = self:SkillService():ProcessHit(casterEntity, targetEntity, hitBackData)

    --血条刷新
    local castDamage = res:GetDamageInfo(1)

    --伤害飘字
    playDamageSvc:AsyncUpdateHPAndDisplayDamage(targetEntity, castDamage)

    --等待攻击者整体动画结束
    local overDelay = phaseParam:GetOverDelay()
    if overDelay > 0 then
        YIELD(TT, overDelay)
    end

    ---等待击退/撞墙等处理
    if processHitTaskID then
        while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
            YIELD(TT)
        end
    end
end
