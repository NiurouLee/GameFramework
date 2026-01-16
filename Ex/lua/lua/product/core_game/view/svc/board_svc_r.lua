require("base_service")

_class("BoardServiceRender", BaseService)
---@class BoardServiceRender:BaseService
BoardServiceRender = BoardServiceRender

function BoardServiceRender:Constructor(world)
    self.pieceHeight = 0
    self._gridEntityTable = {} --表现层的entity BW_WEMatchers.Piece
end
---@param entity Entity
function BoardServiceRender:GetEntityRealTimeGridPosByGO(entity, needOffSet)
    ---@type UnityEngine.GameObject
    local go = entity:View():GetGameObject()
    local pos = go.transform.position
    return self:_GetEntityRealTimeGridPos(entity,pos, needOffSet)
end
---@param pos Vector3
function BoardServiceRender:_GetEntityRealTimeGridPos(entity,renderPosition, needOffSet)
    local targetGridPos
    if not needOffSet then
        local monster_body_area_cmpt = entity:BodyArea()
        local monster_body_area = {}
        if monster_body_area_cmpt then
            monster_body_area = monster_body_area_cmpt:GetArea()
        end

        ---多格怪
        if #monster_body_area > 1 then
            targetGridPos = self:BoardRenderPos2FloatGridPos_New(renderPosition)
            local offset = entity:GridLocation().Offset
            targetGridPos = targetGridPos - offset
            targetGridPos = Vector2(math.floor(targetGridPos.x), math.floor(targetGridPos.y))
        else
            targetGridPos = self:BoardRenderPos2GridPos(renderPosition)
        end
    else
        targetGridPos = self:BoardRenderPos2FloatGridPos_New(renderPosition)
    end
    return targetGridPos
end

---表现使用可以获取实时 怪物或宝宝的坐标
---获取的是通过渲染坐标算出来的基准坐标
function BoardServiceRender:GetEntityRealTimeGridPos(entity, needOffSet)
    return self:_GetEntityRealTimeGridPos(entity,entity:Location().Position, needOffSet)
    --local targetGridPos
    --if not needOffSet then
    --    local monster_body_area_cmpt = entity:BodyArea()
    --    local monster_body_area = {}
    --    if monster_body_area_cmpt then
    --        monster_body_area = monster_body_area_cmpt:GetArea()
    --    end
    --
    --    ---多格怪
    --    if #monster_body_area > 1 then
    --        local renderPosition = entity:Location().Position
    --        targetGridPos = self:BoardRenderPos2FloatGridPos_New(renderPosition)
    --        local offset = entity:GridLocation().Offset
    --        targetGridPos = targetGridPos - offset
    --        targetGridPos = Vector2(math.floor(targetGridPos.x), math.floor(targetGridPos.y))
    --    else
    --        local renderPosition = entity:Location().Position
    --        targetGridPos = self:BoardRenderPos2GridPos(renderPosition)
    --    end
    --else
    --    local renderPosition = entity:Location().Position
    --    targetGridPos = self:BoardRenderPos2FloatGridPos_New(renderPosition)
    --end
    --return targetGridPos
end

--渲染坐标转格子坐标
---@param pos UnityEngine.Vector3
---@return UnityEngine.Vector2
function BoardServiceRender:BoardRenderPos2FloatGridPos_New(pos)
    local basePos = self:GetBaseGridRenderPos()
    local render_pos_offset = pos - basePos
    local new_grid_pos = Vector3(1, 0, 1) + render_pos_offset
    return Vector2(new_grid_pos.x, new_grid_pos.z)
end

function BoardServiceRender:BoardRenderPos2GridPos(pos)
    local gridPos = self:BoardRenderPos2FloatGridPos(pos)
    return Vector2(math.floor(gridPos.x), math.floor(gridPos.y))
end

