_class("PreviewPreviewSkillEffectCalc_MultiTraction_SingleTargetPossession", Object)
function PreviewPreviewSkillEffectCalc_MultiTraction_SingleTargetPossession:Constructor(
    entityID,
    path,
    finalPos,
    beginPos)
    self.entityID = entityID
    self.path = path
    self.finalPos = finalPos
    self.beginPos = beginPos
end

function PreviewPreviewSkillEffectCalc_MultiTraction_SingleTargetPossession:SetTriggerTraps(triggerTraps)
    self._triggerTraps = triggerTraps
end

function PreviewPreviewSkillEffectCalc_MultiTraction_SingleTargetPossession:GetTriggerTraps()
    return self._triggerTraps
end

_class("PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap", Object)
---@class  PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap:Object
PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap =
    PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap
function PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap:Constructor()
    self.all = {}
    self.array = {}
    self.dimensionMap = {}
end

---@param pos Vector2
---@param entity Entity
---@param path Vector2[]
function PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap:MarkPossessInfo(pos, entity, path)
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
        PreviewPreviewSkillEffectCalc_MultiTraction_SingleTargetPossession:New(
            entityID,
            path,
            pos,
            entity:GetGridPosition()
        )
    )
end

---@class PreviewSkillEffectCalc_MultiTraction: Object
_class("PreviewSkillEffectCalc_MultiTraction", Object)
PreviewSkillEffectCalc_MultiTraction = PreviewSkillEffectCalc_MultiTraction
function PreviewSkillEffectCalc_MultiTraction:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    self._gridPossessionMap = PreviewPreviewSkillEffectCalc_MultiTraction_GridPossessorMap:New()

    self._logFlag = true
end

function PreviewSkillEffectCalc_MultiTraction:_Log(entity, ...)
    if not self._logFlag then
        return
    end

    local eid = entity and entity:GetID() or "nil"
    Log.notice(self._className, eid, ": ", ...)
end

-- 考虑除了怪物和玩家以外的阻挡
function PreviewSkillEffectCalc_MultiTraction:IsPosObstructed(pos, targetType)
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type PieceBlockData
    local blockData = env:GetPosBlockData(pos)
    if not blockData then
        return true
    end

    ---@type BlockFlag
    local monsterBlockFlag = 0

    if MonsterRaceType.Land == targetType then
        monsterBlockFlag = BlockFlag.MonsterLand
    elseif MonsterRaceType.Fly == targetType then
        monsterBlockFlag = BlockFlag.MonsterFly
    else
        monsterBlockFlag = BlockFlag.LinkLine
    end

    for entityID, value in pairs(blockData.m_listBlock) do
        if entityID > 0 then
            local entity = self._world:GetEntityByID(entityID)
            if entity and (entity:TrapRender()) and ((value & monsterBlockFlag) > 0) then
                return true
            end
        else
            -- entityID < 0 是地形造成的
            if (value & monsterBlockFlag) > 0 then
                return true
            end
        end
    end

    return false
end

function PreviewSkillEffectCalc_MultiTraction:_FetchCandidatesIn(range, monsterRaceType)
    local candidates = {}
    for _, pos in ipairs(range) do
        if (not self:IsPosObstructed(pos, monsterRaceType)) then
            -- Log.notice("candidate in acceptable range ", pos)
            table.insert(candidates, pos)
        end
    end

    return candidates
end

