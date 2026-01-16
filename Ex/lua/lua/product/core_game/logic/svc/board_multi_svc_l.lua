--[[ 
    棋盘生成专用
]]
require("base_service")

_class("BoardMultiServiceLogic", BaseService)
---@class BoardMultiServiceLogic:BaseService
BoardMultiServiceLogic = BoardMultiServiceLogic

function BoardMultiServiceLogic:GetCurBoard(index)
    if not self._multiBoard then
        self._multiBoard = {}
    end
    if not self._multiBoard[index] then
        self._multiBoard[index] = {}
    end

    local curBoard = self._multiBoard[index]
    return curBoard
end

function BoardMultiServiceLogic:GetCurBoardMaxX(curBoard)
    return curBoard._defaultMaxX or BattleConst.DefaultMaxX
end
function BoardMultiServiceLogic:GetCurBoardMaxY(curBoard)
    return curBoard._defaultMaxY or BattleConst.DefaultMaxY
end
---获取当前地图最大的长度（x或y）
function BoardMultiServiceLogic:GetCurBoardMaxLen(curBoard)
    local maxX = self:GetCurBoardMaxX(curBoard)
    local maxY = self:GetCurBoardMaxY(curBoard)
    return maxX > maxY and maxX or maxY
end
function BoardMultiServiceLogic:_SetCurBoardCfgInfo(curBoard)
    if curBoard._boardConfig then
        curBoard._defaultMaxX =
            curBoard._boardConfig.DefaultMaxX and curBoard._boardConfig.DefaultMaxX or BattleConst.DefaultMaxX
        curBoard._defaultMaxY =
            curBoard._boardConfig.DefaultMaxY and curBoard._boardConfig.DefaultMaxY or BattleConst.DefaultMaxY
        BattleConst.BoardMaxLen = math.max(curBoard._defaultMaxX, curBoard._defaultMaxY)
        curBoard._defaultPlayerAreaSizeX = BattleConst.DefaultPlayerAreaSize
        curBoard._defaultPlayerAreaSizeY = BattleConst.DefaultPlayerAreaSize
        if curBoard._boardConfig.DefaultPlayerAreaSize then
            if type(curBoard._boardConfig.DefaultPlayerAreaSize) == "table" then
                if #curBoard._boardConfig.DefaultPlayerAreaSize == 2 then
                    curBoard._defaultPlayerAreaSizeX = curBoard._boardConfig.DefaultPlayerAreaSize[1]
                    curBoard._defaultPlayerAreaSizeY = curBoard._boardConfig.DefaultPlayerAreaSize[2]
                end
            end
        end
        curBoard._defaultAIAreaSizeX = BattleConst.DefaultAIAreaSize
        curBoard._defaultAIAreaSizeY = BattleConst.DefaultAIAreaSize
        if curBoard._boardConfig.DefaultAIAreaSize then
            if type(curBoard._boardConfig.DefaultAIAreaSize) == "table" then
                if #curBoard._boardConfig.DefaultAIAreaSize == 2 then
                    curBoard._defaultAIAreaSizeX = curBoard._boardConfig.DefaultAIAreaSize[1]
                    curBoard._defaultAIAreaSizeY = curBoard._boardConfig.DefaultAIAreaSize[2]
                end
            end
        end
        if curBoard.PlayerArea then
            curBoard.PlayerArea.maxX = curBoard._defaultPlayerAreaSizeX
            curBoard.PlayerArea.maxY = curBoard._defaultPlayerAreaSizeY
        end
        if curBoard.AIArea then
            curBoard.AIArea.maxX = curBoard._defaultAIAreaSizeX
            curBoard.AIArea.maxY = curBoard._defaultAIAreaSizeY
        end
        self:_GenBoardRingMax(curBoard)
    end
