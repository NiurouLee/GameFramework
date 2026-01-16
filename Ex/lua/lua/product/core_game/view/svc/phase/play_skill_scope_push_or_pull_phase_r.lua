require "play_skill_phase_base_r"
_class("PlaySkillScopePushOrPullPhase", PlaySkillPhaseBase)
PlaySkillScopePushOrPullPhase = PlaySkillScopePushOrPullPhase

function PlaySkillScopePushOrPullPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseScopePushOrPullParam
    local scopePushOrPullParam = phaseParam
    local gridEffectID = scopePushOrPullParam:GetBornEffectID()

    local bornEffectID = scopePushOrPullParam:GetBornEffectID()
    local bornEffectDelayTime = scopePushOrPullParam:GetBornEffectDelayTime()

    local moveEffectID = scopePushOrPullParam:GetMoveEffectID()
    local moveEffectDelayTime = scopePushOrPullParam:GetMoveEffectDelayTime()
    local moveEffectSpeed = scopePushOrPullParam:GetEffectFlyOneGridMs()

    local disappearEffectID = scopePushOrPullParam:GetDisappearEffectID()
    local disappearEffectTime = scopePushOrPullParam:GetDisappearEffectTime()

    local hasDamage = scopePushOrPullParam:HasDamage()
    local hasConvert = scopePushOrPullParam:HasConvert()
    local hitAnimationName = scopePushOrPullParam:GetHitAnimationName()
    local hitEffectID = scopePushOrPullParam:GetHitEffectID()
    local effectDirection = scopePushOrPullParam:GetEffectDirection()

    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position
    self._casterPos = castPos
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    local checkPush = false
    local checkPull = false
    
    local pickCount = 0
    if renderPickUpComponent then
        pickCount = renderPickUpComponent:GetAllValidPickUpGridPosCount()
    end
    if pickCount == 0 then
        checkPush = true
    elseif pickCount == 1 then
        checkPull = true
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()
    local targetGridType = nil
    local convertGridList = {}
    
    --8方向 近及远
    local targetGirdList, _, maxGridCount = InnerGameSortGridHelperRender:SortGrid(gridDataArray, castPos)

    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()
    if isFinalAttack then
        local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
        local targetEntityID = self:_SortDistanceForFinalAttack(castPos, damageResultArray)
        skillEffectResultContainer:SetFinalAttackEntityID(targetEntityID)
    end

    self._beAttackPos = {}

    local tidHitTask = {}

    local effBornGridList={}
    local effEndGridList={}
    for dir = 1, 8 do
        local dirGrids = targetGirdList[dir]
        if #dirGrids.gridList > 0 then
            local bornGrid,endGrid = self:_CalEffBornEndGrid(dirGrids,castPos,checkPush,checkPull)
            if bornGrid then
                effBornGridList[dir] = bornGrid
            end
            if endGrid then
                effEndGridList[dir] = endGrid
            end
        end
    end
    --出生特效
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    for dir = 1, 8 do
        local bornGrid = effBornGridList[dir]
        if bornGrid then
            local effDir = self:_CalEffDir(bornGrid,castPos,checkPush,checkPull)
            effectService:CreateWorldPositionDirectionEffect(
                        bornEffectID,
                        bornGrid,
                        effDir + self:_GetDirection(effectDirection)
                    )
        end
    end
    YIELD(TT, moveEffectDelayTime)
    --特效移动
    local effInfoList = {}
    for dir = 1, 8 do
        local bornGrid = effBornGridList[dir]
        if bornGrid then
            local effDir = self:_CalEffDir(bornGrid,castPos,checkPush,checkPull)
            local effEntity = effectService:CreateWorldPositionDirectionEffect(
                        moveEffectID,
                        bornGrid,
                        effDir + self:_GetDirection(effectDirection)
                    )
            local effInfo = {}
            effInfo.entity = effEntity
            effInfo.effStartPos = bornGrid
            effInfo.effEndPos = effEndGridList[dir]
            effInfoList[dir] = effInfo
        end
    end
    local effFlyTaskID =
        GameGlobal.TaskManager():CoreGameStartTask(
        self._StartEffectFly,
        self,
        casterEntity,
        castPos,
        effInfoList,
        scopePushOrPullParam,
        castPos
    )
    while not TaskHelper:GetInstance():IsAllTaskFinished({effFlyTaskID}) do
        YIELD(TT)
    end
    YIELD(TT, disappearEffectTime)
end

