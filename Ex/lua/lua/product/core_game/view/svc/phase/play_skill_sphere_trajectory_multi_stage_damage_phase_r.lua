require "play_skill_phase_base_r"

_class("PlaySkillSphereTrajectoryMultiStageDamagePhase", PlaySkillPhaseBase)
---@class PlaySkillSphereTrajectoryMultiStageDamagePhase: Object
PlaySkillSphereTrajectoryMultiStageDamagePhase = PlaySkillSphereTrajectoryMultiStageDamagePhase

function PlaySkillSphereTrajectoryMultiStageDamagePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseSphereTrajectoryMultiStageDamageParam
    local effectParam = phaseParam
    local eftID = effectParam:GetEftID()
    local trajectoryCount = effectParam:GetTrajectoryCount()
    local sphereRadius = effectParam:GetSphereRadius()
    local startWait = effectParam:GetStartWait()
    self._moveSpeed = effectParam:GetMoveSpeed()
    self._rotateSpeed = effectParam:GetRotateSpeed()
    --
    self._turnToTarget = effectParam:GetTurnToTarget()
    self._hitAnimName = effectParam:GetHitAnimName()
    self._hitEffectID = effectParam:GetHitEffectID()
    self._intervalTime = effectParam:GetIntervalTime()
    self._hitSoundID = effectParam:GetHitSoundID()
    local random = effectParam:GetRandom()
    local randomPercent = effectParam:GetRandomPercent()

    local listTask = {}

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    --检测是否有攻击目标 没有就返回
    if damageResultArray == nil then
        return
    end

    --设置最远的怪物是最后一击
    -- local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    -- if isFinalAttack then
    --     local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
    --     skillEffectResultContainer:SetFinalAttackEntityID(targetEntityID)
    -- end

    ----

    --根据格子进行分组
    self._formatList = {}
    ---t
    ---t.damageResult   伤害结果
    ---t.attackCount    这个格子被攻击几次
    ---t.effectEntityIDList   对应特效
    ---t.damageInfoList   拆成多个表现伤害
    ---t.damageStageValueList   伤害数值的数组
    ---t.playDamage   开始播放伤害

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
            format.attackCount = 1
            format.effectEntityIDList = {}
            format.playDamage = false

            table.insert(self._formatList, format)
        end
    end

    --有伤害结果，但是没有实际造成伤害
    if table.count(self._formatList) == 0 then
        return
    end

    --计算范围的中心点
    local skillResult = skillEffectResultContainer
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local skillRange = scopeResult:GetAttackRange()
    local rangeCount = table.count(skillRange)
    local scopeTotal = Vector2(0, 0)
    for i = 1, rangeCount do
        scopeTotal = scopeTotal + skillRange[i]
    end
    local scopeCenterPos = Vector2(scopeTotal.x / rangeCount, scopeTotal.y / rangeCount)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local sphereCenterPos = boardServiceRender:GridPos2RenderPos(scopeCenterPos)

    local damageResultArrayCount = table.count(damageResultArray)
    --伤害结果和配置弹道数  最大的就是弹道数量
    local needAttackCount = math.max(damageResultArrayCount, trajectoryCount)

    --需要补充的攻击次数
    --如果没有伤害目标，  技能结果数量1    有伤害的数量0
    local needSupplementAttackCount = needAttackCount - table.count(self._formatList)

    --为每个逻辑伤害结果，添加表现的攻击次数
    for i = 1, needSupplementAttackCount do
        local random = math.random(1, damageResultArrayCount)
        self._formatList[random].attackCount = self._formatList[random].attackCount + 1
    end

    --攻击次数最多的是最后一击
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        -- local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
        local attackCountLargest = 0
        local targetEntityIDLargest = 0
        for i = 1, table.count(self._formatList) do
            local format = self._formatList[i]
            local attackCount = format.attackCount
            if attackCount > attackCountLargest then
                attackCountLargest = attackCount
                local damageResult = format.damageResult
                local damageInfo = damageResult:GetDamageInfo(1)
                targetEntityIDLargest = damageInfo:GetTargetEntityID()
            end
        end

        skillEffectResultContainer:SetFinalAttackEntityID(targetEntityIDLargest)
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    --将每一个伤害拆成多段伤害表现
    for i = 1, table.count(self._formatList) do
        local format = self._formatList[i]
        local attackCount = format.attackCount
        local damageResult = format.damageResult
        local damageInfo = damageResult:GetDamageInfo(1)
        --获取多段伤害列表
        local damageInfoList, damageStageValueList =
            utilCalcSvc:DamageInfoSplitMultiStage(damageInfo, attackCount, random, randomPercent)
        format.damageInfoList = damageInfoList
        format.damageStageValueList = damageStageValueList
    end

    local eftEntityList = {} --特效实体数组
    local eftTargetPosList = {} --特效目标坐标数组

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    --创建特效在一个球面上
    for i = 1, needAttackCount do
        local randomDir = math.random(0, 360)
        local tmpX = math.cos(randomDir * 3.14 / 180) * sphereRadius
        local tmpZ = math.sin(randomDir * 3.14 / 180) * sphereRadius
        local tmpY = math.random() * 2 + 0.5 --高度是0.5 ~ 2.5 之间
        local randomPos = Vector3(tmpX, tmpY, tmpZ)
        local dir = randomPos - sphereCenterPos
        local workPos = sphereCenterPos + (dir.normalized * sphereRadius)
        ---@type Entity
        local eftEntity = effectService:CreatePositionEffect(eftID, workPos)
        --加入特效列表
        table.insert(eftEntityList, eftEntity)

        for i = 1, table.count(self._formatList) do
            local format = self._formatList[i]
            if table.count(format.effectEntityIDList) < format.attackCount then
                table.insert(format.effectEntityIDList, eftEntity:GetID())

                local renderGridPos = boardServiceRender:GridPos2RenderPos(format.damageResult:GetGridPos())
                table.insert(eftTargetPosList, renderGridPos)
                break
            end
        end
    end

    if not eftEntityList[table.count(eftEntityList)]:HasView() then
        YIELD(TT)
    end

    for i = 1, table.count(eftEntityList) do
        local eftTansform = eftEntityList[i]:View():GetGameObject().transform
        --朝向中心点
        -- local dir = sphereCenterPos - eftTansform.position
        --不加偏移是0/180，直线不转
        local offset = Vector3(math.random(), -math.random(), math.random())
        --先朝向外面
        local dir = (eftTansform.position + offset) - sphereCenterPos
        eftEntityList[i]:SetDirection(dir)
    end

    -----------------------------------------------------------------------------

    ---等待特效动画成型
    YIELD(TT, startWait)

    --计算的
    self:_TransformTrajectory(TT, eftEntityList, eftTargetPosList, casterEntity)

    -- local nTask =
    --     GameGlobal.TaskManager():CoreGameStartTask(
    --     self._TransformTrajectory,
    --     self,
    --     eftEntityList,
    --     eftTargetPosList,
    --     casterEntity
    -- )
    -- table.insert(listTask, nTask)

    -- while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
    --     YIELD(TT)
    -- end