end
---根据实际地图max x,y 生成RingMax，代替Ring9
function BoardMultiServiceLogic:_GenBoardRingMax(curBoard)
    curBoard._ringMax = {}
    local maxX = self:GetCurBoardMaxX(curBoard)
    local maxY = self:GetCurBoardMaxY(curBoard)
    local maxLen = self:GetCurBoardMaxLen(curBoard)
    local pushPos = function(posX, posY)
        if posX >= -maxX and posX <= maxX then
            if posY >= -maxY and posY <= maxY then
                local pos = {posX, posY}
                table.insert(curBoard._ringMax, pos)
            end
        end
    end
    for ringNum = 1, maxLen do
        for posY = -ringNum, ringNum do
            pushPos(-ringNum, posY)
        end
        for posX = -(ringNum - 1), (ringNum - 1) do
            pushPos(posX, -ringNum)
            pushPos(posX, ringNum)
        end
        for posY = -ringNum, ringNum do
            pushPos(ringNum, posY)
        end
    end
end

function BoardMultiServiceLogic:ChangeGapTiles(index, GapTilesList)
    local curBoard = self:GetCurBoard(index)
    curBoard.GapTiles = GapTilesList
end

function BoardMultiServiceLogic:GetGapTiles(index)
    local curBoard = self:GetCurBoard(index)
    return curBoard.GapTiles
end

function BoardMultiServiceLogic:GetGridTiles(index)
    local curBoard = self:GetCurBoard(index)
    return curBoard.GridTiles
end

function BoardMultiServiceLogic:GetBoardCenterPos(index)
    local curBoard = self:GetCurBoard(index)
    return curBoard.BoardCenterPos
end
function BoardMultiServiceLogic:SetBoardCenterPos(index, boardCenterPos)
    local curBoard = self:GetCurBoard(index)
    curBoard.BoardCenterPos = boardCenterPos
end

--生成格子算法
function BoardMultiServiceLogic:GenerateBoard(index, boardId)
    local curBoard = self:GetCurBoard(index)

    curBoard.index = index
    --全部格子
    curBoard.GridTiles = {}
    --全部格子数组
    curBoard._gridArray = {}

    --空位置  BoardServiceLogic:ChangeGapTiles(GapTilesList)
    -- curBoard.GapTiles = {}

    --连通率 = 总连通值/填色格子数
    curBoard._connectRate = 0
    --总连通值
    curBoard._totalConnect = 0
    --填色格子数
    curBoard._totalGridCnt = 0
    --配置
    curBoard._boardConfig = Cfg.cfg_board[boardId]

    self:_SetCurBoardCfgInfo(curBoard)

    --生成权重和
    curBoard._genPieceTotalWeight = 0
    local generatePieceWeight = self:GetCurBoardGeneratePieceWeight(curBoard)
    for i = 1, #generatePieceWeight do
        curBoard._genPieceTotalWeight = curBoard._genPieceTotalWeight + generatePieceWeight[i]
    end

    --初始化格子地形
    local maxX = self:GetCurBoardMaxX(curBoard)
    local maxY = self:GetCurBoardMaxY(curBoard)
    local val = BattleConst.OtherBoardConnectRate
    for x = 1, maxX do
        curBoard.GridTiles[x] = {}
        for y = 1, maxY do
            curBoard.GridTiles[x][y] = {x = x, y = y, connect = 0, color = PieceType.None, connvalue = val}
            table.insert(curBoard._gridArray, curBoard.GridTiles[x][y])
        end
    end

    for _, v in ipairs(curBoard.GapTiles) do
        local x, y = v[1], v[2]
        curBoard.GridTiles[x][y] = nil
    end

    --角色所在格子
    curBoard._roleGrid = nil

    local boardMode = curBoard._boardConfig.BoardMode
    --染色阶段
    if boardMode == GenBoardMode.Generated then
        self:GeneratedColor(curBoard)
    elseif boardMode == GenBoardMode.Specified then
        self:SpecifiedColor(curBoard._boardConfig.SpecifiedBoard, curBoard)
    elseif boardMode == GenBoardMode.Guide then
        self:SpecifiedColor(curBoard._boardConfig.SpecifiedBoard, curBoard)
    end

    local supplyPieceWeight = table.cloneconf(curBoard._boardConfig.SupplyPieceWeight)
    supplyPieceWeight = self:ProcessSupplyPieceWeight(supplyPieceWeight)
    self:CalculateSupplyPieceWeights(supplyPieceWeight, curBoard)

    return curBoard.GridTiles
