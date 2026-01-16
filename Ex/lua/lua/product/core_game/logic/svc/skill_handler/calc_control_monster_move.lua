--[[
    ControlMonsterMove = 200, -- 控制目标怪物位移(n28蜘蛛)
]]
---@class SkillEffectCalc_ControlMonsterMove : SkillEffectCalc_Base
_class("SkillEffectCalc_ControlMonsterMove", SkillEffectCalc_Base)
SkillEffectCalc_ControlMonsterMove = SkillEffectCalc_ControlMonsterMove

function SkillEffectCalc_ControlMonsterMove:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ControlMonsterMove:DoSkillEffectCalculator(skillEffectCalcParam)
    self._skillEffectCalcParam = skillEffectCalcParam
    ---@type SkillEffectParamControlMonsterMove
    local skillParam = skillEffectCalcParam.skillEffectParam

    local targetMonsterClassID = skillParam:GetMonsterClassID()

    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterPos = casterEntity:GetGridPosition()
    local casterDir = casterEntity:GetGridDirection()
    self._casterBodyPosList = {}
    for _, area in ipairs(casterBodyArea) do
        local workPos = area + casterPos
        table.insert(self._casterBodyPosList, workPos)
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    self._monsterBodyPosList = utilDataSvc:GetAllMonsterPos()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local selectXPosList = {}
    local selectYPosList = {}
    -- local selectXPosListNotBlock = {}
    -- local selectYPosListNotBlock = {}
    --剩余的坐标
    self._residueEdgePosXList = {}
    self._residueEdgePosYList = {}
    -- for _, pos in ipairs(selectXPosList) do
    --     if not table.intable(selectXPosListNotBlock, pos) then
    --         table.insert(self._residueEdgePosXList, pos)
    --     end
    -- end
    -- for _, pos in ipairs(selectYPosList) do
    --     if not table.intable(selectYPosListNotBlock, pos) then
    --         table.insert(self._residueEdgePosYList, pos)
    --     end
    -- end

    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local arr = board:GetBlockFlagArray()
    for x, col in pairs(arr) do
        for y, block in pairs(col) do
            local grid = Vector2(x, y)
            --只判断被玩家阻挡   如果在BOSS的身形内则不算
            local isBlock = utilDataSvc:IsPosBlock(grid, BlockFlag.MonsterLand)
            local isCasterBodyPos = table.intable(self._monsterBodyPosList, grid)
            if x == 1 then
                table.insert(selectXPosList, grid)
                if isCasterBodyPos or (not isBlock) then
                    -- table.insert(selectXPosListNotBlock, grid)
                    table.insert(self._residueEdgePosXList, grid)
                end
            end
            if y == 9 and not table.intable(selectXPosList, grid) then
                table.insert(selectYPosList, grid)
                if isCasterBodyPos or (not isBlock) then
                    -- table.insert(selectYPosListNotBlock, grid)
                    table.insert(self._residueEdgePosYList, grid)
                end
            end
        end
    end

    --优先选择就在边上的

    local scopeParamEdge = {x = 1, y = 9, type = BoardSelectEdgeRandomAndExtendType.None}
    ---@type SkillScopeResult
    local scopeResultEdge =
        scopeCalculator:ComputeScopeRange(
        SkillScopeType.BoardSelectEdgeRandomAndExtend,
        scopeParamEdge,
        casterPos,
        casterBodyArea,
        casterDir
    )

    --边上的范围
    self._scopeResultEdgeRange = scopeResultEdge:GetAttackRange()
    --用过的坐标，中转的时候虽然不考虑阻挡，但是也会考虑是否使用过该线路
    self._useEdgePosList = {}
    --用过的终点
    self._useEndEdgePosList = {}

    -- --剩余的坐标
    -- self._residueEdgePosXList = {}
    -- self._residueEdgePosYList = {}
    -- for _, pos in ipairs(selectXPosList) do
    --     if not table.intable(selectXPosListNotBlock, pos) then
    --         table.insert(self._residueEdgePosXList, pos)
    --     end
    -- end
    -- for _, pos in ipairs(selectYPosList) do
    --     if not table.intable(selectYPosListNotBlock, pos) then
    --         table.insert(self._residueEdgePosYList, pos)
    --     end
    -- end

    local onEdgeMonsterEntity = {}
    local moveMonsterEntity = {}

    local monsterEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, entity in ipairs(monsterEntityList) do
        local curMonsterClassID = entity:MonsterID():GetMonsterClassID()
        if not entity:HasDeadMark() and targetMonsterClassID == curMonsterClassID then
            local monsterPos = entity:GetGridPosition()
            if table.intable(self._scopeResultEdgeRange, monsterPos) then
                table.insert(onEdgeMonsterEntity, entity)
            else
                table.insert(moveMonsterEntity, entity)
            end
        end
    end

    self._hasSummonTrapPosList = {}

    --在边上的直接计算位移后的
    for _, entity in ipairs(onEdgeMonsterEntity) do
        local posStart = entity:GetGridPosition()
        local posMiddle = entity:GetGridPosition()
        table.insert(self._useEdgePosList, posMiddle)
        local posEnd, posList, dir = self:_CalcLineToEdgeEnd(posMiddle)
        table.insert(self._useEndEdgePosList, posEnd)

        self:_AddResult(entity, posStart, posMiddle, posEnd, posList, dir)
    end

    for _, pos in ipairs(self._useEdgePosList) do
        table.removev(self._residueEdgePosXList, pos)
        table.removev(self._residueEdgePosYList, pos)
    end

    --有不在边上的怪物
    for _, entity in ipairs(moveMonsterEntity) do
        local posStart = entity:GetGridPosition()
        local posMiddle = self:_CalcEdgeEmpty(posStart)
        if posMiddle then
            local posEnd, posList, dir = self:_CalcLineToEdgeEnd(posMiddle)
            self:_AddResult(entity, posStart, posMiddle, posEnd, posList, dir)
        end
    end

    --最后再计算本体的位移