--[[
    渲染坐标转格子坐标，因为有取整，只能用在单格怪上
    表现的过程中，目标位置在变化，需要取到一个当前的格子位置，然后取逻辑结果，这样就需要把小数转成整数
    如果逻辑需要支持多格怪，需要使用GetEntityRealTimeGridPos函数，就在这个service里
]]
---@param pos UnityEngine.Vector3
---@return UnityEngine.Vector2
function BoardServiceRender:BoardRenderPos2FloatGridPos(pos)
    local basePos = self:GetBaseGridRenderPos()
    local render_pos_offset = pos - basePos
    local new_grid_pos = Vector3(1, 0, 1) + render_pos_offset
    --四舍五入
    local clamp_x = math.floor(new_grid_pos.x + 0.5)
    local clamp_y = math.floor(new_grid_pos.z + 0.5)
    return Vector2(clamp_x, clamp_y)
end

---@param target Entity
---@return Vector2
---获取参数的实时格子坐标,由渲染坐标转换而成
function BoardServiceRender:GetRealEntityGridPos(target)
    if target:HasLocation() then
        local localPosition = target:GetPosition()
        return self:BoardRenderPos2FloatGridPos_New(localPosition)
    end
    return Vector2(0, 0)
end

---@param casterEntity Entity 观察视角
---@param targetEntity Entity 目标
---@return number 负数，target在view左侧；正数，target在view右侧
function BoardServiceRender:IsLeftOrRight(casterEntity, targetEntity)
    local viewPos = self:GetEntityRealTimeGridPos(casterEntity, true)
    local viewDir = casterEntity:GetDirection()
    local targetPos = self:GetEntityRealTimeGridPos(targetEntity, true)
    if viewPos and targetPos and viewDir then
        local vVT = targetPos - viewPos
        local v = Vector3.Cross(Vector3(viewDir.x, 0, viewDir.z), Vector3(vVT.x, 0, vVT.y))
        if v then
            return v.y
        end
    end
    return 0
end

---@param gridPos UnityEngine.Vector2
---@return UnityEngine.Vector3
function BoardServiceRender:GridPos2RenderPos(gridPos)
    local xOffset = gridPos.x - 1
    local zOffset = gridPos.y - 1
    local basePos = self:GetBaseGridRenderPos()
    return basePos + Vector3(xOffset, self.pieceHeight, zOffset)
end

---这个封装给LocationComponent使用
---@param entity Entity
---@return Vector3
---@protected
function BoardServiceRender:GridPosition2LocationPos(pos, entity)
    if pos then
        if pos._className ~= "Vector3" then
            if pos._className == "Vector2" then
                ---@type number
                local height = entity:GetGridHeight()
                local retPos = self:GridPos2RenderPos(pos)
                if height then
                    retPos.y = retPos.y + height
                end

                return retPos
            else
                Log.fatal("Param Invalid  TrackBack:", Log.traceback())
                return nil
            end
        else
            return pos
        end
    end
    return nil
end

---这个封装给LocationComponent使用
function BoardServiceRender:GridDir2LocationDir(dir)
    if dir then
        if dir._className ~= "Vector3" then
            if dir._className == "Vector2" then
                return Vector3(dir.x, 0, dir.y)
            else
                Log.fatal("Param Invalid  TrackBack:", Log.traceback())
                return nil
            end
        else
            return dir
        end
    end
    return nil
end