end

---标记地图无效区阻挡
function BoardMultiServiceLogic:SetGapTilesBlock(curBoard)
    local boardEntity = self._world:GetBoardEntity()
    local blockFlags = boardEntity:Board():GetBlockFlagArray()
    local mapGapTiles = curBoard.GapTiles
    ---@type BoardMultiServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local cfgId = BattleConst.BlockFlagCfgIDGapTile
    local blockFlag = sBoard:GetBlockFlagByBlockId(cfgId)
    for _, v in ipairs(mapGapTiles) do
        local block = PieceBlockData:New(v[1], v[2])
        block:AddBlock(-cfgId, blockFlag)
        blockFlags[v[1]][v[2]] = block
    end
end

function BoardMultiServiceLogic:SpecifiedColor(board, curBoard)
    for x, row in pairs(board) do
        for y, color in pairs(row) do
            if curBoard.GridTiles[x][y] then
                curBoard.GridTiles[x][y].color = color
                self:AddGridColor(curBoard.GridTiles[x][y], curBoard)
            end
        end
    end
end

function BoardMultiServiceLogic:GeneratedColor(curBoard)
    --生成颜色池
    self:GenColorPool(51, curBoard)
    --生成孤岛池
    self:GenIslandPool(curBoard)
    --生长
    self:GrowIslandPool(curBoard)
    --补充剩余格子颜色
    self:FillRestGridColor(curBoard)
    --自动调整连通率
    self:AdjustConnectRate(curBoard._boardConfig.ConnectRate, curBoard)
end

--生成颜色池
function BoardMultiServiceLogic:GenColorPool(maxGridNum, curBoard)
    local pool = {}
    pool[PieceType.Blue] = curBoard._boardConfig.GeneratePieceAmount[PieceType.Blue] or 0
    pool[PieceType.Red] = curBoard._boardConfig.GeneratePieceAmount[PieceType.Red] or 0
    pool[PieceType.Green] = curBoard._boardConfig.GeneratePieceAmount[PieceType.Green] or 0
    pool[PieceType.Yellow] = curBoard._boardConfig.GeneratePieceAmount[PieceType.Yellow] or 0
    pool[PieceType.Any] = curBoard._boardConfig.GeneratePieceAmount[PieceType.Any] or 0

    local sum = 0
    for i, v in ipairs(pool) do
        sum = sum + v
    end

    local rest = maxGridNum - sum

    for i = 0, rest do
        local color = self:GenGridColorByWeight(curBoard)
        pool[color] = pool[color] + 1
    end

    curBoard._colorPool = pool
    return pool
end

--根据权重随机格子颜色[生成]
function BoardMultiServiceLogic:GenGridColorByWeight(curBoard)
    local randomRes = self:GetBoardRandomNumber(1, curBoard._genPieceTotalWeight)
    local weight = 0
    local generatePieceWeight = self:GetCurBoardGeneratePieceWeight(curBoard)
    for i = 1, #generatePieceWeight do
        weight = weight + generatePieceWeight[i]
        if randomRes <= weight then
            return i
        end
    end
end

--根据权重随机格子颜色[补充]
function BoardMultiServiceLogic:FillGridColorByWeight(curBoard)
    local randomRes = self:GetBoardRandomNumber(1, curBoard._supplyPieceTotalWeight:Value())
    local weight = 0
    for i = 1, #curBoard._supplyPieceWeights do
        weight = weight + curBoard._supplyPieceWeights[i]:Value()
        if randomRes <= weight then
            return i
        end
    end
end

--取格子周围的8个格子
function BoardMultiServiceLogic:GetRoundGrid(grid, curBoard, filter)
    local roundGrids = {}
    if grid == nil or table.count(grid) == 0 then
        return roundGrids
    end

    for x = -1, 1 do
        for y = -1, 1 do
            local pos = Vector2(grid.x + x, grid.y + y)
            if not (x == 0 and y == 0) and curBoard.GridTiles[pos.x] and curBoard.GridTiles[pos.x][pos.y] then
                local g = curBoard.GridTiles[pos.x][pos.y]
                if filter == nil or filter(g) then
                    table.insert(roundGrids, g)
                end
            end
        end
    end
    return roundGrids
