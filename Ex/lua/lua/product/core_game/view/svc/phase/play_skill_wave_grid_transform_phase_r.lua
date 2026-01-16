--[[
    PlaySkillWaveGridTransformPhase 逻辑与PlaySkillWaveGridArrayPhase完全相同，只是格子特效增加旋转和缩放
]]
require "play_skill_phase_base_r"

---@class PlaySkillWaveGridTransformPhase: PlaySkillPhaseBase
_class("PlaySkillWaveGridTransformPhase", PlaySkillPhaseBase)
PlaySkillWaveGridTransformPhase = PlaySkillWaveGridTransformPhase

function PlaySkillWaveGridTransformPhase:PlayFlight(TT, casterEntity, phaseParam)
    --Log.fatal("_PlayWaveGridArrayPhase")
    ---@type SkillPhaseWaveGridArrayParam
    local waveGridArrayParam = phaseParam
    local columnInternalTime = waveGridArrayParam:GetColumnInternalTime()
    -- local waveGridEffectID = waveGridArrayParam:GetGridEffectID()
    local hitAnimName = waveGridArrayParam:GetHitAnimName()
    local hitEffectID = waveGridArrayParam:GetHitEffectID()
    local gridEffectWaitTime = waveGridArrayParam:GetGridWaitEffectTime()
    local hitWaitTime = waveGridArrayParam:GetHitWaitTime()

    --提取施法位置
    local castPos = casterEntity:GridLocation().Position
    local taskIDList = {}

    local finalDamageColumn = -1
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local isFinalDamage = skillEffectResultContainer:IsFinalAttack()
    --Log.fatal('wave grid array phase is final attack=',isFinalDamage, 'petentity id=',casterEntity:GetID())
    if isFinalDamage == true then
        finalDamageColumn = self:_FindLastDamageColumn(casterEntity, castPos)
    end

    --先播角色这一列的特效
    self:_HandlePlayColumnEffect(
        casterEntity,
        castPos.x,
        nil,
        hitAnimName,
        hitEffectID,
        hitWaitTime,
        taskIDList,
        false,
        finalDamageColumn,
        phaseParam
    )
    if columnInternalTime > 0 then
        YIELD(TT, columnInternalTime)
    end

    --开始向两边延展
    local leftColumn = castPos.x - 1
    local rightColumn = castPos.x + 1

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local area = casterEntity:AttackArea():GetAttackArea()
    local leftColumnValid = boardServiceRender:CheckColumnBoundary(leftColumn, area)
    local rightColumnValid = boardServiceRender:CheckColumnBoundary(rightColumn, area)

    while leftColumnValid or rightColumnValid do
        if leftColumnValid then
            self:_HandlePlayColumnEffect(
                casterEntity,
                leftColumn,
                nil,
                hitAnimName,
                hitEffectID,
                hitWaitTime,
                taskIDList,
                true,
                finalDamageColumn,
                phaseParam
            )
        end

        if rightColumnValid then
            self:_HandlePlayColumnEffect(
                casterEntity,
                rightColumn,
                nil,
                hitAnimName,
                hitEffectID,
                hitWaitTime,
                taskIDList,
                false,
                finalDamageColumn,
                phaseParam
            )
        end

        leftColumn = leftColumn - 1
        rightColumn = rightColumn + 1
        leftColumnValid = boardServiceRender:CheckColumnBoundary(leftColumn, area)
        rightColumnValid = boardServiceRender:CheckColumnBoundary(rightColumn, area)

        if columnInternalTime > 0 then
            YIELD(TT, columnInternalTime)
        end

        --Log.fatal("leftColumn ",leftColumn,"rightColumn ",rightColumn)
    end

    YIELD(TT, gridEffectWaitTime)

    local notFinished = true
    while notFinished do
        notFinished = false
        for i = 1, #taskIDList do
            if not TaskHelper:GetInstance():IsTaskFinished(taskIDList[i]) then
                notFinished = true
                break
            end
        end
        if notFinished then
            YIELD(TT)
        end
    end
    --Log.fatal("_PlayWaveGridArrayPhase end ")