---@param skillEffectCalcParam SkillEffectCalcParam
function PreviewSkillEffectCalc_MultiTraction:DoSkillEffectCalculator(skillEffectCalcParam, scopeResult)
    ---@type SkillEffectMultiTractionParam
    local tractionParam = skillEffectCalcParam.skillEffectParam

    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    -----@type SkillEffectResultContainer
    --local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    -----@type SkillScopeResult
    --local scopeResult = skillEffectResultContainer:GetScopeResult()
    local centerPos
    local tractionCenterType = tractionParam:GetTractionCenterType()
    if tractionCenterType == TractionCenterType.Normal then
        if tractionParam:IsCasterCentered() then
            centerPos = casterEntity:GetGridPosition()
        else
            centerPos = skillEffectCalcParam.gridPos
            if not centerPos then
                centerPos = scopeResult:GetCenterPos()
            end

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
        if not scopeResult then
            return
        end
        local scopeCenterPos = scopeResult:GetCenterPos()
        if #scopeCenterPos < 2 then
            return
        end
        local mainPos = scopeCenterPos[1]
        local scopeRange = scopeResult:GetAttackRange()
        centerPos = self:_PetANaTuoLiFindTractionCenter(scopeRange,mainPos)
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local fullScreenCalc = SkillScopeCalculator_FullScreen:New(skillCalculater)

    ---@type SkillScopeResult
    local platformScopeResult =
        fullScreenCalc:CalcRange(
        SkillScopeType.FullScreen,
        1, -- bExcludeSelf
        centerPos,
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        SkillTargetType.Board,
        centerPos
    )

    local rt, rb, lb, lt = utilCalcSvc:DivideGridsByQuadrant(platformScopeResult:GetAttackRange(), centerPos)

    self.rangeByQuadrant = {
        [BoardQuadrant.RightTop] = rt,
        [BoardQuadrant.RightBottom] = rb,
        [BoardQuadrant.LeftBottom] = lb,
        [BoardQuadrant.LeftTop] = lt
    }
    self.rangeByQuadrant[BoardQuadrant.Center] = {centerPos}

    local skillID = skillEffectCalcParam.skillID
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()

    local attackPosArray = skillEffectCalcParam.skillRange

    local targetEntityIDMap = {}

    local skillConfig = configService:GetSkillConfigData(skillID, casterEntity)
    local targetType = skillConfig and skillConfig:GetSkillTargetType() or SkillTargetType.Board

    local overrideTargetType = tractionParam:GetSkillEffectTargetType()
    if overrideTargetType then
        targetType = overrideTargetType
    end

    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
        local v2PosTL = enemyTeam:GetGridPosition()
        if table.icontains(attackPosArray, v2PosTL) then
            self:_DoSingleTraction(centerPos, v2PosTL, enemyTeam, casterEntity)
        end
    else
        if targetType == SkillTargetType.Team then
            local teamEntity = self._world:Player():GetPreviewTeamEntity()
            -- 这里不同目标的处理逻辑差别有点大，不是很好合
            local v2PosTL = teamEntity:GetGridPosition()
            if table.icontains(attackPosArray, v2PosTL) then
                self:_DoSingleTraction(centerPos, v2PosTL, teamEntity, casterEntity)
            end
        else

            local scope = SkillScopeResult:New(SkillScopeType.None, centerPos, attackPosArray, attackPosArray)
            local selector = SkillScopeTargetSelector:New(self._world)
            local targetIDs = selector:DoSelectSkillTarget(casterEntity, SkillTargetType.Monster, scope, nil, {})
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

            -- 对范围内的目标按原顺序处理
            for _, monsterDisInfo in ipairs(validMonsterDisList) do
                local gridPos = monsterDisInfo.monster_e:GetGridPosition()
                self:_DoSingleTraction(centerPos, gridPos, monsterDisInfo.monster_e, casterEntity)
            end
        end
    end

    return SkillEffectMultiTractionResult:New(self._gridPossessionMap)
end

