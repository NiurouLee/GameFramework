require("base_ins_r")
---@class PlayTrainAttackInstruction: BaseInstruction
_class("PlayTrainAttackInstruction", BaseInstruction)
PlayTrainAttackInstruction = PlayTrainAttackInstruction

function PlayTrainAttackInstruction:Constructor(paramList)
    ---攻击
    self._attackCount =  tonumber(paramList["AttackCount"])
    self._oneDamageTime = tonumber(paramList["OneDamageTime"])
    self._randomPercent = tonumber(paramList["RandomPercent"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTrainAttackInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type Vector2
    local castPos = casterEntity:GridLocation().Position
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    --检测是否有攻击目标 没有就返回
    if damageResultArray == nil then
        return
    end
    --根据格子进行分组
    self._formatList = {}
    ---t
    ---t.damageResult   伤害结果
    ---t.attackCount    这个格子被攻击几次
    ---t.effectEntityIDList   对应特效
    ---t.damageInfoList   拆成多个表现伤害
    ---t.damageStageValueList   伤害数值的数组
    ---t.playDamage   开始播放伤害
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    for _, v in ipairs(damageResultArray) do
        local format = {}
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        ---单体伤害只有一个
        local damageInfo = damageResult:GetDamageInfo(1)
        local damagePos = damageResult:GetGridPos()

        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity then
            format.damageResult = damageResult
            format.attackCount = self._attackCount
            format.playDamage = false
            --获取多段伤害列表
            local damageInfoList, damageStageValueList =
            utilCalcSvc:DamageInfoSplitMultiStage(damageInfo, self._attackCount, 1, self._randomPercent)
            format.damageInfoList = damageInfoList
            format.damageStageValueList = damageStageValueList
            table.insert(self._formatList, format)
        end
    end

    --有伤害结果，但是没有实际造成伤害
    if table.count(self._formatList) == 0 then
        return
    end
    local listTask = {}
    for i, format in ipairs(self._formatList) do
        local nTask,nTaskDamage = self:PlayDamage(casterEntity,format)
        table.insert(listTask, nTask)
        table.insert(listTask, nTaskDamage)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
        YIELD(TT)
    end
end

function PlayTrainAttackInstruction:PlayDamage(casterEntity,curFormat)
    local damageResult = curFormat.damageResult
    local damageInfo = damageResult:GetDamageInfo(1)
    local damageInfoList = curFormat.damageInfoList
    local damageStageValueList = curFormat.damageStageValueList
    --纯表现 伤害为格子伤害
    for i = 1, #damageInfoList do
        damageInfoList[i]:SetShowType(DamageShowType.Grid)
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local damageGridPos = damageResult:GetGridPos()
    -- local targetId = damageInfo:GetTargetEntityID()
    local targetId = damageResult:GetTargetID()
    local targetEntity = self._world:GetEntityByID(targetId)
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    local nTask =
    GameGlobal.TaskManager():CoreGameStartTask(
            playSkillService.HandleBeHitMultiStage,
            playSkillService,
            casterEntity,
            targetEntity,
            "Hit",
            nil,
            damageInfoList,
            damageGridPos,
            0,
            isFinalAttack,
            skillID,
            damageStageValueList,
            self._oneDamageTime
    )

    local nTaskDamage =
    GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                local intervalCount = table.count(damageStageValueList) - 1

                YIELD(TT, self._oneDamageTime * intervalCount)

                --血条刷新
                playDamageSvc:UpdateTargetHPBar(TT, targetEntity, damageInfo)
                --血量变化的buff通知表现
                playDamageSvc:_OnHpChangeNotifyBuff(TT, targetEntity, damageInfo:GetChangeHP(), damageInfo)
            end
    )
    return nTask,nTaskDamage
end