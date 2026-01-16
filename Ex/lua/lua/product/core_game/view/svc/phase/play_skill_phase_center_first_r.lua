--[[
时序
    1  中心特效
    不等待
    2  中心8格子伤害
    等待    centerHitDelay
    
    3  外围格子特效 
    等待    centerDelay 
    4  外围格子伤害
    等待    centerDelay  + otherGridHitDelay
    
    5 再外面 特效
    等待    centerDelay + (distanceDelay * 距离-1)
    6 再外围格子伤害
    等待    centerDelay  + otherGridHitDelay+ (distanceDelay * 距离-1)
]]
require "play_skill_phase_base_r"

_class("PlaySkillPhaseCenterFirst", PlaySkillPhaseBase)
PlaySkillPhaseCenterFirst = PlaySkillPhaseCenterFirst

---@param casterEntity Entity
---@param phaseParam SkillPhaseCenterFirstParam
function PlaySkillPhaseCenterFirst:PlayFlight(TT, casterEntity, phaseParam)
    self._damageStageIndex = phaseParam:GetdDmageStageIndex()
    local gridCenterEffectID = phaseParam:GetAtkCenterEffectID()
    local shandowCenterEffectID = phaseParam:GetAtkShandowCenterEffectID()
    local gridEffectID = phaseParam:GetAtkEffectID()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    self:InitSkillResult(skillEffectResultContainer)
    local gridDataArray = scopeResult:GetAttackRange() --GetWholeGridRange
    local centerPos = scopeResult:GetCenterPos()
    local playerEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = playerEntity:GridLocation().Position
    local targetGirdList, maxLength, maxGridCount = InnerGameSortGridHelperRender:SortGrid(gridDataArray, centerPos)
    ---特效
    ---@type EffectService
    local effService = self._world:GetService("Effect")
    local centerDelay = phaseParam:GetCenterDelay()
    local hitAnimationName = phaseParam:GetHitAnimation()
    local hitEffectID = phaseParam:GetHitEffectID()
    ---@type TimeService
    local timeService = self._world:GetService("Time")
    local atkAnim = phaseParam:GetAtkAnimation()
    casterEntity:SetAnimatorControllerTriggers({ atkAnim })
    local distanceDelay = phaseParam:GetDistanceDelay()

    local randomArray = phaseParam:GetRandomEffectIDs()
    local randomRequired = #randomArray > 0
    local maxRandom = #randomArray
    for i = 1, maxGridCount do
        --特效
        if i == 1 then
            if (((centerPos.x == playerPos.x and centerPos.y == playerPos.y) or shandowCenterEffectID == 0) and
                gridCenterEffectID > 0)
            then
                effService:CreateWorldPositionEffect(gridCenterEffectID, centerPos)
            else
                if shandowCenterEffectID > 0 then
                    effService:CreateWorldPositionEffect(shandowCenterEffectID, centerPos)
                end
            end
        else
            for dir = 1, 8 do
                local t = targetGirdList[dir]
                if #(t.gridList) >= i then
                    local gridPos = t.gridList[i]
                    local fxid = gridEffectID
                    if randomRequired then
                        fxid = randomArray[math.random(1, maxRandom)]
                    end
                    local dx = t.direction.x
                    local dy = t.direction.y
                    local fxdir = Vector2.New(0 - dy, dx)
                    effService:CreateWorldPositionDirectionEffect(fxid, gridPos, fxdir)
                end
            end
        end

        --伤害
        local waitTime = 0
        if i == 1 then
            waitTime = phaseParam:GetCenterHitDelay()
        else
            waitTime = phaseParam:GetOtherGridHitDelay()
        end
        for dir = 1, 8 do
            local t = targetGirdList[dir]
            if #(t.gridList) >= i then
                local gridPos = t.gridList[i]
                ---local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, gridPos)
                local damageResults = self:GetResultByGridPos(gridPos)
                if damageResults then
                    for _, damageRes in ipairs(damageResults) do
                        self:_ShowDamage(
                            damageRes,
                            skillEffectResultContainer,
                            hitAnimationName,
                            hitEffectID,
                            casterEntity,
                            gridPos,
                            phaseParam:HitTurnToTarget(),
                            skillID,
                            waitTime
                        )
                    end
                end
            end
        end

        if i ~= maxGridCount then
            if i == 1 then
                YIELD(TT, centerDelay)
            else
                if distanceDelay > 0 then
                    YIELD(TT, distanceDelay)
                end
            end
        end
    end
    local finishDelayTime = phaseParam:GetFinishDelayTime()
    if finishDelayTime > 0 then
        YIELD(TT, phaseParam:GetFinishDelayTime())
    end
end

---@param skillEffectResultContainer SkillEffectResultContainer
function PlaySkillPhaseCenterFirst:_ShowDamage(
    damageResult,
    skillEffectResultContainer,
    hitAnimName,
    hitEffectID,
    casterEntity,
    gridPos,
    hitTurnToTarget,
    skillID,
    waitTime)
    local targetEntityID = damageResult:GetTargetID()
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if targetEntity ~= nil then
        ---@type PlaySkillService
        local skillService = self:SkillService()
        local targetDamage = damageResult:GetDamageInfo(1)
        local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
        local damageResultStageCount = skillEffectResultContainer:GetEffectResultsStageCount(SkillEffectType.Damage)
        local playFinalAttack = false
        if isFinalAttack and self._damageStageIndex == damageResultStageCount then
            playFinalAttack = true
        end

        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                if waitTime > 0 then
                    YIELD(TT, waitTime)
                end

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
                    :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
                    :SetHandleBeHitParam_SkillID(skillID)

                skillService:HandleBeHit(TT, beHitParam)
            end
        )
    end
end

function PlaySkillPhaseCenterFirst:InitSkillResult(skillEffectResultContainer)
    ----@type SkillDamageEffectResult[]
    self._resultList = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, self._damageStageIndex)
end

---
function PlaySkillPhaseCenterFirst:GetResultByGridPos(gridPos)
    local resultArray = {}
    for _, result in ipairs(self._resultList) do
        local resultPos = result:GetGridPos()
        if resultPos.x == gridPos.x and resultPos.y == gridPos.y then
            table.insert(resultArray, result)
        end
    end

    return resultArray
end