---获得一个矩形范围的中心坐标
---@param posList Vector2[]
function BoardServiceRender:GetPosListCenter(posList)
    local tmp = Vector2(0, 0)
    for k, v in pairs(posList) do
        tmp = tmp + v
    end
    tmp = Vector2(tmp.x / (#posList), tmp.y / (#posList))
    return tmp
end

---显隐所有格子实体
function BoardServiceRender:ShowHideAllPieces(isShow)
    local g = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(g:GetEntities()) do
        local y = 0
        if not isShow then
            y = BattleConst.CacheHeight
        end
        ---@type Entity
        local pieceEntity = e
        ---@type ViewComponent
        local viewCmpt = pieceEntity:View()
        local gameObj = viewCmpt:GetGameObject()
        local curPos = gameObj.transform.position
        gameObj.transform.position = Vector3(curPos.x, y, curPos.z)
    end
end

--渲染坐标值距离格子中心的偏移
--其实就是取出小数部分的值
---@param pos UnityEngine.Vector2
---@return UnityEngine.Vector2
function BoardServiceRender:BoardGridPosOffset(pos)
    local roundX = math.floor(math.abs(pos.x) + 0.5)
    if pos.x < 0 then
        roundX = roundX * -1
    end

    local roundZ = math.floor(math.abs(pos.z) + 0.5)
    if pos.z < 0 then
        roundZ = roundZ * -1
    end

    local decimalX = pos.x - roundX
    local decimalZ = pos.z - roundZ

    local offset = Vector2(decimalX, decimalZ)
    return offset
end

--pos是否与center的十字方向相同
---@public
---@return boolean
function BoardServiceRender:IsSameCrossPos(center, pos)
    if center.x == pos.x or center.y == pos.y then
        return true
    end
    return false
end

function BoardServiceRender:CheckColumnBoundary(columnVal, attackArea)
    if columnVal >= attackArea.minX and columnVal <= attackArea.maxX then
        return true
    end

    return false
end

function BoardServiceRender:IsInPlayerArea(pos)
    local x, y = pos.x, pos.y
    if x == nil or y == nil then
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local playerArea = utilDataSvc:GetPlayerArea()
    local gridTiles = utilDataSvc:GetGridTiles()
    return x >= playerArea.minX and x <= playerArea.maxX and y >= playerArea.minY and y <= playerArea.maxY and
        gridTiles[x] and
        gridTiles[x][y]
end

--棋盘边缘按玩家攻击范围计算
function BoardServiceRender:GetEdgePosList()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local edgePosList = {}
    local left, right, top, down
    local playerArea = utilDataSvc:GetPlayerArea()
    for x = playerArea.minX, playerArea.maxX do
        for y = playerArea.minY, playerArea.maxY do
            if self:IsInPlayerArea(Vector2(x, y)) then
                left = {x - 1, y}
                right = {x + 1, y}
                top = {x, y + 1}
                down = {x, y - 1}
                local dirs = {left, down, right, top} -- 注：左 下 右 上
                local curDirs = {}
                -- 四方向
                local isAdd = false
                local data = {}
                for dir, gridPos in ipairs(dirs) do
                    if not self:IsInPlayerArea(Vector2(gridPos[1], gridPos[2])) then
                        if isAdd == false then
                            data.pos = Vector2(x, y)
                            data.dirs = {}
                            isAdd = true
                        end
                        table.insert(data.dirs, dir)
                    end
                end
                if isAdd then
                    table.insert(edgePosList, data)
                end
            end
        end
    end
    return edgePosList
end

---pos（如出口坐标、任意门坐标等）是否可划线
function BoardServiceRender:IsPosCanLinkLine(pos, chainPath)
    local len = table.count(chainPath)
    if len <= 1 then --没连时，只连了一格时，都可以连
        return true
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local lastPos = chainPath[len] --拿到 ChainPath 最后一个坐标
    local isBreakLastPos = utilDataSvc:IsPosExit(lastPos) or utilDataSvc:IsPosDimensionDoor(lastPos)
    if isBreakLastPos then --如果出口坐标任意门坐标已加入 ChainPath
        if not table.icontains(chainPath, pos) then
            return false
        end
    end
    return true
end

--计算联通区
---@param entityWork Entity
function BoardServiceRender:CalcConnectPieces(chainPath, pieceType, bMoveBack, entityWork)
    if #chainPath <= 1 or pieceType == PieceType.None or pieceType == PieceType.Any then
        return {}
    end

    local endPos = chainPath[#chainPath]

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieces = env:GetAllPieceType()

    local conn = {}
    for x, v in pairs(pieces) do
        conn[x] = {}
    end

    local connect_pieces = {}
    table.insert(connect_pieces, endPos)
    conn[endPos.x][endPos.y] = true

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local search9 = function(center, next)
        for i = -1, 1 do
            for j = -1, 1 do
                local pos = Vector2(center.x + i, center.y + j)
                if utilDataSvc:IsValidPiecePos(pos) then
                    local piece_type = env:GetPieceType(pos)
                    local canLinkLine =
                        self:IsInPlayerArea(pos) and self:IsPosCanLinkLine(pos, chainPath) and
                        not utilDataSvc:IsPosBlockLinkLineForChain(pos) --pos是否可连线
                    local pieceMatch =
                        CanMatchPieceType(pieceType, piece_type) or
                        utilDataSvc:IsPosCanMapOtherPiece(pos, pieceType, piece_type)
                    if not conn[pos.x][pos.y] and pieceMatch and canLinkLine then
                        table.insert(connect_pieces, pos)
                        conn[pos.x][pos.y] = true
                        next(pos, next)
                    end
                end
            end
        end
    end

    search9(endPos, search9)
    return connect_pieces
end

--生成格子相关逻辑专用枚举----
local OutlineDirType = {Up = 1, Down = 2, Left = 3, Right = 4}
local OutlineType = {Short = 1, LeftShort = 2, RightShort = 3, Long = 4}
---获取周围四格坐标
---@return table<number,Vector2>
---@param pos Vector2
function BoardServiceRender:GetRoundPosList(pos)
    local res = {}
    res[OutlineDirType.Up] = Vector2(pos.x, pos.y + 1)
    res[OutlineDirType.Down] = Vector2(pos.x, pos.y - 1)
    res[OutlineDirType.Right] = Vector2(pos.x + 1, pos.y)
    res[OutlineDirType.Left] = Vector2(pos.x - 1, pos.y)
    return res
end

---@return number
---@param dir Vector2
function BoardServiceRender:GetOutlineDirType(dir)
    if dir.x > 0 and dir.y == 0 then
        return OutlineDirType.Right
    elseif dir.x < 0 and dir.y == 0 then
        return OutlineDirType.Left
    elseif dir.x == 0 and dir.y > 0 then
        return OutlineDirType.Up
    else
        return OutlineDirType.Down
    end
end

function BoardServiceRender:GetBoardRect()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local playerArea = utilDataSvc:GetPlayerArea()
    local basePos = self:GetBaseGridRenderPos()
    --棋盘矩形范围，世界坐标
    self.boardRect = {
        x = basePos.x - 0.5,
        y = basePos.z - 0.5,
        z = basePos.x - 0.5 + playerArea.maxX - playerArea.minX,
        w = basePos.z - 0.5 + playerArea.maxY - playerArea.minY
    }
    return self.boardRect
end

---根据格子特效的类型，创建格子特效Entity
---@param gridPos Vector2
---@return Entity
function BoardServiceRender:CreateEmptyGridEffectEntity(gridPos)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local gridEffectEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.EmptyGridEffect)
    gridEffectEntity:SetGridPosition(gridPos)
    gridEffectEntity:SetPosition(gridPos)
    return gridEffectEntity
end

function BoardServiceRender:GetExceptGrids(curGrids)
    local gridGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    local targetGridEntity = nil
    local exceptGrids = {}
    for _, gridEntity in ipairs(gridGroup:GetEntities()) do
        local curGridPos = gridEntity:GridLocation().Position
        table.insert(exceptGrids, curGridPos)
    end
    for index, pos in ipairs(curGrids) do
        for i = #exceptGrids, 1, -1 do
            if exceptGrids[i] == pos then
                table.remove(exceptGrids, i)
                break
            end
        end
    end

    return exceptGrids
end
---填充连线路径上的点
function BoardServiceRender:FillChainPathPieces(fillPieceTable)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    for i, grid in ipairs(fillPieceTable) do
        local x, y = grid.x, grid.y

        local targetGridColor = grid.color

        --Log.fatal("setpiececolor:",x," ",y," ",targetGridColor)
        local pos = Vector2(x, y)
        local currentPiece = renderBoardCmpt:GetGridRenderEntity(grid)
        if currentPiece then
            Log.debug(
                "FillChainPathPieces() pos=",
                Vector2.Pos2Index(pos),
                " from=",
                currentPiece:Piece():GetPieceType(),
                " to=",
                targetGridColor
            )
            ---如果已经有格子，说明是需要重建
            local gridEntity = self:ChangeGridEntity(targetGridColor, pos)
            pieceService:SetPieceEntityAnimNormal(gridEntity)
            pieceService:SetPieceEntityBirth(gridEntity)
        else
            ---没有格子，新建一个Grid
            local gridEntity = self:CreateGridEntity(targetGridColor, pos)
        end
    end
end

---划线后，更换格子
function BoardServiceRender:ChangeGridEntity(pieceType, gridPos, isHide)
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local modifyEntity = pieceSvc:FindPieceEntity(gridPos)
    if modifyEntity == nil then
        Log.debug("BoardServiceRender:ChangeGridEntity() pos=", Vector2.Pos2Index(gridPos), " not FindPieceEntity")
        return
    end

    local gridPrefabPath = self:_GetGridPrefabPath(pieceType)
    modifyEntity:ReplacePiece(pieceType)
    modifyEntity:SetGridPosition(gridPos)
    modifyEntity:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath, not isHide))
    modifyEntity:SetPosition(gridPos)
    ---这个地方要清理一次，不然后续播放的还是回池的gameobject身上的animation
    ---@type LegacyAnimationComponent
    local legacyAnimCmpt = modifyEntity:LegacyAnimation()
    if legacyAnimCmpt then 
        legacyAnimCmpt:SetU3DAnimationCmpt(nil)
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    modifyEntity:AddReplaceMaterialComponent(gridMatPath)

    Log.debug("ChangeGridEntity gridPos=", Vector2.Pos2Index(gridPos), " pieceType=", pieceType)
    return modifyEntity