---@return Vector2
function PlaySkillScopePushOrPullPhase:_GetDirection(effectDirection)
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
function PlaySkillScopePushOrPullPhase:_SortDistanceForFinalAttack(castPos, damageResultArray,checkPush,checkPull)
    local function CmpDistancefuncPush(skillDamageEffectResult1, skillDamageEffectResult2)
        local dis1 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult1)
        local dis2 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult2)

        return dis1 > dis2
    end
    local function CmpDistancefuncPull(skillDamageEffectResult1, skillDamageEffectResult2)
        local dis1 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult1)
        local dis2 = self:_CalcDistanceToCaster(castPos, skillDamageEffectResult2)

        return dis1 < dis2
    end
    if checkPush then
        table.sort(damageResultArray, CmpDistancefuncPush)
    elseif checkPull then
        table.sort(damageResultArray, CmpDistancefuncPull)
    end

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

function PlaySkillScopePushOrPullPhase:_CalcDistanceToCaster(castPos, skillDamageResult)
    local gridPos = skillDamageResult:GetGridPos()
    return Vector2.Distance(gridPos, castPos)
end
function PlaySkillScopePushOrPullPhase:_CalEffBornEndGrid(dirGrids, castPos,checkPush,checkPull)
    local startIndex
    local stopIndex
    local indexStep
    if checkPush then
        startIndex = 1
        stopIndex = #(dirGrids.gridList)
        indexStep = 1
    elseif checkPull then
        startIndex = #(dirGrids.gridList)
        stopIndex = 1
        indexStep = -1
    else
        return
    end
     ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local bornPos
    local stopPos
    for i = startIndex, stopIndex, indexStep do
        local pos = dirGrids.gridList[i]
        local isPieceOnBoard = 
        utilDataSvc:IsValidPiecePos(pos) and 
        not utilDataSvc:IsPosBlock(pos, BlockFlag.Skill | BlockFlag.SkillSkip)
        if isPieceOnBoard then
            if not bornPos then
                bornPos = pos
            end
            stopPos = pos
        else
            break
        end
    end
    return bornPos,stopPos
end
function PlaySkillScopePushOrPullPhase:_CalEffDir(bornGrid,castPos,checkPush,checkPull)
    if checkPush then
        return bornGrid - castPos
    elseif checkPull then
        return castPos - bornGrid
    end
end

---@param phaseParam SkillPhaseLineFlyWithDirectionParam
function PlaySkillScopePushOrPullPhase:_StartEffectFly(
    TT,
    castEntity,
    worldPos,
    effInfoList,
    phaseParam,
    castPos)
    local flyOneGridMs = phaseParam:GetEffectFlyOneGridMs()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    YIELD(TT)
    local atklist = ArrayList:New()
    for k, v in pairs(effInfoList) do
        local effectEntity = v.entity
        if effectEntity ~= nil then
            --local gridpos = v.gridpos
            local endPos = v.effEndPos
            local startPos = v.effStartPos
            local go = effectEntity:View():GetGameObject()
            local tran = go.transform
            v.tran = go.transform

            ---@type Vector3
            local gridWorldpos = boardServiceRender:GridPos2RenderPos(endPos)
            local disx = math.abs(endPos.x - startPos.x)
            local disy = math.abs(endPos.y - startPos.y)
            local dis = math.max(disx, disy)
            v.FinalWorldPos = gridWorldpos
            Log.notice(
                "[skill] PlaySkillService:_StartEffectFly from ",
                startPos.x,
                startPos.y,
                " to ",
                endPos.x,
                endPos.y
            )
            self:_EffectMove(tran, gridWorldpos, dis, flyOneGridMs)
        end
    end
    self:_CheckFlyAttack(TT, effInfoList, boardServiceRender, castEntity, phaseParam, atklist)