---@param entity Entity target entity reference
---@param casterEntity Entity caster entity reference
function PreviewSkillEffectCalc_MultiTraction:_DoSingleTraction(center, currentPos, entity, casterEntity)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = configService:GetMonsterConfigData()

    local isTargetMonster = entity:HasMonsterID()

    local monsterIDComponent = entity:MonsterID()

    local monsterID, monsterRaceType
    if monsterIDComponent then
        monsterID = monsterIDComponent:GetMonsterID()
        monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
    end

    local areaArray = {}
    if entity:HasBodyArea() then
        areaArray = entity:BodyArea():GetArea()
    end

    local relativePos = currentPos - center

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    local currentRingNum = utilCalcSvc:GetGridRingNumWithBodyArea(currentPos, center, areaArray)
    -- 第一圈根据规则不会移动
    if currentRingNum <= 1 then
        self:_Log(entity, "already in 1st ring, skipping. ")
        self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
        return
    end

    -- if isTargetMonster then
    --     if not monsterConfigData:CanMove(monsterID) then
    --         self:_Log(entity, "monster cannot move: ", monsterID)
    --         self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
    --         return
    --     end
    -- end

    ---@type BuffLogicService
    local BuffLogicSvc = self._world:GetService("BuffLogic")
    if not BuffLogicSvc:CheckCanBeHitBack(entity) then
        self:_Log(entity, "monster cannot move: ", monsterID)
        self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
        return
    end

    local monsterQuadrant = utilCalcSvc:GetPosQuadrant(center, currentPos)

    self:_Log(entity, "target quadrant: ", monsterQuadrant)

    -- 可接受的只有圈数更少的棋盘范围内...
    local acceptableRange =
        utilCalcSvc:GetGridsByRing(self.rangeByQuadrant[monsterQuadrant], center, currentRingNum - 1)
    -- ...未被占据的部分...
    for _, gridPos in pairs(self._gridPossessionMap.all) do
        table.removev(acceptableRange, gridPos)
    end
    -- ...且不能是选中格子自身——中心格不算任何象限内...
    table.removev(acceptableRange, center)

    -- ...且不能撞在施法者身上
    ---@type BodyAreaComponent
    local casterBodyArea = casterEntity:BodyArea()
    if casterBodyArea then
        local casterBodyAreaArray = casterBodyArea:GetArea()
        local casterGridLocationComponent = casterEntity:GridLocation()
        local casterPos = casterGridLocationComponent:GetGridPos()
        for _, areaPos in ipairs(casterBodyAreaArray) do
            table.removev(acceptableRange, (areaPos + casterPos))
        end
    end

    local candidates = self:_FetchCandidatesIn(acceptableRange, monsterRaceType)

    -- 没找到位置则维持原位置
    if (not candidates) or (#candidates == 0) then
        self:_Log(entity, "no candidate in acceptable range, skipping")
        self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
        return
    end

    local casterPos = casterEntity:GetGridPosition()

    -- 对每个能放置目标的位置，根据牵引规则进行预选
    local preselectCandidates = {}
    for i = 1, #candidates do
        local candidateAbsolutePos = candidates[i]
        local candidateRelativePos = candidateAbsolutePos - center
        local candidateRingNum = utilCalcSvc:GetGridRingNum(candidateAbsolutePos, center)

        local fitFullBodyArea = true
        for _, areaPos in ipairs(areaArray) do
            local areaAbsPos = areaPos + candidateAbsolutePos

            -- local canPlaceMonster = boardService:CanCreateMonsterAtPos({areaAbsPos}, monsterRaceType)
            local isNotObstacled = not self:IsPosObstructed(areaAbsPos, monsterRaceType)
            local isNotCastCenter = areaAbsPos ~= center
            local isNotCasterPos = areaAbsPos ~= casterPos
            local isNotOccupied = (not table.icontains(self._gridPossessionMap.all, areaAbsPos))

            fitFullBodyArea =
                (fitFullBodyArea) --[[canPlaceMonster and]] and
                (isNotObstacled and isNotCastCenter and isNotCasterPos and isNotOccupied)
        end

        local isRelativeXLE = (math.abs(relativePos.x) >= math.abs(candidateRelativePos.x))
        local isRelativeYLE = (math.abs(relativePos.y) >= math.abs(candidateRelativePos.y))

        if fitFullBodyArea and isRelativeXLE and isRelativeYLE then
            -- Log.notice("candidate preselected: ", candidateAbsolutePos)
            table.insert(preselectCandidates, candidateAbsolutePos)
        end
    end

    if #preselectCandidates == 0 then
        -- Log.notice("no candidate preselected, skipping")
        self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
        return
    end

    -- 如果有位置通过预选，最后按距离和顺时针规则选择【距离原始位置最近的位置】
    local targetPos = entity:GetGridPosition()
    local sortedByDis = HelperProxy:SortPosByCenterPosDistance(targetPos, preselectCandidates)

    local finalPos = preselectCandidates[1]
    local currentFinalPosRingNum = utilCalcSvc:GetGridRingNum(finalPos, center)
    local currentFinalPosDisIndex = table.ikey(sortedByDis, finalPos)
    -- Log.notice(
    --     "first target: ",
    --     finalPos,
    --     " ring: ",
    --     currentFinalPosRingNum,
    --     " disIndex: ",
    --     currentFinalPosDisIndex
    -- )
    for _, pos in ipairs(preselectCandidates) do
        local ringNum = utilCalcSvc:GetGridRingNum(pos, center)
        if ringNum < currentFinalPosRingNum then
            -- Log.notice(
            --     "new target: ",
            --     finalPos,
            --     " ring: ",
            --     currentFinalPosRingNum,
            --     " disIndex: ",
            --     currentFinalPosDisIndex
            -- )
            finalPos = pos

            currentFinalPosRingNum = ringNum
            currentFinalPosDisIndex = table.ikey(sortedByDis, pos)
        else
            local disIndex = table.ikey(sortedByDis, pos)
            if disIndex < currentFinalPosRingNum then
                finalPos = pos
                currentFinalPosRingNum = ringNum
                currentFinalPosDisIndex = disIndex

            -- Log.notice(
            --     "new target: ",
            --     finalPos,
            --     " ring: ",
            --     currentFinalPosRingNum,
            --     " disIndex: ",
            --     currentFinalPosDisIndex
            -- )
            end
        end
    end

    -- 选定位置的情况下，判断是否有障碍物，没有则记录位置，有则停留在障碍物旁边
    local approachPath = self:GetGridPath(currentPos, finalPos)
    local additionalObstacleArray = {}
    table.insert(additionalObstacleArray, casterEntity:GetGridPosition())
    for _, pos in pairs(self._gridPossessionMap.all) do
        table.insert(additionalObstacleArray, pos)
    end

    local monsterIDComponent = entity:MonsterID()

    local blockFlag = BlockFlag.LinkLine
    if monsterIDComponent then
        blockFlag =
            (monsterIDComponent:GetMonsterRaceType() == MonsterRaceType.Fly) and BlockFlag.MonsterFly or
            BlockFlag.MonsterLand
    end

    local obstacledPos, obstacleIndex =
        utilCalcSvc:GetFirstObstacleInPath(
        approachPath,
        additionalObstacleArray,
        monsterIDComponent and monsterIDComponent:GetMonsterRaceType() == MonsterRaceType.Fly or false,
        entity:HasTeam() or entity:HasPetPstID(),
        blockFlag,
        entity
    )
    local finalPath = {}
    if obstacledPos then
        -- Log.notice("obstacle found: ", obstacledPos)
        local lastIndex = obstacleIndex - 1
        -- 遇到障碍物时，尝试选择前一个位置
        -- 规则是：在路境内 && 怪物可站 && 未被占据
        while ((lastIndex > 0) and
            ((not table.icontains(preselectCandidates, approachPath[lastIndex])) or
                (table.icontains(self._gridPossessionMap.all, approachPath[lastIndex])))) do
            lastIndex = lastIndex - 1
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
        self._gridPossessionMap:MarkPossessInfo(currentPos, entity, {})
        return
    end

    self._gridPossessionMap:MarkPossessInfo(finalPos, entity, finalPath)
    -- Log.notice("finalPos=", finalPos)
end

function PreviewSkillEffectCalc_MultiTraction:GetGridPath(posBegin, posEnd)
    local beginX = posBegin.x
    local endX = posEnd.x
    local beginY = posBegin.y
    local endY = posEnd.y

    local vFirst = Vector2.New(posBegin.x, posBegin.y)
    local vLast = Vector2.New(posEnd.x, posEnd.y)

    local vDirection = vLast - vFirst
    local lerpXToY = (math.abs(vDirection.x) >= math.abs(vDirection.y))

    -- 根据直线选择路线
    local independentVar = 0
    local maxIndependentVar = 0

    local step = 1
    if lerpXToY then
        if beginX < endX then
            independentVar = beginX + 0.5
            maxIndependentVar = endX - 0.5

            step = 1
        else
            independentVar = beginX - 0.5
            maxIndependentVar = endX + 0.5

            step = -1
        end
    else
        if beginY < endY then
            independentVar = beginY + 0.5
            maxIndependentVar = endY - 0.5

            step = 1
        else
            independentVar = beginY - 0.5
            maxIndependentVar = endY + 0.5

            step = -1
        end
    end

    ---@type MathService
    local mathService = self._world:GetService("Math")

    local intersections = {}
    for idv = independentVar, maxIndependentVar, step do
        if lerpXToY then
            table.insert(intersections, {x = idv, y = mathService:LerpGetY(vFirst, vLast, idv)})
        else
            table.insert(intersections, {x = mathService:LerpGetX(vFirst, vLast, idv), y = idv})
        end
    end

    local path = {vFirst}
    for index = 1, #intersections - 1 do
        local intersection1 = intersections[index]
        local intersection2 = intersections[index + 1]

        local points = self:GetPassedGridPositionByIntersections(intersection1, intersection2)
        for _, pos in ipairs(points) do
            if not table.icontains(path, pos) then
                table.insert(path, pos)
            end
        end
    end

    table.insert(path, vLast)

    local snappedPath = self:SnapContinuousPath(path)
    return snappedPath
end

function PreviewSkillEffectCalc_MultiTraction:GetPassedGridPositionByIntersections(intersection1, intersection2)
    local x1 = intersection1.x
    local y1 = intersection1.y
    local x2 = intersection2.x
    local y2 = intersection2.y

    local grid1 = Vector2.zero
    local grid2 = Vector2.zero

    if math.floor(x1) == math.floor(x1 + 0.5) then
        grid1.x = math.floor(x1)
    else
        grid1.x = math.floor(x1 + 1)
    end
    if math.floor(y1) == math.floor(y1 + 0.5) then
        grid1.y = math.floor(y1)
    else
        grid1.y = math.floor(y1 + 1)
    end

    if math.floor(x2) == math.floor(x2 + 0.5) then
        grid2.x = math.floor(x2)
    else
        grid2.x = math.floor(x2 + 1)
    end
    if math.floor(y2) == math.floor(y2 + 0.5) then
        grid2.y = math.floor(y2)
    else
        grid2.y = math.floor(y2 + 1)
    end

    local blocks = {}

    if (grid1 == grid2) then
        table.insert(blocks, grid1)
    else
        table.insert(blocks, grid1)
        table.insert(blocks, grid2)
    end

    return blocks
end

---@param dir Vector2
local function GetLogicDirection(dir)
    local ret = Vector2.zero
    if dir.x > 0 then
        ret.x = 1
    elseif dir.x < 0 then
        ret.x = -1
    end

    if dir.y > 0 then
        ret.y = 1
    elseif dir.y < 0 then
        ret.y = -1
    end

    return ret
end

-- 保证路线中不出现斜向移动
function PreviewSkillEffectCalc_MultiTraction:SnapContinuousPath(path)
    local finalPath = {}
    for index, pos in ipairs(path) do
        if index ~= 1 then
            local lastPos = finalPath[#finalPath]
            local distance = Vector2.Distance(lastPos, pos)
            if distance <= 1 then
                table.insert(finalPath, pos)
            else
                local dir = GetLogicDirection(lastPos - pos)
                while (dir ~= Vector2.zero) do
                    if dir.x ~= 0 and dir.y ~= 0 then
                        table.insert(finalPath, Vector2.New(pos.x, lastPos.y))
                    else
                        table.insert(finalPath, lastPos - dir)
                    end

                    lastPos = finalPath[#finalPath]
                    dir = GetLogicDirection(lastPos - pos)
                end
            end
        else
            table.insert(finalPath, pos)
        end
    end
    return finalPath
end

function PreviewSkillEffectCalc_MultiTraction:_PetANaTuoLiFindTractionCenter(skillRangePos, castPos)
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