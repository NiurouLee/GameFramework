--[[
    RubikCube = 164, --魔方
]]
---@class SkillEffectCalc_RubikCube: Object
_class("SkillEffectCalc_RubikCube", Object)
SkillEffectCalc_RubikCube = SkillEffectCalc_RubikCube

function SkillEffectCalc_RubikCube:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_RubikCube:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamRubikCube
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    ---@type BattleStatComponent
    local battleCmpt = self._world:BattleStat()
    local curRound = battleCmpt:GetLevelTotalRoundCount()

    ---@type SkillEffectResultRubikCube
    local result = SkillEffectResultRubikCube:New()

    --
    self._centerPos = Vector2(4, 4)

    local dir = Vector2(-1, 0)
    local rotateAngle = 0
    local radian = 0
    --移动的棋盘
    local boardList = {}
    local rangeListX = {}
    local rangeListY = {}
    local posList = {}

    local aloneBoard = nil

    --从11到17是-90
    --从17到11是90

    --单回合横转 双回合竖转
    if curRound % 2 == 0 then
        dir = Vector2(-1, 0)
        boardList = {1, 4, 3, 2}
        rangeListX = {1, 2, 3, 4, 5, 6, 7}
        --优先考虑y=567的范围
        local priorityY = {5, 6, 7}
        if not table.intable(priorityY, teamPos.y) then
            rangeListY = {5, 6, 7}
            aloneBoard = 6
            rotateAngle = -90
        else
            rangeListY = {1, 2, 3}
            aloneBoard = 5
            rotateAngle = 90
        end

        result:SetRubikCubeTargetAngle(Vector3(0, 0, 90))
    else
        dir = Vector2(0, 1)
        boardList = {1, 6, 3, 5}
        rangeListY = {1, 2, 3, 4, 5, 6, 7}
        --优先考虑x=567的范围
        local priorityX = {5, 6, 7}
        if not table.intable(priorityX, teamPos.x) then
            rangeListX = {5, 6, 7}
            aloneBoard = 2
            rotateAngle = -90
        else
            rangeListX = {1, 2, 3}
            aloneBoard = 4
            rotateAngle = 90
        end
        result:SetRubikCubeTargetAngle(Vector3(90, 0, 0))
    end

    result:SetAloneBoard(aloneBoard)

    --角度换成弧度
    radian = rotateAngle * math.pi / 180

    --转动的范围
    for i = 1, table.count(rangeListX) do
        local x = rangeListX[i]
        for j = 1, table.count(rangeListY) do
            local y = rangeListY[j]
            local posWork = Vector2(x, y)
            table.insert(posList, posWork)
        end
    end

    local aloneBoardPosList = {}
    for x = 1, 7 do
        for y = 1, 7 do
            local pos = Vector2(x, y)
            table.insert(aloneBoardPosList, pos)
        end
    end

    --[1]设置颜色
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()
    ---@type BoardMultiComponent
    local boardMultiComponent = boardEntity:BoardMulti()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type BoardMultiServiceLogic
    local boardMultiServiceLogic = self._world:GetService("BoardMultiLogic")

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local rubikBoardList = {}
    for i, boardIndex in ipairs(boardList) do
        local rubikBoard = self:_CalcRubikBoard(boardList, i)
        table.insert(rubikBoardList, rubikBoard)
    end
    --加入单转的面
    local rubikBoard = {}
    rubikBoard.fromBoard = aloneBoard
    rubikBoard.toBoard = aloneBoard
    table.insert(rubikBoardList, rubikBoard)

    --筛选entity用的，目前都筛选
    local filter = function(e)
        -- return not e:HasDeadMark()

        if (e:HasMonsterID() or e:HasTrapID()) and not e:HasDeadMark() then
            return true
        end

        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion and outsideRegion:GetMonsterID() then
            return true
        end

        return false
    end

    local rubikList = {}

    local destroyTrap = {}
    for _, rubikBoard in ipairs(rubikBoardList) do
        local fromBoard = rubikBoard.fromBoard
        local toBoard = rubikBoard.toBoard

        local calcPosList = posList
        if fromBoard == toBoard then
            calcPosList = aloneBoardPosList
        end

        --当前棋盘
        for _, pos in ipairs(calcPosList) do
            -- local rubikEnv = {}

            local oldPos = pos
            local newPos = pos
            if fromBoard == 6 and toBoard == 3 then
                newPos = self:_GetOppositeBoardPos(oldPos)
            elseif fromBoard == 3 and toBoard == 5 then
                oldPos = self:_GetOppositeBoardPos(newPos)
            end

            --单转
            if fromBoard == toBoard then
                newPos = self:_GetAloneBoardAotatePos(oldPos, radian)
            end

            local oldPieceType = PieceType.None
            local newPieceType = PieceType.None
            local es = {}
            local isPrism = nil
            local prismEntityID = nil
            if fromBoard == 1 then
                newPieceType = boardComponent:GetPieceType(oldPos)
                es = boardComponent:GetPieceEntities(oldPos, filter)
                isPrism = boardComponent:IsPrismPiece(oldPos)
                prismEntityID = boardComponent:GetPrismEntityIDAtPos(oldPos)
            else
                newPieceType = boardMultiComponent:GetPieceType(oldPos, fromBoard)
                es = boardMultiComponent:GetPieceEntities(fromBoard, oldPos, filter)
                isPrism = boardMultiComponent:IsPrismPiece(fromBoard, oldPos)
            end

            if toBoard == 1 then
                oldPieceType = boardComponent:GetPieceType(newPos)
            else
                oldPieceType = boardMultiComponent:GetPieceType(newPos, toBoard)
            end

            --基础面的棋盘 and 召唤者是光灵 才会删机关
            if fromBoard == 1 then
                for _, e in ipairs(es) do
                    ---@type Entity
                    local summonEntity = e:GetSummonerEntity()
                    local summonIsPet = summonEntity and summonEntity:HasPet()

                    ---@type Entity
                    local summonSuperEntity = nil
                    if summonEntity and summonEntity:GetSuperEntity() then
                        summonSuperEntity = summonEntity:GetSuperEntity()
                    end
                    local summonSuperIsPet = summonEntity and summonSuperEntity and summonSuperEntity:HasPet()
                    if e:HasTrapID() and (summonIsPet or summonSuperIsPet) then
                        table.insert(destroyTrap, e)
                    end
                end
            end

            local envIndex = #rubikList + 1
            rubikList[envIndex] = {
                index = envIndex,
                fromBoard = fromBoard,
                toBoard = toBoard,
                oldPos = oldPos,
                newPos = newPos,
                oldPieceType = oldPieceType,
                newPieceType = newPieceType,
                entityList = es,
                isPrism = isPrism,
                prismEntityID = prismEntityID
            }
        end
    end

    --apply remove
    for _, rubikData in ipairs(rubikList) do
        local fromBoard = rubikData.fromBoard
        -- local toBoard = rubikData.toBoard
        local oldPos = rubikData.oldPos
        local newPos = rubikData.newPos
        local entityList = rubikData.entityList
        local isPrism = rubikData.isPrism

        if fromBoard == 1 then
            if isPrism then
                boardComponent:RemovePrismPiece(oldPos)
            end
            for _, e in ipairs(entityList) do
                -- local gridPosition = e:GetGridPosition()
                boardServiceLogic:RemoveEntityBlockFlag(e, oldPos)
            end
        else
            if isPrism then
                boardMultiComponent:RemovePrismPiece(fromBoard, oldPos)
            end
            for _, e in ipairs(entityList) do
                -- local gridPosition = e:GetGridPosition()
                boardMultiServiceLogic:RemoveEntityBlockFlagMultiBoard(fromBoard, e, oldPos)
            end
        end
    end

    --apply set
    for _, rubikData in ipairs(rubikList) do
        local fromBoard = rubikData.fromBoard
        local toBoard = rubikData.toBoard
        local oldPos = rubikData.oldPos
        local newPos = rubikData.newPos
        local entityList = rubikData.entityList
        local isPrism = rubikData.isPrism
        local prismEntityID = rubikData.prismEntityID
        local oldPieceType = rubikData.oldPieceType
        local newPieceType = rubikData.newPieceType

        --skill result
        result:AddRubikCubePiece(oldPos, newPos, fromBoard, toBoard)
        result:AddConvertColor(oldPos, newPos, oldPieceType, newPieceType, fromBoard, toBoard)
        if isPrism then
            result:AddRubikCubePrism(oldPos, newPos, fromBoard, toBoard)
        end
        for _, e in ipairs(entityList) do
            result:AddRubikCubeEntity(e:GetID(), oldPos, newPos, fromBoard, toBoard)
        end
        --skill result

        if toBoard == 1 then
            boardServiceLogic:SetPieceTypeLogic(newPieceType, newPos)
            if isPrism then
                boardComponent:AddPrismPiece(newPos, prismEntityID)
            end
        else
            boardMultiServiceLogic:SetPieceTypeLogic(toBoard, newPieceType, newPos)
            if isPrism then
                boardMultiComponent:AddPrismPiece(toBoard, newPos)
            end
        end

        --entity
        for _, e in ipairs(entityList) do
            ---@type Entity
            local e = e
            ---@type OutsideRegionComponent
            local outsideRegion = e:OutsideRegion()
            local blockFlag = boardServiceLogic:GetBlockFlag(e)
            ---@type BuffComponent
            local buffComponent = e:BuffComponent()
            if toBoard == 1 then
                boardServiceLogic:SetEntityBlockFlag(e, newPos, blockFlag)

                local monsterID = outsideRegion:GetMonsterID()
                if monsterID then
                    e:ReplaceComponent(e:GetMonsterIDComponentEnum(), monsterID)
                end

                --多面组件
                e:RemoveOutsideRegion()

                buffComponent:SetBuffValue("Freeze", nil)
            else
                boardMultiServiceLogic:SetEntityBlockFlagMultiBoard(toBoard, e, newPos, blockFlag)
                --多面组件
                if not outsideRegion then
                    e:AddOutsideRegion(toBoard)
                    outsideRegion = e:OutsideRegion()
                end
                outsideRegion:SetBoardIndex(toBoard)

                --转到其他面的要冻结buff组件
                buffComponent:SetBuffValue("Freeze", 1)
            end

            if newPos ~= oldPos then
                e:SetGridPosition(newPos)
            end
        end
    end

    --转出去机关如果召唤者是光灵，删掉
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    for _, trapEntity in ipairs(destroyTrap) do
        ---@type TrapComponent
        local trapCmpt = trapEntity:Trap()
        trapEntity:Attributes():Modify("HP", 0)
        --关闭死亡技能
        local disableDieSkill = true
        trapServiceLogic:AddTrapDeadMark(trapEntity, disableDieSkill)
        result:AddTrapDestroyList(trapEntity:GetID())
    end

    return result
end

---计算魔方
function SkillEffectCalc_RubikCube:_CalcRubikBoard(boardList, i)
    local rubikBoard = {}

    rubikBoard.fromBoard = boardList[i]
    local toIndex = i + 1
    if toIndex > table.count(boardList) then
        toIndex = 1
    end
    rubikBoard.toBoard = boardList[toIndex]

    return rubikBoard
end

---获得相反面的对应坐标
function SkillEffectCalc_RubikCube:_GetOppositeBoardPos(oldPos)
    local newPos = Vector2(8 - oldPos.x, 8 - oldPos.y)
    return newPos
end

function SkillEffectCalc_RubikCube:_GetAloneBoardAotatePos(oldPos, radian)
    local newX =
        (oldPos.x - self._centerPos.x) * math.cos(radian) - (oldPos.y - self._centerPos.y) * math.sin(radian) +
        self._centerPos.x
    local newY =
        (oldPos.y - self._centerPos.y) * math.cos(radian) + (oldPos.x - self._centerPos.x) * math.sin(radian) +
        self._centerPos.y

    return Vector2(math.floor(newX), math.floor(newY))
end
