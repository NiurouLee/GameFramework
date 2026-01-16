require "play_skill_flight_base_r"
--@class PlaySkillTurnRoundFlightVehiclePhase: Object
_class("PlaySkillTurnRoundFlightVehiclePhase", PlaySkillPhaseBase)
PlaySkillTurnRoundFlightVehiclePhase = PlaySkillTurnRoundFlightVehiclePhase
function PlaySkillTurnRoundFlightVehiclePhase:Constructor()
    self._bBack = false
end

function PlaySkillTurnRoundFlightVehiclePhase:_GetGridList(pet_entity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = pet_entity:SkillRoutine():GetResultContainer()
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local ret = scopeResult:GetAttackRange()
    return ret
end
---@param casterEntity Entity
function PlaySkillTurnRoundFlightVehiclePhase:PlayFlight(TT, casterEntity, phaseParam)
    local chainGrid = self:_GetGridList(casterEntity)
    if (chainGrid == nil) then
        return
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --提取施法位置
    local castPos = casterEntity:GetRenderGridPosition()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()

    self._bBack = false

    --获得攻击范围的排序
    local targetGirdList, _, maxGridCount = InnerGameSortGridHelperRender:SortGrid(gridDataArray, castPos)

    --不卡流程 新起协程
    for dir = 1, 8 do
        local targetGird = targetGirdList[dir]
        if #targetGird.gridList > 0 then
            local nTaskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                self._DoCrossToGridEdges,
                self,
                casterEntity,
                targetGird,
                phaseParam
            )
        end
    end
end

function PlaySkillTurnRoundFlightVehiclePhase:_DoCrossToGridEdges(TT, casterEntity, targetGird, phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local gridPosStart = casterEntity:GridLocation().Position
    local gridPosEnd = targetGird.gridList[#targetGird.gridList]

    local distance = Vector2.Distance(gridPosStart, gridPosEnd)

    --总的飞行时间
    local flyTime = phaseParam:GetFlyTime()
    local flyBackTime = phaseParam:GetFlyBackTime()

    --飞行一格的时间
    local flyOneGridTime = flyTime / distance
    local flyBackOneGridTime = flyBackTime / distance

    local hitAnimName = phaseParam:GetHitAnimName()
    local hitEffectID = phaseParam:GetHitEffectID()

    ---检查这个方向上面的伤害结果
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local results1 = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, 1)
    for _, result in pairs(results1) do
        local targetEntityID = result:GetTargetID()
        local pos = result:GetGridPos()
        if table.intable(targetGird.gridList, pos) then
            GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    local hitTime = Vector2.Distance(pos, gridPosStart) * flyOneGridTime
                    YIELD(TT, hitTime)
                    local targetDamage = result:GetDamageInfo(1)
                    self:_PlayAttackOnPos(TT, casterEntity, pos, targetEntityID, targetDamage, hitAnimName, hitEffectID)
                end
            )
        end
    end

    local results2 = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, 2)
    for _, result in pairs(results2) do
        local targetEntityID = result:GetTargetID()
        local pos = result:GetGridPos()

        if table.intable(targetGird.gridList, pos) then
            GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    local hitTime = Vector2.Distance(pos, gridPosEnd) * flyBackOneGridTime
                    local backWaitTime = phaseParam:GetFlyBackStartWaitTime() + flyTime
                    YIELD(TT, hitTime + backWaitTime)
                    local targetDamage = result:GetDamageInfo(1)
                    self:_PlayAttackOnPos(TT, casterEntity, pos, targetEntityID, targetDamage, hitAnimName, hitEffectID)
                end
            )
        end
    end

    --飞出去的特效
    local entityEffect =
        effectService:CreateWorldPositionDirectionEffect(
        phaseParam:GetFlyEffectID(),
        gridPosStart,
        targetGird.direction
    )
    YIELD(TT)
    local go = entityEffect:View():GetGameObject()
    local tran = go.transform
    --目标坐标
    local gridWorldpos = boardServiceRender:GridPos2RenderPos(gridPosEnd)
    tran:DOMove(gridWorldpos, phaseParam:GetFlyTime() / 1000.0, false):SetEase(DG.Tweening.Ease.InOutSine)

    YIELD(TT, phaseParam:GetFlyTime())

    GameGlobal.TaskManager():CoreGameStartTask(
        self._DestroyEffect,
        self,
        entityEffect,
        phaseParam:GetFlyArriveDestory()
    )

    --飞回来前等待的时间
    YIELD(TT, phaseParam:GetFlyBackStartWaitTime())

    self._bBack = true

    --飞回来的特效
    local entityEffectBack =
        effectService:CreateWorldPositionDirectionEffect(
        phaseParam:GetFlyBackEffectID(),
        gridPosEnd,
        -targetGird.direction
    )
    YIELD(TT)
    local goBack = entityEffectBack:View():GetGameObject()
    local tranBack = goBack.transform
    --目标坐标
    local gridWorldposBack = boardServiceRender:GridPos2RenderPos(gridPosStart)
    tranBack:DOMove(gridWorldposBack, phaseParam:GetFlyBackTime() / 1000.0, false):SetEase(DG.Tweening.Ease.InOutSine)

    YIELD(TT, phaseParam:GetFlyBackTime())

    self._world:DestroyEntity(entityEffectBack)
end

function PlaySkillTurnRoundFlightVehiclePhase:_PlayAttackOnPos(
    TT,
    casterEntity,
    pos,
    targetEntityID,
    targetDamage,
    hitAnimName,
    hitEffectID)
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if targetEntity ~= nil then
        local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
        local finalAttackTargetID = skillEffectResultContainer:GetFinalAttackEntityID()
        local skillID = skillEffectResultContainer:GetSkillID()
        --如果攻击的目标是最后一击，去的时候不能播放最后一击
        if isFinalAttack == true and finalAttackTargetID == targetEntityID then
            if self._bBack ~= nil and not self._bBack then
                isFinalAttack = false
            end
        end

        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(hitAnimName)
            :SetHandleBeHitParam_HitEffectID(hitEffectID)
            :SetHandleBeHitParam_DamageInfo(targetDamage)
            :SetHandleBeHitParam_DamagePos(pos)
            :SetHandleBeHitParam_HitTurnTarget(TurnToTargetType.Caster)
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
            :SetHandleBeHitParam_SkillID(skillID)

        self:SkillService():HandleBeHit(TT, beHitParam)
    end
end

function PlaySkillTurnRoundFlightVehiclePhase:_DestroyEffect(TT, effectEntity, waitTime)
    YIELD(TT, waitTime)

    self._world:DestroyEntity(effectEntity)
end