end

function BoardServiceRender:_GetGridPrefabPath(gridType)
    local gridConfig = self:_GetGridConfig()
    local gridTypeString = self:_GetGridTypeString(gridType)
    local gridPrefabPath = gridConfig[gridTypeString]

    return gridPrefabPath
end

function BoardServiceRender:_GetBrokenGridPrefabPath(gridType)
    if gridType >= 1 and gridType <= 5 then
        local path = string.format("eff_gezi_suilie_0%d.prefab", gridType)
        return path
    end
end

function BoardServiceRender:_GetGridConfig()
    ---这个应该放到ConfigService的LevelConfigData里
    local levelID = self._world.BW_WorldInfo.level_id
    local levelConfig = Cfg.cfg_level[levelID]
    local themeID = levelConfig.Theme
    local cfgThemeData = Cfg.cfg_theme[themeID]
    return cfgThemeData
end

function BoardServiceRender:_GetGridTypeString(gridType)
    if gridType == PieceType.Blue then
        return "Blue"
    elseif gridType == PieceType.Red then
        return "Red"
    elseif gridType == PieceType.Green then
        return "Green"
    elseif gridType == PieceType.Yellow then
        return "Yellow"
    elseif gridType == PieceType.Any then
        return "Any"
    elseif gridType == PieceType.None then
        return "Gray"
    end

    return "Gray"
