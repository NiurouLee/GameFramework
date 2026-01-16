--[[
    注意！预览也会用到这个！
]]
_class("SkillEffectCalc_MultiTraction_SingleTargetPossession", Object)
function SkillEffectCalc_MultiTraction_SingleTargetPossession:Constructor(
    entityID,
    path,
    finalPos,
    beginPos)
    self.entityID = entityID
    self.path = path
    self.finalPos = finalPos
    self.beginPos = beginPos
end

function SkillEffectCalc_MultiTraction_SingleTargetPossession:SetTriggerTraps(triggerTraps)
    self._triggerTraps = triggerTraps
end

function SkillEffectCalc_MultiTraction_SingleTargetPossession:GetTriggerTraps()
    return self._triggerTraps
end

function SkillEffectCalc_MultiTraction_SingleTargetPossession:GetTargetEntityID()
    return self.entityID
end

_class("SkillEffectCalc_MultiTraction_GridPossessorMap", Object)
---@class  SkillEffectCalc_MultiTraction_GridPossessorMap:Object
SkillEffectCalc_MultiTraction_GridPossessorMap = SkillEffectCalc_MultiTraction_GridPossessorMap
function SkillEffectCalc_MultiTraction_GridPossessorMap:Constructor()
    self.all = {}
    self.array = {}
    self.dimensionMap = {}
end

---@param pos Vector2
---@param entity Entity
---@param path Vector2[]
function SkillEffectCalc_MultiTraction_GridPossessorMap:MarkPossessInfo(pos, entity, path)
    local entityID = entity:GetID()
    local bodyAreaComponent = entity:BodyArea()

    local dimensionMap = self.dimensionMap

    if bodyAreaComponent then
        local areaArray = bodyAreaComponent:GetArea()
        for i = 1, #areaArray do
            local absoluteAreaPos = areaArray[i] + pos
            local absX = absoluteAreaPos.x
            local absY = absoluteAreaPos.y
            if not dimensionMap[absX] then
                dimensionMap[absX] = {}
            end
            dimensionMap[absX][absY] = entityID
            table.insert(self.all, absoluteAreaPos)
        end
    else
        local absX = pos.x
        local absY = pos.y
        if not dimensionMap[absX] then
            dimensionMap[absX] = {}
        end
        dimensionMap[absX][absY] = entityID
        table.insert(self.all, pos)
    end

    table.insert(
        self.array,
        SkillEffectCalc_MultiTraction_SingleTargetPossession:New(
            entityID,
            path,
            pos,
            entity:GetGridPosition()
        )
    )
end

---@class SkillEffectCalc_MultiTraction: Object
_class("SkillEffectCalc_MultiTraction", Object)
SkillEffectCalc_MultiTraction = SkillEffectCalc_MultiTraction
function SkillEffectCalc_MultiTraction:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    self._logFlag = true
end

function SkillEffectCalc_MultiTraction:_Log(entity, ...)
    if not self._logFlag then
        return
    end

    local eid = entity and entity:GetID() or "nil"
    Log.notice(self._className, eid, ": ", ...)
end

