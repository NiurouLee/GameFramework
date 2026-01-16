require "play_skill_phase_base_r"
---@class PlaySkillSinkAllTargetPhase: PlaySkillPhaseBase
_class("PlaySkillSinkAllTargetPhase", PlaySkillPhaseBase)
PlaySkillSinkAllTargetPhase = PlaySkillSinkAllTargetPhase

---@param phaseParam SkillPhaseParamSinkAllTarget
function PlaySkillSinkAllTargetPhase:PlayFlight(TT, casterEntity, phaseParam)
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if damageResultArray == nil then
        return
    end
    local damageResCount = #damageResultArray
    if damageResCount <= 0 then
        return
    end

    local posCaster = casterEntity:GetGridPosition()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")
    local effectId = phaseParam:GetEffectId()
    local effectScale = phaseParam:GetEffectScale()
    local intervalTime = phaseParam:GetIntervalTime()
    local listWaitTask = {}
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    for i = 1, damageResCount do
        ---@type SkillDamageEffectResult
        local damageResult = damageResultArray[i]
        local targetEntityId = damageResult:GetTargetID()
        if targetEntityId and targetEntityId > 0 then
            local targetEntity = world:GetEntityByID(targetEntityId)
            if targetEntity:HasTeam() then
                targetEntityId = targetEntity:GetTeamLeaderPetEntity()
            end
            --创建特效
            if effectId and effectId > 0 then
                ---@type Vector2 伤害中心
                local posDamageCenter = boardServiceRender:GetEntityRealTimeGridPos(targetEntity, true)
                local entityEffect =
                    effectService:CreateWorldPositionDirectionEffect(
                    effectId,
                    posDamageCenter,
                    posDamageCenter - posCaster
                )
                ---四格怪要求放大特效
                if entityEffect then
                    local nBodyAreaCount = targetEntity:BodyArea():GetAreaCount()
                    if nBodyAreaCount and 4 == nBodyAreaCount then
                        ---@type UnityEngine.Transform
                        local trajectoryObject = entityEffect:View():GetGameObject()
                        local transWork = trajectoryObject.transform
                        local scaleData = Vector3.New(effectScale, effectScale, effectScale)
                        ---@type DG.Tweening.Sequence
                        local sequence = transWork:DOScale(scaleData, 0)
                        local easeWork = sequence:SetEase(DG.Tweening.Ease.InOutSine)
                    end
                end
            end
        end
        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(self._SinkTarget, self, casterEntity, damageResult, phaseParam)
        listWaitTask[#listWaitTask + 1] = taskID
        YIELD(TT, intervalTime)
    end
    if listWaitTask and table.count(listWaitTask) > 0 then
        while not TaskHelper:GetInstance():IsAllTaskFinished(listWaitTask) do
            YIELD(TT)
        end
    end
end

---@param casterEntity Entity
---@param damageResult SkillDamageEffectResult
---@param phaseParam SkillPhaseParamSinkAllTarget
function PlaySkillSinkAllTargetPhase:_SinkTarget(TT, casterEntity, damageResult, phaseParam)
    local targetEntityId = damageResult:GetTargetID()
    if targetEntityId == nil or targetEntityId <= 0 then
        return
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityId)
    local nBodyAreaCount = targetEntity:BodyArea():GetAreaCount()
    local cantSink =
        targetEntity:View() and targetEntity:View():GetGameObject() and
        targetEntity:View():GetGameObject().name == "2903001"

    ---只有一格怪和四格怪才会被拖入地下
    local canSink = true
    if nBodyAreaCount < 1 or nBodyAreaCount > 4 or cantSink then
        canSink = false
    end
    local waitDownTime = phaseParam:GetWaitDownTime()
    local downDis = phaseParam:GetDownDistance()
    local downTime = phaseParam:GetDownTime()
    local waitTime = phaseParam:GetWaitTime()
    local upTime = phaseParam:GetUpTime()
    local waitDamageTime = phaseParam:GetWaitDamageTime()
    local hitEffectId = phaseParam:GetHitEffectId()
    local hitAnimName = phaseParam:GetHitAnimName()

    YIELD(TT, waitDownTime)

    ---@type UnityEngine.Vector3
    local gridWorldPos = targetEntity:GetPosition()
    local gridWorldNew = UnityEngine.Vector3.New()
    gridWorldNew.x = gridWorldPos.x
    gridWorldNew.y = gridWorldPos.y + downDis
    gridWorldNew.z = gridWorldPos.z
    if canSink then
        self:_ShowLineRenderer(world, casterEntity, false)
        self:_MoveEntity(TT, targetEntity, gridWorldNew, downTime)
        if not phaseParam:DoNotHideTarget() then -- phase初始需求是要隐藏，这个不隐藏是后加的
            ---隐藏目标
            self:_ShowEntity(world, targetEntity, false)
        end
    else
        YIELD(TT, downTime)
    end
    --等待
    YIELD(TT, waitTime)
    if canSink then
        if not phaseParam:DoNotHideTarget() then -- phase初始需求是要隐藏，这个不隐藏是后加的
            ---显示目标
            self:_ShowEntity(world, targetEntity, true)
        end
        --向上移动
        self:_MoveEntity(TT, targetEntity, gridWorldPos, upTime)
        self:_ShowLineRenderer(world, casterEntity, true)
    else
        YIELD(TT, upTime)
    end
    --等待伤害
    YIELD(TT, waitDamageTime)
    --播放伤害动画和被击特效
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(1)
    local damageGridPos = damageResult:GetGridPos()

    ---调用统一处理被击的逻辑
    local beHitParam = HandleBeHitParam:New()
        :SetHandleBeHitParam_CasterEntity(casterEntity)
        :SetHandleBeHitParam_TargetEntity(targetEntity)
        :SetHandleBeHitParam_HitAnimName(hitAnimName)
        :SetHandleBeHitParam_HitEffectID(hitEffectId)
        :SetHandleBeHitParam_DamageInfo(damageInfo)
        :SetHandleBeHitParam_DamagePos(damageGridPos)
        :SetHandleBeHitParam_HitTurnTarget(TurnToTargetType.None)
        :SetHandleBeHitParam_DeathClear(false)
        :SetHandleBeHitParam_IsFinalHit(skillEffectResultContainer:IsFinalAttack())
        :SetHandleBeHitParam_SkillID(skillID)

    playSkillService:HandleBeHit(TT, beHitParam)
