--[[------------------------------------------------------------------------------------------
    主动技预览阶段的连线终止system
]]
--------------------------------------------------------------------------------------------

---@class PreviewLinkLineEndDragSystem_Render:UniqueReactiveSystem
_class("PreviewLinkLineEndDragSystem_Render", UniqueReactiveSystem)
PreviewLinkLineEndDragSystem_Render = PreviewLinkLineEndDragSystem_Render

function PreviewLinkLineEndDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end
    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end
    if (component:GetGridTouchStateID() ~= GridTouchStateID.PLLEndDrag) then
        return false
    end
    return true
end

function PreviewLinkLineEndDragSystem_Render:ExecuteWorld(world)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPBuffButtonRayCast, true)

    ---@type GridTouchComponent
    local gridTouchCmpt = world:GridTouch()
    local isTouchPlayer = gridTouchCmpt:IsTouchPlayer()

    if isTouchPlayer == true then
        ---@type MainCameraComponent
        local cameraCmpt = world:MainCamera()
        cameraCmpt:DoMoveCamera(false)
    else
        return
    end

    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end

    ---@type LinkageRenderService
    local linkageSvc = world:GetService("LinkageRender")

    ---@type Entity
    local previewEntity = world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    if chainPath == nil then
        linkageSvc:DestroyTouchPosEffect()
        return
    end

    -- 增加这个判断是因为怪物技能预览那里会用到PieceAnim这个东西
    if isTouchPlayer then
        ---@type PieceServiceRender
        local piece_service = world:GetService("Piece")
        piece_service:RefreshPieceAnim()
    end

    ---@type PreviewLinkLineService
    local linkLineService = world:GetService("PreviewLinkLine")
    linkLineService:FinishBulletTime()

    --引导相关的先注释掉；若需要则重写
    if isTouchPlayer == true then
        ---@type GuideServiceRender
        local guideService = world:GetService("Guide")
        if #chainPath <= 1 then
            guideService:ShowGuideWeakLine()
        end

        local guideFinishType = guideService:HandlePLLEndDragTrigger()
        if guideFinishType == false then
            ---需要引导就可以返回了
            self:_ClearLinkIn()
            linkageSvc:DestroyTouchPosEffect()
            self:_DestroyLinkLine()
            linkLineService:CancelAllLinkPosPieceType(chainPath)
            previewLinkLineCmpt:ClearPreviewChainPath()

            linkLineService:AllMonsterAndTrapTrans(false)
            linkLineService:ShowChainPathCancelArea(false)

            gridTouchCmpt:SetTouchPlayer(false)
            return
        end
    else
        -- linkLineService:CancelAllLinkPosPieceType(chainPath)
        -- previewLinkLineCmpt:ClearPreviewChainPath()
        --return
    end

    --重置本次点击状态
    gridTouchCmpt:SetTouchPlayer(false)

    linkLineService:AllMonsterAndTrapTrans(false)

    if #chainPath > 1 then
        local pieceType = previewLinkLineCmpt:GetPreviewPieceType()

        previewLinkLineCmpt:SetPreviewChainPath(chainPath, pieceType)
        self:_LinkDone(chainPath)
        linkageSvc:DestroyTouchPosEffect()
    else
        -- ---@type CanMoveArrowService
        -- local arrowService = world:GetService("CanMoveArrow")
        -- arrowService:ShowCanMoveArrow(true)

        --离开连线的格子动画
        if #chainPath == 1 then
            ---@type PieceServiceRender
            local pieceSvc = world:GetService("Piece")
            local pieceEntity = pieceSvc:FindPieceEntity(chainPath[#chainPath])
            if not pieceEntity then
                Log.fatal("连线坐标：" .. tostring(chainPath[#chainPath]) .. " 位置的格子无法获取到！")
            else
                pieceSvc:SetPieceAnimLinkOut(chainPath[#chainPath])
            end
            ---@type Entity
            local previewEntity = world:GetPreviewEntity()
            previewEntity:ReplacePreviewLinkLine({}, PieceType.None, PieceType.None)

            linkLineService:NotifyPickUpTargetChange()

            linkageSvc:DestroyTouchPosEffect()
            --如果连线能穿怪，需要把怪物脚下格子再压暗
            linkLineService:SetMonsterShadowPosListDown(true)
        end
    end

    linkLineService:ShowChainPathCancelArea(false)
end

function PreviewLinkLineEndDragSystem_Render:Filter(world)
    return true
end

function PreviewLinkLineEndDragSystem_Render:_DestroyLinkLine()
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    for _, linkLineEntity in ipairs(allEntities) do
        linkageRenderService:DestroyLinkLine(linkLineEntity)
    end
end

function PreviewLinkLineEndDragSystem_Render:_ClearLinkIn()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

    for _, pos in ipairs(chainPath) do
        self._world:GetService("Piece"):SetPieceAnimLinkOut(pos)
    end
end

function PreviewLinkLineEndDragSystem_Render:_LinkDone(chainPath)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    for i = 1, #chainPath do
        pieceService:SetPieceAnimLinkDone(chainPath[i])
    end
end