function SkillEffectCalc_MultiTraction:_NewPieceBlockBlackboard(centerPos, targetIDs,canMoveToCenter)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local blackboard = utilData:CreatePieceBlockBlackboard(targetIDs)
    if not canMoveToCenter then
        blackboard[centerPos.x][centerPos.y]:AddBlock(-1, BlockFlag.MonsterLand | BlockFlag.MonsterFly | BlockFlag.LinkLine)
    end
    return blackboard
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MultiTraction:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectMultiTractionParam
    local tractionParam = skillEffectCalcParam.skillEffectParam
    local enableByPickNum = tractionParam:GetEnableByPickNum()
    if enableByPickNum then
        local checkNum = tonumber(enableByPickNum)
        ---@type Entity
        local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
        ---@type ActiveSkillPickUpComponent
        local component = attacker:ActiveSkillPickUpComponent()
        if component then
            local curPickNum = component:GetAllValidPickUpGridPosCount()
            if curPickNum ~= checkNum then
                return
            end
        end
    end

    self._gridPossessionMap = SkillEffectCalc_MultiTraction_GridPossessorMap:New()

    

    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()

    local skipTractionCalc = false
    local skipTractionByPickNum = tractionParam:GetSkipTractionByPickNum()
    if skipTractionByPickNum then
        local checkNum = tonumber(skipTractionByPickNum)
        ---@type Entity
        local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
        ---@type ActiveSkillPickUpComponent
        local component = attacker:ActiveSkillPickUpComponent()
        if component then
            local curPickNum = component:GetAllValidPickUpGridPosCount()
            if curPickNum == checkNum then
                skipTractionCalc = true--跳过牵引计算，但会返回结果，用于表现
            end
        end
    end

    local includeCasterTeam = false --光灵阿纳托利 牵引怪和自己
    local centerPos
    local tractionCenterType = tractionParam:GetTractionCenterType()
    if tractionCenterType == TractionCenterType.Normal then
        if tractionParam:IsCasterCentered() then
            centerPos = casterEntity:GetGridPosition()
        else
            if casterEntity:HasPetPstID() then
                centerPos = skillEffectCalcParam.gridPos
                if not centerPos then
                    centerPos = scopeResult:GetCenterPos()
                end
            else
                centerPos = scopeResult:GetCenterPos()
            end
        end
    elseif tractionCenterType == TractionCenterType.PetANaTuoLi then
        local isCfgPreview = tractionParam:GetIsPreview()
        local scopeCenterPos
        if isCfgPreview then
            scopeCenterPos = skillEffectCalcParam.gridPos
        else
            scopeCenterPos = scopeResult:GetCenterPos()
        end
        if #scopeCenterPos < 2 then
            return
        end
        local mainPos = scopeCenterPos[1]
        local scopeRange
        if isCfgPreview then
            scopeRange = skillEffectCalcParam.skillRange
        else
            scopeRange = scopeResult:GetAttackRange()
        end
        centerPos = self:_PetANaTuoLiFindTractionCenter(scopeRange,mainPos)
        local petANaTuoLiCanTractionSelf = tractionParam:GetPetANaTuoLiCanTractionSelf()
        if petANaTuoLiCanTractionSelf then
            if isCfgPreview then
                ---@type PreviewPickUpComponent
                local component = casterEntity:PreviewPickUpComponent()
                if component then
                    local curPickNum = component:GetAllValidPickUpGridPosCount()
                    if curPickNum == 1 then
                        includeCasterTeam = true
                    end
                end
            else
                ---@type ActiveSkillPickUpComponent
                local component = casterEntity:ActiveSkillPickUpComponent()
                if component then
                    local curPickNum = component:GetAllValidPickUpGridPosCount()
                    if curPickNum == 1 then
                        includeCasterTeam = true
                    end
                end
            end
        end
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    self.rangeByQuadrant = utilScopeSvc:GetBoardQuadrantsByCenter(centerPos, casterEntity, true)
    self.rangeByQuadrant[BoardQuadrant.Center] = {centerPos}
    
    local attackPosArray = skillEffectCalcParam.skillRange

    local skillID = skillEffectCalcParam.skillID
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local skillConfig = configService:GetSkillConfigData(skillID)
    local targetType = skillConfig and skillConfig:GetSkillTargetType() or SkillTargetType.Board

    local overrideTargetType = tractionParam:GetSkillEffectTargetType()
    if overrideTargetType then
        targetType = overrideTargetType
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local canMoveToCenter = tractionParam:GetCanMoveToCenter()
    if not skipTractionCalc then
        if self._world:MatchType() == MatchType.MT_BlackFist then
            local teamEntity, enemyTeam
            --MSG70199 除非另有需求，黑拳赛内施法者为机关的，直接认为是我方队伍
            if casterEntity:HasTrap() then
                teamEntity = self._world:Player():GetLocalTeamEntity()
            else
                ---@type Entity
                teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
            end
            enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
            local v2PosTL = enemyTeam:GetGridPosition()
            if table.icontains(attackPosArray, v2PosTL) then
                local targetIDs = {}
                table.insert(targetIDs, enemyTeam:GetID())
                local casterTeamEntity = nil
                if includeCasterTeam then
                    casterTeamEntity = casterEntity:Pet():GetOwnerTeamEntity()
                    table.insert(targetIDs,casterTeamEntity:GetID())
                end
                self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(centerPos, targetIDs,canMoveToCenter)
                for _, targetID in ipairs(targetIDs) do
                    ---@type Entity
                    local targetEntity = self._world:GetEntityByID(targetID)
                    local gridPos = targetEntity:GetGridPosition()
                    self:_DoSingleTraction(skillEffectCalcParam, centerPos, gridPos, targetEntity, casterEntity,includeCasterTeam)
                end
            end
        else
            if targetType == SkillTargetType.Team then
                local teamEntity = self._world:Player():GetPreviewTeamEntity()
                -- 这里不同目标的处理逻辑差别有点大，不是很好合
                local v2PosTL = teamEntity:GetGridPosition()
                if table.icontains(attackPosArray, v2PosTL) then
                    self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(centerPos, {teamEntity:GetID()},canMoveToCenter)
                    self:_DoSingleTraction(skillEffectCalcParam, centerPos, v2PosTL, teamEntity, casterEntity)
                end
            elseif targetType == SkillTargetType.MonsterAndChessPet then
                local scope = SkillScopeResult:New(SkillScopeType.None, centerPos, attackPosArray, attackPosArray)
                local selector = SkillScopeTargetSelector:New(self._world)
                local targetIDs =
                    selector:DoSelectSkillTarget(casterEntity, SkillTargetType.MonsterAndChessPet, scope, nil, {})
    
                self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(centerPos, targetIDs,canMoveToCenter)
                for _, targetID in ipairs(targetIDs) do
                    ---@type Entity
                    local targetEntity = self._world:GetEntityByID(targetID)
                    local gridPos = targetEntity:GetGridPosition()
                    self:_DoSingleTraction(skillEffectCalcParam, centerPos, gridPos, targetEntity, casterEntity)
                end
            else
                local targetEntityIDMap = {}
    
                -- 为了保证逻辑只运行1次，牵引怪物时，配置上的targetType是5，这里要重新取一遍范围内的怪物
                local scope = SkillScopeResult:New(SkillScopeType.None, centerPos, attackPosArray, attackPosArray)
                local selector = SkillScopeTargetSelector:New(self._world)
                local targetIDs = selector:DoSelectSkillTarget(casterEntity, SkillTargetType.Monster, scope, nil, {})
                local casterTeamEntity = nil
                if includeCasterTeam then
                    casterTeamEntity = casterEntity:Pet():GetOwnerTeamEntity()
                    table.insert(targetIDs,casterTeamEntity:GetID())
                end
                for _, id in ipairs(targetIDs) do
                    targetEntityIDMap[id] = true
                end
    
                local monsterDisList = utilScopeSvc:SortMonstersByPos(centerPos, true)
                local validMonsterDisList = {}
    
                -- 首先排除技能范围以外的目标
                for _, monsterDisInfo in ipairs(monsterDisList) do
                    if not targetEntityIDMap[monsterDisInfo.monster_e:GetID()] then
                        self:_Log(monsterDisInfo.monster_e, " Outside of skill range, skipping. ")
                        local gridPos = monsterDisInfo.monster_e:GetGridPosition()
                        self._gridPossessionMap:MarkPossessInfo(gridPos, monsterDisInfo.monster_e, {})
                    else
                        table.insert(validMonsterDisList, monsterDisInfo)
                    end
                end
                if includeCasterTeam then
                    local casterPos = casterEntity:GetGridPosition()
                    local casterFakeInfo = { dis = 1000, monster_e = casterTeamEntity, pos = casterPos }
                    table.insert(validMonsterDisList, casterFakeInfo)
                end
    
                -- 将除技能目标以外的阻挡复制一份用来计算
                self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(centerPos, targetIDs,canMoveToCenter)
    
                -- 对范围内的目标按原顺序处理
                for _, monsterDisInfo in ipairs(validMonsterDisList) do
                    local gridPos = monsterDisInfo.monster_e:GetGridPosition()
                    self:_DoSingleTraction(skillEffectCalcParam, centerPos, gridPos, monsterDisInfo.monster_e, casterEntity,includeCasterTeam)
                end
            end
        end
    end

    local result = SkillEffectMultiTractionResult:New(self._gridPossessionMap)

    local damageIncreaseRate = tractionParam:GetFinalDamageIncreaseRate()
    if damageIncreaseRate then
        result:SetDamageIncreaseRate(damageIncreaseRate)
    end
    result:SetTractionCenterPos(centerPos)

    return result
