require("base_ins_r")
---@class PlayGridRangeBeHitInstruction: BaseInstruction
_class("PlayGridRangeBeHitInstruction", BaseInstruction)
PlayGridRangeBeHitInstruction = PlayGridRangeBeHitInstruction

function PlayGridRangeBeHitInstruction:Constructor(paramList)
    self._hitAnimName = paramList["hitAnimName"]
    self._hitEffectID = tonumber(paramList["hitEffectID"])
    self._turnToTarget = tonumber(paramList["turnToTarget"])
    self._deathClear = tonumber(paramList["deathClear"])
    self._bodyArea = tonumber(paramList["bodyArea"]) or 1
    self._damageStageIndex = tonumber(paramList["damageStageIndex"]) or 1 --技能阶段
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridRangeBeHitInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    if not scopeGridRange then
        return
    end
    local maxScopeRangeCount = phaseContext:GetMaxRangeCount()
    if not maxScopeRangeCount then
        return
    end
    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    if curScopeGridRangeIndex > maxScopeRangeCount then
        return
    end
    --播放被击特效
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local world = casterEntity:GetOwnerWorld()
    local effectService = world:GetService("Effect")

    local visited={}
    local taskIds = {}
    for _, range in pairs(scopeGridRange) do
        if range then
            local posList = range[curScopeGridRangeIndex]
            if posList then
                for _, pos in pairs(posList) do
                    if self._bodyArea == 1 then
                        --默认区域是一个格子
                        local t =
                            skillEffectResultContainer:GetEffectResultsAsArray(
                            SkillEffectType.Damage,
                            self._damageStageIndex
                        )
                        for _, result in ipairs(t) do
                            if result:GetGridPos() == pos then
                                local taskid = self:_CommonBeHit(TT, casterEntity, phaseContext, result)
                                taskIds[#taskIds + 1] = taskid
                            end
                        end
                    elseif self._bodyArea == 4 then
                        --如果是每4个格子作为一个区域的
                        local bodyAreaFix = {}
                        table.insert(bodyAreaFix, Vector2(0.5, 0.5))
                        table.insert(bodyAreaFix, Vector2(0.5, -0.5))
                        table.insert(bodyAreaFix, Vector2(-0.5, 0.5))
                        table.insert(bodyAreaFix, Vector2(-0.5, -0.5))

                        for _, bodyArea in pairs(bodyAreaFix) do
                            local workPos = bodyArea + pos
                            local t =
                                skillEffectResultContainer:GetEffectResultsAsArray(
                                SkillEffectType.Damage,
                                self._damageStageIndex
                            )
                            for _, result in ipairs(t) do
                                if result:GetGridPos() == workPos and not table.icontains(visited,workPos) then
                                    visited[#visited + 1] = workPos
                                    local taskid = self:_CommonBeHit(TT, casterEntity, phaseContext, result)
                                    taskIds[#taskIds + 1] = taskid
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
        YIELD(TT)
    end
end

function PlayGridRangeBeHitInstruction:_CommonBeHit(TT, casterEntity, phaseContext, damageResult)
    local targetID = damageResult:GetTargetID()
    if not targetID then
        return 0
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    local targetEntity = world:GetEntityByID(targetID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()

    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()
    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)

    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
    local damageGridPos = damageResult:GetGridPos()
    local playFinalAttack = false

    if skillEffectResultContainer:IsFinalAttack() and damageResultArray[#damageResultArray] == damageResult then
        playFinalAttack = true
    end

    local taskid =
        GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            ---调用统一处理被击的逻辑
            local beHitParam = HandleBeHitParam:New()
                :SetHandleBeHitParam_CasterEntity(casterEntity)
                :SetHandleBeHitParam_TargetEntity(targetEntity)
                :SetHandleBeHitParam_HitAnimName(self._hitAnimName)
                :SetHandleBeHitParam_HitEffectID(self._hitEffectID)
                :SetHandleBeHitParam_DamageInfo(damageInfo)
                :SetHandleBeHitParam_DamagePos(damageGridPos)
                :SetHandleBeHitParam_HitTurnTarget(self._turnToTarget)
                :SetHandleBeHitParam_DeathClear(self._deathClear)
                :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
                :SetHandleBeHitParam_SkillID(skillID)

            playSkillService:HandleBeHit(TT, beHitParam)
        end
    )
    return taskid
end

function PlayGridRangeBeHitInstruction:_GetFinalAttackIndex(damageResultArray)
    if not damageResultArray then
        return -1
    end
    for i = #damageResultArray, 1, -1 do
        local result = damageResultArray[i]
        local targetId = result:GetTargetID()
        if targetId ~= nil and targetId > 0 then
            return i
        end
    end
    return -1
end