end
---移动Entity
---@param entityCaster Entity
---@param worldPos UnityEngine.Vector3
---@param nMoveTime number  移动时长： 单位毫秒
function PlaySkillSinkAllTargetPhase:_MoveEntity(TT, entityWork, worldPos, moveTime)
    if nil == entityWork then
        return
    end
    if not entityWork:View() then
        return
    end
    ---@type UnityEngine.Transform
    local trajectoryObject = entityWork:View():GetGameObject()
    local transWork = trajectoryObject.transform
    local easeWork = transWork:DOMove(worldPos, moveTime / 1000, false):SetEase(DG.Tweening.Ease.InOutSine)
    YIELD(TT, moveTime)
end
---移动Entity
---@param entityCaster Entity
function PlaySkillSinkAllTargetPhase:_ShowEntity(world, entityWork, bShow)
    entityWork:SetUpToVisible(bShow)
    if not entityWork:HP() then
        return
    end
    local slider_entity_id = entityWork:HP():GetHPSliderEntityID()
    local slider_entity = world:GetEntityByID(slider_entity_id)
    if slider_entity then
        slider_entity:SetViewVisible(bShow)
    end
    -- targetEntity:View():GetGameObject():SetActive(false)
end

function PlaySkillSinkAllTargetPhase:_ShowLineRenderer(world, casterEntity, show)
    local monsterGroup = world:GetGroup(world.BW_WEMatchers.Trap)

    for i, entity in ipairs(monsterGroup:GetEntities()) do
        local effectID

        ---@type EffectLineRendererComponent
        local effectLineRenderer = entity:EffectLineRenderer()
        if effectLineRenderer then
            effectLineRenderer:SetEffectLineRendererShow(casterEntity:GetID(), show)

            effectID = effectLineRenderer:GetEffectLineRendererEffectID(casterEntity:GetID())
        end

        ---@type BuffViewComponent
        local buffView = entity:BuffView()
        local notOpenLineEffectObjName = buffView:GetBuffValue("NotOpenLineEffectObjName")

        ---@type EffectHolderComponent
        local effectHolderCmpt = entity:EffectHolder()
        if effectHolderCmpt then
            local effectList = effectHolderCmpt:GetPermanentEffect()

            for i, eff in ipairs(effectList) do
                local e = world:GetEntityByID(eff)
                if e and e:HasView() then
                    local go = e:View():GetGameObject()

                    local renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)

                    for i = 0, renderers.Length - 1 do
                        local line = renderers[i]
                        if line and (notOpenLineEffectObjName ~= line.gameObject.name) then
                            line.gameObject:SetActive(show)
                        end
                    end
                end
            end
        end
    end
end