end

function PlaySkillSphereTrajectoryMultiStageDamagePhase:_TransformTrajectory(
    TT,
    eftEntityList,
    eftTargetPosList,
    casterEntity)
    local moveSpeed = self._moveSpeed / 30 --移动速度
    local moveSpeedMin = 1 --移动速度
    local moveSpeedMax = moveSpeed --移动速度
    local rotateSpeed = self._rotateSpeed / 30 --旋转速度

    local lastFrameNormalizedList = {} --上一帧的向量
    local finalAngleList = {} --开始前需要旋转的角度
    for i = 1, table.count(eftEntityList) do
        local eftEntity = eftEntityList[i]
        local eftTansform = eftEntity:View():GetGameObject().transform
        local lastFrameNormalized = eftTansform.forward
        table.insert(lastFrameNormalizedList, lastFrameNormalized)

        local finalForwardBefore = (eftTargetPosList[i] - eftTansform.position).normalized
        local finalAngle = Vector3.Angle(eftTansform.forward, finalForwardBefore) --总旋转角度
        table.insert(finalAngleList, finalAngle)
    end

    local listTask = {}
    local farmCount = 0
    while table.count(eftEntityList) > 0 do
        for i = 1, table.count(eftEntityList) do
            -- for i = 1, 1 do
            local eftEntity = eftEntityList[i]
            local endPos = eftTargetPosList[i]
            local finalAngle = finalAngleList[i]
            local lastFrameNormalized = lastFrameNormalizedList[i]
            local eftTansform = eftEntity:View():GetGameObject().transform

            local finalForward = (endPos - eftTansform.position).normalized
            --如果当前向量 不等 最终向量
            if finalForward ~= eftTansform.forward then
                --旋转慢
                -- local angleOffset = Vector3.Angle(eftTansform.forward, finalForward)
                -- local t = rotateSpeed / angleOffset / 30
                -- eftTansform.forward = Vector3.Lerp(eftTansform.forward, finalForward, t)
                -- moveSpeed = (angleOffset / 180 * moveSpeedMax) + moveSpeedMin

                --新
                local angleOffset = Vector3.Angle(eftTansform.forward, finalForward)
                local t = (farmCount * rotateSpeed) / finalAngle
                eftTansform.forward = Vector3.Lerp(lastFrameNormalized, finalForward, t)
            else
                moveSpeed = moveSpeed + 5
            end

            --移动
            local changeSpeed = moveSpeed / 30
            eftTansform.position =
                eftTansform.position +
                Vector3(
                    eftTansform.forward.x * changeSpeed,
                    eftTansform.forward.y * changeSpeed,
                    eftTansform.forward.z * changeSpeed
                )
        end

        for i = 1, table.count(eftEntityList) do
            local eftEntity = eftEntityList[i]
            local eftTansform = eftEntity:View():GetGameObject().transform
            lastFrameNormalizedList[i] = eftTansform.forward
        end

        farmCount = farmCount + 1

        --所有的运动一帧后
        YIELD(TT)

        --删除到达的特效
        for i = table.count(eftEntityList), 1, -1 do
            local eftEntity = eftEntityList[i]
            local eftTansform = eftEntity:View():GetGameObject().transform
            local endPos = eftTargetPosList[i]
            local currentDist = Vector3.Distance(eftTansform.position, endPos)

            if currentDist < 0.7 or eftTansform.position.y < 0 then
                AudioHelperController.PlayInnerGameSfx(self._hitSoundID)
                table.remove(eftEntityList, i)
                table.remove(eftTargetPosList, i)
                table.remove(finalAngleList, i)
                table.remove(lastFrameNormalizedList, i)

                local nTask, nTaskDamage = self:_TrajectoryFinish(eftEntity, casterEntity)
                if nTask and nTask > 0 then
                    table.insert(listTask, nTask)
                    table.insert(listTask, nTaskDamage)
                end
            end
        end

        --
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
        YIELD(TT)
    end
