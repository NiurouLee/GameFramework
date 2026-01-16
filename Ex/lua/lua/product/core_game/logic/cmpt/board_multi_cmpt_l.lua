--[[------------------------------------------------------------------------------------------
    BoardMultiComponent : 棋盘组件
]] --------------------------------------------------------------------------------------------

_class("BoardMultiComponent", Object)
---@class BoardMultiComponent: Object
BoardMultiComponent = BoardMultiComponent

--- 初始化棋盘格子
function BoardMultiComponent:Constructor(pieceTable, index)
end

function BoardMultiComponent:InitBoardMulti(pieceTable, index)
    if not self._multiBoard then
        self._multiBoard = {}
    end
    if not self._multiBoard[index] then
        self._multiBoard[index] = {}
    end

    local curBoard = self._multiBoard[index]

    ---@type table<number,table<number,number>>
    curBoard.Pieces = {}
    curBoard.DimensionDoor = {} --任意门
    curBoard.Exit = {}
    curBoard.BenumbTrigger = {} --麻痹弩车触发器
    ---@type table<number, number> key => vector2:Pos2Index()
    curBoard.GridEdgeMinDistance = {}

    --region Init _blockFlags
    ---@type PieceBlockData[][] 存储所有棋盘坐标阻挡信息
    curBoard._blockFlags = {}
    ---@type table<Vector2>
    curBoard._posIndex2Pos = {}
    if pieceTable then
        for x, ys in pairs(pieceTable) do
            curBoard._blockFlags[x] = {}
            for y, _ in pairs(ys) do
                curBoard._blockFlags[x][y] = PieceBlockData:New(x, y)
                curBoard._posIndex2Pos[x * 100 + y] = Vector2(x, y)
            end
        end
    end
    --endregion

    ---@type table<int,Vector2> 发生变化的格子位置 便于ReactiveSystem处理格子变化逻辑
    curBoard.ChangePos = {}
    curBoard._gridEntityTable = {}

    ---格子填充流程所需数据
    ---@type bool 处于填充格子状态
    curBoard.isFilling = false
    ---@type table<Vector2, PieceType> 新增格子数据
    curBoard.PieceFillTable = {}

    if pieceTable then
        for x, col in pairs(pieceTable) do
            curBoard.Pieces[x] = {}
            for y, grid in pairs(col) do
                curBoard.Pieces[x][y] = grid.color
                curBoard.ChangePos[#curBoard.ChangePos + 1] = Vector2(x, y)
            end
        end
    end

    ---连线结束时，会立刻计算出连线点的新格子颜色属性
    ---在后续的处理中，会应用这些颜色属性
    curBoard._chainPathNewGridElementList = {}

    --记录棱镜格子
    curBoard._prismPieces = {}
    --格子上的entity索引
    curBoard._pieceEntities = nil
    self:InitGridEdgeDistance(pieceTable, curBoard)

    curBoard._blockChangeFlag = false
    ---@type table<BlockFlag,table<number,boolean>>
    curBoard._blockFlagMaps = {}
end

function BoardMultiComponent:SetPieceEntities(boardIndex, t)
    local curBoard = self._multiBoard[boardIndex]
    curBoard._pieceEntities = t
end

--位移、召唤、死亡、替换
function BoardMultiComponent:AddPieceEntity(boardIndex, pos, entity)
    local curBoard = self._multiBoard[boardIndex]
    --防止有其他类型的entity乱入导致错误
    if entity:HasTeam() or entity:HasTrapID() or entity:HasMonsterID() then
        if not curBoard._pieceEntities then
            curBoard._pieceEntities = {}
        end
        local posIdx = Vector2.Pos2Index(pos)
        local es = curBoard._pieceEntities[posIdx] or {}
        if not table.icontains(es, entity) then
            es[#es + 1] = entity
        end
        curBoard._pieceEntities[posIdx] = es
    end
end

function BoardMultiComponent:RemovePieceEntity(boardIndex, pos, entity)
    local curBoard = self._multiBoard[boardIndex]
    if not curBoard._pieceEntities then
        return
    end
    local posIdx = Vector2.Pos2Index(pos)
    local es = curBoard._pieceEntities[posIdx]
    if not es then
        return
    end

    table.removev(es, entity)
end

function BoardMultiComponent:GetPieceEntities(boardIndex, pos, filter)
    local curBoard = self._multiBoard[boardIndex]
    if not curBoard._pieceEntities then
        return {}
    end
    local posIdx = Vector2.Pos2Index(pos)

    local es = curBoard._pieceEntities[posIdx]
    if not es then
        return {}
    end
    local ret = {}
    if filter then
        for i, e in ipairs(es) do
            if filter(e) then
                ret[#ret + 1] = e
            end
        end
    else
        ret = es
    end
    return ret
end

function BoardMultiComponent:ClonePieceEntities()
    local t = {}
    for idx, es in pairs(self._pieceEntities) do
        t[idx] = es
    end
    return t
end
function BoardMultiComponent:GetChangePosAndClear(boardIndex)
    local curBoard = self._multiBoard[boardIndex]

    local chagePosArray = curBoard.ChangePos
    curBoard.ChangePos = {}
    return chagePosArray
end

function BoardMultiComponent:GetGridEntityData()
    local gridEntityTableList = {}
    for index, curBoard in pairs(self._multiBoard) do
        gridEntityTableList[index] = curBoard
    end

    return gridEntityTableList
end

function BoardMultiComponent:AddGridEntityData(pos, pieceType, boardIndex)
    local curBoard = self._multiBoard[boardIndex]
    curBoard._gridEntityTable[pos] = pieceType
end

--region Prism
--判断当前位置是否是棱镜格子
---@param pos Vector2
function BoardMultiComponent:IsPrismPiece(boardIndex, pos)
    local curBoard = self._multiBoard[boardIndex]
    local posIdx = Vector2.Pos2Index(pos)
    return curBoard._prismPieces[posIdx]
end

function BoardMultiComponent:AddPrismPiece(boardIndex, pos)
    local curBoard = self._multiBoard[boardIndex]
    local posIdx = Vector2.Pos2Index(pos)
    curBoard._prismPieces[posIdx] = true
end

function BoardMultiComponent:RemovePrismPiece(boardIndex, pos)
    local curBoard = self._multiBoard[boardIndex]
    local posIdx = Vector2.Pos2Index(pos)
    curBoard._prismPieces[posIdx] = nil
end

function BoardMultiComponent:ApplyPrism(boardIndex, prePos, prismPos)
    --2022/12/30: 十字棱镜格处理没有修改这里，因为这段的棱镜是一个单独的需求
    local curBoard = self._multiBoard[boardIndex]
    local posIdx = Vector2.Pos2Index(prismPos)
    if not curBoard._prismPieces[posIdx] then
        return
    end
    local prismPieceType = self:GetPieceType(prismPos, boardIndex)
    local dir = prismPos - prePos
    for i = 1, BattleConst.PrismEffectPieceCount do
        local targetPos = prismPos + dir * i
        local targetPieceType = self:GetPieceType(targetPos, boardIndex)
        local canChange = not self:IsPosBlock(boardIndex, targetPos, BlockFlag.ChangeElement)
        if targetPieceType and targetPieceType ~= PieceType.None and canChange then
            self:SetPieceElement(boardIndex, targetPos, prismPieceType)
        end
    end
end
--endregion

function BoardMultiComponent:InitPieceTableData(pieceTable, boardIndex)
    if not self._multiBoard then
        self._multiBoard = {}
    end
    if not self._multiBoard[boardIndex] then
        self:InitBoardMulti(pieceTable, boardIndex)
    end

    local curBoard = self._multiBoard[boardIndex]

    self:InitGridEdgeDistance(pieceTable, curBoard)
end

--- 删除一个棋盘格子
function BoardMultiComponent:RemovePiece(x, y)
    if self.Pieces[x] and self.Pieces[x][y] then
        self.Pieces[x][y] = nil
        self.ChangePos[#self.ChangePos + 1] = Vector2(x, y)
        return true
    end
    return false
end

function BoardMultiComponent:GetPieceTypeByIndex(index)
    local pos = self:GetVector2PosByPosIndex(index)
    if pos then
        return self:GetPieceType(pos)
    else
        return PieceType.None
    end
end

---获取格子类型
function BoardMultiComponent:GetPieceType(pos, boardIndex)
    local curBoard = self._multiBoard[boardIndex]

    local x, y = pos.x, pos.y
    if curBoard.Pieces[x] and curBoard.Pieces[x][y] then
        return curBoard.Pieces[x][y]
    end
    return PieceType.None
end

--- GetPieceType里有PieceType.None的默认结果，因此不能用来判断格子有效性
function BoardMultiComponent:GetPieceData(pos, boardIndex)
    local curBoard = self._multiBoard[boardIndex]
    local x, y = pos.x, pos.y
    if curBoard.Pieces[x] and curBoard.Pieces[x][y] then
        return curBoard.Pieces[x][y]
    end

    return nil
end
---@return Vector2[]
function BoardMultiComponent:GetPiecePosByType(pieceTypeList)
    if type(pieceTypeList) ~= "table" then
        pieceTypeList = {pieceTypeList}
    end
    local retPosList = {}
    for x, columnDic in pairs(self.Pieces) do
        for y, gridType in pairs(columnDic) do
            if table.icontains(pieceTypeList, gridType) then
                table.insert(retPosList, Vector2(x, y))
            end
        end
    end
    return retPosList
end

function BoardMultiComponent:SetPieceElement(boardIndex, pos, pieceType)
    local curBoard = self._multiBoard[boardIndex]
    local old = curBoard.Pieces[pos.x][pos.y]
    curBoard.Pieces[pos.x][pos.y] = pieceType

    ---@type BoardMultiServiceLogic
    local boardMultiServiceLogic = self._entity._world:GetService("BoardMultiLogic")
    local GridTiles = boardMultiServiceLogic:GetGridTiles(boardIndex)
    if GridTiles[pos.x] and GridTiles[pos.x][pos.y] then
        GridTiles[pos.x][pos.y].color = pieceType
    end

    self._entity._world:GetSyncLogger():Trace(
        {
            key = "SetPieceElement",
            pos = Vector2.Pos2Index(pos),
            from = old,
            to = pieceType
        }
    )
    self:PrintBoardCmptLog("SetPieceElement() pos=", Vector2.Pos2Index(pos), " from=", old, " to=", pieceType)
end

function BoardMultiComponent:GetBlockFlagArray()
    return self._blockFlags
end

---@return PieceBlockData
function BoardMultiComponent:FindBlockByPos(boardIndex, pos)
    local curBoard = self._multiBoard[boardIndex]

    local nX = math.floor(pos.x)
    if nil == curBoard._blockFlags[nX] then
        return nil
    end
    local nY = math.floor(pos.y)

    ---@type PieceBlockData
    local blockData = curBoard._blockFlags[nX][nY]
    if nil == blockData then
    end
    return blockData
end

function BoardMultiComponent:GetPosListByFlag(blockFlag)
    local t = {}
    for x, ys in pairs(self._blockFlags) do
        ---@param blockData PieceBlockData
        for y, blockData in pairs(ys) do
            if blockData:CheckBlock(blockFlag) then
                table.insert(t, Vector2(x, y))
            end
        end
    end
    return t
end
function BoardMultiComponent:IsPosBlock(boardIndex, pos, blockFlag)
    if not pos then
        return false
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(boardIndex, pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end

---pos位置是否为空
function BoardMultiComponent:IsPosNil(pos)
    local x, y = pos.x, pos.y
    if self.Pieces[x] and self.Pieces[x][y] then
        return false
    end
    return true
end

---从当前的位置队列里克隆一份出来
function BoardMultiComponent:CloneBoardPosList()
    local multiBoardPieceList = {}
    for boardIndex, board in pairs(self._multiBoard) do
        local pieceList = {}
        for x, row in pairs(board.Pieces) do
            for y, color in pairs(row) do
                pieceList[#pieceList + 1] = Vector2(x, y)
            end
        end
        multiBoardPieceList[boardIndex] = pieceList
    end
    return multiBoardPieceList
end

function BoardMultiComponent:InitGridEdgeDistance(pieceTable, curBoard)
    if type(pieceTable) ~= "table" then
        return
    end

    local columnXMinMax = {}
    local rowYMinMax = {}

    for x, col in pairs(pieceTable) do
        for y, v2 in pairs(col) do
            if not columnXMinMax[y] then
                columnXMinMax[y] = {}
            end
            if (not columnXMinMax[y].min) or (columnXMinMax[y].min > x) then
                columnXMinMax[y].min = x
            end
            if (not columnXMinMax[y].max) or (columnXMinMax[y].max < x) then
                columnXMinMax[y].max = x
            end

            if not rowYMinMax[x] then
                rowYMinMax[x] = {}
            end
            if (not rowYMinMax[x].min) or (rowYMinMax[x].min > y) then
                rowYMinMax[x].min = y
            end
            if (not rowYMinMax[x].max) or (rowYMinMax[x].max < y) then
                rowYMinMax[x].max = y
            end
        end
    end

    curBoard.GridMinEdgeDistanceX = {}
    curBoard.GridMinEdgeDistanceY = {}

    for x, col in pairs(pieceTable) do
        for y, v2 in pairs(col) do
            if columnXMinMax[y] and rowYMinMax[x] then
                local posIndex = (x * 100) + y
                local rowYEdgeDis1 = x - columnXMinMax[y].min
                local rowYEdgeDis2 = columnXMinMax[y].max - x
                local rowYEdgeMinDis = math.min(rowYEdgeDis1, rowYEdgeDis2)
                curBoard.GridMinEdgeDistanceX[posIndex] = rowYEdgeMinDis

                local colXEdgeDis1 = y - rowYMinMax[x].min
                local colXEdgeDis2 = rowYMinMax[x].max - y
                local colXEdgeMinDis = math.min(colXEdgeDis1, colXEdgeDis2)
                curBoard.GridMinEdgeDistanceY[posIndex] = colXEdgeMinDis
            end
        end
    end

    curBoard._columnXMinMax = columnXMinMax
    curBoard._rowYMinMax = rowYMinMax
end

function BoardMultiComponent:PrintBoardCmptLog(...)
    if self._entity._world and self._entity._world:IsDevelopEnv() then
        Log.debug(...)
    end
end
---@return Vector2
---@param posIndex number
function BoardMultiComponent:GetVector2PosByPosIndex(posIndex)
    local pos = self._posIndex2Pos[posIndex]
    return pos
end

---@param blockFlag BlockFlag
function BoardMultiComponent:BuildBlockFlagMap(blockFlag)
    local posCanMove = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._entity._world:GetService("BoardLogic")
    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()
    for x = 1, boardMaxX do
        for y = 1, boardMaxY do
            local posIndex = x * 100 + y
            local pos = self._posIndex2Pos[posIndex]
            if not pos then
                pos = Vector2(x, y)
                self._posIndex2Pos[posIndex] = pos
            end
            if not self:IsPosBlock(pos, blockFlag) then
                posCanMove[posIndex] = true
            end
        end
    end
    return posCanMove
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return BoardMultiComponent
function Entity:BoardMulti()
    return self:GetComponent(self.WEComponentsEnum.BoardMulti)
end

function Entity:HasBoardMulti()
    return self:HasComponent(self.WEComponentsEnum.BoardMulti)
end

--- 初始化棋盘格子内容
---@param pieceTable table<int,table<int,PieceType>>
function Entity:AddBoardMulti(pieceTable)
    local index = self.WEComponentsEnum.BoardMulti
    local component = BoardMultiComponent:New(pieceTable)
    self:AddComponent(index, component)
end
