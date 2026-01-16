--[[
    SummonEverything = 34, ---召唤一切
]]
---@class SkillEffectCalc_SummonEverything: Object
_class("SkillEffectCalc_SummonEverything", Object)
SkillEffectCalc_SummonEverything = SkillEffectCalc_SummonEverything

function SkillEffectCalc_SummonEverything:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type MathService
    self._mathService = self._world:GetService("Math")
    ---初始化召唤行为功能函数表
    if nil == self.m_listFuncCalSummonID then
        self.m_listFuncCalSummonID = {}
        self.m_listFuncCalSummonID[SkillEffectEnum_SummonBehavior.Random] = self._CalSummonID_Random
        self.m_listFuncCalSummonID[SkillEffectEnum_SummonBehavior.RandomDifferent] = self._CalSummonID_RandomDifferent
        self.m_listFuncCalSummonID[SkillEffectEnum_SummonBehavior.OutOfGridRange] = self._CalSummonID_OutOfRangeTrap
    end
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonEverything:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local posCaster = casterEntity:GetGridPosition()

    ---召唤时，gridPos是召唤的下标，真正的坐标需要重新算

    ---@type SkillEffectParam_SummonEverything
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local summonResArray = {}

    local nSummonType = skillEffectParam:GetSummonType()
    local nSummonList = skillEffectParam:GetSummonList()
    local nSummonBehavior = skillEffectParam:GetSummonBehavior() ---获取召唤怪物的行为 随机还是非随机
    local nSummonNumber = skillEffectParam:GetSummonNumber() ---如果是非随机召唤是召唤怪物数量 如果是随机召唤就是随机召唤次数
    local tSummonNumberRange = skillEffectParam:GetSummonNumberRange() ---次数区间，如果有值，则次数需要从区间随机
    local nSummonMonsterLimitCount = skillEffectParam:GetSummonMonsterLimitCount()
    local tLimitCheckID = skillEffectParam:GetLimitCheckID()
    local bIgnoreBlock = skillEffectParam:IsIgnoreBlock()
    local exceptionType = skillEffectParam:GetSummonExceptionType()
    local bCheckIgnoreBodyArea = skillEffectParam:GetSummonCheckIgnoreBodyArea()
    --MSG45408 A/A1...召唤B，B可以再召唤A/A1...，利用buff value来传递A/A1...的ID,在B召唤时替换召唤ID
    local bUseRecordIDAsSummonID = skillEffectParam:IsUseRecordIDAsSummonID()
    if bUseRecordIDAsSummonID then
        local cBuff = casterEntity:BuffComponent()
        if cBuff then
            local recordID = tonumber(cBuff:GetBuffValue("RecordSummonerCfgID")) or 0
            if recordID > 0 then
                nSummonList = {recordID}
            end
        end
    end

    local blockType = nil
    if bIgnoreBlock then
        blockType = BlockFlag.None
    end
    if tSummonNumberRange then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        ---产生随机数
        local random = randomSvc:LogicRand(tSummonNumberRange.min, tSummonNumberRange.max)
        nSummonNumber = random
    end
    -- 随机生成的列表需要特殊处理
    local listSummonID = self:_CalSummonID(nSummonBehavior, nSummonNumber, nSummonList)

    local nSummonTimes = 1 -- 同一个怪的召唤次数
    -- 非随机怪需要召唤的怪的数量
    if nSummonBehavior == SkillEffectEnum_SummonBehavior.Nonrandom then
        nSummonTimes = nSummonNumber
    end

    local searchRing9 = false
    if exceptionType == SkillEffectEnum_SummonExceptionType.Ring9 then
        searchRing9 = true
    end
    local listPosHaveDown = {}
    for key, v in ipairs(listSummonID) do
        for i = 1, nSummonTimes do
            --检查是否到达召唤上限
            local canSummon =
                self:_CheckSummonEverythingLimitCount(
                casterEntity,
                #summonResArray,
                nSummonType,
                listSummonID,
                nSummonMonsterLimitCount,
                tLimitCheckID
            )
            if canSummon then
                local curSummonID = v
                local posSummon = nil
                if nSummonBehavior == SkillEffectEnum_SummonBehavior.OutOfGridRange then
                    posSummon = skillEffectCalcParam.skillRange[key]
                else
                    local range = skillEffectCalcParam.skillRange
                    if searchRing9 then
                        range = skillEffectCalcParam.wholeRange
                    end
                    posSummon =
                        self._skillEffectService:_FindSummonPos(
                        nSummonType,
                        range,
                        curSummonID,
                        listPosHaveDown,
                        blockType,
                        searchRing9,
                        bCheckIgnoreBodyArea
                    )
                end
                if not posSummon then
                    if exceptionType == SkillEffectEnum_SummonExceptionType.Around4 then
                        posSummon =
                            self:ExceptionAround4(
                            self._world,
                            nSummonType,
                            skillEffectCalcParam.skillRange,
                            curSummonID,
                            listPosHaveDown,
                            blockType
                        )
                    elseif exceptionType == SkillEffectEnum_SummonExceptionType.Around4AndNearToFar then
                        posSummon =
                            self:ExceptionAround4(
                            self._world,
                            nSummonType,
                            skillEffectCalcParam.skillRange,
                            curSummonID,
                            listPosHaveDown,
                            blockType
                        )

                        if not posSummon then
                            posSummon =
                                self:ExceptionAroundSquareRing(
                                self._world,
                                nSummonType,
                                skillEffectCalcParam.skillRange,
                                curSummonID,
                                listPosHaveDown,
                                blockType
                            )
                        end
                    elseif exceptionType == SkillEffectEnum_SummonExceptionType.Around4AndNearToFarNoRandom then
                        local range = skillEffectCalcParam.skillRange
                        if range and #range < 1 then
                            range = skillEffectCalcParam.wholeRange
                        end
                        posSummon = self:Around4AndNearToFarNoRandom(
                            self._world,
                            nSummonType,
                            range,
                            curSummonID,
                            listPosHaveDown,
                            blockType,
                            true
                        )
                    end
                    if not posSummon then
                        Log.info(
                            "[SkillEffectCalcService] SummonEverything: not enough space at [",
                            key,
                            "], skipping. "
                        )
                        break
                    end
                end
                if posSummon then
                    local summonResult =
                        SkillEffectResult_SummonEverything:New(nSummonType, curSummonID, posCaster, posSummon)
                    summonResArray[#summonResArray + 1] = summonResult
                end
            end
        end
    end

    return summonResArray
end

---检查是否到达召唤上限
function SkillEffectCalc_SummonEverything:_CheckSummonEverythingLimitCount(
    casterEntity,
    hadSummonCount,
    nSummonType,
    nSummonID,
    nSummonMonsterLimitCount,
    tLimitCheckID)
    local canSummon = true
    --0 没有召唤限制
    if nSummonMonsterLimitCount == 0 then
        return canSummon
    end
    local checkIDs = nSummonID
    if tLimitCheckID and #tLimitCheckID > 0 then
        checkIDs = tLimitCheckID
    end
    if SkillEffectEnum_SummonType.Monster == nSummonType then
        local hadCount = 0
        hadCount = hadSummonCount

        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        if monsterGroup then
            for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
                if not monsterEntity:HasDeadMark() then
                    local monsterID = monsterEntity:MonsterID():GetMonsterID()
                    if table.intable(checkIDs, monsterID) then
                        hadCount = hadCount + 1
                    end

                    if hadCount >= nSummonMonsterLimitCount then
                        return false
                    end
                end
            end
        end
    elseif SkillEffectEnum_SummonType.Trap == nSummonType then
        --没考虑重叠
        local hadCount = 0
        hadCount = hadSummonCount
        local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        if trapGroup then
            for _, trapEntity in ipairs(trapGroup:GetEntities()) do
                if not trapEntity:HasDeadMark() then
                    local trapID = trapEntity:Trap():GetTrapID()
                    if table.intable(checkIDs, trapID) then
                        hadCount = hadCount + 1
                    end
                    if hadCount >= nSummonMonsterLimitCount then
                        return false
                    end
                end
            end
        end
    end

    return canSummon
end

function SkillEffectCalc_SummonEverything:_CalSummonID(nSummonBehavior, nSummonNumber, nSummonList)
    local pFunction = self.m_listFuncCalSummonID[nSummonBehavior]
    if nil == pFunction then
        return nSummonList
    end
    return pFunction(self, nSummonNumber, nSummonList)
end

---从给定的技能效果列表里召唤
function SkillEffectCalc_SummonEverything:_CalSummonID_Random(nSummonNumber, nSummonList)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    local listSummonID = {}
    local nSummonTableNum = table.count(nSummonList) ---召唤列表中的id数量
    if nSummonTableNum > 1 then
        for i = 1, nSummonNumber do
            local nRandomIndex = randomSvc:LogicRand(1, nSummonTableNum)
            listSummonID[#listSummonID + 1] = nSummonList[nRandomIndex]
        end
    end
    return listSummonID
end

---从给的列表里随机nSummonNumber次不同的
function SkillEffectCalc_SummonEverything:_CalSummonID_RandomDifferent(nSummonNumber, nSummonList)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    local listSummonID = {}
    local nSummonTableNum = table.count(nSummonList) ---召唤列表中的id数量
    if nSummonTableNum > 1 then
        while table.count(listSummonID) < nSummonNumber do
            local nRandomIndex = randomSvc:LogicRand(1, nSummonTableNum)

            local monsterID = nSummonList[nRandomIndex]
            if not table.icontains(listSummonID, monsterID) then
                listSummonID[#listSummonID + 1] = nSummonList[nRandomIndex]
            end
        end
    end
    return listSummonID
end
---场外召唤机关
function SkillEffectCalc_SummonEverything:_CalSummonID_OutOfRangeTrap(nSummonNumber, nSummonList)
    return nSummonList
end

---@param boardServiceLogic BoardServiceLogic
function SkillEffectCalc_SummonEverything:_CalTrapSommonPos(boardServiceLogic, nTrapID, listPosPlan)
    local posSummon = nil
    local cfgTrap = Cfg.cfg_trap[nTrapID]
    local trapBodyArea = {}
    if cfgTrap then
        for key, value in ipairs(cfgTrap.Area) do
            local posTemp = Vector2(tonumber(value[1]), tonumber(value[2]))
            table.insert(trapBodyArea, posTemp)
        end
    end

    for i = 1, #listPosPlan do
        local posTemp = Vector2.New(listPosPlan[i].x, listPosPlan[i].y)
        local bIsBlock = false
        if #trapBodyArea > 0 then
            bIsBlock = boardServiceLogic:IsPosBlockByArea(posTemp, BlockFlag.SummonTrap, trapBodyArea, nil)
        else
            bIsBlock = boardServiceLogic:IsPosBlock(posTemp, BlockFlag.SummonTrap)
        end
        if not bIsBlock then
            posSummon = posTemp
            break
        end
    end
    return posSummon
end

---@param skillRange Vector2[]
function SkillEffectCalc_SummonEverything:ExceptionAround4(
    world,
    nSummonType,
    skillRange,
    curSummonID,
    listPosHaveDown,
    blockType,
    noRandom)
    ---@type Vector2[]
    local exceptionRange = {}
    ---@type BoardServiceLogic
    local boardSvc = world:GetService("BoardLogic")
    for _, pos in ipairs(skillRange) do
        local up = Vector2(pos.x, pos.y + 1)
        local down = Vector2(pos.x, pos.y - 1)
        local left = Vector2(pos.x + 1, pos.y)
        local right = Vector2(pos.x - 1, pos.y)
        if boardSvc:IsValidPiecePos(up) and not table.Vector2Include(exceptionRange, up) then
            table.insert(exceptionRange, up)
        end
        if boardSvc:IsValidPiecePos(down) and not table.Vector2Include(exceptionRange, down) then
            table.insert(exceptionRange, down)
        end
        if boardSvc:IsValidPiecePos(left) and not table.Vector2Include(exceptionRange, left) then
            table.insert(exceptionRange, left)
        end
        if boardSvc:IsValidPiecePos(right) and not table.Vector2Include(exceptionRange, right) then
            table.insert(exceptionRange, right)
        end
    end
    return self._skillEffectService:_FindSummonPos(nSummonType, exceptionRange, curSummonID, listPosHaveDown, blockType,
        nil, nil, noRandom)
end

---@param skillRange Vector2[]
function SkillEffectCalc_SummonEverything:ExceptionAroundSquareRing(
    world,
    nSummonType,
    skillRange,
    curSummonID,
    listPosHaveDown,
    blockType,
    noRandom)
    ---@type BoardServiceLogic
    local boardSvc = world:GetService("BoardLogic")
    local maxLen = boardSvc:GetCurBoardMaxLen()
    local posSummon

    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    for i = 1, maxLen do
        ---@type Vector2[]
        local posList = ComputeScopeRange.ComputeRange_SquareRing(skillRange[1], 1, i, true)

        posSummon =
            self._skillEffectService:_FindSummonPos(nSummonType, posList, curSummonID, listPosHaveDown, blockType,
                nil, nil, noRandom)

        if posSummon then
            return posSummon
        end
    end

    return posSummon
end

function SkillEffectCalc_SummonEverything:Around4AndNearToFarNoRandom(
    world,
    nSummonType,
    skillRange,
    curSummonID,
    listPosHaveDown,
    blockType,
    noRandom
)
    local posSummon =
        self:ExceptionAround4(
            world,
            nSummonType,
            skillRange,
            curSummonID,
            listPosHaveDown,
            blockType,
            noRandom
        )

    if not posSummon then
        posSummon =
            self:ExceptionAroundSquareRing(
                world,
                nSummonType,
                skillRange,
                curSummonID,
                listPosHaveDown,
                blockType,
                noRandom
            )
    end

    return posSummon
end