end

function SkillEffectCalc_MultiTraction:_SaveTargetEntityTractionResult(targetEntity, finalPos, path)
    self._gridPossessionMap:MarkPossessInfo(finalPos, targetEntity, path)
    local areaArray = targetEntity:BodyArea():GetArea()
    for _, v2RelativeBody in ipairs(areaArray) do
        local v2 = finalPos + v2RelativeBody
        --发现有单位站在了版外导致报错
        if self._pieceBlockBlackboard[v2.x] and self._pieceBlockBlackboard[v2.x][v2.y] then
            self._pieceBlockBlackboard[v2.x][v2.y]:AddBlock(targetEntity:GetID(), targetEntity:BlockFlag():GetBlockFlag())
        else
            Log.error(self._className, " out of board pos: ", tostring(v2))
        end
    end
end

---@param skillEffectCalcParam  SkillEffectCalcParam
---@param entity                Entity target entity reference
---@param casterEntity          Entity caster entity reference
function SkillEffectCalc_MultiTraction:_DoSingleTraction(skillEffectCalcParam, center, currentPos, entity, casterEntity,includeCasterTeam)
    local areaArray = entity:BodyArea():GetArea()

    ---@type SkillEffectMultiTractionParam
    local tractionParam = skillEffectCalcParam.skillEffectParam
    local canMoveToCenter = tractionParam:GetCanMoveToCenter()
    if not tractionParam:GetForceMove() then
        -- 免疫击退单位不受影响
        ---@type BuffLogicService
        local bufflsvc = self._world:GetService("BuffLogic")
        if not bufflsvc:CheckCanBeHitBack(entity) then
            self:_Log(entity, "target cannot move: ", entity:GetID())
            self:_SaveTargetEntityTractionResult(entity, currentPos, {})
            return
        end
    else
        --强制位置，不能拉boss
        if entity:HasMonsterID() then
            ---@type ConfigService
            local cfgsvc = self._world:GetService("Config")
            local monsterConfigData = cfgsvc:GetMonsterConfigData()

            local monsterID = entity:MonsterID():GetMonsterID()
            if monsterConfigData:IsBoss(monsterID) then
                self:_Log(entity, "target is boss, cannot move: ", entity:GetID())
                self:_SaveTargetEntityTractionResult(entity, currentPos, {})
                return
            end
        end
        -- 免疫 强制位移（及牵引的强制效果）
        ---@type BuffLogicService
        local bufflsvc = self._world:GetService("BuffLogic")
        if bufflsvc:CheckForceMoveImmunity(entity) then
            self:_Log(entity, "target is ForceMoveImmunity, cannot move: ", entity:GetID())
            self:_SaveTargetEntityTractionResult(entity, currentPos, {})
            return
        end
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    --多格怪计算圈数会使用离目标点最近的格子做计算 不一定是逻辑位置
    --nearestPos 多格怪用来计算圈数的格子位置 后续步骤里也用该位置当做逻辑位置，并同时处理bodyArea
    --useOffV2 nearestPos相对原逻辑位置的偏移
    local currentRingNum,nearestPos,useOffV2 = utilCalcSvc:GetGridRingNumWithBodyArea(currentPos, center, areaArray)
    local bodyAreaByOff = {}
    for index, value in ipairs(areaArray) do
        local newPos = value - useOffV2
        table.insert(bodyAreaByOff,newPos)
    end
    if not canMoveToCenter then
        -- 第一圈根据规则不会移动
        if currentRingNum <= 1 then
            self:_Log(entity, "already in 1st ring, skipping. ")
            self:_SaveTargetEntityTractionResult(entity, currentPos, {})
            return
        end
    end

    local monsterQuadrant = utilCalcSvc:GetPosQuadrant(center, nearestPos)
    self:_Log(entity, "target quadrant: ", monsterQuadrant)

    -- 可接受的只有圈数更少的棋盘范围内...
    local acceptableRange = utilCalcSvc:GetGridsByRing(
        self.rangeByQuadrant[monsterQuadrant],
        center,
        currentRingNum - 1
    )
    if canMoveToCenter then
        table.insert(acceptableRange,center)
    end
    ---@type SkillEffectMultiTractionParam
    local tractionParam = skillEffectCalcParam.skillEffectParam
    local maxStep = tractionParam:GetMaxMoveStep()--最多走几步
    if maxStep > 0 then
        acceptableRange = self:CutOutMaxStepRangeForSingle(acceptableRange, maxStep, nearestPos, bodyAreaByOff)
    end
    -- ...未被占据的部分，且相对中心点的x和y都不能增大
    ---@type BoardServiceLogic
    local boardsvc = self._world:GetService("BoardLogic")
    local blockVal = boardsvc:GetEntityMoveBlockFlag(entity)
    if blockVal == BlockFlag.LinkLine then
        if self._world:MatchType() == MatchType.MT_BlackFist then
            --黑拳赛下 牵引自己时会与敌方队伍重叠 blockflag只用linkline无法判断队伍
            blockVal = BlockFlag.LinkLine | BlockFlag.MonsterLand
        end
    end
    local relativeCurrentPos = nearestPos - center
    local candidates = {}
    for _, gridPos in ipairs(acceptableRange) do
        local fitFullBodyArea = self:IsPosFitFullBodyArea(gridPos, entity, blockVal,bodyAreaByOff, casterEntity,includeCasterTeam)
        if not fitFullBodyArea then
            goto MULTI_TRACTION_CANDIDATE_TARGET_POS_CONTINUE
        end

        local candidateRelativePos = gridPos - center
        local candidateRingNum = utilCalcSvc:GetGridRingNum(gridPos, center)

        local isRelativeXLE = (math.abs(relativeCurrentPos.x) >= math.abs(candidateRelativePos.x))
        local isRelativeYLE = (math.abs(relativeCurrentPos.y) >= math.abs(candidateRelativePos.y))

        if (not isRelativeXLE) or (not isRelativeYLE) then
            goto MULTI_TRACTION_CANDIDATE_TARGET_POS_CONTINUE
        end

        table.insert(candidates, gridPos)
        ::MULTI_TRACTION_CANDIDATE_TARGET_POS_CONTINUE::
    end

    -- 没找到位置则维持原位置
    if (not candidates) or (#candidates == 0) then
        self:_Log(entity, "no candidate in acceptable range, skipping")
        self:_SaveTargetEntityTractionResult(entity, currentPos, {})
        return
    end

    -- 如果有位置通过预选，最后按距离和顺时针规则选择【距离原始位置最近的位置】
    --local targetPos = entity:GetGridPosition()
    local sortedByDis = HelperProxy:SortPosByCenterPosDistance(nearestPos, candidates)

    local finalPos = candidates[1]
    local currentFinalPosRingNum = utilCalcSvc:GetGridRingNum(finalPos, center)
    local currentFinalPosDisIndex = table.ikey(sortedByDis, finalPos)
    self._Log(entity,"first target: ",finalPos," ring: ",currentFinalPosRingNum," disIndex: ",currentFinalPosDisIndex)
    for _, pos in ipairs(candidates) do
        local ringNum = utilCalcSvc:GetGridRingNum(pos, center)
        -- 圈数较少的点优先
        if ringNum < currentFinalPosRingNum then
            self._Log(entity,"new target: ",finalPos," ring: ",currentFinalPosRingNum," disIndex: ",currentFinalPosDisIndex)
            finalPos = pos

            currentFinalPosRingNum = ringNum
            currentFinalPosDisIndex = table.ikey(sortedByDis, pos)
        else
            -- 圈数相同时取距离最小的点
            local disIndex = table.ikey(sortedByDis, pos)
            if disIndex < currentFinalPosRingNum then
                finalPos = pos
                currentFinalPosRingNum = ringNum
                currentFinalPosDisIndex = disIndex

            self._Log(entity,"new target: ",finalPos," ring: ",currentFinalPosRingNum," disIndex: ",currentFinalPosDisIndex)
            end
        end
    end

    -- 选定位置的情况下，判断是否有障碍物，没有则记录位置，有则停留在障碍物旁边
    local approachPath = utilCalcSvc:GetGridPathByVectorLerp(nearestPos, finalPos)
    --限制步数
    approachPath,finalPos = self:CheckApproachPathForMaxStep(approachPath,finalPos,maxStep)
    local obstacledPos, obstacleIndex = self:GetFirstObstacleInPath(approachPath, entity, blockVal,bodyAreaByOff, casterEntity,includeCasterTeam)
    local finalPath = {}
    if obstacledPos then
        -- Log.notice("obstacle found: ", obstacledPos)
        local lastIndex = obstacleIndex - 1
        -- 遇到障碍物时，尝试选择前一个位置
        -- 规则是：在路境内 && 怪物可站
        while (lastIndex > 0) do
            local gridPos = approachPath[lastIndex]
            local fitFullBodyArea = self:IsPosFitFullBodyArea(gridPos, entity, blockVal,bodyAreaByOff, casterEntity,includeCasterTeam)

            if not fitFullBodyArea then
                lastIndex = lastIndex - 1
            else
                break
            end
        end

        finalPos = approachPath[lastIndex]
        for i = 1, lastIndex do
            table.insert(finalPath, approachPath[i])
        end
    else
        finalPath = approachPath
    end

    if (#finalPath == 0) then
        -- Log.notice("no path to target pos, skipping")
        self:_SaveTargetEntityTractionResult(entity, currentPos, {})
        return
    end
    --将多格怪偏移的逻辑位置恢复
    local finalPathNoOff = {}
    for index, value in ipairs(finalPath) do
        local gridPos = value - useOffV2
        table.insert(finalPathNoOff,gridPos)
    end
    local finalPosNoOff = finalPos - useOffV2
    self:_SaveTargetEntityTractionResult(entity, finalPosNoOff, finalPathNoOff)
    -- Log.notice("finalPos=", finalPos)
end

---@param gridPos Vector2
---@param entity Entity
---@param usePosOff Vector2 多格怪 用于计算圈数的点可能是逻辑坐标+usePosOff 计算fit时需要做偏移
function SkillEffectCalc_MultiTraction:IsPosFitFullBodyArea(gridPos, entity, testBlockVal,bodyAreaByOff, casterEntity,includeCasterTeam)
    local checkPos = gridPos
    local areaArray = entity:BodyArea():GetArea()
    if bodyAreaByOff then
        areaArray = bodyAreaByOff
    end
    local casterBodyAreaOff = casterEntity:BodyArea():GetArea()
    local casterBodyArea = {}
    local casterPos = casterEntity:GetGridPosition()
    for _, area in ipairs(casterBodyAreaOff) do
        local workPos = casterPos + area
        table.insert(casterBodyArea, workPos)
    end
    for _, v2RelativeBody in ipairs(areaArray) do
        local v2 = checkPos + v2RelativeBody
        if (not self._pieceBlockBlackboard[v2.x]) or (not self._pieceBlockBlackboard[v2.x][v2.y]) then
            return false
        end
        if (self._pieceBlockBlackboard[v2.x][v2.y]:GetBlock() & testBlockVal ~= 0) then
            return false
        end
        local checkCasterBodyArea = true
        if includeCasterTeam then
            if casterEntity:HasPet() then
                local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
                if entity:GetID() == teamEntity:GetID() then
                    checkCasterBodyArea = false --牵引自己（队伍）时不视自己位置为阻挡
                end
            end
        end
        if checkCasterBodyArea then
            if table.intable(casterBodyArea, checkPos) then
                return false
            end
        end
        ---@type UtilDataServiceShare
        local utilData = entity:GetOwnerWorld():GetService("UtilData")
        if (utilData:IsPosBlockWithEntityRace(v2, testBlockVal, entity)) then
            return false
        end
    end
    return true
end

function SkillEffectCalc_MultiTraction:GetFirstObstacleInPath(approachPath, entity, testBlockVal,bodyAreaByOff, casterEntity,includeCasterTeam)
    for index, v2 in ipairs(approachPath) do
        if not self:IsPosFitFullBodyArea(v2, entity, testBlockVal,bodyAreaByOff, casterEntity,includeCasterTeam) then
            return v2, index
        end
    end
end

---对单个目标，去掉范围内圈数差超过限制的格子
function SkillEffectCalc_MultiTraction:CutOutMaxStepRangeForSingle(gridList,maxStep,center,areaArry)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local accpetRange = {}
    if maxStep > 0 then
        local maxRing = maxStep
        if maxRing >= 0 then
            for index, value in ipairs(gridList) do
                local gridRing = utilCalcSvc:GetGridRingNumWithBodyArea(center, value, areaArry)
                if gridRing <= maxRing then
                    table.insert(accpetRange,value)
                end
            end
        end
    end
    return accpetRange
end

---步数超过最大步数，截断路径
function SkillEffectCalc_MultiTraction:CheckApproachPathForMaxStep(approachPath,finalPos,maxStep)
    if maxStep > 0 then--限制了步数
        local validPath = {}
        for index, value in ipairs(approachPath) do
            if index <= (maxStep + 1) then --路径包含了起点
                table.insert(validPath,value)
            else
                break
            end
        end
        approachPath = validPath
        finalPos = approachPath[#approachPath]
        return approachPath,finalPos
    else
        return approachPath,finalPos
    end
end

function SkillEffectCalc_MultiTraction:_PetANaTuoLiFindTractionCenter(skillRangePos, castPos)
    ---@type SortedArray    注意这里的排序函数，不同需求应当不同
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    sortPosList:AllowDuplicate()
    for i = 1, #skillRangePos do
        AINewNode.InsertSortedArray(sortPosList, castPos, skillRangePos[i], i)
    end
    local totalCount = sortPosList:Size()
    local centerIndex = math.floor((totalCount+1)/2)--取中位数，偶数个则取前面一个
    ---@type AiSortByDistance
    local centerElement = sortPosList:GetAt(centerIndex)
    local centerPos = centerElement:GetPosData()
    return centerPos
end