end

---@param pieceType PieceType
---@param piecePos Vector2
---@return Entity
function BoardServiceRender:CreateGridEntity(pieceType, piecePos, isHide)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local gridEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.Grid)
    local gridPrefabPath = self:_GetGridPrefabPath(pieceType)
    self:_InitGridEntity(gridEntity, gridPrefabPath, pieceType, piecePos, isHide)

    Log.debug("CreateGridEntity gridPos=", Vector2.Pos2Index(piecePos), " pieceType=", pieceType)

    return gridEntity
end

---这个函数是纯表现，严禁出现任何修改逻辑的代码
---重建一个新的格子entity
---会先删除旧的，再创建新的
---@param pieceType PieceType 新创建格子的颜色类型
---@param gridPos Vector2 要重置的格子位置
---@param isHide boolean 是否要隐藏
---@param needBirthEffect boolean 是否需要格子出生特效
---@return Entity
function BoardServiceRender:ReCreateGridEntity(
    pieceType,
    gridPos,
    isHide,
    hidePieceEffect,
    needBirthEffect,
    notRefreshPrism)
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local toDestroyGridEntity = pieceSvc:FindPieceEntity(gridPos)
    if toDestroyGridEntity == nil then
        return
    end

    local gridPrefabPath = self:_GetGridPrefabPath(pieceType)
    ---@type Entity
    local newGridEntity = toDestroyGridEntity
    self:_InitGridEntity(newGridEntity, gridPrefabPath, pieceType, gridPos, isHide)

    if needBirthEffect then
        newGridEntity:ReplaceLegacyAnimation({"gezi_birth"})
        local position= newGridEntity:GetPosition()
        if  position.y==  BattleConst.CacheHeight then
            Log.exception("位置:("..position.x..","..position.y..","..position.z..") 播放动画名称:".."gezi_birth", Log.traceback())
        end
    end

    --碎格子颜色
    local brokenTrap =
        self._world:GetPreviewEntity():PreviewEnv():GetEntitiesAtPos(
        gridPos,
        function(e)
            return e:TrapRender() and e:TrapRender():GetTrapRender_IsBrokenGrid() and not e:HasDeadMark()
        end
    )
    if brokenTrap and #brokenTrap > 0 then
        for i, trap in ipairs(brokenTrap) do
            local prefabPath = self:_GetBrokenGridPrefabPath(pieceType)
            if prefabPath then
                trap:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath, not isHide))
            end
        end
    end

    --棱镜特效
    if not notRefreshPrism then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        if utilDataSvc:IsPrismPiece(gridPos) then
            pieceSvc:SetPieceRenderEffect(gridPos, PieceEffectType.Prism)
        else
            pieceSvc:SetPieceRenderEffect(gridPos, PieceEffectType.Normal)
        end
    end

    pieceSvc:InitializeGridU3DCmpt(newGridEntity)

    Log.debug("ReCreateGridEntity gridPos=", Vector2.Pos2Index(gridPos), " pieceType=", pieceType)
    return newGridEntity
