require "play_skill_phase_base_r"

---@class PlaySkillDrillerExplosionSimplePhase: PlaySkillPhaseBase
_class("PlaySkillDrillerExplosionSimplePhase", PlaySkillPhaseBase)
PlaySkillDrillerExplosionSimplePhase = PlaySkillDrillerExplosionSimplePhase

---@param phaseParam SkillPhaseDrillerExplosionSimpleParam
---@param casterEntity Entity
function PlaySkillDrillerExplosionSimplePhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    -- casterEntity:SetAnimatorControllerTriggers({phaseParam.castAnimation})
    -- if (phaseParam.castEffectID) and (phaseParam.castEffectID ~= 0) then
    --     effectService:CreateEffect(phaseParam.castEffectID, casterEntity)
    -- end
    ---@type SkillEffectDestroyMonsterResult[]
    local destroyResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyMonster)
    if not destroyResultArray then
        return
    end
    local index = 1
    local destroyResult = destroyResultArray[index]
    if not destroyResult then
        return
    end
    local singleBossEntity = nil
    local singleBossClassID = phaseParam:GetMonsterClassID()
    if singleBossClassID and singleBossClassID > 0 then
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            if e:HasView() and not e:HasShowDeath() and singleBossClassID == e:MonsterID():GetMonsterClassID() then
                singleBossEntity = e
                break
            end
        end
    end
    if not singleBossEntity then
        return
    end
    local singleBossPos = singleBossEntity:GetRenderGridPosition()
    local boomEffDir = self:_GetGridDirection(singleBossEntity)
    local eID = destroyResult:GetEntityID()
    local eMonster = self._world:GetEntityByID(eID)
    if not eMonster then--这里 eMonster就是casterEntity，现在是用5格怪放技能
        return
    end
    self:SetHPVisible(casterEntity,false)
    self:SetHPVisible(singleBossEntity,false)
    YIELD(TT)
    local startAction = phaseParam:GetStartAction()
    casterEntity:SetAnimatorControllerTriggers({startAction})
    local startEffectID = phaseParam:GetStartEffectID()
    if (startEffectID) and (startEffectID ~= 0) then
        effectService:CreateEffect(startEffectID, casterEntity)
    end
    local mainEffectID = phaseParam:GetMainEffectID()
    if (mainEffectID) and (mainEffectID ~= 0) then
        --effectService:CreateEffect(mainEffectID, casterEntity)
        local boomGridPos = singleBossPos + boomEffDir * 1
        effectService:CreateWorldPositionDirectionEffect(mainEffectID, boomGridPos,boomEffDir)
    end
    local startMatAnim = phaseParam:GetStartMatAnim()
    casterEntity:PlayMaterialAnim(startMatAnim)
    
    local bossShowDelayMs = phaseParam:GetBossShowDelayMs()
    YIELD(TT,bossShowDelayMs)
    eMonster:SetViewVisible(false)
    ---@type MonsterShowRenderService
    local svc = self._world:GetService("MonsterShowRender")
    GameGlobal.TaskManager():CoreGameStartTask(function(TT)
        svc:_DoOneMonsterDead(TT, eMonster)
    end)


    
    singleBossEntity:SetViewVisible(true)
    self:SetHPVisible(singleBossEntity,false)
    --取消表现代理 之前隐藏时被击由底座怪表现
    singleBossEntity:RemoveRenderPerformanceByAgent()
    local bossShowAction = phaseParam:GetBossShowAction()
    singleBossEntity:SetAnimatorControllerTriggers({bossShowAction})
    local bossShowEffectID = phaseParam:GetBossShowEffectID()
    if (bossShowEffectID) and (bossShowEffectID ~= 0) then
        effectService:CreateEffect(bossShowEffectID, singleBossEntity)
    end
    local finalDelayMs = phaseParam:GetFinalDelayMs()
    YIELD(TT,finalDelayMs)

    self:SetHPVisible(singleBossEntity,true)
end

---@param summonRes SkillEffectResult_SummonEverything
function PlaySkillDrillerExplosionSimplePhase:_ShowTrapFromSummonEverything(TT, summonRes,phaseParam)
    local summonMonsterData = summonRes:GetTrapData()
    local posSummon = summonRes:GetSummonPos()
    ---@type Entity
    local trapEntity = self._world:GetEntityByID(summonMonsterData.m_entityWorkID)
    GameGlobal.TaskManager():CoreGameStartTask(self._ShowTrap,self,trapEntity,posSummon,phaseParam)
    --self:_ShowTrap(TT, trapEntity, posSummon,phaseParam)
end
---@param world MainWorld
---@param summonRes SkillEffectResult_SummonEverything
function PlaySkillDrillerExplosionSimplePhase:_ShowTrap(TT, trapEntity, posSummon,phaseParam)
    trapEntity:SetPosition(posSummon)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
end
function PlaySkillDrillerExplosionSimplePhase:_ShowDamage(
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

function PlaySkillDrillerExplosionSimplePhase:SetHPVisible(entity,bVisible)
    local hpCmpt = entity:HP()
    if hpCmpt then
        local sliderEntityID = entity:HP():GetHPSliderEntityID()
        local sliderEntity = self._world:GetEntityByID(sliderEntityID)
        if sliderEntity then
            hpCmpt:SetHPBarTempHide(not bVisible)
            hpCmpt:SetHPPosDirty(true)
            --sliderEntity:SetViewVisible(bVisible)
        end
    end
end
---@param entity Entity
---@return Vector2
function PlaySkillDrillerExplosionSimplePhase:_GetGridDirection(entity)
    local dir = entity:GetGridDirection():Clone()

    if dir.x > 1 then
        dir.x = 1
    elseif dir.x < -1 then
        dir.x = -1
    end
    if dir.y > 1 then
        dir.y = 1
    elseif dir.y < -1 then
        dir.y = -1
    end

    return dir
end