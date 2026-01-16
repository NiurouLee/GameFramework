require("base_service")

_class("BoardMultiServiceRender", BaseService)
---@class BoardMultiServiceRender:BaseService
BoardMultiServiceRender = BoardMultiServiceRender

function BoardMultiServiceRender:Constructor(world)

end

---@param pieceType PieceType
---@param piecePos Vector2
---@return Entity
function BoardMultiServiceRender:CreateGridEntity(boardIndex, pieceType, piecePos, isHide, boardRoot)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local gridEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.Grid)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local gridPrefabPath = boardServiceRender:_GetGridPrefabPath(pieceType)

    --多面棋盘
    gridEntity:ReplaceOutsideRegion(boardIndex)

    self:_InitGridEntity(boardIndex, gridEntity, gridPrefabPath, pieceType, piecePos, isHide, boardRoot)

    Log.debug("CreateGridEntity gridPos=", Vector2.Pos2Index(piecePos), " pieceType=", pieceType)

    return gridEntity
end

---重建一个新的格子entity
---会先删除旧的，再创建新的
---@param pieceType PieceType 新创建格子的颜色类型
---@param gridPos Vector2 要重置的格子位置
---@param isHide boolean 是否要隐藏
---@param needBirthEffect boolean 是否需要格子出生特效
---@return Entity
function BoardMultiServiceRender:ReCreateGridEntity(
    boardIndex,
    pieceType,
    gridPos,
    isHide,
    hidePieceEffect,
    needBirthEffect,
    notRefreshPrism)
    ---@type PieceServiceRender
    local pieceServiceRender = self._world:GetService("Piece")
    ---@type PieceMultiServiceRender
    local pieceMultiServiceRender = self._world:GetService("PieceMulti")
    local toDestroyGridEntity = pieceMultiServiceRender:FindPieceEntity(boardIndex, gridPos)
    if toDestroyGridEntity == nil then
        return
    end

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local gridPrefabPath = boardServiceRender:_GetGridPrefabPath(pieceType)

    ---@type Entity
    local newGridEntity = toDestroyGridEntity
    self:_InitGridEntity(boardIndex, newGridEntity, gridPrefabPath, pieceType, gridPos, isHide)

    if needBirthEffect then
        newGridEntity:ReplaceLegacyAnimation({"gezi_birth"})
        local position= newGridEntity:GetPosition()
        if  position.y==  BattleConst.CacheHeight then
             Log.exception("位置:("..position.x..","..position.y..","..position.z..") 播放动画名称:".."gezi_birth", Log.traceback())
        end
    end

    --棱镜特效
    if not notRefreshPrism then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        if utilDataSvc:IsPrismPieceMultiBoard(boardIndex, gridPos) then
            pieceMultiServiceRender:SetPieceRenderEffect(boardIndex, gridPos, PieceEffectType.Prism)
        else
            pieceMultiServiceRender:SetPieceRenderEffect(boardIndex, gridPos, PieceEffectType.Normal)
        end
    end

    pieceServiceRender:InitializeGridU3DCmpt(newGridEntity)

    Log.debug("ReCreateGridEntity gridPos=", Vector2.Pos2Index(gridPos), " pieceType=", pieceType)
    return newGridEntity
end

---@param gridEntity Entity
function BoardMultiServiceRender:_InitGridEntity(
    boardIndex,
    gridEntity,
    prefabPath,
    pieceType,
    piecePos,
    isHide,
    boardRoot)
    gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath, not isHide))

    if boardRoot and gridEntity:View() then
        gridEntity:View():GetGameObject().transform.parent = boardRoot.transform
    end

    --多面棋盘
    gridEntity:RemoveOutsideRegion()
    gridEntity:AddOutsideRegion(boardIndex)
    --下面SetPosition会触发TransformServiceRenderer:SetEntityLocation设置坐标

    gridEntity:ReplacePiece(pieceType)
    gridEntity:SetGridPosition(piecePos)
    gridEntity:SetPosition(piecePos)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderMultiBoardComponent
    local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
    renderMultiBoardCmpt:SetGridRenderEntityData(boardIndex, piecePos, gridEntity)

    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    gridEntity:AddReplaceMaterialComponent(gridMatPath)
end

--endregion
