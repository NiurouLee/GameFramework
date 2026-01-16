require "play_skill_phase_base_r"
--@class PlaySkillSquareRingPhase: Object
_class("PlaySkillScopeForwardPhase", PlaySkillPhaseBase)
PlaySkillScopeForwardPhase = PlaySkillScopeForwardPhase

function PlaySkillScopeForwardPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseScopeForwardParam
    local scopeForwardParam = phaseParam
    local gridEffectID = scopeForwardParam:GetGridEffectID()
    local bestEffectTime = scopeForwardParam:GetBestEffectTime()
    local gridIntervalTime = scopeForwardParam:GetGridIntervalTime()
    local hasDamage = scopeForwardParam:HasDamage()
    local hasConvert = scopeForwardParam:HasConvert()
    local hitAnimationName = scopeForwardParam:GetHitAnimationName()
    local hitEffectID = scopeForwardParam:GetHitEffectID()
    local effectDirection = scopeForwardParam:GetEffectDirection()
    

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position

    --支持 反向、根据点击格子数反向
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    local pickNum
    if renderPickUpComponent then
        pickNum = renderPickUpComponent:GetAllValidPickUpGridPosCount()
    end
    local bBackward = scopeForwardParam:IsBackward(pickNum)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()
    local targetGridType = nil
    local convertGridList = {}
    if hasConvert then
        ---@type SkillConvertGridElementEffectResult
        local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
        targetGridType = convertResult:GetTargetElementType()
        convertGridList = convertResult:GetTargetGridArray()
    end

    local targetGirdList, _, maxGridCount = InnerGameSortGridHelperRender:SortGrid(gridDataArray, castPos)

    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
        local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
        skillEffectResultContainer:SetFinalAttackEntityID(targetEntityID)
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    local tConvertInfo = {}
    local tnConvertTaskID = {}
    local tidHitTask = {}

    for i = 1, maxGridCount do
        for dir = 1, 8 do
            local t = targetGirdList[dir]
            local gridIndex = i
            if bBackward then --反向 从各方向最远处开始
                gridIndex = #(t.gridList) - (i - 1)
            end
            if gridIndex > 0 and #(t.gridList) >= gridIndex then
                local gridPos = t.gridList[gridIndex]
                ---转色范围可能跟伤害范围不同
                if hasConvert and table.icontains(convertGridList, gridPos) then
                    local oldGridType = PieceType.None
                    local gridEntity = pieceService:FindPieceEntity(gridPos)
                    ---@type PieceComponent
                    local pieceCmpt = gridEntity:Piece()
                    oldGridType = pieceCmpt:GetPieceType()

                    local convertInfo = NTGridConvert_ConvertInfo:New(gridPos, oldGridType, targetGridType)
                    table.insert(tConvertInfo, convertInfo)
                    local tid =
                        GameGlobal.TaskManager():CoreGameStartTask(
                        self:SkillService()._SingleGridEffect,
                        self:SkillService(),
                        gridEffectID,
                        gridPos,
                        bestEffectTime,
                        targetGridType
                    )
                    table.insert(tnConvertTaskID, tid)
                else
                    --self._world:GetService("Effect"):CreateWorldPositionEffect(gridEffectID, gridPos)
                    local gridDir = t.direction + self:_GetDirection(effectDirection)
                    self._world:GetService("Effect"):CreateWorldPositionDirectionEffect(
                        gridEffectID,
                        gridPos,
                        t.direction + self:_GetDirection(effectDirection)
                    )
                end
                if hasDamage then
                    local damageResult =
                        skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, gridPos)
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
        end
        if i ~= maxGridCount then
            YIELD(TT, gridIntervalTime)
        end
    end
    local finishDelayTime = scopeForwardParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
    --通知出现水格子表现
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")

    while not TaskHelper:GetInstance():IsAllTaskFinished(tnConvertTaskID) do
        YIELD(TT)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(tidHitTask) do
        YIELD(TT)
    end

    local nt = NTGridConvert:New(casterEntity, tConvertInfo)
    nt:SetConvertEffectType(SkillEffectType.ConvertGridElement)

    svcPlayBuff:PlayBuffView(TT, nt)
end

function PlaySkillScopeForwardPhase:_ShowDamage(
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

---@return Vector2
function PlaySkillScopeForwardPhase:_GetDirection(effectDirection)
    if effectDirection == "Bottom" then
        return Vector2(0, -1)
    elseif effectDirection == "Up" then
        return Vector2(0, 0)
    elseif effectDirection == "Left" then
        return Vector2(1, 0)
    elseif effectDirection == "Right" then
        return Vector2(-1, 0)
    else
        return Vector2(0, 0)
    end
end

---按照距离玩家远近来判定最后一击
---返回最远的那个目标的ID
function PlaySkillScopeForwardPhase:_SortDistanceForFinalAttack(castPos, damageResultArray)
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

function PlaySkillScopeForwardPhase:_CalcDistanceToCaster(castPos, skillDamageResult)
    local gridPos = skillDamageResult:GetGridPos()
    return Vector2.Distance(gridPos, castPos)
end
