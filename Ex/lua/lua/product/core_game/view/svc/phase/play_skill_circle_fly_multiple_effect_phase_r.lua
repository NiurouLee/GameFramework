require "play_skill_phase_base_r"

_class("PlaySkillCircleFlyMultipleEffectPhase", PlaySkillPhaseBase)
---@class PlaySkillCircleFlyMultipleEffectPhase: Object
PlaySkillCircleFlyMultipleEffectPhase = PlaySkillCircleFlyMultipleEffectPhase

function PlaySkillCircleFlyMultipleEffectPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseCircleFlyMultipleEffectParam
    local effectParam = phaseParam

    local radius = effectParam:GetRadius()
    local effectHigh = effectParam:GetHigh()
    local gridEffectID = effectParam:GetGridEffectID()
    local flyEffectID = effectParam:GetFlyEffectID()
    local hitEffectID = effectParam:GetHitEffectID()
    local waitFlyTime = effectParam:GetWaitFlyTime()
    local flyTime = effectParam:GetFlyTime()
    local angleInterval = effectParam:GetAngle()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

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

    local hasTargetDamageResultArray = {}
    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity then
            table.insert(hasTargetDamageResultArray, damageResult)
        end
    end
    --有伤害结果，但是没有实际造成伤害
    if table.count(hasTargetDamageResultArray) == 0 then
        return
    end

    ------------
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local casterPos = casterEntity:GridLocation():GetGridPos()
    local casterRenderPos = casterEntity:Location():GetPosition() --模型世界坐标
    local casterTansform = casterEntity:View():GetGameObject().transform --星灵模型

    local tmpTableSortDataList = {}
    for _, v in ipairs(hasTargetDamageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local damagePos = damageResult:GetGridPos()
        local effectRenderPos = boardServiceRender:GridPos2RenderPos(damagePos)
        --当前的向量
        local curNormalized = (effectRenderPos - casterRenderPos).normalized

        local finalAngle = Vector3.Angle(casterTansform.forward, curNormalized)
        local finalAngle360
        local v3 = Vector3.Cross(casterTansform.forward, curNormalized)
        if v3.y > 0 then
            finalAngle360 = finalAngle
        else
            finalAngle360 = 360 - finalAngle
        end

        local tmpTableSortData = {}
        tmpTableSortData.angle = finalAngle360
        tmpTableSortData.damageResult = damageResult
        tmpTableSortData.curNormalized = curNormalized

        table.insert(tmpTableSortDataList, tmpTableSortData)
    end

    table.sort(
        tmpTableSortDataList,
        function(a, b)
            return a.angle < b.angle
        end
    )
    local baseGridRenderPos = boardServiceRender:GetBaseGridRenderPos()
    local effectGridPosList = {}
    local damagePosList = {}
    local normalizedList = {} --已经有的向量
    for i = 1, #tmpTableSortDataList do
        local curNormalized = tmpTableSortDataList[i].curNormalized
        local damagePos = tmpTableSortDataList[i].damageResult:GetGridPos()
        --是否有在角度内的已有向量
        local hasNormalized = self:_OnCheckNormalizIsHas(normalizedList, curNormalized, angleInterval)
        if not hasNormalized then
            --没有重复的方向 直接添加
        else
            local lastNormalized = tmpTableSortDataList[i - 1].curNormalized
            local scondNormalized = lastNormalized * Quaternion.Euler(0, angleInterval, 0)
            tmpTableSortDataList[i].curNormalized = scondNormalized
            curNormalized = scondNormalized
        end

        --新的格子坐标位置=施法者坐标+新向量*半径
        local newEffectPosV3 = casterRenderPos + curNormalized * radius
        --转成v2用于创建特效
        local effectPosV2 = self:BoardRenderPos2FloatGridPos_New(newEffectPosV3,baseGridRenderPos)
        table.insert(normalizedList, curNormalized)
        table.insert(effectGridPosList, effectPosV2) --格子起点
        table.insert(damagePosList, damagePos) --目标点
    end

    --创建格子特效
    ---@type EffectService
    local effectService = world:GetService("Effect")
    local effectEntityList = {}
    for _, effectPos in ipairs(effectGridPosList) do
        ---@type Entity
        local effectEntity = effectService:CreatePositionEffect(gridEffectID, effectPos)
        table.insert(effectEntityList, effectEntity)
    end

    --等待一段时间后
    YIELD(TT, waitFlyTime)

    --创建飞行特效
    local flyEffectEntityList = {}
    for _, effectPos in ipairs(effectGridPosList) do
        local flyEffectPos = effectPos
        ---@type Entity
        local flyEffectEntity = effectService:CreatePositionEffect(flyEffectID, flyEffectPos)
        table.insert(flyEffectEntityList, flyEffectEntity)
    end

    while not flyEffectEntityList[#flyEffectEntityList]:View() do
        YIELD(TT)
    end

    --调整弹道特效高度
    for i = 1, #flyEffectEntityList do
        local effectEntity = flyEffectEntityList[i]
        local view = effectEntity:View()
        local effectTran = view:GetGameObject().transform
        effectTran.position = effectTran.position + Vector3(0, effectHigh, 0)
    end

    --删除格子特效
    for _, effectEntity in ipairs(effectEntityList) do
        world:DestroyEntity(effectEntity)
    end

    --飞向目标
    for i = 1, #flyEffectEntityList do
        local damagePos = damagePosList[i]
        local renderPos = boardServiceRender:GridPos2RenderPos(damagePos)
        local effectEntity = flyEffectEntityList[i]

        ---@type UnityEngine.Transform
        local effectTransform = effectEntity:View():GetGameObject().transform
        effectTransform:LookAt(renderPos, Vector3.up)
        effectTransform:DOMove(renderPos, flyTime / 1000):SetEase(DG.Tweening.Ease.Linear)
    end

    YIELD(TT, flyTime)
    for _, effectEntity in ipairs(flyEffectEntityList) do
        world:DestroyEntity(effectEntity)
    end

    --通用被击需要参数
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    ---@type PlaySkillService
    local skillService = self:SkillService()

    for i = 1, #hasTargetDamageResultArray do
        ---@type SkillDamageEffectResult
        local damageResult = hasTargetDamageResultArray[i]
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = world:GetEntityByID(targetEntityID)
        local damage = damageResult:GetDamageInfo(1)
        local damagePos = damageResult:GetGridPos()

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName("Hit")
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(damage)
            :SetHandleBeHitParam_DamagePos(damagePos)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)

        GameGlobal.TaskManager():CoreGameStartTask(
            skillService.HandleBeHit,
            skillService,
            beHitParam
        )
    end
end

function PlaySkillCircleFlyMultipleEffectPhase:_OnCheckNormalizIsHas(normalizedList, curNormalized, angleInterval)
    local hasNormalized
    for i = 1, #normalizedList do
        local normalized = normalizedList[i]

        --已经有的向量  和  本次向量做角度计算
        local finalAngle = Vector3.Angle(normalized, curNormalized)

        if finalAngle < angleInterval + 1 then
            hasNormalized = normalized
            break
        end
    end

    return hasNormalized

    -- if not hasNormalized then
    --     return nil, 0
    -- end

    -- local v3 = Vector3.Cross(hasNormalized, curNormalized)
    -- local dirThird = Vector3.Dot(Vector3.up, v3)
    -- local addAngle = angleInterval
    -- if dirThird < 0 then
    --     addAngle = -angleInterval
    -- else
    --     addAngle = angleInterval
    -- end

    -- return hasNormalized, addAngle
end

function PlaySkillCircleFlyMultipleEffectPhase:BoardRenderPos2FloatGridPos_New(pos,baseGridRenderPos)
    local render_pos_offset = pos - baseGridRenderPos
    local new_grid_pos = Vector3(1, 0, 1) + render_pos_offset
    return Vector2(new_grid_pos.x, new_grid_pos.z)
end
