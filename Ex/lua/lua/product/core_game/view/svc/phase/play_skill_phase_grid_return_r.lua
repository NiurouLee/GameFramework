--[[------------------------------------------------------------------------------------------
    2020-02-20 韩玉信添加
    PlaySkillPhase_GridReturn : 随机打击
]] --------------------------------------------------------------------------------------------
require "play_skill_phase_base_r"

---@class PlaySkillPhase_GridReturn: PlaySkillPhaseBase
_class("PlaySkillPhase_GridReturn", PlaySkillPhaseBase)
PlaySkillPhase_GridReturn = PlaySkillPhase_GridReturn

---@param casterEntity Entity
function PlaySkillPhase_GridReturn:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParam_GridReturn
    local workParam = phaseParam
    local listGridPos = {}
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if SkillPhaseParam_GridReturn_TargetType.Damage == workParam:GetTargetType() then ---有BUG没有调试完成 2020-02-20
        ---@type SkillDamageEffectResult
        local skillResultArray = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)
        local listEntity = {}
        if skillResultArray and (#skillResultArray > 0) then
            for k, res in pairs(skillResultArray) do
                local targetEntityID = res:GetTargetID()
                ---@type Entity
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                if false == table.icontains(listEntity, targetEntity) then
                    listEntity[#listEntity + 1] = targetEntity
                    listGridPos[#listGridPos + 1] = targetEntity:GetGridPosition() --res:GetGridPos()
                end
            end
        end
    elseif SkillPhaseParam_GridReturn_TargetType.RandAttack == workParam:GetTargetType() then
        ---@type SkillEffectResult_RandAttack
        local skillResultArray = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RandAttack)
        if not skillResultArray then
            return
        end
        local listDeathPos = skillResultArray:GetListDeathPos()
        for i = 1, #listDeathPos do
            listGridPos[#listGridPos + 1] = listDeathPos[i]
        end
    elseif SkillPhaseParam_GridReturn_TargetType.AllRangeGrid == workParam:GetTargetType() then
        ---@type SkillScopeResult
        local scopeResult = skillEffectResultContainer:GetScopeResult()
        listGridPos = scopeResult:GetAttackRange()
    end

    if #listGridPos <= 0 then
        return
    end
    GameGlobal.TaskManager():CoreGameStartTask(
        self._skillService.PlayCastAudio,
        self._skillService,
        workParam:GetAudioID(),
        workParam:GetAudioWaitTime()
    )
    --施法者动作
    local castAnimation, castEffectID, castDelayTime = workParam:GetCastAnimationEffect()
    self:_PlayAnimationEffect(TT, casterEntity, castAnimation, castEffectID, castDelayTime)

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --提取施法位置
    ---@param castPos UnityEngine.Vector3
    local castPos = casterEntity:Location().Position --:GetGridPosition()
    local gridEffectID = workParam:GetGridEffectID()

    ---出生特效
    local bornEffectID = workParam:GetBornEffectID()
    if bornEffectID and bornEffectID > 0 then
        for k, v in pairs(listGridPos) do
            local renderPos = boardServiceRender:GridPos2RenderPos(v)
            local effectEntity = effectService:CreatePositionEffect(bornEffectID, renderPos)
        end
    end
    self:_DelayTime(TT, workParam:GetBornEffectTime())

    ---弹道特效
    local ballHigh = workParam:GetStartHigh()
    local effectEntityList = {}
    for k, v in pairs(listGridPos) do
        local renderPos = boardServiceRender:GridPos2RenderPos(v)
        renderPos.y = renderPos.y + ballHigh
        local effectEntity = effectService:CreatePositionEffect(gridEffectID, renderPos)
        table.insert(effectEntityList, {entity = effectEntity, position = renderPos, gridPos = v})
        Log.debug(
            "[Grid_Return]特效：GridPos = (" ..
                v.x ..
                    "," .. v.y .. "), RenderPos = (" .. renderPos.x .. "," .. renderPos.y .. "," .. renderPos.z .. ")"
        )
    end
    YIELD(TT)

    local nTrajectoryType = workParam:GetTrajectoryType()

    local taskIDs = {}
    for k, v in pairs(effectEntityList) do
        local view = v.entity:View()
        local go = view:GetGameObject()
        local curTaskID = 0
        if 1 == nTrajectoryType then ---直线
            curTaskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                self._DoFlyLine,
                self,
                v.entity,
                casterEntity,
                v.gridPos,
                phaseParam
            )
        elseif 2 == nTrajectoryType then ---螺旋曲线
            curTaskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                self._DoSpiral,
                self,
                v.entity,
                casterEntity,
                v.gridPos,
                phaseParam
            )
        end
        if curTaskID > 0 then
            taskIDs[#taskIDs + 1] = curTaskID
        end
        YIELD(TT)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
    self:_PlayAnimationEffect(TT, casterEntity, nil, workParam:GetEndEffectID(), 0)
    self:_DelayTime(TT, workParam:GetFinishDelayTime())
end

---@param phaseParam SkillPhaseParam_GridReturn
function PlaySkillPhase_GridReturn:_GetTotalFlyTime(posCaster, posEffect, phaseParam)
    local nTotalTime = phaseParam:GetFlyTotalTime()
    if nil == nTotalTime or 0 == nTotalTime then
        local nDistance = Vector2.Distance(posCaster, posEffect)
        nTotalTime = phaseParam:GetFlySpeed() * nDistance
    end
    return nTotalTime
end

---@param phaseParam SkillPhaseParam_GridReturn
---@param casterEntity Entity
function PlaySkillPhase_GridReturn:_DoSpiral(TT, effectEntity, casterEntity, posEffectGrid, phaseParam)
    local deltaAngle = phaseParam:GetDeltaAngle()

    ---@type ViewComponent
    local effectViewCmpt = effectEntity:View()
    ---@type UnityEngine.GameObject
    local effectGo = effectViewCmpt:GetGameObject()
    local effectPos = effectGo.transform.position
    local effectHeight = effectPos.y

    ---@type ViewComponent
    local casterViewCmpt = casterEntity:View()
    ---@type UnityEngine.GameObject
    local casterGo = casterViewCmpt:GetGameObject()
    local casterPos = casterGo.transform.position
    local totalTime = self:_GetTotalFlyTime(casterEntity:GetGridPosition(), posEffectGrid, phaseParam)

    local startValue = Vector3.Distance(effectPos, casterPos)
    local deltaRotation = Quaternion.AngleAxis(deltaAngle, Vector3.up)

    local curTime = totalTime

    while curTime > 0 do
        local curEffectDir = Vector3.Normalize(effectPos - casterPos)

        local deltaTime = self._timeService:GetDeltaTimeMs()
        curTime = curTime - deltaTime
        local curDistance = curTime / totalTime * startValue

        local curEffectPos = deltaRotation * curEffectDir * curDistance + casterPos
        curEffectPos.y = effectHeight

        effectGo.transform.position = curEffectPos
        effectPos = curEffectPos
        YIELD(TT)
    end

    effectGo:SetActive(false)
    self._world:DestroyEntity(effectEntity)
end

---直线飞行
---@param phaseParam SkillPhaseParam_GridReturn
---@param entityEffect Entity
---@param entityCaster Entity
function PlaySkillPhase_GridReturn:_DoFlyLine(TT, entityEffect, entityCaster, posEffectGrid, phaseParam)
    local posCaster = entityCaster:GetGridPosition()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type ViewComponent
    local effectViewCmpt = entityEffect:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()

    local posEffect = effectObject.transform.position
    local nTotalTime = self:_GetTotalFlyTime(posCaster, posEffectGrid, phaseParam)

    local nFlyTime = nTotalTime / 1000.0
    local endtime = GameGlobal:GetInstance():GetCurrentTime() + nTotalTime

    local transWork = effectObject.transform
    local gridWorldpos = boardServiceRender:GridPos2RenderPos(posCaster)
    gridWorldpos.y = gridWorldpos.y + phaseParam:GetEndHigh()
    local easeWork = transWork:DOMove(gridWorldpos, nFlyTime, false):SetEase(DG.Tweening.Ease.InOutSine)

    ---等待飞行结束
    while GameGlobal:GetInstance():GetCurrentTime() < endtime do
        YIELD(TT)
    end
    effectObject:SetActive(false)
    self._world:DestroyEntity(entityEffect)
end
