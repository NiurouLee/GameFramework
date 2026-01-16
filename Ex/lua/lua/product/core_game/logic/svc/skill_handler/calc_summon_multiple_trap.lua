--[[
    SummonMultipleTrap = 64, --对范围内所有特定颜色的格子召唤机关
]]
_class("SkillEffectCalc_SummonMultipleTrap", Object)
---@class SkillEffectCalc_SummonMultipleTrap: Object
SkillEffectCalc_SummonMultipleTrap = SkillEffectCalc_SummonMultipleTrap

function SkillEffectCalc_SummonMultipleTrap:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonMultipleTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectSummonMultipleTrapParam
    local summonMultipleTrapParam = skillEffectCalcParam.skillEffectParam
    local colorDic = summonMultipleTrapParam:GetSelectedColorTable()
    local trapID = summonMultipleTrapParam:GetTrapID()
    local maxCount = summonMultipleTrapParam:GetMaxCount() or #skillEffectCalcParam.skillRange
    local randomSummon = summonMultipleTrapParam:IsRandom()
    local absPosArray = summonMultipleTrapParam:GetAbsPosArray()
    local isEmptyPosOnly = summonMultipleTrapParam:IsEmptyPosOnly()
    local useBoardRandom = summonMultipleTrapParam:IsUseBoardRandom()
    local blockSummonTrapType = summonMultipleTrapParam:GetBlockSummonTrapType()

    local sortValidPosType = summonMultipleTrapParam:GetSortValidPosType()

    -- 雨森 优先选取范围内空格子（刀会阻挡刀本身）若范围内无空格子，则选取存在无阻挡机关所在格，若都每有则会随机选取一个有刀的格子，在该格子重新召唤一把刀
    local findPosEmptyOrTrap = summonMultipleTrapParam:IsEmptyOrTrap()
    local findPosTrapId = summonMultipleTrapParam:GetFindPosTrapId()
    local excludeTraps = summonMultipleTrapParam:GetExcludeTraps()
    local bFindRandEmptyPosIfNoValid = summonMultipleTrapParam:IsFindRandEmptyPosIfNoValid()

    local ignoreBlock = summonMultipleTrapParam:IgnoreBlock()
    local ignoreAbyss = summonMultipleTrapParam:GetIgnoreAbyss()
    local blockFlag = BlockFlag.SummonTrap
    if ignoreBlock or ignoreAbyss then
        blockFlag = 0
    end

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()

    local validPosArray = {}
    if #absPosArray > 0 then
        validPosArray = absPosArray
    else
        for _, gridPos in ipairs(skillEffectCalcParam.skillRange) do
            local checkPosType = utilData:FindPieceElement(gridPos)
            if colorDic[checkPosType] then
                table.insert(validPosArray, gridPos)
            end
        end
        if validPosArray then
            local _validPosArray = {}
            for _, gridPos in ipairs(validPosArray) do
                if trapServiceLogic:CanSummonTrapOnPos(gridPos, trapID, blockFlag, ignoreAbyss) then
                    if not self:IsPosHasBlockTrap(gridPos, blockSummonTrapType) then
                        table.insert(_validPosArray, gridPos)
                    end
                end
            end
            validPosArray = _validPosArray
        end
    end

    local excludePosList = {}
    --local excludeTraps = {2002100,20021001,20021002}
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    if excludeTraps then
        for _, excludeTrapID in ipairs(excludeTraps) do
            local trapPosList = trapSvc:FindTrapPosByTrapID(excludeTrapID)
            if #trapPosList > 0 then
                table.appendArray(excludePosList,trapPosList)
            end
        end
    end
    local oriValidPosArray = {}
    local tmpPosList = {}
    for _, pos in ipairs(validPosArray) do
        if not table.icontains(excludePosList,pos) then
            table.insert(tmpPosList,pos)
        end
        table.insert(oriValidPosArray,pos)
    end
    validPosArray = tmpPosList

    if bFindRandEmptyPosIfNoValid then
        if (#validPosArray == 0) and (#oriValidPosArray > 0) then
            ---@type UtilScopeCalcServiceShare
            local utilScopeSvc = self._world:GetService("UtilScopeCalc")
            local pieces = utilScopeSvc:GetEmptyPieces()

            local r = randomSvc:LogicRand(1, #pieces)
            local dropPos = pieces[r]
            local centerPos = oriValidPosArray[1]

            local listArea = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
            listArea:AllowDuplicate()
            for i = 1, #pieces do
                AINewNode.InsertSortedArray(listArea, centerPos, pieces[i], i)
            end
            local posSize = listArea:Size()
            for i = 1, posSize do
                local nearestPos = listArea:GetAt(i):GetPosData()
                if trapServiceLogic:CanSummonTrapOnPos(nearestPos, trapID) then
                    table.insert(validPosArray,nearestPos)
                    break
                end
            end
        end
    end
    

    if findPosEmptyOrTrap then --雨森
        --空格子上创建机关
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        --空位置
        local pieces = utilScopeSvc:GetEmptyPieces(validPosArray)
        if #pieces == 0 then
            --无空位置，则获取场上有机关的位置
            pieces = utilScopeSvc:GetTrapPiecesExceptTrapID(trapID, validPosArray)
        end
        validPosArray = pieces
    end

    local additionalCount = 0

    local scopeType = summonMultipleTrapParam:GetAdditionalCountScopeType()
    local rawScopeParam = summonMultipleTrapParam:GetAdditionalCountScopeParam()

    if scopeType then
        local parser = SkillScopeParamParser:New()
        local scopeParam = parser:ParseScopeParam(scopeType, rawScopeParam)

        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---@type SkillScopeCalculator
        local calcScope = utilScopeSvc:GetSkillScopeCalc()
        ---@type SkillScopeResult
        local additionalCountScopeResult = calcScope:ComputeScopeRange(
            scopeType,
            scopeParam,
            skillEffectCalcParam.centerPos,
            { Vector2.zero },
            Vector2.up,
            SkillTargetType.Team, -- 不影响结果
            skillEffectCalcParam.centerPos
        )

        local elementDic = summonMultipleTrapParam:GetAdditionalCountElementDic()
        ---@type BoardServiceLogic
        local blsvc = self._world:GetService("BoardLogic")
        for _, v2GridPos in ipairs(additionalCountScopeResult) do
            local pieceType = blsvc:GetPieceType(v2GridPos)
            if elementDic[pieceType] then
                additionalCount = additionalCount + 1
            end
        end

        local maxAdditionalCount = summonMultipleTrapParam:GetMaxAdditionalCount() or additionalCount
        additionalCount = math.min(additionalCount, maxAdditionalCount)

    end

    local summonTrapResultArray = {}

    if randomSummon then
        local randomFunc
        if useBoardRandom then
            randomFunc = randomSvc.BoardLogicRand
        else
            randomFunc = randomSvc.LogicRand
        end

        local randCount = maxCount
        local minRandCount, maxRandCount = summonMultipleTrapParam:GetRandCount()
        if minRandCount and maxRandCount then
            randCount = randomFunc(randomSvc, minRandCount, maxRandCount)
        end
        randCount = randCount + additionalCount
        while ((#summonTrapResultArray < randCount) and (#validPosArray) > 0) do
            local randIdx = randomFunc(randomSvc, 1, #validPosArray)
            local gridPos = table.remove(validPosArray, randIdx)

            table.insert(summonTrapResultArray,
                SkillSummonTrapEffectResult:New(trapID, gridPos, summonMultipleTrapParam:IsTransferDisabled()))
        end
    else
        maxCount = maxCount + additionalCount

        local sortedValidPosArray = self:SortValidPiecePos(sortValidPosType, validPosArray, skillEffectCalcParam.centerPos)

        for _, gridPos in ipairs(sortedValidPosArray) do
            if #summonTrapResultArray >= maxCount then
                break
            end

            table.insert(summonTrapResultArray,
                SkillSummonTrapEffectResult:New(trapID, gridPos, summonMultipleTrapParam:IsTransferDisabled()))
        end
    end

    return summonTrapResultArray
end

function SkillEffectCalc_SummonMultipleTrap:IsPosHasBlockTrap(pos, blockSummonTrapType)
    if not blockSummonTrapType then
        return false
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local isValidPos = utilSvc:IsValidPiecePos(pos)
    if not isValidPos then
        return false
    end

    local samePosTraps = utilSvc:GetTrapsAtPos(pos)
    if #samePosTraps == 0 then
        return false
    end

    for _, e in ipairs(samePosTraps) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        local type = trapCmpt:GetTrapType()
        if table.icontains(blockSummonTrapType, type) and trapCmpt:IsBlockSummon() then
            return true
        end
    end

    return false
end

function SkillEffectCalc_SummonMultipleTrap:SortValidPiecePos(type, array, centerPos)
    if type == 1 then -- 目前只有一种情况所以没有写枚举
        local dicPosByRing = {}
        local tablePosByRing = {}

        -- 按圈排列
        for _, candidate in ipairs(array) do
            local disX = math.abs(centerPos.x - candidate.x)
            local disY = math.abs(centerPos.y - candidate.y)
            local disRingCount = math.max(disX, disY) - 1
            if not dicPosByRing[disRingCount] then
                local t = {
                    array = {},
                    ring = disRingCount
                }
                dicPosByRing[disRingCount] = t
                table.insert(tablePosByRing, t)
            end
            table.insert(dicPosByRing[disRingCount].array, candidate)
        end

        -- 圈数更远的位置优先
        table.sort(tablePosByRing, function (a, b)
            -- a.ring 一定不能等于b.ring
            return a.ring > b.ring
        end)

        local t = {}

        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        -- 圈相同的情况下，对格子进行随机
        for _, data in ipairs(tablePosByRing) do
            local shuffled = table.cloneconf(data.array)
            local maxn = #data.array
            for i = 1, maxn do
                local rand = randomSvc:LogicRand(1, maxn)
                shuffled[i], shuffled[rand] = shuffled[rand], shuffled[i]
            end
            data.shuffled = shuffled --简单小引用，debug大用处

            table.appendArray(t, shuffled)
        end

        return t
    end

    return array
end
