--[[ 
    棋盘生成专用
]]
require("board_svc_l")

local AttackAreaType = {
    PlayerArea = 1,
    AIArea = 2
}
---@class AttackAreaType
_enum("AttackAreaType", AttackAreaType)

--棋盘生成模式
local GenBoardMode = {
    Generated = 0, --生成
    Specified = 1, --指定
    Guide = 2, --引导
    Archived = 3, --存档
    BigBoard = 4 --大地图
}
---@class GenBoardMode
_enum("GenBoardMode", GenBoardMode)

--向右旋转一个nxn二维数组
local function RightRotate(arr)
    local brr = {}
    local n = #arr
    for y = 1, n do
        local t = {}
        table.insert(brr, t)
        for x = n, 1, -1 do
            table.insert(t, arr[x][y])
        end
    end
    return brr
end

--房间原型
local RoomPrototype = {
    [1000] = 1,
    [0100] = 1,
    [0010] = 1,
    [0001] = 1,
    [1100] = 2,
    [0110] = 2,
    [0011] = 2,
    [1001] = 2,
    [1010] = 3,
    [0101] = 3,
    [1110] = 4,
    [0111] = 4,
    [1011] = 4,
    [1101] = 4,
    [1111] = 5
}

--旋转表
local RotateTable = {
    [1000] = 0,
    [0100] = 1,
    [0010] = 2,
    [0001] = 3,
    [1100] = 0,
    [0110] = 1,
    [0011] = 2,
    [1001] = 3,
    [1010] = 0,
    [0101] = 1,
    [1110] = 0,
    [0111] = 1,
    [1011] = 2,
    [1101] = 3,
    [1111] = 0
}

--旋转坐标对照表
local PointRightRotateTable = {
    [101] = 501,
    [201] = 502,
    [301] = 503,
    [401] = 504,
    [501] = 505,
    [102] = 401,
    [202] = 402,
    [302] = 403,
    [402] = 404,
    [502] = 405,
    [103] = 301,
    [203] = 302,
    [303] = 303,
    [403] = 304,
    [503] = 305,
    [104] = 201,
    [204] = 202,
    [304] = 203,
    [404] = 204,
    [504] = 205,
    [105] = 101,
    [205] = 102,
    [305] = 103,
    [405] = 104,
    [505] = 105
}
--坐标旋转对照表
local DirRightRotateTable = {
    [12] = 21,
    [21] = 10,
    [10] = 01,
    [01] = 12,
    [02] = 22,
    [22] = 20,
    [20] = 00,
    [00] = 02
}
--大地图房间的尺寸，格子数
local BigBoardRoomSize = 5


local function Filter_MatchGAndGrid(g, filter_grid)
    return CanMatchPieceType(g.color, filter_grid.color)
end

function BoardServiceLogic:_RightRotatePoint(x, y, cnt)
    if cnt == 0 then
        return x, y
    end
    local val = x * 100 + y
    for i = 1, cnt do
        val = PointRightRotateTable[val]
    end
    x = val // 100
    y = val % 100
    return x, y
end
function BoardServiceLogic:_RightRotateDir(x, y, cnt)
    if cnt == 0 then
        return x, y
    end
    local val = (x + 1) * 10 + y + 1
    for i = 1, cnt do
        val = DirRightRotateTable[val]
    end
    x = val // 10 - 1
    y = val % 10 - 1
    return x, y
