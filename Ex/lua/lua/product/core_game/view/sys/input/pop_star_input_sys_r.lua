--[[------------------------------------------------------------------------------------------
    消灭星星模式下的输入
]]
--------------------------------------------------------------------------------------------

---@class PopStarInputSystem_Render:UniqueReactiveSystem
_class("PopStarInputSystem_Render", UniqueReactiveSystem)
PopStarInputSystem_Render = PopStarInputSystem_Render

function PopStarInputSystem_Render:IsInterested(index, previousComponent, component)
    if component == nil then
        return false
    end
    if not PopStarPickUpComponent:IsInstanceOfType(component) then
        return false
    end
    return true
end

function PopStarInputSystem_Render:Filter(world)
    return true
end

---@param world MainWorld
function PopStarInputSystem_Render:ExecuteWorld(world)
    self._world = world

    ---@type PopStarPickUpComponent
    local popStarPickUpCmpt = world:PopStarPickUp()
    local clickRenderPos = popStarPickUpCmpt:GetPopStarClickPos()

    ---@type BoardServiceRender
    local boardSvc = world:GetService("BoardRender")
    local gridPos = boardSvc:BoardRenderPos2GridPos(clickRenderPos)
    local offset = boardSvc:BoardGridPosOffset(clickRenderPos)

    ---强制引导相关
    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    local isGuide, isValid = guideService:IsGuideAndPieceValid(gridPos.x, gridPos.y)
    if isGuide then
        if isValid then
            self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
        else
            return
        end
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PopStarPickUpResultComponent
    local pickUpResCmpt = renderBoardEntity:PopStarPickUpResult()
    if not pickUpResCmpt then
        return
    end

    local curPickUpGirdPos = pickUpResCmpt:GetPopStarPickUpPos()
    if curPickUpGirdPos == Vector2(0, 0) then
        --首次点击
        self:_HandleFirstClick(gridPos, offset, pickUpResCmpt)
    else
        --再次点击
        local validPosList = pickUpResCmpt:GetPopStarConnectPieces()

        if table.icontains(validPosList, gridPos) then
            --点击有效区域
            self:_HandlePop(pickUpResCmpt)
        else
            --点击无效区域，取消预览
            self:_HandleCancel(pickUpResCmpt)
        end
    end
end

---@param pickUpResCmpt PopStarPickUpResultComponent
function PopStarInputSystem_Render:_HandleFirstClick(gridPos, offset, pickUpResCmpt)
    ---是否点击有效格子
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(gridPos) then
        return
    end

    ---不能点击灰格子
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieceType = env:GetPieceType(gridPos)
    if pieceType == PieceType.None then
        return
    end

    ---设置点击结果
    pickUpResCmpt:SetPopStarPickUpPos(gridPos)

    ---是否点击道具
    ---@type PopStarServiceRender
    local popStarRSvc = self._world:GetService("PopStarRender")
    local isPickUpTrap, trapEntityID = self:_CheckPickUpTrap(gridPos)
    if isPickUpTrap then
        popStarRSvc:ShowPreviewTrap(trapEntityID, gridPos, offset)
    end

    ---计算连通区域
    local connectPieces = popStarRSvc:CalculatePopStarConnectPieces(gridPos)
    pickUpResCmpt:SetPopStarConnectPieces(connectPieces)

    ---显示连通区域
    popStarRSvc:PreviewPopArea(connectPieces)

    ---显示消除格子数
    popStarRSvc:ShowPopGridNum(connectPieces)
end

function PopStarInputSystem_Render:_CheckPickUpTrap(touchPosition)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local trapList = utilDataSvc:FindTrapByTypeAndPos(TrapType.PopStar_Prop, touchPosition)
    if #trapList > 0 then
        return true, trapList[1]:GetID()
    end

    return false, nil
end

---@param pickUpResCmpt PopStarPickUpResultComponent
function PopStarInputSystem_Render:_HandlePop(pickUpResCmpt)
    ---获取点击结果
    local pickUpPos = pickUpResCmpt:GetPopStarPickUpPos()

    ---连通区域用于验证
    local connectPieces = pickUpResCmpt:GetPopStarConnectPieces()

    ---@type PopStarServiceRender
    local popStarRSvc = self._world:GetService("PopStarRender")
    popStarRSvc:ClearPreviewPop(connectPieces)
    popStarRSvc:PopConnectPieces(connectPieces)

    ---通知点击消除
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarPickUp, pickUpPos, connectPieces)

    ---重置
    pickUpResCmpt:ResetPopStarPickUp()
end

---@param pickUpResCmpt PopStarPickUpResultComponent
function PopStarInputSystem_Render:_HandleCancel(pickUpResCmpt)
    ---连通区域
    local connectPieces = pickUpResCmpt:GetPopStarConnectPieces()

    ---清除点击表现
    ---@type PopStarServiceRender
    local popStarRSvc = self._world:GetService("PopStarRender")
    popStarRSvc:ClearPreviewPop(connectPieces)

    ---重置
    pickUpResCmpt:ResetPopStarPickUp()
end