end
---@private
function BoardServiceRender:_InitGridEntity(gridEntity, prefabPath, pieceType, piecePos, isHide)
    gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath, not isHide))
    gridEntity:ReplacePiece(pieceType)
    gridEntity:SetGridPosition(piecePos)
    gridEntity:SetPosition(piecePos)

    gridEntity:RemoveOutsideRegion()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    renderBoardCmpt:SetGridRenderEntityData(piecePos, gridEntity)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    gridEntity:AddReplaceMaterialComponent(gridMatPath)
end

--endregion

--应用预览数据和表现
function BoardServiceRender:ApplyPrism(piecePrePos, piecePos)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    --处理十字棱镜的特效
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --格子动画
    pieceService:SetPieceRenderEffect(piecePos, PieceEffectType.Normal)

    --local changed = env:ApplyPrism(piecePrePos, piecePos)
    local changed = self:_ApplyPrismToPreviewEnv(piecePrePos, piecePos)
    local pieceType = env:GetPieceType(piecePos)
    for posIdx, color in pairs(changed) do
        local pos = Vector2.Index2Pos(posIdx)
        if color ~= pieceType then
            self:ReCreateGridEntity(pieceType, pos, false, false, true)
            trapServiceRender:SetPrismEffectTrapShow(pos, nil, color, false)
            trapServiceRender:SetPrismEffectTrapShow(pos, nil, pieceType, true)
        end
    end
	
    trapServiceRender:SetPrismEffectTrapShow(piecePos, nil, pieceType, false)
end