end
--随机大地图房间
function BoardServiceLogic:_BigBoardRandRoom(cells, cx, cy)
    local adj = {0, 0, 0, 0}
    if cells[cx] and cells[cx][cy + 1] and cells[cx][cy + 1] ~= 0 then --上
        adj[1] = 1
    end
    if cells[cx + 1] and cells[cx + 1][cy] and cells[cx + 1][cy] ~= 0 then --右
        adj[2] = 1
    end
    if cells[cx] and cells[cx][cy - 1] and cells[cx][cy - 1] ~= 0 then --下
        adj[3] = 1
    end
    if cells[cx - 1] and cells[cx - 1][cy] and cells[cx - 1][cy] ~= 0 then --左
        adj[4] = 1
    end
    local val = adj[1] * 1000 + adj[2] * 100 + adj[3] * 10 + adj[4] * 1
    local rotateCnt = RotateTable[val]
    local roomtype = RoomPrototype[val]
    local cfgs = Cfg.cfg_board_big_room {RoomType = roomtype}
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local r = randomSvc:LogicRand(1, #cfgs)
    local roomcfg = cfgs[r]
    --格子旋转
    local grids = roomcfg.RoomGrid
    for i = 1, rotateCnt do
        grids = RightRotate(grids)
    end
    local role, traps, monsters
    --玩家旋转
    if roomcfg.Role then
        role = table.clone(roomcfg.Role)
        role.Pos[1], role.Pos[2] = self:_RightRotatePoint(role.Pos[1], role.Pos[2], rotateCnt)
        role.Dir[1], role.Dir[2] = self:_RightRotateDir(role.Dir[1], role.Dir[2], rotateCnt)
    end
    --机关旋转
    if roomcfg.Traps then
        traps = table.clone(roomcfg.Traps)
        for _, v in ipairs(traps) do
            v.Pos[1], v.Pos[2] = self:_RightRotatePoint(v.Pos[1], v.Pos[2], rotateCnt)
            v.Dir[1], v.Dir[2] = self:_RightRotateDir(v.Dir[1], v.Dir[2], rotateCnt)
        end
    end
    --怪物旋转
    if roomcfg.Monsters then
        monsters = table.clone(roomcfg.Monsters)
        for _, v in ipairs(monsters) do
            v.Pos[1], v.Pos[2] = self:_RightRotatePoint(v.Pos[1], v.Pos[2], rotateCnt)
            v.Dir[1], v.Dir[2] = self:_RightRotateDir(v.Dir[1], v.Dir[2], rotateCnt)
        end
    end
    Log.error(
        "[gen board] cx=",
        cx,
        "cy=",
        cy,
        "val=",
        val,
        "roll=",
        rotateCnt,
        "roomtype=",
        roomtype,
        "roomcfg.id=",
        roomcfg.ID
    )
    return grids, role, traps, monsters
end
--大地图固定房间
function BoardServiceLogic:_BigBoardFixedRoom(cellID)
    local cellCfg = Cfg.cfg_board_big_room[cellID]
    local grids = cellCfg.RoomGrid
    local role = cellCfg.Role
    local traps = cellCfg.Traps
    local monsters = cellCfg.Monsters
    return grids, role, traps, monsters
end
function BoardServiceLogic:GetCurBoardMaxX()
    return self._defaultMaxX or BattleConst.DefaultMaxX
end
function BoardServiceLogic:GetCurBoardMaxY()
    return self._defaultMaxY or BattleConst.DefaultMaxY
end
---获取当前地图最大的长度（x或y）
function BoardServiceLogic:GetCurBoardMaxLen()
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()
    return maxX > maxY and maxX or maxY
end
function BoardServiceLogic:_SetCurBoardCfgInfo()
    if self._boardConfig then
        self._defaultMaxX = self._boardConfig.DefaultMaxX and self._boardConfig.DefaultMaxX or BattleConst.DefaultMaxX
        self._defaultMaxY = self._boardConfig.DefaultMaxY and self._boardConfig.DefaultMaxY or BattleConst.DefaultMaxY
        BattleConst.BoardMaxLen = math.max(self._defaultMaxX, self._defaultMaxY)
        self._defaultPlayerAreaSizeX = BattleConst.DefaultPlayerAreaSize
        self._defaultPlayerAreaSizeY = BattleConst.DefaultPlayerAreaSize
        if self._boardConfig.DefaultPlayerAreaSize then
            if type(self._boardConfig.DefaultPlayerAreaSize) == "table" then
                if #self._boardConfig.DefaultPlayerAreaSize == 2 then
                    self._defaultPlayerAreaSizeX = self._boardConfig.DefaultPlayerAreaSize[1]
                    self._defaultPlayerAreaSizeY = self._boardConfig.DefaultPlayerAreaSize[2]
                end
            end
        end
        self._defaultAIAreaSizeX = BattleConst.DefaultAIAreaSize
        self._defaultAIAreaSizeY = BattleConst.DefaultAIAreaSize
        if self._boardConfig.DefaultAIAreaSize then
            if type(self._boardConfig.DefaultAIAreaSize) == "table" then
                if #self._boardConfig.DefaultAIAreaSize == 2 then
                    self._defaultAIAreaSizeX = self._boardConfig.DefaultAIAreaSize[1]
                    self._defaultAIAreaSizeY = self._boardConfig.DefaultAIAreaSize[2]
                end
            end
        end
        if self.PlayerArea then
            self.PlayerArea.maxX = self._defaultPlayerAreaSizeX
            self.PlayerArea.maxY = self._defaultPlayerAreaSizeY
        end
        if self.AIArea then
            self.AIArea.maxX = self._defaultAIAreaSizeX
            self.AIArea.maxY = self._defaultAIAreaSizeY
        end
        self:_GenBoardRingMax()
    end
end
---根据实际地图max x,y 生成RingMax，代替Ring9
function BoardServiceLogic:_GenBoardRingMax()
    self._ringMax = {}
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()
    local maxLen = self:GetCurBoardMaxLen()
    local pushPos = function(posX,posY)
        if posX >= -maxX and posX <= maxX then
            if posY >= -maxY and posY <= maxY then
                local pos = {posX,posY}
                table.insert(self._ringMax,pos)
            end
        end
    end
    for ringNum = 1, maxLen do
        for posY = -ringNum, ringNum do
            pushPos(-ringNum,posY)
        end
        for posX = -(ringNum-1), (ringNum-1) do
            pushPos(posX,-ringNum)
            pushPos(posX,ringNum)
        end
        for posY = -ringNum, ringNum do
            pushPos(ringNum,posY)
        end
    end
    -- Log.error("_GenBoardRingMax")
    -- for index, value in ipairs(self._ringMax) do
    --     Log.error("{",value[1],value[2],"}")
    -- end
end
---返回当前地图的RingMax，代替Ring9
function BoardServiceLogic:GetCurBoardRingMax()
    if self._ringMax then
        return self._ringMax
    else
        return Ring9
    end
end
--生成格子算法
---@param boardId number
---@param teamEntity Entity
function BoardServiceLogic:GenerateBoard(boardId, teamEntity)
    --全部格子
    self.GridTiles = {}
    --全部格子数组
    self._gridArray = {}
    self.MonsterArea = {}
    self.TrapArea = {}
    self.RoleArea = {}

    --连通率 = 总连通值/填色格子数
    self._connectRate = 0
    --总连通值
    self._totalConnect = 0
    --填色格子数
    self._totalGridCnt = 0
    --配置
    self._boardConfig = Cfg.cfg_board[boardId]
    self:_SetCurBoardCfgInfo()

    --生成权重和
    self._genPieceTotalWeight = 0
    local generatePieceWeight = self:GetCurBoardGeneratePieceWeight()
    for i = 1, #generatePieceWeight do
        self._genPieceTotalWeight = self._genPieceTotalWeight + generatePieceWeight[i]
    end

    local levelConfigData = self._configService:GetLevelConfigData()
    self.RoleArea.Pos = levelConfigData:GetPlayerBornPos()
    self.RoleArea.Dir = levelConfigData:GetPlayerBornRotation()

    ---传入teamEntity 代表中途按照配置ID生成地板 不使用配置中的初始队伍位置
    if teamEntity then
        self.RoleArea.Pos = table.cloneconf(teamEntity:GetGridPosition())
        self.RoleArea.Dir = table.cloneconf(teamEntity:GetGridDirection())
    end

    --初始化格子地形
    if self._boardConfig.BoardMode == GenBoardMode.BigBoard then
        local cfg = Cfg.cfg_board_big_cell[self._boardConfig.BigBoard]
        local cells = cfg.BigBoardCells
        local fixCells = cfg.FixCells or {}
        --1,1,1,0|1,1,1,0|0,0,1,1|0,0,0,1
        --组内y坐标组间x坐标
        for cx, row in ipairs(cells) do
            for cy, cellType in ipairs(row) do
                local grids, role, traps, monsters
                if cellType == 1 then --随机
                    grids, role, traps, monsters = self:_BigBoardRandRoom(cells, cx, cy)
                elseif cellType == 2 then --固定
                    local cellID = 1 --默认固定区域使用1号房间
                    for i, v in ipairs(fixCells) do
                        if v.Pos[1] == cx and v.Pos[2] == cy then
                            cellID = v.CellID
                        end
                    end
                    grids, role, traps, monsters = self:_BigBoardFixedRoom(cellID)
                end

                if grids then
                    --基地址
                    local basex = BigBoardRoomSize * (cx - 1)
                    local basey = BigBoardRoomSize * (cy - 1)

                    if role then
                        self.RoleArea = {
                            Pos = Vector2(basex + role.Pos[1], basey + role.Pos[2]),
                            Dir = Vector2(role.Dir[1], role.Dir[2])
                        }
                    end

                    --填充格子地形
                    for ox, row in ipairs(grids) do
                        for oy, gt in ipairs(row) do
                            local x = ox + basex
                            local y = oy + basey
                            if not self.GridTiles[x] then
                                self.GridTiles[x] = {}
                            end

                            if gt == 1 then --TODO jwk 改成地形枚举 0空地 1格子
                                local offset = math.abs(x - self.RoleArea.Pos.x) + math.abs(y - self.RoleArea.Pos.y)
                                local val = BattleConst.BoardGenConnectRateParamTable[offset]

                                self.GridTiles[x][y] = {
                                    x = x,
                                    y = y,
                                    connect = 0,
                                    color = PieceType.None,
                                    connvalue = val
                                }
                                table.insert(self._gridArray, self.GridTiles[x][y])
                            end
                        end
                    end

                    --单位
                    if traps then
                        for _, trap in ipairs(traps) do
                            local t = {
                                ID = trap.TrapID,
                                Pos = Vector2(basex + trap.Pos[1], basey + trap.Pos[2]),
                                Dir = Vector2(trap.Dir[1], trap.Dir[2])
                            }
                            table.insert(self.TrapArea, t)
                        end
                    end

                    if monsters then
                        for _, monster in ipairs(monsters) do
                            local t = {
                                ID = monster.MonsterID,
                                Pos = Vector2(basex + monster.Pos[1], basey + monster.Pos[2]),
                                Dir = Vector2(monster.Dir[1], monster.Dir[2])
                            }
                            table.insert(self.MonsterArea, t)
                        end
                    end
                end
            end
        end
    else
        local maxX = self:GetCurBoardMaxX()
        local maxY = self:GetCurBoardMaxY()
        for x = 1, maxX do
            self.GridTiles[x] = {}
            for y = 1, maxY do
                local offset = math.abs(x - self.RoleArea.Pos.x) + math.abs(y - self.RoleArea.Pos.y) + 1
                local val = BattleConst.BoardGenConnectRateParamTable[offset]
                assert(val ~= nil, "offset=" .. offset)
                self.GridTiles[x][y] = {x = x, y = y, connect = 0, color = PieceType.None, connvalue = val}
                table.insert(self._gridArray, self.GridTiles[x][y])
            end
        end

        for _, v in ipairs(self.GapTiles) do
            local x, y = v[1], v[2]
            self.GridTiles[x][y] = nil
        end
    end

    --角色所在格子
    if self._world:MatchType() ~= MatchType.MT_PopStar then
        self._roleGrid = self.GridTiles[self.RoleArea.Pos.x][self.RoleArea.Pos.y]
    end
    
    local boardMode = self._boardConfig.BoardMode
    local pieces = nil
    local archive = self._world:GetService("Maze"):GetBattleArchive()
    if archive then
        boardMode = GenBoardMode.Archived
        pieces = archive.pieces
    end

    --染色阶段
    if boardMode == GenBoardMode.Generated then
        self:GeneratedColor()
    elseif boardMode == GenBoardMode.Specified then
        self:SpecifiedColor(self._boardConfig.SpecifiedBoard)
    elseif boardMode == GenBoardMode.Guide then
        self:SpecifiedColor(self._boardConfig.SpecifiedBoard)
    elseif boardMode == GenBoardMode.Archived then
        self:SpecifiedColor(pieces)
    elseif boardMode == GenBoardMode.BigBoard then
        self:GeneratedColor()
    end
    if boardMode ~= GenBoardMode.Archived then
        if self._roleGrid then
            self._roleGrid.color = PieceType.None
        end
    end

    local supplyPieceWeight = table.cloneconf(self._boardConfig.SupplyPieceWeight)
    supplyPieceWeight = self:ProcessSupplyPieceWeight(supplyPieceWeight)
    self:CalculateSupplyPieceWeights(supplyPieceWeight)
	
    --扩展棋盘
    if self._extraBoardPosList then
        for i = 1, #self._extraBoardPosList do
            local x = self._extraBoardPosList[i][1]
            local y = self._extraBoardPosList[i][2]
            self.GridTiles[x][y] = {
                x = x,
                y = y,
                connect = 0,
                color = PieceType.None,
                connvalue = 0
            }
        end
    end
	
    return self.GridTiles
end

---标记地图无效区阻挡
function BoardServiceLogic:SetGapTilesBlock()
    local boardEntity = self._world:GetBoardEntity()
    local blockFlags = boardEntity:Board():GetBlockFlagArray()
    local mapGapTiles = self.GapTiles
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local cfgId = BattleConst.BlockFlagCfgIDGapTile
    local blockFlag = sBoard:GetBlockFlagByBlockId(cfgId)
    for _, v in ipairs(mapGapTiles) do
        local block = PieceBlockData:New(v[1], v[2])
        block:AddBlock(-cfgId, blockFlag)
        blockFlags[v[1]][v[2]] = block
    end
end

function BoardServiceLogic:ModifyPieceWeight(piece_type, weight, flag)
    self._supplyPieceWeights[piece_type]:AddModify(weight, flag)
    self._supplyPieceTotalWeight:AddModify(weight, flag)
end

function BoardServiceLogic:RemoveModifyPieceWeight(piece_type, flag)
    self._supplyPieceWeights[piece_type]:RemoveModify(flag)
    self._supplyPieceTotalWeight:RemoveModify(flag)
end

function BoardServiceLogic:SpecifiedColor(board)
    for x, row in pairs(board) do
        for y, color in pairs(row) do
            if self.GridTiles[x][y] then
                self.GridTiles[x][y].color = color
                self:AddGridColor(self.GridTiles[x][y])
            end
        end
    end
end

function BoardServiceLogic:GetConnectRate()
    return self._connectRate
end

function BoardServiceLogic:GeneratedColor()
    --生成颜色池
    self:GenColorPool(51)
    --生成孤岛池
    self:GenIslandPool()
    --生长
    self:GrowIslandPool()
    --补充剩余格子颜色
    self:FillRestGridColor()
    --自动调整连通率
    self:AdjustConnectRate(self._boardConfig.ConnectRate)
    --Log.notice("generate board end ------")
end

--生成颜色池
function BoardServiceLogic:GenColorPool(maxGridNum)
    local pool = {}
    pool[PieceType.Blue] = self._boardConfig.GeneratePieceAmount[PieceType.Blue] or 0
    pool[PieceType.Red] = self._boardConfig.GeneratePieceAmount[PieceType.Red] or 0
    pool[PieceType.Green] = self._boardConfig.GeneratePieceAmount[PieceType.Green] or 0
    pool[PieceType.Yellow] = self._boardConfig.GeneratePieceAmount[PieceType.Yellow] or 0
    pool[PieceType.Any] = self._boardConfig.GeneratePieceAmount[PieceType.Any] or 0

    local sum = 0
    for i, v in ipairs(pool) do
        sum = sum + v
    end

    local rest = maxGridNum - sum

    for i = 0, rest do
        local color = self:GenGridColorByWeight()
        pool[color] = pool[color] + 1
    end

    self._colorPool = pool
    return pool
end

--根据权重随机格子颜色[生成]
function BoardServiceLogic:GenGridColorByWeight()
    local randomRes = self:GetBoardRandomNumber(1, self._genPieceTotalWeight)
    local weight = 0
    local generatePieceWeight = self:GetCurBoardGeneratePieceWeight()
    for i = 1, #generatePieceWeight do
        weight = weight + generatePieceWeight[i]
        if randomRes <= weight then
            return i
        end
    end
end

--根据权重随机格子颜色[补充]
function BoardServiceLogic:FillGridColorByWeight()
    local randomRes = self:GetBoardRandomNumber(1, self._supplyPieceTotalWeight:Value())
    local weight = 0
    for i = 1, #self._supplyPieceWeights do
        weight = weight + self._supplyPieceWeights[i]:Value()
        if randomRes <= weight then
            return i
        end
    end
end

--取格子周围的8个格子
function BoardServiceLogic:GetRoundGrid(grid, filter,...)
    local roundGrids = {}
    if grid == nil then 
        return roundGrids
    end

    for x = -1, 1 do
        for y = -1, 1 do
            local pos = Vector2(grid.x + x, grid.y + y)
            if not (x == 0 and y == 0) and self.GridTiles[pos.x] and self.GridTiles[pos.x][pos.y] then
                local g = self.GridTiles[pos.x][pos.y]
                if filter == nil or filter(g,...) then
                    table.insert(roundGrids, g)
                end
            end
        end
    end
    return roundGrids
end

--生成孤岛池
function BoardServiceLogic:GenIslandPool()
    self._initIslands = {}
    if self._boardConfig.RoundIslandCount > 8 then
        self._boardConfig.RoundIslandCount = 8
    end
    
    local baseGrid = self._roleGrid
    if self._world:MatchType() == MatchType.MT_PopStar then
        ---消灭星星模式无玩家角色格子，直接使用配置中的位置
        baseGrid = self.GridTiles[self.RoleArea.Pos.x][self.RoleArea.Pos.y]
    end
    local round = self:GetRoundGrid(baseGrid)
    if #round == 0 then 
        return 
    end

    for _ = 1, self._boardConfig.RoundIslandCount do
        local r = self:GetBoardRandomNumber(1, #round)
        local grid = round[r]
        table.remove(round, r)
        local island = {}
        if self._maxIsland == nil then
            self._maxIsland = island
            island.length =
                self:GetBoardRandomNumber(self._boardConfig.LongIsland[2], self._boardConfig.LongIsland[3] + 1)
            grid.color = self._boardConfig.LongIsland[1]
        else
            island.length = self:GetBoardRandomNumber(2, self._maxIsland.length)
            grid.color = self:FillGridColorFromPool(grid)
        end
        self:AddGridColor(grid)
        table.insert(island, grid)
        table.insert(self._initIslands, island)
    end
end

--孤岛生长
function BoardServiceLogic:GrowIslandPool()
    for i, v in ipairs(self._initIslands) do
        self:GrowIsland(v)
    end
end

function BoardServiceLogic:GrowIsland(island)
    for i = 1, island.length do
        local color = island[1].color
        if self._colorPool[color] == 0 then
            return
        end
        local last = island[#island]
        local next = self:FindNextGrowGrid(last)
        if next == nil then
            return
        end
        self._colorPool[color] = self._colorPool[color] - 1
        next.color = color
        self:AddGridColor(next)
        table.insert(island, next)
    end
end

--怪物配置的棋盘位置
function BoardServiceLogic:IsMonsterConfigPos(pos)
    return false
end
local function Filter_FindNextGrowGrid(g,self,last)
    return g.color == PieceType.None and g ~= self._roleGrid and not self:IsMonsterConfigPos(last)
end
function BoardServiceLogic:FindNextGrowGrid(last)
    local round =
        self:GetRoundGrid(
        last,
                Filter_FindNextGrowGrid,self,last)
    --    function(g)
    --        -- 避开怪物占位
    --        return g.color == PieceType.None and g ~= self._roleGrid and not self:IsMonsterConfigPos(last)
    --    end
    --)
    if #round > 0 then
        local r = self:GetBoardRandomNumber(1, #round)
        return round[r]
    end
end

--填充剩余格子[无序]
function BoardServiceLogic:FillRestGridColor()
    for _, grid in ipairs(self._gridArray) do
        if grid.color == PieceType.None and grid ~= self._roleGrid then
            grid.color = self:FillGridColorFromPool(grid)
            self:AddGridColor(grid)
        end
    end
end

local function Filter_FillGridColorFromPool(g,maxIsland)
    return table.icontains(maxIsland, g)
end

--从池中选择颜色填充到格子
function BoardServiceLogic:FillGridColorFromPool(grid)
    local colors = {}
    for k, v in ipairs(self._colorPool) do
        if v > 0 then
            table.insert(colors, k)
        end
    end
    --绕开最长孤岛
    if #colors > 1 then
        local round =
            self:GetRoundGrid(
            grid,Filter_FillGridColorFromPool,self._maxIsland
        )
        if #round > 0 then
            table.removev(colors, self._maxIsland[1].color)
        end
    end
    --随机颜色
    if #colors > 0 then
        local r = self:GetBoardRandomNumber(1, #colors)
        local c = colors[r]
        self._colorPool[c] = self._colorPool[c] - 1
        return c
    end
    --按权重随机
    return self:GenGridColorByWeight()
end

--增量计算连通率：交换格子
function BoardServiceLogic:ExchangeGrid(gridA, gridB)
    --原位置格子连通值变化
    local roundA =
        self:GetRoundGrid(
        gridA,Filter_MatchGAndGrid,gridA
    )
    for _, g in pairs(roundA) do
        g.connect = g.connect - gridA.connvalue
        self._totalConnect = self._totalConnect - g.connvalue - gridA.connvalue
    end
    --table.foreach(
    --    roundA,
    --    function(g)
    --        g.connect = g.connect - gridA.connvalue
    --        self._totalConnect = self._totalConnect - g.connvalue - gridA.connvalue
    --    end
    --)
    local roundB =
        self:GetRoundGrid(
        gridB,Filter_MatchGAndGrid,gridB
    )
    for k, g in pairs(roundB) do
        g.connect = g.connect - gridB.connvalue
        self._totalConnect = self._totalConnect - g.connvalue - gridB.connvalue
    end
    --table.foreach(
    --    roundB,
    --    function(g)
    --        g.connect = g.connect - gridB.connvalue
    --        self._totalConnect = self._totalConnect - g.connvalue - gridB.connvalue
    --    end
    --)

    --交换颜色
    local color = gridA.color
    gridA.color = gridB.color
    gridB.color = color

    --新位置格子连通值变化
    roundA =
        self:GetRoundGrid(
        gridA,Filter_MatchGAndGrid,gridA
    )
    for k, g in pairs(roundA) do
        g.connect = g.connect + gridA.connvalue
        gridA.connect = gridA.connect + g.connvalue
        self._totalConnect = self._totalConnect + g.connvalue + gridA.connvalue
    end
    --table.foreach(
    --    roundA,
    --    function(g)
    --        g.connect = g.connect + gridA.connvalue
    --        gridA.connect = gridA.connect + g.connvalue
    --        self._totalConnect = self._totalConnect + g.connvalue + gridA.connvalue
    --    end
    --)
    roundB =
        self:GetRoundGrid(
        gridB,Filter_MatchGAndGrid,gridB
    )
    for k, g in pairs(roundB) do
        g.connect = g.connect + gridB.connvalue
        gridB.connect = gridB.connect + g.connvalue
        self._totalConnect = self._totalConnect + g.connvalue + gridB.connvalue
    end
    --table.foreach(
    --    roundB,
    --    function(g)
    --        g.connect = g.connect + gridB.connvalue
    --        gridB.connect = gridB.connect + g.connvalue
    --        self._totalConnect = self._totalConnect + g.connvalue + gridB.connvalue
    --    end
    --)

    self._connectRate = self._totalConnect / self._totalGridCnt
end

--增加格子颜色连通率变化
function BoardServiceLogic:AddGridColor(grid)
    if grid == self._roleGrid then --TODO 角色位置会变化
        return
    end

    local round =self:GetRoundGrid(grid, Filter_MatchGAndGrid,grid)

    for _, g in pairs(round) do
        g.connect = g.connect + grid.connvalue
        grid.connect = grid.connect + g.connvalue
        self._totalConnect = self._totalConnect + g.connvalue + grid.connvalue
    end
    --table.foreach(
    --    round,
    --    function(g)
    --        g.connect = g.connect + grid.connvalue
    --        grid.connect = grid.connect + g.connvalue
    --        self._totalConnect = self._totalConnect + g.connvalue + grid.connvalue
    --    end
    --)

    self._totalGridCnt = self._totalGridCnt + 1
    self._connectRate = self._totalConnect / self._totalGridCnt
end

--移除格子颜色连通率变化
function BoardServiceLogic:RemoveGridColor(grid)
    if grid == self._roleGrid then
        return
    end

    local round =
        self:GetRoundGrid(
        grid, Filter_MatchGAndGrid,grid
    )

    for _, g in pairs(round) do
        g.connect = g.connect - grid.connvalue
        self._totalConnect = self._totalConnect - g.connvalue - grid.connvalue
    end
    --table.foreach(
    --    round,
    --    function(g)
    --        g.connect = g.connect - grid.connvalue
    --        self._totalConnect = self._totalConnect - g.connvalue - grid.connvalue
    --    end
    --)
    grid.connect = 0
    grid.color = PieceType.None

    self._totalGridCnt = self._totalGridCnt - 1
    self._connectRate = self._totalConnect / self._totalGridCnt
end

local function Filter_AdjustConnectRate1(g,color)
    return g.color == color and g.connect < 3
end

local function Filter_AdjustConnectRate2(g,color,grid)
    return g.color ~= color and g.connect + grid.connect > 6
end

--提升连通率
--a) 寻找孤岛A上的格子G，其连通值<3，并且格子G周围和G不同色的同色的格子数量>3，颜色为C
--b) 寻找颜色为C的格子X，其连通值<3
--c) G和X交换位置，则连通率提升
--降低连通率
--a) 寻找孤岛A上的格子G，其连通值>3
--b) 寻找孤岛B上的格子X，其连通值>2 => 改成G和X连接数之和>6
--c) G和X交换位置，则连通率降低
function BoardServiceLogic:AdjustConnectRate(target)
    if math.abs(target - self._connectRate) < 0.1 then
        return
    end

    --提升
    if self._connectRate < target then
        for _, v in ipairs(self.GridTiles) do
            for _, grid in ipairs(v) do
                if self:IsValidPiecePos(grid) then
                    local color = self:GetIncrGridColor(grid)
                    if color ~= PieceType.None then
                        local grid2 =
                            self:FirstGrid(Filter_AdjustConnectRate1,color)
                        if grid2 ~= nil then
                            self:ExchangeGrid(grid, grid2)
                            if math.abs(target - self._connectRate) < 0.1 then
                                return
                            end
                        end
                    end
                end
            end
        end
    else --降低
        for _, v in ipairs(self.GridTiles) do
            for _, grid in ipairs(v) do
                local color = self:GetDecrGridColor(grid)
                if color ~= PieceType.None then
                    local grid2 =
                        self:FirstGrid(Filter_AdjustConnectRate2,color,grid)
                    if grid2 ~= nil then
                        self:ExchangeGrid(grid, grid2)
                        if math.abs(target - self._connectRate) < 0.1 then
                            return
                        end
                    end
                end
            end
        end
    end
