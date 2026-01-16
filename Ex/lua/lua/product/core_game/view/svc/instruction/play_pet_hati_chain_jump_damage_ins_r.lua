---@class PlayPetHatiChainJumpDamageInstruction:BaseInstruction
_class("PlayPetHatiChainJumpDamageInstruction", BaseInstruction)
PlayPetHatiChainJumpDamageInstruction = PlayPetHatiChainJumpDamageInstruction

function PlayPetHatiChainJumpDamageInstruction:Constructor(paramList)
    self._casterAnimateTrigger = paramList.casterAnimateTrigger
    self._hideEffectID = tonumber(paramList.hideEffectID)
    self._showEffectID = tonumber(paramList.showEffectID)
    self._mainEffTimeMs = tonumber(paramList.mainEffTimeMs)
    self._jumpTimeMs = tonumber(paramList.jumpTimeMs)
    self._landingTimeMs = tonumber(paramList.landingTimeMs)
    self._mainEffectID = tonumber(paramList.mainEffectID)
    self._resetPosEffectID = tonumber(paramList.resetPosEffectID)
    self._roundDamageDelayMs = tonumber(paramList.roundDamageDelayMs)
    self._roundEffDelayFromStartMs = tonumber(paramList.roundEffDelayFromStartMs)
    self._roundGridEffectID = tonumber(paramList.roundGridEffectID)
    self._damageToHideTimeMs = tonumber(paramList.damageToHideTimeMs)
    self._hideToEffTimeMs = tonumber(paramList.hideToEffTimeMs)
    self._resetPosTimeMs = tonumber(paramList.resetPosTimeMs)
end
function PlayPetHatiChainJumpDamageInstruction:_CacheEff(t,effID,count)
    local cacheCount = count or 1
    if effID and effID ~= 0 then
        table.insert(t, {Cfg.cfg_effect[effID].ResPath, cacheCount})
    end