end

--生成孤岛池
function BoardMultiServiceLogic:GenIslandPool(curBoard)
    curBoard._initIslands = {}
    if curBoard._boardConfig.RoundIslandCount > 8 then
        curBoard._boardConfig.RoundIslandCount = 8
    end
    local round = self:GetRoundGrid(curBoard._roleGrid, curBoard)
    if #round == 0 then
        return
    end

    for _ = 1, curBoard._boardConfig.RoundIslandCount do
        local r = self:GetBoardRandomNumber(1, #round)
        local grid = round[r]
        table.remove(round, r)
        local island = {}
        if curBoard._maxIsland == nil then
            curBoard._maxIsland = island
            island.length =
                self:GetBoardRandomNumber(curBoard._boardConfig.LongIsland[2], curBoard._boardConfig.LongIsland[3] + 1)
            grid.color = curBoard._boardConfig.LongIsland[1]
        else
            island.length = self:GetBoardRandomNumber(2, curBoard._maxIsland.length)
            grid.color = self:FillGridColorFromPool(grid)
        end
        self:AddGridColor(grid)
        table.insert(island, grid)
        table.insert(curBoard._initIslands, island)
    end
end

--孤岛生长
function BoardMultiServiceLogic:GrowIslandPool(curBoard)
    for i, v in ipairs(curBoard._initIslands) do
        self:GrowIsland(v, curBoard)
    end
end

function BoardMultiServiceLogic:GrowIsland(island, curBoard)
    for i = 1, island.length do
        local color = island[1].color
        if curBoard._colorPool[color] == 0 then
            return
        end
        local last = island[#island]
        local next = self:FindNextGrowGrid(last, curBoard)
        if next == nil then
            return
        end
        curBoard._colorPool[color] = curBoard._colorPool[color] - 1
        next.color = color
        self:AddGridColor(next, curBoard)
        table.insert(island, next)
    end
end

--怪物配置的棋盘位置
function BoardMultiServiceLogic:IsMonsterConfigPos(pos)
    return false
end

function BoardMultiServiceLogic:FindNextGrowGrid(last, curBoard)
    local round =
        self:GetRoundGrid(
        last,
        curBoard,
        function(g)
            -- 避开怪物占位
            return g.color == PieceType.None and g ~= curBoard._roleGrid and not self:IsMonsterConfigPos(last)
        end
    )
    if #round > 0 then
        local r = self:GetBoardRandomNumber(1, #round)
        return round[r]
    end
end

--填充剩余格子[无序]
function BoardMultiServiceLogic:FillRestGridColor(curBoard)
    for _, grid in ipairs(curBoard._gridArray) do
        if grid.color == PieceType.None and grid ~= curBoard._roleGrid then
            grid.color = self:FillGridColorFromPool(grid, curBoard)
            self:AddGridColor(grid, curBoard)
        end
    end
end

--从池中选择颜色填充到格子
function BoardMultiServiceLogic:FillGridColorFromPool(grid, curBoard)
    local colors = {}
    for k, v in ipairs(curBoard._colorPool) do
        if v > 0 then
            table.insert(colors, k)
        end
    end
    --绕开最长孤岛
    if #colors > 1 then
        local round =
            self:GetRoundGrid(
            grid,
            curBoard,
            function(g)
                return table.icontains(curBoard._maxIsland, g)
            end
        )
        if #round > 0 then
            table.removev(colors, curBoard._maxIsland[1].color)
        end
    end
    --随机颜色
    if #colors > 0 then
        local r = self:GetBoardRandomNumber(1, #colors)
        local c = colors[r]
        curBoard._colorPool[c] = curBoard._colorPool[c] - 1
        return c
    end
    --按权重随机
    return self:GenGridColorByWeight(curBoard)
end

--增量计算连通率：交换格子
function BoardMultiServiceLogic:ExchangeGrid(gridA, gridB, curBoard)
    --原位置格子连通值变化
    local roundA =
        self:GetRoundGrid(
        gridA,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, gridA.color)
        end
    )
    table.foreach(
        roundA,
        function(g)
            g.connect = g.connect - gridA.connvalue
            curBoard._totalConnect = curBoard._totalConnect - g.connvalue - gridA.connvalue
        end
    )
    local roundB =
        self:GetRoundGrid(
        gridB,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, gridB.color)
        end
    )
    table.foreach(
        roundB,
        function(g)
            g.connect = g.connect - gridB.connvalue
            curBoard._totalConnect = curBoard._totalConnect - g.connvalue - gridB.connvalue
        end
    )

    --交换颜色
    local color = gridA.color
    gridA.color = gridB.color
    gridB.color = color

    --新位置格子连通值变化
    roundA =
        self:GetRoundGrid(
        gridA,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, gridA.color)
        end
    )
    table.foreach(
        roundA,
        function(g)
            g.connect = g.connect + gridA.connvalue
            gridA.connect = gridA.connect + g.connvalue
            curBoard._totalConnect = curBoard._totalConnect + g.connvalue + gridA.connvalue
        end
    )
    roundB =
        self:GetRoundGrid(
        gridB,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, gridB.color)
        end
    )
    table.foreach(
        roundB,
        function(g)
            g.connect = g.connect + gridB.connvalue
            gridB.connect = gridB.connect + g.connvalue
            curBoard._totalConnect = curBoard._totalConnect + g.connvalue + gridB.connvalue
        end
    )

    curBoard._connectRate = curBoard._totalConnect / curBoard._totalGridCnt