end

function BoardServiceLogic:FirstGrid(filter,...)
    if filter == nil then
        return
    end
    for _, v in ipairs(self.GridTiles) do
        for _, grid in ipairs(v) do
            if filter(grid,...) then
                return grid
            end
        end
    end
end

function BoardServiceLogic:GetIncrGridColor(grid)
    if grid ~= self._roleGrid and grid.connect < 2 then
        local dict = self:CalcRoundGridColor(grid)
        for k, v in ipairs(dict) do
            if not CanMatchPieceType(k, grid.color) and v > 3 then
                return k
            end
        end
    end
    return PieceType.None
end

function BoardServiceLogic:GetDecrGridColor(grid)
    if grid.connect > 3 and grid.color ~= PieceType.Any then
        return grid.color
    end
    return PieceType.None
end

local function Filter_CalcRoundGridColor(g)
    return g.color ~= PieceType.None
end

function BoardServiceLogic:CalcRoundGridColor(grid)
    local dict = {
        [PieceType.Blue] = 0,
        [PieceType.Red] = 0,
        [PieceType.Green] = 0,
        [PieceType.Yellow] = 0,
        [PieceType.Any] = 0
    }
    local round =
        self:GetRoundGrid(
        grid,Filter_CalcRoundGridColor
    )
    for k, g in pairs(round) do
        dict[g.color] = dict[g.color] + 1
    end
    --table.foreach(
    --    round,
    --    function(g)
    --        dict[g.color] = dict[g.color] + 1
    --    end
    --)
    return dict
