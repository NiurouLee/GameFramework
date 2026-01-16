--[[
    
]]
---@class SkillEffectCalc_SpliceBoard: Object
_class("SkillEffectCalc_SpliceBoard", Object)
SkillEffectCalc_SpliceBoard = SkillEffectCalc_SpliceBoard

function SkillEffectCalc_SpliceBoard:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SpliceBoard:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    ---@type SkillEffectParamSpliceBoard
    local skillEffectParam = skillEffectCalcParam.skillEffectParam

    local distance = skillEffectParam:GetDistance()
    local directionParam = skillEffectParam:GetDirection()
    local direction = Vector2(directionParam[1], directionParam[2])
    local notifyTrapList = skillEffectParam:GetNotifyTrapList()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local round = battleStatCmpt:GetLevelTotalRoundCount()

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()
    ---@type BoardSpliceComponent
    local boardSpliceComponent = boardEntity:BoardSplice()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")

    local boardGridPos = utilDataSvc:GetCloneBoardGridPos()
    local boardSpliceGridPos = utilDataSvc:GetCloneBoardSpliceGridPos()

    ---@type SkillEffectResultSpliceBoard
    local result = SkillEffectResultSpliceBoard:New()

    --移动阶段

    --有位移距离
    if distance > 0 then
        --筛选entity用的，目前都筛选
        local filter = function(e)
            if (e:HasTeam() or e:HasMonsterID() or e:HasTrapID()) and not e:HasDeadMark() then
                return true
            end
            return false
        end

        local pieceTable = {}

        --中心格子需要去掉外面激活的格子
        for _, pos in ipairs(boardSpliceGridPos) do
            if table.icontains(boardGridPos, pos) then
                table.removev(boardGridPos, pos)
            end
        end

        --boardGridPos需要根据方向做排序
        table.sort(
            boardGridPos,
            function(a, b)
                if direction.x == 1 then
                    return a.x > b.x
                elseif direction.x == -1 then
                    return a.x < b.x
                elseif direction.y == 1 then
                    return a.y > b.y
                elseif direction.y == -1 then
                    return a.y < b.y
                end
            end
        )

        --中心格子
        for _, pos in ipairs(boardGridPos) do
            local entityList = boardComponent:GetPieceEntities(pos, filter)

            local posNew = pos + Vector2(direction.x * distance, direction.y * distance)
            for i, e in ipairs(entityList) do
                result:AddMoveEntity(e:GetID(), pos, posNew)
            end

            local isPrism = boardComponent:IsPrismPiece(pos)
            if isPrism then
                result:AddSpliceBoardPrism(pos, posNew)
            end

            --新格子=原本得无效格子
            local isAddGrid = not utilDataSvc:IsValidPiecePos(posNew)

            local isRemoveGrid = false
            if direction.x ~= 0 then
                local data = utilScope:GetMinMaxGridXByGridY(pos.y)
                if data then
                    local min = data.min
                    local max = data.max
                    if direction.x > 0 then
                        --当前坐标x < 最小+2
                        isRemoveGrid = (pos.x < min + 2)
                    else
                        isRemoveGrid = (pos.x > max - 2)
                    end
                end
            elseif direction.y ~= 0 then
                local data = utilScope:GetMinMaxGridYByGridX(pos.x)
                if data then
                    local min = data.min
                    local max = data.max
                    if direction.y > 0 then
                        --当前坐标x < 最小+2
                        isRemoveGrid = (pos.y < min + 2)
                    else
                        isRemoveGrid = (pos.y > max - 2)
                    end
                end
            end

            local pieceType = boardComponent:GetPieceType(pos)

            if not pieceTable[posNew.x] then
                pieceTable[posNew.x] = {}
            end
            pieceTable[posNew.x][posNew.y] = {
                x = posNew.x,
                y = posNew.y,
                color = pieceType
            }

            result:AddConvertColor(pos, posNew, pieceType, isAddGrid, isRemoveGrid)
        end

        result:SetPieceTable(pieceTable)
    end

    result:SetMoveParam(distance, direction)

    --不移动也有拼接效果

    local maxX = boardServiceLogic:GetCurBoardMaxX()
    local maxY = boardServiceLogic:GetCurBoardMaxY()
    local boardLineCount = 7

    --拆分/拼接
    local boardSpliceGridPosList = utilDataSvc:GetCloneBoardSpliceGridPos()

    local isAddGridPosList = {}
    local isRemoveGridPosList = {}

    for _, pos in ipairs(boardSpliceGridPosList) do
        local pieceType = boardSpliceComponent:GetPieceType(pos)
        local isPrism = boardSpliceComponent:IsPrismPiece(pos)
        local isAddGrid = false
        local isRemoveGrid = false

        if direction == Vector2(0, 0) then
            if pos.x <= boardLineCount + 1 and pos.y > 3 then
                isAddGrid = true
            end
        elseif direction == Vector2(1, 0) then
            if pos.x >= maxX - 2 and pos.y > 3 then
                isAddGrid = true
            end
            if pos.x <= 3 and pos.y > 3 then
                isRemoveGrid = true
            end
        elseif direction == Vector2(0, -1) then
            if pos.x > 3 and pos.y <= 3 then
                isAddGrid = true
            end
            if pos.x > 3 and pos.y >= maxY - 2 then
                isRemoveGrid = true
            end
        elseif direction == Vector2(-1, 0) then
            if pos.x <= 3 and pos.y < maxY - 2 then
                isAddGrid = true
            end
            if pos.x >= maxX - 2 and pos.y < maxY - 2 then
                isRemoveGrid = true
            end
        elseif direction == Vector2(0, 1) then
            if pos.x < maxX - 2 and pos.y > 3 then
                isAddGrid = true
            end
            if pos.x < maxX - 2 and pos.y <= 3 then
                isRemoveGrid = true
            end
        end

        if isAddGrid then
            table.insert(isAddGridPosList, pos)
        end
        if isRemoveGrid then
            table.insert(isRemoveGridPosList, pos)
            pieceType = boardComponent:GetPieceType(pos)
            isPrism = boardComponent:IsPrismPiece(pos)
        end

        if isAddGrid or isRemoveGrid then
            result:AddSpliceBoardGrid(pos, isAddGrid, isRemoveGrid, pieceType, isPrism)
        end

        if distance == 0 and isAddGrid == false and isRemoveGrid == false then
            result:AddSpliceBoardOnlyPlayDark(pos)
        end
    end

    local destroyTrapList = {}

    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            local pos = e:GetGridPosition()
            ---@type TrapComponent
            local trapCmp = e:Trap()
            local trapID = trapCmp:GetTrapID()

            if table.icontains(notifyTrapList, trapID) then
                if table.icontains(isRemoveGridPosList, pos) then
                    result:SetNotifyStartTrapEntityID(e:GetID())
                end
                if table.icontains(isAddGridPosList, pos) then
                    result:SetNotifyEndTrapEntityID(e:GetID())
                end
            end

            if table.icontains(isRemoveGridPosList, pos) and trapCmp:GetCanStayBoardSplice() ~= 1 then
                table.insert(destroyTrapList, e:GetID())
            end
        end
    end

    result:SetDestroyTrapList(destroyTrapList)

    return result
end
