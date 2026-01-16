--[[------------------------------------------------------------------------------------------
    BoardSpliceComponent : BoardSplice组件
]] --------------------------------------------------------------------------------------------

_class("BoardSpliceComponent", Object)
---@class BoardSpliceComponent: Object
BoardSpliceComponent = BoardSpliceComponent

function BoardSpliceComponent:Constructor(pieceTable)
    ---@type table<number,table<number,number>>
    self.Pieces = {}

    ---@type table<Vector2>
    self._posIndex2Pos = {}

    ---@type PieceBlockData[][] 存储所有棋盘坐标阻挡信息
    self._blockFlags = {}
    ---@type table<int,Vector2> 发生变化的格子位置 便于ReactiveSystem处理格子变化逻辑
    self.ChangePos = {}
    self._gridEntityTable = {}

    if pieceTable then
        for x, col in pairs(pieceTable) do
            self.Pieces[x] = {}
            for y, grid in pairs(col) do
                self.Pieces[x][y] = grid.color
                self.ChangePos[#self.ChangePos + 1] = Vector2(x, y)
            end
        end
    end

    --记录棱镜格子
    self._prismPieces = {}
    self._prismEntityIDs = {}

    --格子上的entity索引
    self._pieceEntities = nil
end

--复制一份格子颜色数据
function BoardSpliceComponent:ClonePieceTable()
    local t = table_to_class(self.Pieces)
    return t
end

function BoardSpliceComponent:InitPieceTableData(pieceTable)
    ---@type number[][] 存储所有棋盘坐标阻挡信息
    self._blockFlags = {}
    for x, ys in pairs(pieceTable) do --TODO暂时使用格子数组初始化，之后可以改成在棋盘矩形内的所有位置数组
        self._blockFlags[x] = {}
        for y, _ in pairs(ys) do
            self._blockFlags[x][y] = PieceBlockData:New(x, y)
            self._posIndex2Pos[x * 100 + y] = Vector2(x, y)
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

    -- self:InitGridEdgeDistance(pieceTable)
end

function BoardSpliceComponent:CloneBoardPosList()
    local pieceList = {}
    for x, row in pairs(self.Pieces) do
        for y, color in pairs(row) do
            pieceList[#pieceList + 1] = Vector2(x, y)
        end
    end
    return pieceList
end

function BoardSpliceComponent:GetPieceType(pos)
    local x, y = pos.x, pos.y
    if self.Pieces[x] and self.Pieces[x][y] then
        return self.Pieces[x][y]
    end
    return PieceType.None
end

--- GetPieceType里有PieceType.None的默认结果，因此不能用来判断格子有效性
function BoardSpliceComponent:GetPieceData(pos)
    local x, y = pos.x, pos.y
    if self.Pieces[x] and self.Pieces[x][y] then
        return self.Pieces[x][y]
    end

    return nil
end

function BoardSpliceComponent:SetPieceElement(pos, pieceType)
    local old = self.Pieces[pos.x][pos.y]
    self.Pieces[pos.x][pos.y] = pieceType

    self:PrintBoardCmptLog("SetPieceElement() pos=", Vector2.Pos2Index(pos), " from=", old, " to=", pieceType)
end

function BoardSpliceComponent:PrintBoardCmptLog(...)
    if self._entity._world and self._entity._world:IsDevelopEnv() then
        Log.debug(...)
    end
end

function BoardSpliceComponent:ClonePieceEntities()
    local t = {}
    for idx, es in pairs(self._pieceEntities) do
        t[idx] = es
    end
    return t
end
function BoardSpliceComponent:GetChangePosAndClear()
    local chagePosArray = self.ChangePos
    self.ChangePos = {}
    return chagePosArray
end

function BoardSpliceComponent:GetGridEntityData()
    return self._gridEntityTable
end

function BoardSpliceComponent:AddGridEntityData(pos, pieceType)
    self._gridEntityTable[pos] = pieceType
end

----外部使用这个
function BoardSpliceComponent:GetCloneVector2PosByPosIndex(posIndex)
    ---@type Vector2
    local pos = self._posIndex2Pos[posIndex]
    return pos:Clone()
end
---内部使用这个
---@return Vector2
---@param posIndex number
function BoardSpliceComponent:GetVector2PosByPosIndex(posIndex)
    local pos = self._posIndex2Pos[posIndex]
    return pos
end

---@param pos Vector2
function BoardSpliceComponent:IsPrismPiece(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismPieces[posIdx]
end

---@param pos Vector2
function BoardSpliceComponent:GetPrismEntityIDAtPos(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismEntityIDs[posIdx]
end

--复制一份棱镜数据
function BoardSpliceComponent:ClonePrismPieces()
    local t = table_to_class(self._prismPieces)
    return t
end

function BoardSpliceComponent:ClonePrismEntityIDs()
    return table_to_class(self._prismEntityIDs)
end

function BoardSpliceComponent:AddPrismPiece(pos, prismEntityID)
    local posIdx = Vector2.Pos2Index(pos)
    self._prismPieces[posIdx] = true
    self._prismEntityIDs[posIdx] = prismEntityID
end

function BoardSpliceComponent:RemovePrismPiece(pos)
    local posIdx = Vector2.Pos2Index(pos)
    self._prismPieces[posIdx] = nil
    self._prismEntityIDs[posIdx] = nil
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return BoardSpliceComponent
function Entity:BoardSplice()
    return self:GetComponent(self.WEComponentsEnum.BoardSplice)
end

function Entity:HasBoardSplice()
    return self:HasComponent(self.WEComponentsEnum.BoardSplice)
end

function Entity:ReplaceBoardSplice(pieceTable)
    local index = self.WEComponentsEnum.BoardSplice
    local component = BoardSpliceComponent:New(pieceTable)
    self:ReplaceComponent(index, component)
end

--- 初始化棋盘格子内容
---@param pieceTable table<int,table<int,PieceType>>
function Entity:AddBoardSplice(pieceTable)
    local index = self.WEComponentsEnum.BoardSplice
    local component = BoardSpliceComponent:New(pieceTable)
    self:AddComponent(index, component)
end