end

--补充消除的格子(不含最后一个位置，即角色移动到的位置)
--round是补充格子时的回合数，从第一回合开始
function BoardServiceLogic:SupplyPieceList(poslist)
    self._world:GetSyncLogger():Trace(
        {
            key = "SupplyPieceList",
            posCnt = #poslist
        }
    )

    --坐标转换成格子
    local chainPath = {}
    for _, pos in ipairs(poslist) do
        local grid = self.GridTiles[pos.x][pos.y]
        if grid then
            table.insert(chainPath, grid)
            if self:GetCanConvertGridElement(grid) then
                self:RemoveGridColor(grid)
            end
        end
    end

    --引导模式
    local round = self._world:BattleStat():GetPieceRefreshCount()
    if round == 0 then
        round = 1
    end
    if self._boardConfig.BoardMode == GenBoardMode.Guide and round <= #self._boardConfig.GuideBoard then
        local idx = self._boardConfig.GuideBoard[round]
        local cfg = Cfg.cfg_board_guide[idx]
        if cfg == nil then
            Log.error("GenBoardMode.Guide round=", round, " idx=", idx)
        end
        for _, grid in ipairs(chainPath) do
            if self:GetCanConvertGridElement(grid) then
                grid.color = cfg.Board[grid.x][grid.y]
                self:AddGridColor(grid)
            end
        end
        return chainPath
    end

    local colors = {}
    --随机
    for _, grid in ipairs(chainPath) do
        if self:GetCanConvertGridElement(grid) then
            grid.color = self:FillGridColorByWeight()
            self:AddGridColor(grid)
            table.insert(colors, grid.color)
        end
    end
    --连通率
    colors.rate = self._connectRate

    --删除
    for _, grid in ipairs(chainPath) do
        if self:GetCanConvertGridElement(grid) then
            self:RemoveGridColor(grid)
        end
    end

    --染色
    local nResultIndex = 1
    for i, grid in ipairs(chainPath) do
        if self:GetCanConvertGridElement(grid) then
            grid.color = colors[nResultIndex]
            nResultIndex = nResultIndex + 1
            self:AddGridColor(grid)
        end
    end
    return chainPath