end

--增加格子颜色连通率变化
function BoardMultiServiceLogic:AddGridColor(grid, curBoard)
    if grid == curBoard._roleGrid then --TODO 角色位置会变化
        return
    end
    local round =
        self:GetRoundGrid(
        grid,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, grid.color)
        end
    )
    table.foreach(
        round,
        function(g)
            g.connect = g.connect + grid.connvalue
            grid.connect = grid.connect + g.connvalue
            curBoard._totalConnect = curBoard._totalConnect + g.connvalue + grid.connvalue
        end
    )

    curBoard._totalGridCnt = curBoard._totalGridCnt + 1
    curBoard._connectRate = curBoard._totalConnect / curBoard._totalGridCnt
end

--移除格子颜色连通率变化
function BoardMultiServiceLogic:RemoveGridColor(grid, curBoard)
    if grid == curBoard._roleGrid then
        return
    end
    local round =
        self:GetRoundGrid(
        grid,
        curBoard,
        function(g)
            return CanMatchPieceType(g.color, grid.color)
        end
    )
    table.foreach(
        round,
        function(g)
            g.connect = g.connect - grid.connvalue
            curBoard._totalConnect = curBoard._totalConnect - g.connvalue - grid.connvalue
        end
    )
    grid.connect = 0
    grid.color = PieceType.None

    curBoard._totalGridCnt = curBoard._totalGridCnt - 1
    curBoard._connectRate = curBoard._totalConnect / curBoard._totalGridCnt
end