function BoardServiceRender:_ApplyPrismToPreviewEnv(prePos, prismPos)
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    local prismPieceType = env:GetPieceType(prismPos)

    local tTargetPieces = {}

    local prismEntityID = env:GetPrismEntityIDAtPos(prismPos)
    local scopeType, scopeParam = self._world:GetService("UtilData"):GetPrismCustomScopeConfig(prismEntityID)
    if scopeType then
        ---@type SkillScopeCalculator
        local calc = SkillScopeCalculator:New(self._world:GetService("UtilScopeCalc"))
        local result = calc:ComputeScopeRange(scopeType, scopeParam, prismPos, {Vector2.zero})
        local range = result:GetAttackRange() or {}
        for _, v2 in ipairs(range) do
            local targetPieceType = env:GetPieceType(v2)
            --如果下个位置不能转色就跳过
            local canChange = not env:IsPosBlock(v2, BlockFlag.ChangeElement)
            if targetPieceType and targetPieceType ~= PieceType.None and canChange then
                table.insert(tTargetPieces, {
                    pos = v2,
                    originalPieceType = env:GetPieceType(v2),
                    pieceType = prismPieceType
                })
            end
        end
    else
        local dir = prismPos - prePos
        for i = 1, BattleConst.PrismEffectPieceCount do
            local targetPos = prismPos + dir * i
            local targetPieceType = env:GetPieceType(targetPos)
            --如果下个位置不能转色就跳过
            local canChange = not env:IsPosBlock(targetPos, BlockFlag.ChangeElement)
            if targetPieceType and targetPieceType ~= PieceType.None and canChange then
                table.insert(tTargetPieces, {
                    pos = targetPos,
                    originalPieceType = targetPieceType,
                    pieceType = prismPieceType
                })
            end
        end
    end

    local changed = {}
    for _, data in ipairs(tTargetPieces) do
        local changedPosIndex = Vector2.Pos2Index(data.pos)
        changed[changedPosIndex] = data.originalPieceType
        env._pieceTypes[changedPosIndex] = data.pieceType
    end

    local prismPosIndex = Vector2.Pos2Index(prismPos)
    env._prismChangedPieces[prismPosIndex] = changed -- TODO: function-lize it
    env:SetNeedUpdateConnectPieces(true)

    return changed
end

--回退预览数据和表现
function BoardServiceRender:UnapplyPrism(prismPos)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    --处理十字棱镜的特效
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    pieceService:SetPieceRenderEffect(prismPos, PieceEffectType.Prism)
    local pieceType = env:GetPieceType(prismPos)
    local changed = env:GetPrismChangedPieces(prismPos)
    for posIdx, color in pairs(changed) do
        local pos = Vector2.Index2Pos(posIdx)
        --if color ~= pieceType then 不要判断颜色，棱镜可能被其他棱镜转色！
        self:ReCreateGridEntity(color, pos, false, false, true)
        trapServiceRender:SetPrismEffectTrapShow(pos, nil, pieceType, false)
        trapServiceRender:SetPrismEffectTrapShow(pos, nil, color, true)
        --end
    end

    env:UnapplyPrism(prismPos)
	
    trapServiceRender:SetPrismEffectTrapShow(prismPos, nil, pieceType, true)
end

---移动以前抬起一次 到达重点压暗一次；每移动一个格子会处理格子上的机关的显示隐藏
---@param targetEntity Entity
function BoardServiceRender:RefreshPiece(targetEntity, bUp, isAI)
    ---取当前的渲染坐标
    ---@type PieceServiceRender
    local sPiece = self._world:GetService("Piece")
    ---@type TrapServiceRender
    local sTrapRender = self._world:GetService("TrapRender")
    local curPos = self:GetRealEntityGridPos(targetEntity)
    --上面的显示坐标是模型中点有.5，要减去逻辑的偏移
    local workPos = curPos - targetEntity:GridLocation():GetGridOffset()
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    if bUp then
        renderEntityService:DestroyMonsterAreaOutLineEntity(targetEntity)
    else
        renderEntityService:CreateMonsterAreaOutlineEntity(targetEntity)
    end
    --计算多格怪重叠
    local area = targetEntity:BodyArea():GetArea()
    for i, p in ipairs(area) do
        local posWork = workPos + p
        ---整数坐标才执行逻辑
        if posWork.x == math.floor(posWork.x) and posWork.y == math.floor(posWork.y) then
            if bUp then --在这里再做一次是为了做一次矫正，由于AI执行GridMove顺序不同，而使得隐藏机关在显示机关之前执行，由此出现该隐藏的机关没隐藏的问题
                sPiece:SetPieceAnimUp(posWork)
                if not isAI then
                    sTrapRender:ShowHideTrapAtPos(posWork, true)
                end
            else
                sPiece:SetPieceAnimDown(posWork)
                if not isAI then
                    sTrapRender:ShowHideTrapAtPos(posWork, false)
                end
            end
        end
    end