end

function BoardServiceLogic:SyncGridTilesColor()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    for x, col in ipairs(boardCmpt.Pieces) do
        for y, color in pairs(col) do
            local grid = self.GridTiles[x][y]
            if grid.color ~= color then
                self:RemoveGridColor(grid)
                grid.color = color
                self:AddGridColor(grid)
            end
        end
    end
end

---@param chainPath Vector2[]
---@param dir Vector2
function BoardServiceLogic:FallGrids(chainPath, dir, teamEntity)
    local delset = {}
    local newset = {}
    local movset = {}
    local rolegrid = {}
    local lastPos = chainPath[#chainPath]
    ---@type BoardServiceLogic
    local boardLogicSvc = self._world:GetService("BoardLogic")
    boardLogicSvc:RemoveEntityBlockFlag(teamEntity, lastPos)

    if self:GetCanConvertGridElement(lastPos) then
        local lastGrid = self.GridTiles[lastPos.x][lastPos.y]
        lastGrid.color = PieceType.None
        rolegrid.color = PieceType.None
        rolegrid.pos = lastPos
    end
    boardLogicSvc:SetEntityBlockFlag(teamEntity, lastPos)

    for i = 1, #chainPath - 1 do
        local pos = chainPath[i]
        local grid = self.GridTiles[pos.x][pos.y]
        if grid then
            delset[#delset + 1] = {pos = pos, color = grid.color}
            grid.del = true
        end
    end
    newset,movset = self:_FallGrid_CalSetByDir(dir)
    --self.logstr = "delset="
    --删除
    self:_FallGrid_DelGrids(delset)
    --Log.error(self.logstr)
    --self.logstr = "movset="
    self:_FallGrid_DelMoveFromGrids(movset)
    --Log.error(self.logstr)
    --self.logstr = "newset="
    --染色
    self:_FallGrid_NewGrids(newset)
    --Log.error(self.logstr)
    self:_FallGrid_AddMoveToGrids(movset)
    return delset, newset, movset, rolegrid
end
---FallGrid 根据方向 计算newset movset
function BoardServiceLogic:_FallGrid_CalSetByDir(dir)
    local newset = {}
    local movset = {}
    if dir.x == 0 and dir.y == -1 then
        newset,movset = self:_FallGrid_CalDown()
    elseif dir.x == 0 and dir.y == 1 then
        newset,movset = self:_FallGrid_CalUp()
    elseif dir.x == 1 and dir.y == 0 then
        newset,movset = self:_FallGrid_CalRight()
    elseif dir.x == -1 and dir.y == 0 then
        newset,movset = self:_FallGrid_CalLeft()
    end
    return newset,movset
end
---FallGrid 方向下落 计算newset movset
function BoardServiceLogic:_FallGrid_CalDown()
    local slot = nil
    local movset = {}
    local newset = {}
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()

    local findslot = function(x, y1)
        for y = y1, maxY do
            local grid = self.GridTiles[x][y]
            if grid and grid.del then
                slot = Vector2(x, y)
                return slot
            end
        end
    end
    local findmove = function(x, y1)
        for y = y1, maxY do
            local grid = self.GridTiles[x][y]
            if grid then
                local pos = Vector2(x, y)
                if not grid.del and self:CanFallGrid(pos) then
                    return pos
                end
            end
        end
    end
    for x = 1, maxX do
        slot = findslot(x, 1)
        while slot do
            local pos = findmove(x, slot.y + 1)
            if pos then
                local grid = self.GridTiles[pos.x][pos.y]
                grid.del = true
                movset[#movset + 1] = {from = pos, to = slot, color = grid.color}
            else
                local maxY = self:_GetMaxYOfColX(x)
                newset[#newset + 1] = {from = Vector2(x, maxY), pos = slot, color = self:FillGridColorByWeight()}
            end
            self.GridTiles[slot.x][slot.y].del = nil
            slot = findslot(x, slot.y + 1)
        end
    end
    return newset,movset
end
---FallGrid 方向向上 计算newset movset
function BoardServiceLogic:_FallGrid_CalUp()
    local slot = nil
    local movset = {}
    local newset = {}
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()

    local findslot = function(x, y1)
        for y = y1, 1, -1 do
            local grid = self.GridTiles[x][y]
            if grid and grid.del then
                slot = Vector2(x, y)
                return slot
            end
        end
    end
    local findmove = function(x, y1)
        for y = y1, 1, -1 do
            local grid = self.GridTiles[x][y]
            if grid then
                local pos = Vector2(x, y)
                if not grid.del and self:CanFallGrid(pos) then
                    return pos
                end
            end
        end
    end
    for x = 1, maxX do
        slot = findslot(x, maxY)
        while slot do
            local pos = findmove(x, slot.y - 1)
            if pos then
                local grid = self.GridTiles[pos.x][pos.y]
                grid.del = true
                movset[#movset + 1] = {from = pos, to = slot, color = grid.color}
            else
                local minY = self:_GetMinYOfColX(x)
                newset[#newset + 1] = {from = Vector2(x, minY), pos = slot, color = self:FillGridColorByWeight()}
            end
            self.GridTiles[slot.x][slot.y].del = nil
            slot = findslot(x, slot.y - 1)
        end
    end
    return newset,movset
end
---FallGrid 方向向左 计算newset movset
function BoardServiceLogic:_FallGrid_CalLeft()
    local slot = nil
    local movset = {}
    local newset = {}
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()

    local findslot = function(x1, y)
        for x = x1, maxX do
            local grid = self.GridTiles[x][y]
            if grid and grid.del then
                slot = Vector2(x, y)
                return slot
            end
        end
    end
    local findmove = function(x1, y)
        for x = x1, maxX do
            local grid = self.GridTiles[x][y]
            if grid then
                local pos = Vector2(x, y)
                if not grid.del and self:CanFallGrid(pos) then
                    return pos
                end
            end
        end
    end
    for y = 1, maxY do
        slot = findslot(1, y)
        while slot do
            local pos = findmove(slot.x + 1, slot.y)
            if pos then
                local grid = self.GridTiles[pos.x][pos.y]
                grid.del = true
                movset[#movset + 1] = {from = pos, to = slot, color = grid.color}
            else
                local maxX = self:_GetMaxXOfRowY(y)
                newset[#newset + 1] = {from = Vector2(maxX, y), pos = slot, color = self:FillGridColorByWeight()}
            end
            self.GridTiles[slot.x][slot.y].del = nil
            slot = findslot(slot.x + 1, slot.y)
        end
    end
    return newset,movset
end
---FallGrid 方向向右 计算newset movset
function BoardServiceLogic:_FallGrid_CalRight()
    local slot = nil
    local movset = {}
    local newset = {}
    local maxX = self:GetCurBoardMaxX()
    local maxY = self:GetCurBoardMaxY()

    local findslot = function(x1, y)
        for x = x1, 1, -1 do
            local grid = self.GridTiles[x][y]
            if grid and grid.del then
                slot = Vector2(x, y)
                return slot
            end
        end
    end
    local findmove = function(x1, y)
        for x = x1, 1, -1 do
            local grid = self.GridTiles[x][y]
            if grid then
                local pos = Vector2(x, y)
                if not grid.del and self:CanFallGrid(pos) then
                    return pos
                end
            end
        end
    end
    for y = 1, maxY do
        slot = findslot(maxX, y)
        while slot do
            local pos = findmove(slot.x - 1, slot.y)
            if pos then
                local grid = self.GridTiles[pos.x][pos.y]
                grid.del = true
                movset[#movset + 1] = {from = pos, to = slot, color = grid.color}
            else
                local minX = self:_GetMinXOfRowY(y)
                newset[#newset + 1] = {from = Vector2(minX, y), pos = slot, color = self:FillGridColorByWeight()}
            end
            self.GridTiles[slot.x][slot.y].del = nil
            slot = findslot(slot.x - 1, slot.y)
        end
    end
    return newset,movset
end
---FallGrid 删除格子
function BoardServiceLogic:_FallGrid_DelGrids(delset)
    for _, v in ipairs(delset) do
        local grid = self.GridTiles[v.pos.x][v.pos.y]
        self:RemoveGridColor(grid)
        --self.logstr = self.logstr .. "[" .. v.pos:PosIndex() .. "] "
    end
end
---FallGrid 新增格子
function BoardServiceLogic:_FallGrid_NewGrids(newset)
    for _, v in ipairs(newset) do
        local grid = self.GridTiles[v.pos.x][v.pos.y]
        grid.color = v.color
        self:AddGridColor(grid)
        --self.logstr = self.logstr .. "[" .. v.pos:PosIndex() .. ":" .. v.color .. "] "
    end
end
---FallGrid 清除要移动的格子
function BoardServiceLogic:_FallGrid_DelMoveFromGrids(movset)
    for _, v in ipairs(movset) do
        local grid = self.GridTiles[v.from.x][v.from.y]
        self:RemoveGridColor(grid)
        --self.logstr = self.logstr .. "[" .. v.from:PosIndex() .. "->" .. v.to:PosIndex() .. "] "
    end
end
---FallGrid 移动后格子染色
function BoardServiceLogic:_FallGrid_AddMoveToGrids(movset)
    for _, v in ipairs(movset) do
        local grid = self.GridTiles[v.to.x][v.to.y]
        grid.color = v.color
        self:AddGridColor(grid)
    end
end
---某行格子左边界index
function BoardServiceLogic:_GetMinXOfRowY(rowY)
    local maxX = self:GetCurBoardMaxX()
    local retX = 1
    for index = 1, maxX do
        local colTiles = self.GridTiles[index]
        if colTiles then
            local tile = colTiles[rowY]
            if tile then
                retX = index
                break
            end
        end
    end
    return retX
end
---某行格子右边界index
function BoardServiceLogic:_GetMaxXOfRowY(rowY)
    local maxX = self:GetCurBoardMaxX()
    local retX = maxX
    for index = maxX, 1, -1 do
        local colTiles = self.GridTiles[index]
        if colTiles then
            local tile = colTiles[rowY]
            if tile then
                retX = index
                break
            end
        end
    end
    return retX
end
---某列格子下边界index
function BoardServiceLogic:_GetMinYOfColX(colX)
    local maxY = self:GetCurBoardMaxY()
    local retY = 1
    local colTiles = self.GridTiles[colX]
        if colTiles then
            for index = 1, maxY do
                local tile = colTiles[index]
                if tile then
                    retY = index
                    break
                end
            end
        end
    return retY
end
---某列格子上边界index
function BoardServiceLogic:_GetMaxYOfColX(colX)
    local maxY = self:GetCurBoardMaxY()
    local retY = maxY
    local colTiles = self.GridTiles[colX]
        if colTiles then
            for index = maxY, 1, -1 do
                local tile = colTiles[index]
                if tile then
                    retY = index
                    break
                end
            end
        end
    return retY
end

function BoardServiceLogic:CalculateSupplyPieceWeights(boardSupplyPieceWeights)
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
    self._supplyPieceTotalWeight = MultModifyValue_Add:New(totalSupplyWeight)

    --补充权重
    self._supplyPieceWeights = {
        [PieceType.Blue] = MultModifyValue_Add:New(boardSupplyPieceWeights[1]),
        [PieceType.Red] = MultModifyValue_Add:New(boardSupplyPieceWeights[2]),
        [PieceType.Green] = MultModifyValue_Add:New(boardSupplyPieceWeights[3]),
        [PieceType.Yellow] = MultModifyValue_Add:New(boardSupplyPieceWeights[4]),
        [PieceType.Any] = MultModifyValue_Add:New(boardSupplyPieceWeights[5])
    }
end

--region BoardSplice

--生成格子
function BoardServiceLogic:GenerateSpliceBoard(boardId)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    local spliceBoardPosList = self:GetSpliceBoardPosList()

    --全部格子
    local spliceGridTiles = {}

    if spliceBoardPosList then
        for i = 1, #spliceBoardPosList do
            local x = spliceBoardPosList[i][1]
            local y = spliceBoardPosList[i][2]
            local color = spliceBoardPosList[i][3] or PieceType.None
            if color == -1 then
                color = self:FillGridColorByWeight()
            end

            if not spliceGridTiles[x] then
                spliceGridTiles[x] = {}
            end

            spliceGridTiles[x][y] = {
                x = x,
                y = y,
                connect = 0,
                color = color,
                connvalue = 0
            }
        end
    end

    return spliceGridTiles
end

--endregion BoardSplice

---@param posList Vector2[]
---@param dir Vector2
function BoardServiceLogic:PopStarGridByFallDir(posList, dir)
    local delSet = {}
    local newSet = {}
    local moveSet = {}

    for i = 1, #posList do
        local pos = posList[i]
        local grid = self.GridTiles[pos.x][pos.y]
        if grid then
            delSet[#delSet + 1] = { pos = pos, color = grid.color }
            grid.del = true
        end
    end

    newSet, moveSet = self:_FallGrid_CalSetByDir(dir)

    --删除
    self:_FallGrid_DelGrids(delSet)

    self:_FallGrid_DelMoveFromGrids(moveSet)

    --染色
    self:_FallGrid_NewGrids(newSet)

    self:_FallGrid_AddMoveToGrids(moveSet)

    return delSet, newSet, moveSet
end
function BoardServiceLogic:GetCurBoardGeneratePieceWeight()
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local generatePieceWeight = affixSvc:ProcessGeneratePieceWeight(self._boardConfig.GeneratePieceWeight)
    return generatePieceWeight
end

function BoardServiceLogic:ProcessSupplyPieceWeight(baseSupplyPieceWeight)
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    local generatePieceWeight = affixSvc:ProcessSupplyPieceWeight(baseSupplyPieceWeight)
    return generatePieceWeight
end