--提升连通率
--a) 寻找孤岛A上的格子G，其连通值<3，并且格子G周围和G不同色的同色的格子数量>3，颜色为C
--b) 寻找颜色为C的格子X，其连通值<3
--c) G和X交换位置，则连通率提升
--降低连通率
--a) 寻找孤岛A上的格子G，其连通值>3
--b) 寻找孤岛B上的格子X，其连通值>2 => 改成G和X连接数之和>6
--c) G和X交换位置，则连通率降低
function BoardMultiServiceLogic:AdjustConnectRate(target, curBoard)
    if math.abs(target - curBoard._connectRate) < 0.1 then
        return
    end

    --提升
    if curBoard._connectRate < target then
        for _, v in ipairs(curBoard.GridTiles) do
            for _, grid in ipairs(v) do
                if self:IsValidPiecePos(grid, curBoard) then
                    local color = self:GetIncrGridColor(grid, curBoard)
                    if color ~= PieceType.None then
                        local grid2 =
                            self:FirstGrid(
                            curBoard,
                            function(g)
                                return g.color == color and g.connect < 3
                            end
                        )
                        if grid2 ~= nil then
                            self:ExchangeGrid(grid, grid2, curBoard)
                            if math.abs(target - curBoard._connectRate) < 0.1 then
                                return
                            end
                        end
                    end
                end
            end
        end
    else --降低
        for _, v in ipairs(curBoard.GridTiles) do
            for _, grid in ipairs(v) do
                local color = self:GetDecrGridColor(grid)
                if color ~= PieceType.None then
                    local grid2 =
                        self:FirstGrid(
                        curBoard,
                        function(g)
                            return g.color ~= color and g.connect + grid.connect > 6
                        end
                    )
                    if grid2 ~= nil then
                        self:ExchangeGrid(grid, grid2, curBoard)
                        if math.abs(target - curBoard._connectRate) < 0.1 then
                            return
                        end
                    end
                end
            end
        end
    end
end

function BoardMultiServiceLogic:FirstGrid(curBoard, filter)
    if filter == nil then
        return
    end
    for _, v in ipairs(curBoard.GridTiles) do
        for _, grid in ipairs(v) do
            if filter(grid) then
                return grid
            end
        end
    end
end

function BoardMultiServiceLogic:GetIncrGridColor(grid, curBoard)
    if grid ~= curBoard._roleGrid and grid.connect < 2 then
        local dict = self:CalcRoundGridColor(grid, curBoard)
        for k, v in ipairs(dict) do
            if not CanMatchPieceType(k, grid.color) and v > 3 then
                return k
            end
        end
    end
    return PieceType.None
end

function BoardMultiServiceLogic:GetDecrGridColor(grid)
    if grid.connect > 3 and grid.color ~= PieceType.Any then
        return grid.color
    end
    return PieceType.None
end

function BoardMultiServiceLogic:CalcRoundGridColor(grid, curBoard)
    local dict = {
        [PieceType.Blue] = 0,
        [PieceType.Red] = 0,
        [PieceType.Green] = 0,
        [PieceType.Yellow] = 0,
        [PieceType.Any] = 0
    }
    local round =
        self:GetRoundGrid(
        grid,
        curBoard,
        function(g)
            return g.color ~= PieceType.None
        end
    )
    table.foreach(
        round,
        function(g)
            dict[g.color] = dict[g.color] + 1
        end
    )
    return dict
end

--region board svc l
function BoardMultiServiceLogic:IsValidPiecePos(pos, curBoard)
    local x, y = pos.x, pos.y
    if x == nil or y == nil then
        return
    end
    if curBoard.GridTiles[x] and curBoard.GridTiles[x][y] then
        return true
    end
    return false
end

--endregion board svc l