end
---@param phaseParam SkillPhaseLineFlyWithDirectionParam
---@param boardServiceRender BoardServiceRender
function PlaySkillScopePushOrPullPhase:_CheckFlyAttack(
    TT,
    effInfoList,
    boardServiceRender,
    casterEntity,
    phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local flyOneGridMs = phaseParam:GetEffectFlyOneGridMs()
    local hitAnimName = phaseParam:GetHitAnimationName()
    local hitEffectID = phaseParam:GetHitEffectID()
    local continue = true
    while continue do
        continue = false
        for k, v in pairs(effInfoList) do
            local effectEntity = v.entity
            if effectEntity ~= nil then
                continue = true
                local tran = v.tran
                local flypos = boardServiceRender:BoardRenderPos2GridPos(tran.position)
                if v.flypos ~= flypos then
                    if phaseParam:HasDamage() then
                        self:_HandlePlayFlyAttack(
                            casterEntity,
                            flypos,
                            hitAnimName,
                            hitEffectID,
                            phaseParam:HitTurnToTarget()
                        ) 
                    end
                    v.flypos = flypos
                end
                if tran.position == v.FinalWorldPos then

                    local effectDirection = phaseParam:GetEffectDirection()
                    local effDir = v.effEndPos - v.effStartPos
                    local effEntity = effectService:CreateWorldPositionDirectionEffect(
                        phaseParam:GetDisappearEffectID(),
                        flypos,
                        effDir + self:_GetDirection(effectDirection)
                    )

                    local go = effectEntity:View():GetGameObject()
                    go:SetActive(false)
                    self._world:DestroyEntity(effectEntity)
                    v.entity = nil
                    
                end
            end
        end
        YIELD(TT)
    end
end

function PlaySkillScopePushOrPullPhase:_GetFlyTime(maxLength, flyOneGridMs)
    return flyOneGridMs * maxLength
end
function PlaySkillScopePushOrPullPhase:_EffectMove(tran, gridWorldPos, disGrid, flyOneGridMs)
    tran:DOMove(gridWorldPos, (disGrid * flyOneGridMs) / 1000.0):SetEase(DG.Tweening.Ease.InOutSine)
    --tran:DOMove(gridWorldPos, (disx * flyOneGridMs) / 1000.0):SetEase(DG.Tweening.Ease.InOutSine):OnComplete(
    --    function()
    --        v.needDestroy =true
    --    end
    --)
end
function PlaySkillScopePushOrPullPhase:_HandlePlayFlyAttack(
    casterEntity,
    flypos,
    hitAnimName,
    hitEffectID,
    hitTurnToTarget)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local results = skillEffectResultContainer:GetEffectResultsAsPosDic(SkillEffectType.Damage)

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if not results then
        return
    end

    for posIdx, res in pairs(results) do
        local pos = Vector2.Index2Pos(posIdx)
        if self:IsAttackDataNeedBeHit(flypos, pos) then
            if boardServiceRender:IsInPlayerArea(pos) then
                local targetEntityID = res:GetTargetID()
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                if targetEntity ~= nil then
                    local targetDamage = res:GetDamageInfo(1)
                    Log.debug("[skill] PlaySkillService:_HandlePlayFlyAttack ", targetEntityID, hitAnimName)

                    ---调用统一处理被击的逻辑
                    local beHitParam = HandleBeHitParam:New()
                        :SetHandleBeHitParam_CasterEntity(casterEntity)
                        :SetHandleBeHitParam_TargetEntity(targetEntity)
                        :SetHandleBeHitParam_HitAnimName(hitAnimName)
                        :SetHandleBeHitParam_HitEffectID(hitEffectID)
                        :SetHandleBeHitParam_DamageInfo(targetDamage)
                        :SetHandleBeHitParam_DamagePos(flypos)
                        :SetHandleBeHitParam_HitTurnTarget(hitTurnToTarget)
                        :SetHandleBeHitParam_DeathClear(false)
                        :SetHandleBeHitParam_IsFinalHit(skillEffectResultContainer:IsFinalAttack())
                        :SetHandleBeHitParam_SkillID(skillID)

                    --启动被击者受击动画
                    local damageTextPos = targetEntity:GridLocation().Position
                    GameGlobal.TaskManager():CoreGameStartTask(
                        self:SkillService().HandleBeHit,
                        self:SkillService(),
                        beHitParam
                    )
                end
            end
        end
    end
end

function PlaySkillScopePushOrPullPhase:CompPos2Caster(flyPos, resultPos, dir)
    if dir == Vector2(0, 1) or dir == Vector2(1, 1) or dir == Vector2(-1, 1) then
        return flyPos.y >= resultPos.y
    elseif dir == Vector2(1, 0) then
        return flyPos.x >= resultPos.x
    elseif dir == Vector2(0, -1) or dir == Vector2(-1, -1) or dir == Vector2(1, -1) then
        return flyPos.y <= resultPos.y
    elseif dir == Vector2(-1, 0) then
        return flyPos.x <= resultPos.x
    else
        return false
    end
end

function PlaySkillScopePushOrPullPhase:IsAttackDataNeedBeHit(flyPos, resultPos)
    local flyDir = Vector2.Normalize(flyPos - self._casterPos)
    local resultDir = Vector2.Normalize(resultPos - self._casterPos)
    flyDir = self:_GetBaseDir(flyDir)
    resultDir = self:_GetBaseDir(resultDir)
    ---同方向并且没播放过
    if flyDir.x == resultDir.x and flyDir.y == resultDir.y and not self:IsPosBeAttack(resultPos) then
        if self:CompPos2Caster(flyPos, resultPos, flyDir) then
            table.insert(self._beAttackPos, resultPos)
            return true
        end
    end
    return false
end
function PlaySkillScopePushOrPullPhase:_GetBaseDir(oriDir)
    local dir = oriDir
    if dir.x > 0 then
        dir.x = 1
    end
    if dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    end
    if dir.y < 0 then
        dir.y = -1
    end
    return dir
end

---判断坐标是否被打过
function PlaySkillScopePushOrPullPhase:IsPosBeAttack(pos)
    for i, v in ipairs(self._beAttackPos) do
        if v.x == pos.x and v.y == pos.y then
            return true
        end
    end
    return false
end