end
---返回所有深渊占据的格子
---@return Vector2[]
function BoardServiceRender:GetAllTerrainAbyssAreas()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    ---@type Entity[]
    local eTraps = group:GetEntities()
    ---@type Vector2
    local areaList = {}
    for k, entity in pairs(eTraps) do
        ---@type TrapComponent
        local trapComponent = entity:Trap()
        if trapComponent:GetTrapType() == TrapType.TerrainAbyss then
            ---@type BodyAreaComponent
            local areaCmpt = entity:BodyArea()
            local areas = areaCmpt:GetArea()
            local basePos = entity:GetGridPosition()
            for i, offSet in ipairs(areas) do
                local area = Vector2(basePos.x + offSet.x, basePos.y + offSet.y)
                table.insert(areaList, area)
            end
        end
    end
    return areaList
end

--region BoardSplice

---@param pieceType PieceType
---@param piecePos Vector2
---@return Entity
function BoardServiceRender:CreateGridFakeEntity(pieceType, piecePos, isHide)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local gridEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.GridFake)
    local gridPrefabPath = self:_GetGridPrefabPath(pieceType)
    self:_InitGridFakeEntity(gridEntity, gridPrefabPath, pieceType, piecePos, isHide)

    Log.debug("CreateGridFakeEntity gridPos=", Vector2.Pos2Index(piecePos), " pieceType=", pieceType)

    return gridEntity
end

function BoardServiceRender:_InitGridFakeEntity(gridEntity, prefabPath, pieceType, piecePos, isHide)
    gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath, not isHide))
    -- gridEntity:ReplacePiece(pieceType)
    gridEntity:ReplacePieceFake(pieceType)
    gridEntity:SetGridPosition(piecePos)
    gridEntity:SetPosition(piecePos)

    gridEntity:RemoveOutsideRegion()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardSpliceComponent
    local renderBoardSpliceComponent = renderBoardEntity:RenderBoardSplice()
    renderBoardSpliceComponent:SetGridRenderEntityData(piecePos, gridEntity)

    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    gridEntity:AddReplaceMaterialComponent(gridMatPath)
end

--endregion BoardSplice

function BoardServiceRender:InitBaseGridRenderPos()
    local renderPos = BattleConst.BaseGridRenderPos
    local themeCfg = self:_GetGridConfig()
    if themeCfg then
        if themeCfg.BaseGridRenderPos then
            renderPos = Vector3(themeCfg.BaseGridRenderPos[1],themeCfg.BaseGridRenderPos[2],themeCfg.BaseGridRenderPos[3])
        else
            renderPos = BattleConst.BaseGridRenderPos
        end
    end
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    if renderBoardEntity then
        ---@type RenderBoardComponent
        local renderBoardCmpt = renderBoardEntity:RenderBoard()
        renderBoardCmpt:SetBaseGridRenderPos(renderPos)
    end
end
function BoardServiceRender:GetBaseGridRenderPos()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    if renderBoardEntity then
        ---@type RenderBoardComponent
        local renderBoardCmpt = renderBoardEntity:RenderBoard()
        return renderBoardCmpt:GetBaseGridRenderPos()
    else
        return BattleConst.BaseGridRenderPos
    end
end
