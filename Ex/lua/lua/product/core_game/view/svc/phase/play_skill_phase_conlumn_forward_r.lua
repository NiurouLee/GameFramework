require "play_skill_phase_base_r"
_class("PlaySkillPhaseColumnForward", PlaySkillPhaseBase)
PlaySkillPhaseColumnForward = PlaySkillPhaseColumnForward

---@param casterEntity Entity
---@param phaseParam SkillPhaseParamColumnForward
function PlaySkillPhaseColumnForward:PlayFlight(TT, casterEntity, phaseParam)
    local effectID = phaseParam:GetGridEffectID()
    local hitAnimationName = phaseParam:GetHitAnimationName()
    local hitEffectID = phaseParam:GetHitEffectID()
    local intervalTime = phaseParam:GetEffectIntervalTime()
    local hasDamage = phaseParam:HasDamage()
    local gridDelayTime = phaseParam:GetGridDelayTime()
    local hitPointDelay = phaseParam:GetHitPointDelay()
    local finishDelayTime = phaseParam:GetFinishDelayTime()

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()

    --table.insert(gridDataArray, castPos)

    local sameConlumnList = {}

    local effectList = {}
    local waveCount = 10
    for i = 1, waveCount do
        local waveItem = {}
        waveItem.index = i
        waveItem.gridList = {}

        table.insert(effectList, waveItem)
    end

    -- for i = 1, waveCount do
    for k, v in pairs(gridDataArray) do
        local grid = v
        local effectItem = {}
        if grid.y == castPos.y and grid ~= castPos then
            -- effectItem.grid = grid
            -- effectItem.index = 1
            -- effectItem.direction = Vector2(-1, 0)
            table.insert(sameConlumnList, grid)
        elseif grid.y < castPos.y then
            effectItem.grid = grid
            effectItem.index = castPos.y - grid.y
            -- effectItem.direction = Vector2(-1, 0)
            effectItem.direction = Vector2(0, -1)
        elseif grid.y > castPos.y then
            effectItem.grid = grid
            effectItem.index = grid.y - castPos.y
            -- effectItem.direction = Vector2(1, 0)
            effectItem.direction = Vector2(0, 1)
        end
        -- if effectItem.index == i then
        if effectItem.index then
            table.insert(effectList[effectItem.index].gridList, effectItem)
        end
    end
    -- end

    --先播放和玩家同y的受击效果
    for k, grid in pairs(sameConlumnList) do
        local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, grid)
        if damageResult then
            self:_ShowDamage(
                damageResult,
                skillEffectResultContainer,
                hitAnimationName,
                hitEffectID,
                casterEntity,
                grid,
                0,
                --scopeForwardParam:HitTurnToTarget(),
                skillID
            )
        end
    end

    YIELD(TT, gridDelayTime)

    --播放特效
    for wave, waveItem in pairs(effectList) do
        for k, effectItem in pairs(waveItem.gridList) do
            local entityEffect = world:GetService("Effect"):CreateWorldPositionEffect(effectID, effectItem.grid)
            --entityEffect:SetGridDirection(effectItem.direction)
            entityEffect:SetDirection(effectItem.direction)
            -- end
        end

        YIELD(TT, hitPointDelay)
        if hasDamage then
            for k, effectItem in pairs(waveItem.gridList) do
                local damageResult =
                    skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, effectItem.grid)
                if damageResult then
                    self:_ShowDamage(
                        damageResult,
                        skillEffectResultContainer,
                        hitAnimationName,
                        hitEffectID,
                        casterEntity,
                        effectItem.grid,
                        0,
                        --scopeForwardParam:HitTurnToTarget(),
                        skillID
                    )
                end
            end
        end

        YIELD(TT, intervalTime - hitPointDelay)
    end

    YIELD(TT, finishDelayTime)
end

function PlaySkillPhaseColumnForward:_ShowDamage(
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
            self:SkillService().HandleBeHit,
            self:SkillService(),
            beHitParam
        )
    end
end