end
function PlayPetHatiChainJumpDamageInstruction:GetCacheResource()
    local t = {}
    self:_CacheEff(t,self._hideEffectID,1)
    self:_CacheEff(t,self._showEffectID,1)
    self:_CacheEff(t,self._mainEffectID,1)
    self:_CacheEff(t,self._resetPosEffectID,1)
    self:_CacheEff(t,self._roundGridEffectID,8)
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPetHatiChainJumpDamageInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_DynamicCenterDamage[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DynamicCenterDamage) or {}
    local result = resultArray[1]
    if not result then
        return
    end

    ---@type SkillScopeResult
    local centerScope = result:GetDamageScope()
    local viewCenterPos = centerScope:GetCenterPos()

    --特效问题，伤害范围中，方形九格之外的位置需要额外播格子特效
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local mainCenterScope = scopeCalculator:ComputeScopeRange(SkillScopeType.Square, {1,1},viewCenterPos,{Vector2(0,0)})
    local mainCenterScopeRange = mainCenterScope:GetAttackRange()

    ---@type EffectService
    local effectService = world:GetService("Effect")
    --effectService:CreateCommonGridEffect(self._centerGridEffectID, viewCenterPos, casterEntity:GetRenderGridDirection())


    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    local playFinalAttack = playSkillService:GetFinalAttack(world, casterEntity, phaseContext)
    local skillID = skillEffectResultContainer:GetSkillID()

    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex() or 1
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex() or 1
    ---@type SkillDamageEffectResult[]
    local damageResults = result:GetDamageResults()

    local damageByPosIndex = {}

    for _, damageResult in ipairs(damageResults) do
        local target = damageResult:GetTargetID()
        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
        if (target and target > 0) and (damageInfo) then
            local eTarget = world:GetEntityByID(target)
            local damageGridPos = damageResult:GetGridPos()
            local posIndex = Vector2.Pos2Index(damageGridPos)
            if not damageByPosIndex[posIndex] then
                damageByPosIndex[posIndex] = {}
            end
            table.insert(damageByPosIndex[posIndex], damageResult)
        end
    end

    ---@type SkillScopeResult
    local damageScope = result:GetDamageScope()
    ---@type DataSortScopeGridRangeInstruction
    local scopeGridSort = DataSortScopeGridRangeInstruction:New({sortType = 1}) --借用里面的函数
    local res, maxGridCount = scopeGridSort:_SortGridNearToFar(damageScope:GetAttackRange(), viewCenterPos)

    local hasRoundRange =self:_CheckHasRoundRange(res,maxGridCount,mainCenterScopeRange)


    local viewPosition = casterEntity:GetRenderGridPosition()
    local viewDirection = casterEntity:GetRenderGridDirection()

    local turnDir = viewCenterPos - viewPosition
    casterEntity:SetDirection(turnDir)
    casterEntity:SetAnimatorControllerTriggers({self._casterAnimateTrigger})
    effectService:CreateEffect(self._hideEffectID, casterEntity)

    if hasRoundRange then
        --外围格子特效有延迟 从开始播
        local roundEffTaskID = GameGlobal.TaskManager():CoreGameStartTask(self._ShowRoundEff, self, world, res,maxGridCount,mainCenterScopeRange,viewCenterPos)
        phaseContext:AddPhaseTask(roundEffTaskID)
    end
    local roundEffTaskID = GameGlobal.TaskManager():CoreGameStartTask(self._ShowMainEff, self, world, viewCenterPos)
    phaseContext:AddPhaseTask(roundEffTaskID)
    -- YIELD(TT, self._mainEffTimeMs)
    -- effectService:CreateWorldPositionDirectionEffect(self._mainEffectID, viewCenterPos)
    YIELD(TT, self._jumpTimeMs)

    casterEntity:SetLocation(viewCenterPos)
    effectService:CreateEffect(self._showEffectID, casterEntity)
    YIELD(TT, self._landingTimeMs)
    
    
    --中间九格伤害 同时播
    -- PlayGridRangeEffect+PlayGridRangeBeHit 简化版
    for rangeIndex = 1, maxGridCount do
        for _, range in pairs(res) do
            if range then
                local posList = range[rangeIndex]
                if posList then
                    local len = table.count(posList)
                    for i = 1, len do
                        local pos = posList[i]
                        local targetPos = pos
                        if table.icontains(mainCenterScopeRange,targetPos) then
                            local posIndex = Vector2.Pos2Index(pos)
                            if damageByPosIndex[posIndex] then
                                local damageResultsAtPos = damageByPosIndex[posIndex]
                                for _, damageResult in ipairs(damageResultsAtPos) do
                                    local target = damageResult:GetTargetID()
                                    ---@type DamageInfo
                                    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
                                    if (target and target > 0) and (damageInfo) then
                                        local eTarget = world:GetEntityByID(target)
                                        local damageGridPos = damageResult:GetGridPos()
                                        local beHitParam = HandleBeHitParam:New()
                                                                        :SetHandleBeHitParam_CasterEntity(casterEntity)
                                                                        :SetHandleBeHitParam_TargetEntity(eTarget)
                                                                        :SetHandleBeHitParam_HitAnimName("hit")
                                                                        :SetHandleBeHitParam_HitEffectID(0)
                                                                        :SetHandleBeHitParam_DamageInfo(damageInfo)
                                                                        :SetHandleBeHitParam_DamagePos(damageGridPos)
                                                                        :SetHandleBeHitParam_HitTurnTarget(1)
                                                                        :SetHandleBeHitParam_DeathClear(0)
                                                                        :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
                                                                        :SetHandleBeHitParam_SkillID(skillID)
                                                                        :SetHandleBeHitParam_DamageIndex(curDamageIndex)
                                        local hitBackTaskID = TaskManager:GetInstance():CoreGameStartTask(playSkillService.HandleBeHit,playSkillService,beHitParam)
                                        phaseContext:AddPhaseTask(hitBackTaskID)
                                    end
                                end
                            end
                        else
                            hasRoundRange = true
                        end
                        -- effectService:CreateWorldPositionDirectionEffect(
                        --         self._damageGridEffectID,
                        --         targetPos,
                        --         targetPos - viewCenterPos
                        -- )

                        
                    end
                end
            end
        end
    end
    if hasRoundRange then
        --延迟后播外圈伤害
        YIELD(TT, self._roundDamageDelayMs)

        --外圈伤害
        for rangeIndex = 1, maxGridCount do
            for _, range in pairs(res) do
                if range then
                    local posList = range[rangeIndex]
                    if posList then
                        local len = table.count(posList)
                        for i = 1, len do
                            local pos = posList[i]
                            local targetPos = pos
                            if table.icontains(mainCenterScopeRange,targetPos) then
                            else
                                -- effectService:CreateWorldPositionDirectionEffect(
                                --         self._roundGridEffectID,
                                --         targetPos,
                                --         targetPos - viewCenterPos
                                -- )

                                local posIndex = Vector2.Pos2Index(pos)
                                if damageByPosIndex[posIndex] then
                                    local damageResultsAtPos = damageByPosIndex[posIndex]
                                    for _, damageResult in ipairs(damageResultsAtPos) do
                                        local target = damageResult:GetTargetID()
                                        ---@type DamageInfo
                                        local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)
                                        if (target and target > 0) and (damageInfo) then
                                            local eTarget = world:GetEntityByID(target)
                                            local damageGridPos = damageResult:GetGridPos()
                                            local beHitParam = HandleBeHitParam:New()
                                                                            :SetHandleBeHitParam_CasterEntity(casterEntity)
                                                                            :SetHandleBeHitParam_TargetEntity(eTarget)
                                                                            :SetHandleBeHitParam_HitAnimName("hit")
                                                                            :SetHandleBeHitParam_HitEffectID(0)
                                                                            :SetHandleBeHitParam_DamageInfo(damageInfo)
                                                                            :SetHandleBeHitParam_DamagePos(damageGridPos)
                                                                            :SetHandleBeHitParam_HitTurnTarget(1)
                                                                            :SetHandleBeHitParam_DeathClear(0)
                                                                            :SetHandleBeHitParam_IsFinalHit(playFinalAttack)
                                                                            :SetHandleBeHitParam_SkillID(skillID)
                                                                            :SetHandleBeHitParam_DamageIndex(curDamageIndex)
                                            local hitBackTaskID = TaskManager:GetInstance():CoreGameStartTask(playSkillService.HandleBeHit,playSkillService,beHitParam)
                                            phaseContext:AddPhaseTask(hitBackTaskID)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    YIELD(TT, self._damageToHideTimeMs)
    casterEntity:SetViewVisible(false)
    YIELD(TT, self._hideToEffTimeMs)
    --起点特效
    local resetPos = casterEntity:GetGridPosition()
    effectService:CreateWorldPositionDirectionEffect(self._resetPosEffectID, resetPos)
    YIELD(TT, self._resetPosTimeMs)
    casterEntity:SetViewVisible(true)
    casterEntity:SetLocation(viewPosition,viewDirection)