--region Block
---@param pos Vector2
---@param blockFlag BlockFlag
---pos位置是否阻挡了blockFlag指示的阻挡类型
function BoardMultiServiceLogic:IsPosBlockMultiBoard(boardIndex, pos, blockFlag)
    if not pos then
        return false
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePosMultiBoard(boardIndex, pos) then
        return true --棋盘外的位置一律阻挡
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPosMultiBoard(boardIndex, pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end

---@return PieceBlockData
function BoardMultiServiceLogic:FindBlockByPosMultiBoard(boardIndex, pos)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardMultiComponent
    local cmptBoardMulti = boardEntity:BoardMulti()
    return cmptBoardMulti:FindBlockByPos(boardIndex, pos)
end

---@param e Entity
---@param posOld Vector2
function BoardMultiServiceLogic:RemoveEntityBlockFlagMultiBoard(boardIndex, e, posOld)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end

    local bodyArea = e:BodyArea():GetArea()
    local blockFlag = self:GetBlockFlagMultiBoard(e)
    for _, area in ipairs(bodyArea) do
        self:RemovePosBlockMultiBoard(boardIndex, e, posOld + area, blockFlag)
    end
    return bodyArea, blockFlag
end

---移除pos位置的blockFlag类型的Block
---@param blockFlag BlockFlag
function BoardMultiServiceLogic:RemovePosBlockMultiBoard(boardIndex, e, pos, blockFlag)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePosMultiBoard(boardIndex, pos) then
        return
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPosMultiBoard(boardIndex, pos)
    if nil == pieceBlock then
        return
    end

    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end

    pieceBlock:DelBlock(e:GetID(), blockFlag)

    ---@type BoardMultiComponent
    local cmptBoardMulti = self._world:GetBoardEntity():BoardMulti()

    cmptBoardMulti:RemovePieceEntity(boardIndex, pos, e)
end

---@param e Entity
---@param posOld Vector2
---@param posNew Vector2
function BoardMultiServiceLogic:UpdateEntityBlockFlagMultiBoard(boardIndex, e, posOld, posNew)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea, blockFlag = self:RemoveEntityBlockFlagMultiBoard(boardIndex, e, posOld)
    for _, area in ipairs(bodyArea) do
        self:SetPosBlockMultiBoard(boardIndex, e, posNew + area, blockFlag)
    end
end

---更新目标entity的block为指定的flag
---@param e Entity
---@param pos Vector2
function BoardMultiServiceLogic:SetEntityBlockFlagMultiBoard(boardIndex, e, pos, blockFlag)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea = e:BodyArea():GetArea()
    for _, area in ipairs(bodyArea) do
        self:SetPosBlockMultiBoard(boardIndex, e, pos + area, blockFlag)
    end
end

---给pos位置设置blockFlag类型的Block
function BoardMultiServiceLogic:SetPosBlockMultiBoard(boardIndex, entity, pos, blockFlag)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePosMultiBoard(boardIndex, pos) then
        return
    end

    ---@type BoardMultiComponent
    local cmptBoardMulti = self._world:GetBoardEntity():BoardMulti()
    cmptBoardMulti:AddPieceEntity(boardIndex, pos, entity)

    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPosMultiBoard(boardIndex, pos)
    if pieceBlock == nil then
        return
    end
    blockFlag = blockFlag or self:GetBlockFlagMultiBoard(entity)
    pieceBlock:AddBlock(entity:GetID(), blockFlag)
end

---@param e Entity
function BoardMultiServiceLogic:GetBlockFlagMultiBoard(e)
    if e:HasGhost() then
        local ownerId = e:Ghost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetBlockFlagMultiBoard(eOwner)
        end
        Log.fatal("### Ghost has not owner.", e:GridLocation() and e:GridLocation().Position, ownerId)
        return 0
    end
    if e:HasGuideGhost() then
        local ownerId = e:GuideGhost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetBlockFlagMultiBoard(eOwner)
        end
        Log.fatal("### Guide Ghost has not owner.", e:GridLocation() and e:GridLocation().Position, ownerId)
        return 0
    end
    if e:HasBlockFlag() then
        return e:BlockFlag():GetBlockFlag()
    end
    Log.fatal("### RemoveEntityBlockFlag new entity type.", e:EntityType().Value)
    return 0
end

--endregion Block

---@param pieceType PieceType 格子的颜色
---@param gridPos Vector2 格子位置
function BoardMultiServiceLogic:SetPieceTypeLogic(boardIndex, pieceType, gridPos)
    ---@type BoardMultiComponent
    local cmptBoardMulti = self._world:GetBoardEntity():BoardMulti()
    cmptBoardMulti:SetPieceElement(boardIndex, gridPos, pieceType)
end

function BoardMultiServiceLogic:GetEntityGroup()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    local outsideRegionGroup = self._world:GetGroup(self._world.BW_WEMatchers.OutsideRegion)
    local es = monsterGroup:GetEntities()
    table.appendArray(es, trapGroup:GetEntities())

    for i, e in ipairs(outsideRegionGroup:GetEntities()) do
        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion:GetMonsterID() then
            table.insert(es, e)
        end
    end

    return es
end

function BoardMultiServiceLogic:CalcPieceEntities(entities, boardIndex)
    local posEntities = {}

    for i, e in ipairs(entities) do
        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion and outsideRegion:GetBoardIndex() == boardIndex then
            local pos = e:GridLocation():GetGridPos()
            local bodyArea = e:BodyArea():GetArea()
            for i, area in ipairs(bodyArea) do
                local posWork = pos + area
                local posIndex = Vector2.Pos2Index(posWork)
                local t = posEntities[posIndex] or {}
                t[#t + 1] = e
                posEntities[posIndex] = t
            end
        end
    end
    return posEntities
end

function BoardMultiServiceLogic:SaveMonsterIDCmptOnOutsideRegion()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local removeList = {}
    for i, e in ipairs(monsterGroup:GetEntities()) do
        ---@type OutsideRegionComponent
        local outsideRegion = e:OutsideRegion()
        if outsideRegion then
            ---@type MonsterIDComponent
            local monsterIDCmpt = e:MonsterID()

            outsideRegion:SetMonsterID(monsterIDCmpt)
            table.insert(removeList, e)
        end
    end

    for i, e in ipairs(removeList) do
        e:RemoveMonsterID()
    end
end

function BoardMultiServiceLogic:CalculateSupplyPieceWeights(boardSupplyPieceWeights, curBoard)
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    ---检查关卡是否启用光灵补充刷新格子的权重
    if levelConfigData:IsApplyPetSupplyPieceWeight() then
        local baseBoardSupplyPieceWeights = table.cloneconf(boardSupplyPieceWeights)
        --遍历队员
        ---@type MatchPet[]
        local listMatchPet = self._world.BW_WorldInfo:GetLocalMatchPetList()
        ---@param matchPet MatchPet
        for _, matchPet in ipairs(listMatchPet) do
            local petWeights = matchPet:GetPetSupplyPieceWeights()
            if petWeights then
                if #petWeights ~= 5 then
                    Log.error("Cfg PetSupplyPieceWeights size error: pet ID:", matchPet:GetTemplateID())
                end
                for index, value in ipairs(petWeights) do
                    if baseBoardSupplyPieceWeights[index] ~= 0 then--如果本身这种颜色的权重是0（例如经过词条覆盖后），就不处理光灵修正
                        boardSupplyPieceWeights[index] = boardSupplyPieceWeights[index] + value
                    end
                end
            end
        end
    end

    local totalSupplyWeight = 0
    for i = 1, #boardSupplyPieceWeights do
        if boardSupplyPieceWeights[i] < 0 then
            boardSupplyPieceWeights[i] = 0
        end
        totalSupplyWeight = totalSupplyWeight + boardSupplyPieceWeights[i]
    end

    if totalSupplyWeight < 1 then
        Log.error("Cfg SupplyPieceWeight total weight error!!!")
    end

    --补充权重和
    curBoard._supplyPieceTotalWeight = MultModifyValue_Add:New(totalSupplyWeight)

    --补充权重
    curBoard._supplyPieceWeights = {
        [PieceType.Blue] = MultModifyValue_Add:New(boardSupplyPieceWeights[1]),
        [PieceType.Red] = MultModifyValue_Add:New(boardSupplyPieceWeights[2]),
        [PieceType.Green] = MultModifyValue_Add:New(boardSupplyPieceWeights[3]),
        [PieceType.Yellow] = MultModifyValue_Add:New(boardSupplyPieceWeights[4]),
        [PieceType.Any] = MultModifyValue_Add:New(boardSupplyPieceWeights[5])
    }
end
function BoardMultiServiceLogic:GetCurBoardGeneratePieceWeight(curBoard)
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local generatePieceWeight = affixSvc:ProcessGeneratePieceWeight(curBoard._boardConfig.GeneratePieceWeight)
    return generatePieceWeight
end
function BoardMultiServiceLogic:ProcessSupplyPieceWeight(baseSupplyPieceWeight)
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local generatePieceWeight = affixSvc:ProcessSupplyPieceWeight(baseSupplyPieceWeight)
    return generatePieceWeight
end