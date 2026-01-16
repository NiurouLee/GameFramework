require "play_skill_phase_base_r"
_class("PlaySkillPhaseScopeForwardByDistance", PlaySkillPhaseBase)
PlaySkillPhaseScopeForwardByDistance = PlaySkillPhaseScopeForwardByDistance

---@param casterEntity Entity
function PlaySkillPhaseScopeForwardByDistance:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParamScopeForwardByDistance
    local scopeForwardParam = phaseParam
    local gridEffectID = scopeForwardParam:GetGridEffectID()
    local hitAnimationName = scopeForwardParam:GetHitAnimationName()
    local hitEffectID = scopeForwardParam:GetHitEffectID()
    local effectDirection = scopeForwardParam:GetGridEffectDirection()

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()

    local targetGirdList, maxLength, _ = InnerGameSortGridHelperRender:SortGrid(gridDataArray, castPos)

    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
        local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
        skillEffectResultContainer:SetFinalAttackEntityID(targetEntityID)
    end
    local intervalTime = scopeForwardParam:GetEffectIntervalTime()
    local scopeType = scopeForwardParam:GetScopeType()
    local quadrantDiagonal = scopeForwardParam:GetQuadrantDiagonal()

    local tidHitTask = {}
    for i = 1, maxLength + 1 do
        local completeGirdArray = {}
        for _, gridPos in pairs(gridDataArray) do
            local distance = Vector2.Distance(castPos, gridPos)
            if distance <= i and distance > 0 then
                table.insert(completeGirdArray, gridPos)
                local girdDirection = Vector2.zero
                if quadrantDiagonal then
                    girdDirection = self:_GetEffDir(gridPos, castPos)
                else
                    girdDirection =
                        self:_GetGridDirection(gridPos, castPos, scopeType) + self:_GetEffectDirection(effectDirection)
                end
                local entity =
                    self._world:GetService("Effect"):CreateWorldPositionDirectionEffect(
                    gridEffectID,
                    gridPos,
                    girdDirection
                )
                -- Log.fatal("Pos:", tostring(gridPos), "Direction:", tostring(girdDirection))
                local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, gridPos)
                if damageResult then
                    local tid =
                        self:_ShowDamage(
                        damageResult,
                        skillEffectResultContainer,
                        hitAnimationName,
                        hitEffectID,
                        casterEntity,
                        gridPos,
                        scopeForwardParam:HitTurnToTarget(),
                        skillID
                    )
                    if tid then
                        table.insert(tidHitTask, tid)
                    end
                end
            end
        end
        for _, pos in pairs(completeGirdArray) do
            --table.remove(gridDataArray,pos)
            table.removev(gridDataArray, pos)
        end
        YIELD(TT, intervalTime)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(tidHitTask) do
        YIELD(TT)
    end
end

function PlaySkillPhaseScopeForwardByDistance:_ShowDamage(
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
        --targetDamage = math.floor(targetDamage)
        Log.debug("[skill] PlaySkillService:_HandlePlayFlyAttack ", targetEntityID, hitAnimName)

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

function PlaySkillPhaseScopeForwardByDistance:_GetGridDirection(girdPos, casterPos, scopeType)
    if girdPos == (casterPos + Vector2(0, 1)) then
        return Vector2(0, 1)
    elseif girdPos == (casterPos + Vector2(0, -1)) then
        return Vector2(0, -1)
    elseif girdPos == (casterPos + Vector2(1, 0)) then
        return Vector2(1, 0)
    elseif girdPos == (casterPos + Vector2(-1, 0)) then
        return Vector2(-1, 0)
    end

    ---横着的范围
    if scopeType == 1 then
        ---竖着的范围
        local sub = girdPos - casterPos
        if sub.x < 0 then
            return Vector2(-1, 0)
        else
            return Vector2(1, 0)
        end
    else
        local sub = girdPos - casterPos
        if sub.y < 0 then
            return Vector2(0, -1)
        else
            return Vector2(0, 1)
        end
    end
end

---@return Vector2
function PlaySkillPhaseScopeForwardByDistance:_GetEffectDirection(effectDirection)
    if effectDirection == "Bottom" then
        return Vector2(0, -1)
    elseif effectDirection == "Up" then
        return Vector2(0, 1)
    elseif effectDirection == "Left" then
        return Vector2(1, 0)
    elseif effectDirection == "Right" then
        return Vector2(-1, 0)
    else
        return Vector2(0, 0)
    end
end

---获取在对应格子上的特效方向，格子在施法者位置的轴上返回正向，否则返回斜向
function PlaySkillPhaseScopeForwardByDistance:_GetEffDir(girdPos, casterPos)
    ---@type Vector2
    local sub = girdPos - casterPos
    if sub.x == 0 or sub.y == 0 then --格子和施法者同在xy轴上，则返回sub的单位向量。如(0，-2)就会返回(0, -1)
        return sub.normalized
    else
        return Vector2(sub.x / Mathf.Abs(sub.x), sub.y / Mathf.Abs(sub.y))
    end
end

---按照距离玩家远近来判定最后一击
---返回最远的那个目标的ID
function PlaySkillPhaseScopeForwardByDistance:_SortDistanceForFinalAttack(castPos, damageResultArray)
    local function CmpDistancefunc(skillDamageEffectResult1, skillDamageEffectResult2)
        local dis1 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult1)
        local dis2 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult2)

        return dis1 > dis2
    end
    table.sort(damageResultArray, CmpDistancefunc)

    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local result = v
        local targetEntityID = result:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        if targetEntity:HasDeadFlag() then
            return targetEntityID
        end
    end
end

function PlaySkillPhaseScopeForwardByDistance:_CalcDistanceToCaster(castPos, skillDamageResult)
    local gridPos = skillDamageResult:GetGridPos()
    return Vector2.Distance(gridPos, castPos)
end