end

function SkillEffectCalc_ControlMonsterMove:_AddResult(entity, posStart, posMiddle, posEnd, posList, dir)
    ---@type SkillEffectParamControlMonsterMove
    local skillParam = self._skillEffectCalcParam.skillEffectParam
    local trapID = skillParam:GetTrapID()
    local stageIndex = skillParam:GetSkillEffectDamageStageIndex()

    local casterEntity = self._world:GetEntityByID(self._skillEffectCalcParam.casterEntityID)

    local monsterBodyArea = entity:BodyArea():GetArea()
    local monsterPos = entity:GetGridPosition()
    local monsterDir = entity:GetGridDirection()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    --加血结果入SkillRoutine
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    --伤害
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local teamPos = teamEntity:GetGridPosition()
    local damageInfo = nil
    if table.intable(posList, teamPos) then
        ---@type SkillEffectCalcService
        local effectCalcSvc = self._skillEffectService
        local nTotalDamage, listDamageInfo =
            effectCalcSvc:ComputeSkillDamage(
            entity,
            posEnd,
            teamEntity,
            teamPos,
            self._skillEffectCalcParam.skillID,
            skillParam,
            SkillEffectType.Damage,
            stageIndex
        )

        ---@type SkillDamageEffectResult
        local skillDamageEffectResult =
            effectCalcSvc:NewSkillDamageEffectResult(
            teamPos,
            teamEntity:GetID(),
            nTotalDamage,
            listDamageInfo,
            stageIndex
        )
        skillDamageEffectResult:SetCasterID(entity:GetID())
        skillEffectResultContainer:AddEffectResult(skillDamageEffectResult)
        damageInfo = listDamageInfo
    end

    --召唤机关
    for _, pos in ipairs(posList) do
        --召唤过的就不召唤了 and  不是队伍坐标
        if not table.intable(self._hasSummonTrapPosList, pos) and teamPos ~= pos then
            ---@type SkillSummonTrapEffectResult
            local skillSummonTrapEffectResult = SkillSummonTrapEffectResult:New(trapID, pos, nil, stageIndex)
            table.insert(self._hasSummonTrapPosList, pos)
            skillEffectResultContainer:AddEffectResult(skillSummonTrapEffectResult)
        end
    end

    --表现需要A到B再到C
    ---@type SkillEffectResultControlMonsterMove
    local skillEffectResultControlMonsterMove =
        SkillEffectResultControlMonsterMove:New(entity:GetID(), posStart, posMiddle, posEnd, dir)
    skillEffectResultContainer:AddEffectResult(skillEffectResultControlMonsterMove)

    --实际结果是直接从A到C点
    local colorOld = utilDataSvc:FindPieceElement(monsterPos)
    ---@type SkillEffectResult_Teleport
    local skillEffectResult_Teleport =
        SkillEffectResult_Teleport:New(entity:GetID(), monsterPos, colorOld, posEnd, monsterDir, stageIndex)
    skillEffectResultContainer:AddEffectResult(skillEffectResult_Teleport)