end

function PlaySkillSphereTrajectoryMultiStageDamagePhase:_TrajectoryFinish(eftEntity, casterEntity)
    local curFormat = nil

    for i = 1, table.count(self._formatList) do
        local format = self._formatList[i]
        --这个结果还没有播放
        if not format.playDamage and table.intable(format.effectEntityIDList, eftEntity:GetID()) then
            curFormat = format
            format.playDamage = true
        end
    end

    self._world:DestroyEntity(eftEntity)

    if not curFormat then
        return
    end

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

    -- local listTask = {}
    local nTask =
        GameGlobal.TaskManager():CoreGameStartTask(
        playSkillService.HandleBeHitMultiStage,
        playSkillService,
        casterEntity,
        targetEntity,
        self._hitAnimName,
        self._hitEffectID,
        damageInfoList,
        damageGridPos,
        self._turnToTarget,
        isFinalAttack,
        skillID,
        damageStageValueList,
        self._intervalTime
    )

    local nTaskDamage =
        GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            local intervalCount = table.count(damageStageValueList) - 1

            YIELD(TT, self._intervalTime * intervalCount)

            --血条刷新
            playDamageSvc:UpdateTargetHPBar(TT, targetEntity, damageInfo)

            --血量变化的buff通知表现
            playDamageSvc:_OnHpChangeNotifyBuff(TT, targetEntity, damageInfo:GetChangeHP(), damageInfo)
        end
    )

    return nTask, nTaskDamage

    -- table.insert(listTask, nTask)
    -- while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
    --     YIELD(TT)
    -- end
end

---按照距离玩家远近来判定最后一击
---返回最远的那个目标的ID
function PlaySkillSphereTrajectoryMultiStageDamagePhase:_SortDistanceForFinalAttack(castPos, damageResultArray)
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
