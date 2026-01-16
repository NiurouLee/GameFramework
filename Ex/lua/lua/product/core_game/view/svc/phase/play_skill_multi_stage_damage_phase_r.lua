require "play_skill_phase_base_r"

_class("PlaySkillMultiStageDamagePhase", PlaySkillPhaseBase)
---@class PlaySkillMultiStageDamagePhase: Object
PlaySkillMultiStageDamagePhase = PlaySkillMultiStageDamagePhase

function PlaySkillMultiStageDamagePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseMultiStageDamageParam
    local effectParam = phaseParam
    local turnToTarget = effectParam:GetTurnToTarget()
    local hitAnimName = effectParam:GetHitAnimName()
    local hitEffectID = effectParam:GetHitEffectID()
    local stageCount = effectParam:GetStageCount()
    local intervalTime = effectParam:GetIntervalTime()
    local random = effectParam:GetRandom()
    local randomPercent = effectParam:GetRandomPercent()

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
        skillEffectResultContainer:SetFinalAttackEntityID(targetEntityID)
    end

    --检测是否有攻击目标 没有就返回
    if damageResultArray == nil then
        return
    end
    local hasTargetDamageResultArray = {}
    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity then
            table.insert(hasTargetDamageResultArray, damageResult)
        end
    end
    --有伤害结果，但是没有实际造成伤害
    if table.count(hasTargetDamageResultArray) == 0 then
        return
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    local listTask = {}
    for i = 1, table.count(hasTargetDamageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = hasTargetDamageResultArray[i]
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        local nTargetID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(nTargetID)
        local damageGridPos = damageResult:GetGridPos()

        --获取多段伤害列表
        local damageInfoList, damageStageValueList =
            utilCalcSvc:DamageInfoSplitMultiStage(damageInfo, stageCount, random, randomPercent)

        ---调用统一处理被击的逻辑
        local nTask =
            GameGlobal.TaskManager():CoreGameStartTask(
            playSkillService.HandleBeHitMultiStage,
            playSkillService,
            casterEntity,
            targetEntity,
            hitAnimName,
            hitEffectID,
            damageInfoList,
            damageGridPos,
            turnToTarget,
            isFinalAttack,
            skillID,
            damageStageValueList,
            intervalTime
        )

        table.insert(listTask, nTask)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
        YIELD(TT)
    end
end

---按照距离玩家远近来判定最后一击
---返回最远的那个目标的ID
function PlaySkillMultiStageDamagePhase:_SortDistanceForFinalAttack(castPos, damageResultArray)
    local function CmpDistancefunc(res1, res2)
        local dis1 = math.abs(castPos.x - res1:GetGridPos().x) + math.abs(castPos.y - res1:GetGridPos().y)
        local dis2 = math.abs(castPos.x - res2:GetGridPos().x) + math.abs(castPos.y - res2:GetGridPos().y)

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