end

function SkillEffectCalc_ControlMonsterMove:_CalcEdgeEmpty(posStart)
    local residueEdgePosXCount = table.count(self._residueEdgePosXList)
    local residueEdgePosYCount = table.count(self._residueEdgePosYList)

    --如果可以用的位置为nil
    if residueEdgePosXCount == 0 and residueEdgePosYCount == 0 then
        return nil
    end

    local posEnd = posStart

    --先计算还有多少空位
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local randomXorY = randomSvc:LogicRand(1, 2)
    if randomXorY == 1 then
        if residueEdgePosXCount ~= 0 then
            posEnd = self:_GetRandomX()
        else
            posEnd = self:_GetRandomY()
        end
    elseif randomXorY == 2 then
        if residueEdgePosYCount ~= 0 then
            posEnd = self:_GetRandomY()
        else
            posEnd = self:_GetRandomX()
        end
    end

    return posEnd
end

function SkillEffectCalc_ControlMonsterMove:_GetRandomX()
    local residueEdgePosXCount = table.count(self._residueEdgePosXList)
    local posTarget = nil
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local randomIndex = randomSvc:LogicRand(1, residueEdgePosXCount)
    posTarget = self._residueEdgePosXList[randomIndex]
    table.removev(self._residueEdgePosXList, posTarget)
    return posTarget
end

function SkillEffectCalc_ControlMonsterMove:_GetRandomY()
    local residueEdgePosYCount = table.count(self._residueEdgePosYList)
    local posTarget = nil
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local randomIndex = randomSvc:LogicRand(1, residueEdgePosYCount)
    posTarget = self._residueEdgePosYList[randomIndex]
    table.removev(self._residueEdgePosYList, posTarget)
    return posTarget
end

function SkillEffectCalc_ControlMonsterMove:_CalcLineToEdgeEnd(posStart)
    if not posStart then
        return nil
    end

    local posEnd = posStart
    local posTarget = nil
    local dir = nil

    if posStart.x == 1 and posStart.y == BattleConst.DefaultMaxY then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local randomXorY = randomSvc:LogicRand(1, 2)
        if randomXorY == 1 then
            posTarget, dir = self:_MoveOnX(posStart)
        elseif randomXorY == 2 then
            posTarget, dir = self:_MoveOnY(posStart)
        end
    elseif posStart.x == 1 then
        posTarget, dir = self:_MoveOnX(posStart)
    elseif posStart.y == BattleConst.DefaultMaxY then
        posTarget, dir = self:_MoveOnY(posStart)
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    --被阻挡 但是不是被施法者阻挡
    for i = 1, BattleConst.DefaultMaxX do
        local dis = Vector2(dir.x * (i - 1), dir.y * (i - 1))
        --从版边开始往出发点计算阻挡
        local posWork = posTarget - dis
        local isBlock = utilData:IsPosBlock(posWork, BlockFlag.MonsterLand)
        local isCasterBodyPos = table.intable(self._monsterBodyPosList, posWork)
        --没有被其他移动的怪物占住

        local otherUse = table.intable(self._useEndEdgePosList, posWork)
        if (isCasterBodyPos or (not isBlock)) and not otherUse then
            -- if not isCasterBodyPos and isBlock then
            posEnd = posWork
            break
        end
    end

    local posList = {}
    for i = 1, BattleConst.DefaultMaxX do
        local dis = Vector2(dir.x * (i - 1), dir.y * (i - 1))
        local posWork = posStart + dis
        table.insert(posList, posWork)
        if posWork == posEnd then
            break
        end
    end

    return posEnd, posList, dir
end

function SkillEffectCalc_ControlMonsterMove:_MoveOnX(posStart)
    local posTarget = Vector2(BattleConst.DefaultMaxX, posStart.y)
    local dir = Vector2(1, 0)
    return posTarget, dir
end
function SkillEffectCalc_ControlMonsterMove:_MoveOnY(posStart)
    local posTarget = Vector2(posStart.x, 1)
    local dir = Vector2(0, -1)
    return posTarget, dir
end
