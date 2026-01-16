--[[------------------------------------------------------------------------------------------
    BoardComponent : 棋盘组件
]] --------------------------------------------------------------------------------------------

_class("BoardComponent", Object)
---@class BoardComponent: Object
BoardComponent = BoardComponent

--- 初始化棋盘格子
function BoardComponent:Constructor(pieceTable)
    ---@type table<number,table<number,number>>
    self.Pieces = {}
    self.DimensionDoor = {} --任意门
    self.Exit = {}
    self.BenumbTrigger = {} --麻痹弩车触发器
    ---@type table<number, number> key => vector2:Pos2Index()
    self.GridEdgeMinDistance = {}

    --region Init _blockFlags
    ---@type PieceBlockData[][] 存储所有棋盘坐标阻挡信息
    self._blockFlags = {}
    if pieceTable then
        for x, ys in pairs(pieceTable) do
            self._blockFlags[x] = {}
            for y, _ in pairs(ys) do
                self._blockFlags[x][y] = PieceBlockData:New(x, y)
            end
        end
    end
    --endregion

    ---@type table<int,Vector2> 发生变化的格子位置 便于ReactiveSystem处理格子变化逻辑
    self.ChangePos = {}
    self._gridEntityTable = {}

    ---格子填充流程所需数据
    ---@type bool 处于填充格子状态
    self.isFilling = false
    ---@type table<Vector2, PieceType> 新增格子数据
    self.PieceFillTable = {}

    if pieceTable then
        for x, col in pairs(pieceTable) do
            self.Pieces[x] = {}
            for y, grid in pairs(col) do
                self.Pieces[x][y] = grid.color
                self.ChangePos[#self.ChangePos + 1] = Vector2(x, y)
            end
        end
    end

    ---连线结束时，会立刻计算出连线点的新格子颜色属性
    ---在后续的处理中，会应用这些颜色属性
    self._chainPathNewGridElementList = {}

    --记录棱镜格子
    self._prismPieces = {}
    self._prismPiecesEffectType = {}
    self._prismEntityIDs = {}
    --格子上的entity索引
    self._pieceEntities = nil
    self:InitGridEdgeDistance(pieceTable)

    self._blockChangeFlag = false
    ---@type table<BlockFlag,table<number,boolean>>
    self._blockFlagMaps= {}
    ---@type table<Vector2>
    self._posIndex2Pos={}

    self._tmpPiecePos= {}
	
    --【玩家连线阶段】格子颜色映射，key是被替换的颜色，value是替换后的颜色
    self._mapByPieceType = {}
    --【玩家连线阶段】格子颜色映射，key是坐标，valie是替换后的颜色
    self._mapByPosition = {}
    self._mapForFirstChainPath = nil --连线第一步视为某种颜色
    --连线中途被击 后续棱镜格需要恢复 MSG59215 20230320
    self._prismChangedPieces = {}
end

function BoardComponent:SetPieceEntities(t)
    self._pieceEntities = t
end

--位移、召唤、死亡、替换
function BoardComponent:AddPieceEntity(pos, entity)
    --防止有其他类型的entity乱入导致错误
    if entity:HasTeam() or entity:HasTrapID() or entity:HasMonsterID() then
        if not self._pieceEntities then
            self._pieceEntities = {}
        end
        local posIdx = Vector2.Pos2Index(pos)
        local es = self._pieceEntities[posIdx] or {}
        if not table.icontains(es, entity) then
            es[#es + 1] = entity
        end
        self._pieceEntities[posIdx] = es
    end
end

function BoardComponent:RemovePieceEntity(pos, entity)
    if not self._pieceEntities then
        return
    end
    local posIdx = Vector2.Pos2Index(pos)
    local es = self._pieceEntities[posIdx]
    if not es then
        return
    end

    table.removev(es, entity)
end

function BoardComponent:GetPieceEntities(pos, filter,...)
    if not self._pieceEntities then
        return {}
    end
    local posIdx = Vector2.Pos2Index(pos)

    local es = self._pieceEntities[posIdx]
    if not es then
        return {}
    end
    local ret = {}
    if filter then
        for i, e in ipairs(es) do
            if filter(e,...) then
                ret[#ret + 1] = e
            end
        end
    else
        ret = es
    end
    return ret
end

function BoardComponent:ClonePieceEntities()
    if not self._pieceEntities then
        return {}
    end
    local t = {}
    for idx, es in pairs(self._pieceEntities) do
        t[idx] = es
    end
    return t
end
function BoardComponent:GetChangePosAndClear()
    local chagePosArray = self.ChangePos
    self.ChangePos = {}
    return chagePosArray
end

function BoardComponent:GetGridEntityData()
    return self._gridEntityTable
end

function BoardComponent:AddGridEntityData(pos, pieceType)
    self._gridEntityTable[pos] = pieceType
end

function BoardComponent:ClearGridEntityData()
    self._gridEntityTable = {}
end

--复制一份格子颜色数据
function BoardComponent:ClonePieceTable()
    local t = table_to_class(self.Pieces)
    return t
end

--region Prism
--判断当前位置是否是棱镜格子
---@param pos Vector2
function BoardComponent:IsPrismPiece(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismPieces[posIdx]
end

---@param pos Vector2
function BoardComponent:GetPrismEntityIDAtPos(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismEntityIDs[posIdx]
end

--复制一份棱镜数据
function BoardComponent:ClonePrismPieces()
    local t = table_to_class(self._prismPieces)
    return t
end

function BoardComponent:ClonePrismEntityIDs()
    return table_to_class(self._prismEntityIDs)
end

function BoardComponent:AddPrismPiece(pos, prismEntityID)
    local posIdx = Vector2.Pos2Index(pos)
    self._prismPieces[posIdx] = true
    self._prismEntityIDs[posIdx] = prismEntityID
end

function BoardComponent:RemovePrismPiece(pos)
    local posIdx = Vector2.Pos2Index(pos)
    self._prismPieces[posIdx] = nil
    self._prismEntityIDs[posIdx] = nil
    self:SetPrismPieceEffectType(pos, nil)
end

function BoardComponent:GetPrismPieceEffectType(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismPiecesEffectType[posIdx]
end

function BoardComponent:SetPrismPieceEffectType(pos, pieceEffectType)
    local posIdx = Vector2.Pos2Index(pos)
    self._prismPiecesEffectType[posIdx] = pieceEffectType
end


--BoardComponent:ApplyPrism(...) => BoardServiceLogic:ApplyPrism(...)
--endregion

--region DimensionDoor
--当前位置是否有任意门
---@param pos Vector2
function BoardComponent:IsPosDimensionDoor(pos)
    local t = self.DimensionDoor[pos.x]
    if not t then
        return false
    end
    return t[pos.y] ~= nil
end

--移除指定位置的任意门
---@param pos Vector2
function BoardComponent:RemoveDimensionDoor(pos)
    local t = self.DimensionDoor[pos.x]
    if t then
        t[pos.y] = nil
    end
end

--在指定位置添加任意门
---@param pos Vector2
---@param entity Entity
function BoardComponent:AddDimensionDoor(pos, entity)
    local t = self.DimensionDoor[pos.x]
    if not t then
        t = {}
        self.DimensionDoor[pos.x] = t
    end
    t[pos.y] = entity
end
--endregion

--region Exit
--指定位置是否有出口
---@param pos Vector2
function BoardComponent:IsPosExit(pos)
    local t = self.Exit[pos.x]
    if not t then
        return false
    end
    return t[pos.y] ~= nil
end
--移除指定位置的出口
---@param pos Vector2
function BoardComponent:RemoveExit(pos)
    local t = self.Exit[pos.x]
    if t then
        t[pos.y] = nil
    end
end
--在指定位置添加出口
---@param pos Vector2
---@param entity Entity
function BoardComponent:AddExit(pos, entity)
    local t = self.Exit[pos.x]
    if not t then
        t = {}
        self.Exit[pos.x] = t
    end
    t[pos.y] = entity
end
--endregion

function BoardComponent:InitPieceTableData(pieceTable, isRefresh)
    ---刷新棋盘不重置阻挡信息
    if not isRefresh then
        ---@type number[][] 存储所有棋盘坐标阻挡信息
        self._blockFlags = {}
        for x, ys in pairs(pieceTable) do --TODO暂时使用格子数组初始化，之后可以改成在棋盘矩形内的所有位置数组
            self._blockFlags[x] = {}
            for y, _ in pairs(ys) do
                self._blockFlags[x][y] = PieceBlockData:New(x, y)
                self._posIndex2Pos[x * 100 + y] = Vector2(x, y)
            end
        end
    end    

    local t = {}
    for x, col in pairs(pieceTable) do
        self.Pieces[x] = {}
        for y, grid in pairs(col) do
            self.Pieces[x][y] = grid.color
            self.ChangePos[#self.ChangePos + 1] = Vector2(x, y)
            t[x * 100 + y] = grid.color
        end
    end

    self:InitGridEdgeDistance(pieceTable)
end

--- 删除一个棋盘格子
function BoardComponent:RemovePiece(x, y)
    if self.Pieces[x] and self.Pieces[x][y] then
        self.Pieces[x][y] = nil
        self.ChangePos[#self.ChangePos + 1] = Vector2(x, y)
        return true
    end
    return false
end

--- 填充格子
---@param PieceFillTable table<Vector2, PieceType> 新增格子数据
function BoardComponent:FillPieces(PieceFillTable)
    self.PieceFillTable = PieceFillTable
    local t = {}
    for i, grid in ipairs(PieceFillTable) do
        self.Pieces[grid.x][grid.y] = grid.color
        t[grid.x * 100 + grid.y] = grid.color
    end

    self._entity._world:GetSyncLogger():Trace(
        {
            key = "FillPieces",
            pieceTable = t
        }
    )
    self:PrintBoardCmptLog("BoardComponent FillPieces() :", echo_one_line(ELogLevel.Debug,t))
end

function BoardComponent:GetPieceTypeByIndex(index)
    local pos = self:GetVector2PosByPosIndex(index)
    if pos then
        return self:GetPieceType(pos)
    else
        return PieceType.None
    end
end

function BoardComponent:AddTmpPieceType(pos,type)
    local posIndex = Vector2.Pos2Index(pos)
    self._tmpPiecePos[posIndex] = type
end

function BoardComponent:ClearTmpPieceType()
    self._tmpPiecePos ={}
end
function BoardComponent:GetTmpPieceType(pos)
    local posIndex = Vector2.Pos2Index(pos)
    return self._tmpPiecePos[posIndex]
end

---获取格子类型
function BoardComponent:GetPieceType(pos)
    if self:GetTmpPieceType(pos) then
        return self:GetTmpPieceType(pos)
    end
    local x, y = pos.x, pos.y
    if self.Pieces[x] and self.Pieces[x][y] then
        return self.Pieces[x][y]
    end
    return PieceType.None
end

function BoardComponent:OnlySetPieceType(pos, pieceType)
    if not self.Pieces[pos.x] then
        self.Pieces[pos.x] = {}
    end
    self.Pieces[pos.x][pos.y] = pieceType
end

--- GetPieceType里有PieceType.None的默认结果，因此不能用来判断格子有效性
function BoardComponent:GetPieceData(pos)
    if self:GetTmpPieceType(pos) then
        return self:GetTmpPieceType(pos)
    end
    local x, y = pos.x, pos.y
    if self.Pieces[x] and self.Pieces[x][y] then
        return self.Pieces[x][y]
    end

    return nil
end
---@return Vector2[]
function BoardComponent:GetPiecePosByType(pieceTypeList)
    if type(pieceTypeList) ~= "table" then
        pieceTypeList = {pieceTypeList}
    end
    local retPosList = {}
    for x, columnDic in pairs(self.Pieces) do
        for y, _ in pairs(columnDic) do
            local gridType = self:GetPieceType({x=x,y=y})
            if table.icontains(pieceTypeList, gridType) then
                table.insert(retPosList, Vector2(x, y))
            end
        end
    end
    return retPosList
end
--连线中途被击 后续棱镜格需要恢复 MSG59215 20230320
function BoardComponent:RecordPrismChangeGrid(prismPos, changeRecord)
    local posIdx = Vector2.Pos2Index(prismPos)
    self._prismChangedPieces[posIdx] = {}
    local prismRecord = self._prismChangedPieces[posIdx]
    for _, data in ipairs(changeRecord) do
        local changedPosIdx = Vector2.Pos2Index(data.pos)
        prismRecord[changedPosIdx] = data.oriPieceType
    end
end
--连线中途被击 后续棱镜格需要恢复 MSG59215 20230320
function BoardComponent:UnapplyPrism(prismPos)
    local posIdx = Vector2.Pos2Index(prismPos)
    local changed = self._prismChangedPieces[posIdx]
    if changed then
        for changedPosIdx, oriPieceType in pairs(changed) do
            local changedPos = Vector2.Index2Pos(changedPosIdx)
            self:SetPieceElement(changedPos,oriPieceType)
        end
        self._prismChangedPieces[posIdx] = nil
    end
end
--连线完后重置 棱镜应用记录
function BoardComponent:ResetPrismChangeRecord()
    self._prismChangedPieces = {}
end

function BoardComponent:SetPieceElement(pos, pieceType)
    local old = self.Pieces[pos.x][pos.y]
    self.Pieces[pos.x][pos.y] = pieceType
    
    ---@type BoardServiceLogic
    local boardLogicSvc = self._entity._world:GetService("BoardLogic")
    local GridTiles = boardLogicSvc.GridTiles
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

--region BlockFlag
function BoardComponent:GetBlockFlagArray()
    return self._blockFlags
end

function BoardComponent:RemoveBlockFlag(pos)
    ---@type PieceBlockData
    local blockData = self._blockFlags[pos.x][pos.y]
    if blockData then
        self._blockFlags[pos.x][pos.y] = nil
    end
end

---@return PieceBlockData
function BoardComponent:FindBlockByPos(pos)
    local nX = math.floor(pos.x)
    if nil == self._blockFlags[nX] then
        -- Log.error("BoardComponent:FindBlockByPos 没有找到Block数据", pos.x, pos.y)--, "TrackBack:", Log.traceback()
        return nil
    end
    local nY = math.floor(pos.y)
    ---@type PieceBlockData
    local blockData = self._blockFlags[nX][nY]
    if nil == blockData then
    -- Log.error("BoardComponent:FindBlockByPos 没有找到Block数据", pos.x, pos.y)--, "TrackBack:", Log.traceback()
    end
    return blockData
end

function BoardComponent:SetBlockFlags(pos, pieceBlockData)
    self._blockFlags[pos.x][pos.y] = pieceBlockData
end

function BoardComponent:GetPosListByFlag(blockFlag)
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
function BoardComponent:IsPosBlock(pos, blockFlag)
    if not pos then
        return false
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end
--endregion

---不需要参数
function BoardComponent:FillPieceUseChainGrid()
    self:FillPieces(self._chainPathNewGridElementList)
    return self._chainPathNewGridElementList
end

---pos位置是否为空
function BoardComponent:IsPosNil(pos)
    if self:GetPieceData(pos)  then
        return false
    else
        return true
    end
    --local x, y = pos.x, pos.y
    --if self.Pieces[x] and self.Pieces[x][y] then
    --    return false
    --end
    --return true
end

---从当前的位置队列里克隆一份出来
function BoardComponent:CloneBoardPosList()
    local pieceList = {}
    for x, row in pairs(self.Pieces) do
        for y, color in pairs(row) do
            pieceList[#pieceList + 1] = Vector2(x, y)
        end
    end
    return pieceList
end

--region BenumbTrigger
---@param pos Vector2
function BoardComponent:IsPosBenumbTrigger(pos)
    local t = self.BenumbTrigger[pos.x]
    if not t then
        return false
    end
    return t[pos.y] ~= nil
end
---@param pos Vector2
---@param entity Entity
function BoardComponent:AddBenumbTrigger(pos, entity)
    local t = self.BenumbTrigger[pos.x]
    if not t then
        t = {}
        self.BenumbTrigger[pos.x] = t
    end
    t[pos.y] = entity
end
--endregion

function BoardComponent:InitGridEdgeDistance(pieceTable)
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

    self.GridMinEdgeDistanceX = {}
    self.GridMinEdgeDistanceY = {}

    for x, col in pairs(pieceTable) do
        for y, v2 in pairs(col) do
            if columnXMinMax[y] and rowYMinMax[x] then
                local posIndex = (x * 100) + y
                local rowYEdgeDis1 = x - columnXMinMax[y].min
                local rowYEdgeDis2 = columnXMinMax[y].max - x
                local rowYEdgeMinDis = math.min(rowYEdgeDis1, rowYEdgeDis2)
                self.GridMinEdgeDistanceX[posIndex] = rowYEdgeMinDis

                local colXEdgeDis1 = y - rowYMinMax[x].min
                local colXEdgeDis2 = rowYMinMax[x].max - y
                local colXEdgeMinDis = math.min(colXEdgeDis1, colXEdgeDis2)
                self.GridMinEdgeDistanceY[posIndex] = colXEdgeMinDis
            end
        end
    end

    self._columnXMinMax = columnXMinMax
    self._rowYMinMax = rowYMinMax
end

---@class BoardComponent_RowColumnMinMax
---@field min number
---@field max number

---@param y number
---@return BoardComponent_RowColumnMinMax|nil
function BoardComponent:GetMinMaxGridXByGridY(y)
    return self._columnXMinMax[y]
end

---@param x number
---@return BoardComponent_RowColumnMinMax|nil
function BoardComponent:GetMinMaxGridYByGridX(x)
    return self._rowYMinMax[x]
end

---@param v2 Vector2
function BoardComponent:GetGridEdgeDistance(v2)
    return self:GetGridEdgeDistanceByPosIndex(v2:Pos2Index())
end

function BoardComponent:GetGridEdgeDistanceByPosIndex(posIndex)
    return self.GridMinEdgeDistanceX[posIndex], self.GridMinEdgeDistanceY[posIndex]
end

function BoardComponent:GetGridMinEdgeDistanceX()
    return self.GridMinEdgeDistanceX
end
function BoardComponent:GetGridMinEdgeDistanceY()
    return self.GridMinEdgeDistanceY
end

function BoardComponent:HasDimensionDoor()
    if not self.DimensionDoor then
        return false
    end

    local doorCnt = #self.DimensionDoor
    if doorCnt > 0 then
        return true
    end

    return false
end

function BoardComponent:PrintBoardCmptLog(...)
    if self._entity._world and self._entity._world:IsDevelopEnv() then
        Log.debug(...)
    end
end
----外部使用这个
function BoardComponent:GetCloneVector2PosByPosIndex(posIndex)
    ---@type Vector2
    local pos = self._posIndex2Pos[posIndex]
    return pos:Clone()
end
---内部使用这个
---@return Vector2
---@param posIndex number
function BoardComponent:GetVector2PosByPosIndex(posIndex)
    local pos = self._posIndex2Pos[posIndex]
    return pos
end

---@param blockFlag BlockFlag
function BoardComponent:BuildBlockFlagMap(blockFlag)
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
                pos = Vector2(x,y)
                self._posIndex2Pos[posIndex] = pos
            end
            if not self:IsPosBlock(pos, blockFlag) then
                posCanMove[posIndex] = true
            end
        end
    end
    return posCanMove
end

---@param blockFlag BlockFlag
function BoardComponent:GetBlockFlagCanMoveMap(blockFlag)
    if not self._blockFlagMaps[blockFlag] then
        self._blockFlagMaps[blockFlag] = self:BuildBlockFlagMap(blockFlag)
    end
    return self._blockFlagMaps[blockFlag]
end

function BoardComponent:ClearBlockFlagCanMoveMap(blockFlag)
    self._blockFlagMaps[blockFlag] = nil
end

function BoardComponent:AddMapByPieceType(sourcePiece, targetPiece)
    self._mapByPieceType[sourcePiece] = targetPiece
end

function BoardComponent:SetMapByPieceType(mapByPieceType)
    self._mapByPieceType = mapByPieceType
end

function BoardComponent:GetMapByPieceType()
    return self._mapByPieceType
end

function BoardComponent:SetMapByPosition(mapByPosition)
    self._mapByPosition = mapByPosition
end

function BoardComponent:GetMapByPosition()
    return self._mapByPosition
end
function BoardComponent:SetMapForFirstChainPath(mapPieceType)
    self._mapForFirstChainPath = mapPieceType
end
function BoardComponent:GetMapForFirstChainPath()
    return self._mapForFirstChainPath
end
function BoardComponent:GetPieceTypeMapList(posWork)
    local pieceTypeMapList = {}

    for posindex, piece in pairs(self._mapByPosition) do
        local pos = Vector2.Index2Pos(posindex)
        if pos == posWork then
            table.insert(pieceTypeMapList, piece)
        end
    end
    return pieceTypeMapList
end

function BoardComponent:GetPieceTypeMapListByPosIndex(posIndexWork)
    local pieceTypeMapList = {}

    for posindex, piece in pairs(self._mapByPosition) do
        if posindex == posIndexWork then
            table.insert(pieceTypeMapList, piece)
        end
    end
    return pieceTypeMapList
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return BoardComponent
function Entity:Board()
    return self:GetComponent(self.WEComponentsEnum.Board)
end

function Entity:HasBoard()
    return self:HasComponent(self.WEComponentsEnum.Board)
end

--- 初始化棋盘格子内容
---@param pieceTable table<int,table<int,PieceType>>
function Entity:AddBoard(pieceTable)
    local index = self.WEComponentsEnum.Board
    local component = BoardComponent:New(pieceTable)
    self:AddComponent(index, component)
end