end
function PlayPetHatiChainJumpDamageInstruction:_CheckHasRoundRange(res,maxGridCount,mainCenterScopeRange)
    local hasRoundRange = false
    for rangeIndex = 1, maxGridCount do
        for _, range in pairs(res) do
            if range then
                local posList = range[rangeIndex]
                if posList then
                    local len = table.count(posList)
                    for i = 1, len do
                        local pos = posList[i]
                        local targetPos = pos
                        if not table.icontains(mainCenterScopeRange,targetPos) then
                            hasRoundRange = true
                            break
                        end
                    end
                    if hasRoundRange then
                        break
                    end
                end
            end
        end
        if hasRoundRange then
            break
        end
    end
    return hasRoundRange
end
function PlayPetHatiChainJumpDamageInstruction:_ShowRoundEff(TT,world,res,maxGridCount,mainCenterScopeRange,viewCenterPos)
    --外圈特效
    YIELD(TT, self._roundEffDelayFromStartMs)
    ---@type EffectService
    local effectService = world:GetService("Effect")
    --外圈伤害
    for rangeIndex = 1, maxGridCount do
        for _, range in pairs(res) do
            if range then
                local posList = range[rangeIndex]
                if posList then
                    local len = table.count(posList)
                    for i = 1, len do
                        local pos = posList[i]
                        local targetPos = pos
                        if table.icontains(mainCenterScopeRange,targetPos) then
                        else
                            effectService:CreateWorldPositionDirectionEffect(
                                    self._roundGridEffectID,
                                    targetPos,
                                    targetPos - viewCenterPos
                            )
                        end
                    end
                end
            end
        end
    end
end
function PlayPetHatiChainJumpDamageInstruction:_ShowMainEff(TT,world,viewCenterPos)
    YIELD(TT, self._mainEffTimeMs)
    ---@type EffectService
    local effectService = world:GetService("Effect")
    effectService:CreateWorldPositionDirectionEffect(self._mainEffectID, viewCenterPos)
end