end
function PlaySkillWaveGridTransformPhase:_HandlePlayColumnEffect(
    casterEntity,
    columnVal,
    gridEffectID,
    hitAnimName,
    hitEffectID,
    hitWaitTime,
    taskIDList,
    isLeft,
    finalDamageColumn,
    phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local scope = skillEffectResultContainer:GetScopeResult()
    local gridData = scope:GetAttackRange()
    local results = skillEffectResultContainer:GetEffectResultsAsPosDic(SkillEffectType.Damage)

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---静帧开始时机
    local finalAttackTargetEntityID = -1
    if columnVal == finalDamageColumn then
        ---这里需要改下，找出这一列的一个目标
        finalAttackTargetEntityID = self:_FindFinalAttackTarget(gridData, columnVal, results)
    end

    for _, pos in ipairs(gridData) do
        if pos.x == columnVal then
            if boardServiceRender:IsInPlayerArea(pos) then
                local effectDir = Vector2(0, 0)
                if isLeft then
                    effectDir = Vector2(0, -1)
                end

                local effID, dir, scale =
                    self:_CalculateEffDirAndScale(casterEntity:GridLocation().Position, pos, phaseParam)
                local effEntity = self._world:GetService("Effect"):CreateTransformEffect(effID, pos, dir, scale)

                if results then
                    local res = results[Vector2.Pos2Index(pos)]
                    if res then
                        local targetEntityID = res:GetTargetID()
                        --起task支持延时的受击配置
                        taskIDList[#taskIDList + 1] =
                            GameGlobal.TaskManager():CoreGameStartTask(
                            function(TT)
                                if hitWaitTime and hitWaitTime > 0 then
                                    YIELD(TT, hitWaitTime)
                                end
                                local targetEntity = self._world:GetEntityByID(targetEntityID)
                                local targetDamage = res:GetDamageInfo(1)

                                ---调用统一处理被击的逻辑
                                local isFinalAttack = false
                                if targetEntityID == finalAttackTargetEntityID then
                                    isFinalAttack = true
                                end

                                ---调用统一处理被击的逻辑
                                local beHitParam = HandleBeHitParam:New()
                                    :SetHandleBeHitParam_CasterEntity(casterEntity)
                                    :SetHandleBeHitParam_TargetEntity(targetEntity)
                                    :SetHandleBeHitParam_HitAnimName(hitAnimName)
                                    :SetHandleBeHitParam_HitEffectID(hitEffectID)
                                    :SetHandleBeHitParam_DamageInfo(targetDamage)
                                    :SetHandleBeHitParam_DamagePos(pos)
                                    :SetHandleBeHitParam_HitTurnTarget(phaseParam:HitTurnToTarget())
                                    :SetHandleBeHitParam_DeathClear(false)
                                    :SetHandleBeHitParam_IsFinalHit(isFinalAttack)
                                    :SetHandleBeHitParam_SkillID(skillID)

                                self:SkillService():HandleBeHit(TT, beHitParam)
                            end
                        )
                    end
                end
            end
        end
    end
end

--计算最后带伤害的一列
---@param casterEntity Entity
---@param castPos Vector2
---@return number
function PlaySkillWaveGridTransformPhase:_FindLastDamageColumn(casterEntity, castPos)
    local lastDamageColumn = -1
    local isDamageColumn = self:_IsDamageColumn(casterEntity, castPos.x)
    if isDamageColumn == true then
        lastDamageColumn = castPos.x
    end

    --开始向两边延展
    local leftColumn = castPos.x - 1
    local rightColumn = castPos.x + 1
    local area = casterEntity:AttackArea():GetAttackArea()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local leftColumnValid = boardServiceRender:CheckColumnBoundary(leftColumn, area)
    local rightColumnValid = boardServiceRender:CheckColumnBoundary(rightColumn, area)

    while leftColumnValid == true or rightColumnValid == true do
        if leftColumnValid then
            isDamageColumn = self:_IsDamageColumn(casterEntity, leftColumn)
            if isDamageColumn == true then
                lastDamageColumn = leftColumn
            end
        end

        if rightColumnValid then
            isDamageColumn = self:_IsDamageColumn(casterEntity, rightColumn)
            if isDamageColumn == true then
                lastDamageColumn = rightColumn
            end
        end

        leftColumn = leftColumn - 1
        rightColumn = rightColumn + 1

        leftColumnValid = boardServiceRender:CheckColumnBoundary(leftColumn, area)
        rightColumnValid = boardServiceRender:CheckColumnBoundary(rightColumn, area)
    end

    return lastDamageColumn
end

function PlaySkillWaveGridTransformPhase:_IsDamageColumn(casterEntity, column)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local results = skillEffectResultContainer:GetEffectResultsAsPosDic(SkillEffectType.Damage)
    if nil == results then
        return false
    end
    local scope = skillEffectResultContainer:GetScopeResult()
    local gridData = scope:GetAttackRange()

    ---@type AttackGridData
    for _, pos in ipairs(gridData) do
        if pos.x == column then
            if self:_IsDamagePos(pos, results) then
                return true
            end
        end
    end

    return false
end

function PlaySkillWaveGridTransformPhase:_IsDamagePos(pos, results)
    if nil == results then
        return false
    end
    local res = results[Vector2.Pos2Index(pos)]
    if not res then
        return false
    end

    local targetEntityID = res:GetTargetID()
    local damage = res:GetDamageInfo(1)
    if targetEntityID == nil or damage == nil then
        return false
    end

    if targetEntityID > 0 and damage:GetDamageValue() > 0 then
        return true
    end
end

function PlaySkillWaveGridTransformPhase:_FindFinalAttackTarget(gridData, columnVal, results)
    if results == nil then
        return
    end

    local victimIDArray = {}

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    for _, pos in ipairs(gridData) do
        if pos.x == columnVal then
            --Log.fatal("Grid x ",k.x," y ",k.y," ID ",gridEffectID)

            if boardServiceRender:IsInPlayerArea(pos) then
                local res = results[Vector2.Pos2Index(pos)]
                if res then
                    local targetEntityID = res:GetTargetID()
                    victimIDArray[#victimIDArray + 1] = targetEntityID
                end
            end
        end
    end

    local playerEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = playerEntity:GridLocation().Position

    local function CmpDistancefunc(entityID1, entityID2)
        local entity1 = self._world:GetEntityByID(entityID1)
        local entity2 = self._world:GetEntityByID(entityID2)

        local pos1 = entity1:GridLocation().Position
        local pos2 = entity2:GridLocation().Position
        local castPos = playerPos
        local dis1 = Vector2.Distance(castPos, pos1)
        local dis2 = Vector2.Distance(castPos, pos2)
        return dis1 > dis2
    end
    table.sort(victimIDArray, CmpDistancefunc)

    if #victimIDArray > 0 then
        return victimIDArray[1]
    end
end

---@param phaseParam SkillPhaseWaveGridTransformParam
function PlaySkillWaveGridTransformPhase:_CalculateEffDirAndScale(castPos, effPos, phaseParam)
    local dir = nil
    local scale = nil
    local effID = nil
    local delta = effPos - castPos

    --eft
    if delta.x == 0 or delta.y == 0 then
        --十字方向
        effID = phaseParam:GetCrossGridEffectID()
    else
        --斜方向
        effID = phaseParam:GetOtherGridEffectID()
    end

    --direction
    -- local euler = Quaternion.LookRotation(Vector3(delta.x, 0, delta.y)).eulerAngles
    dir = Vector2.Normalize(delta)

    --scale
    local layer = math.max(math.abs(delta.x), math.abs(delta.y))
    local defaultScale = phaseParam:GetEffDefaultScale()
    local deltaScale = phaseParam:GetEffLayerScale()
    local _scale = defaultScale + layer * deltaScale
    scale = Vector3(_scale, _scale, _scale)

    return effID, dir, scale
end
