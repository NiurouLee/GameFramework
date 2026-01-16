--[[------------------------------------------------------------------------------------------
    终止划线选取格子system
]] --------------------------------------------------------------------------------------------

---@class GridEndDragSystem_Render:UniqueReactiveSystem
_class("GridEndDragSystem_Render", UniqueReactiveSystem)
GridEndDragSystem_Render = GridEndDragSystem_Render

function GridEndDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end
    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end
    if (component:GetGridTouchStateID() ~= GridTouchStateID.EndDrag) then
        return false
    end
    return true
end

function GridEndDragSystem_Render:ExecuteWorld(world)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPBuffButtonRayCast, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MatchLineDragEnd)

    ---@type GridTouchComponent
    local gridTouchCmpt = world:GridTouch()
    local isTouchPlayer = gridTouchCmpt:IsTouchPlayer()

    ---@type MainCameraComponent
    local cameraCmpt = self.world:MainCamera()
    if isTouchPlayer == true then
        cameraCmpt:DoMoveCamera(false)
    end
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end
    local boardServiceR = world:GetService("BoardRender")

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    if chainPath == nil then
        Log.fatal("chain path is nil")
        return
    end
    local pieceType = previewChainPathCmpt:GetPreviewPieceType()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    -- 增加这个判断是因为怪物技能预览那里会用到PieceAnim这个东西
    if isTouchPlayer then
        ---@type PieceServiceRender
        local piece_service = world:GetService("Piece")
        piece_service:RefreshPieceAnim()
    end
    ---@type LinkLineService
    local linkLineService = world:GetService("LinkLine")
    linkLineService:FinishBulletTime()

    -- linkLineService:CancelBoardPieceMap(chainPath)

    ----注意，引导会打断正常的流程，需要做一部分清理工作
    if isTouchPlayer == true then
        ---@type GuideServiceRender
        local guideService = world:GetService("Guide")
        if #chainPath <= 1 then
            guideService:ShowGuideWeakLine()
        end

        local guideFinishType = guideService:HandleEndDragTrigger()
        if guideFinishType == false then
            ---需要引导就可以返回了
            self:_ClearLinkIn()
            self.world:GetService("LinkageRender"):ClearLinkRender()
            self:_ClearFlashTarget()
            linkLineService:AllMonsterAndTrapTrans(false)
            self:_DestroyLinkLine()
            self:_ClearLinkageNum()
            --检查棱镜还原
            local chainPath = previewChainPathCmpt:GetPreviewChainPath()
            if chainPath then
                ---@type BoardServiceRender
                local sBoardRender = self._world:GetService("BoardRender")
                local cPreviewEnv = previewEntity:PreviewEnv()
                for i, pos in ipairs(chainPath) do
                    if cPreviewEnv and cPreviewEnv:IsPrismPiece(pos) then
                        sBoardRender:UnapplyPrism(pos)
                    end
                end
            end
            linkLineService:CancelBoardPieceMap(chainPath)
            previewChainPathCmpt:ClearPreviewChainPath()

            linkLineService:ShowChainPathCancelArea(false)

            GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem, true, 0, nil)
            gridTouchCmpt:SetTouchPlayer(false)
            return
        end
    else
        previewChainPathCmpt:ClearPreviewChainPath()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem, true, 0, nil)
        return
    end

    ---重置本次点击状态
    gridTouchCmpt:SetTouchPlayer(false)

    if chainPath == nil then
        self.world:GetService("LinkageRender"):ClearLinkRender()
        return
    end

    --MSG67706 道理上松手了就应该停止连锁技预览，避免ChainSkillRangeFlashSystem在之后的帧里继续触发预览
    local reBoard = self._world:GetRenderBoardEntity()
    if reBoard then
        ---@type PreviewChainSkillRangeComponent
        local previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()
        previewChainSkillRangeCmpt:EnablePreviewChainSkillRange(false)
    end
    self:_ClearFlashTarget()
    linkLineService:AllMonsterAndTrapTrans(false)

    --如果本次连线的终点是不可以停留的则清空连线数据（特殊情况下可以连线穿过怪物脚下，但是不能停留）
    if #chainPath > 1 then
        local lastchainPathPos = chainPath[#chainPath]
        local isBlock = utilDataSvc:IsPosBlockLinkLineForChainChainEnd(lastchainPathPos)
        if isBlock then
            --回退触发的棱镜
            for i = table.count(chainPath), 2, -1 do
                local chainPos = chainPath[i]
                linkLineService:_OnPieceRemoveFromChain(chainPos)
            end
            chainPath = {chainPath[1]}
        end
    end

    linkLineService:CancelBoardPieceMap(chainPath)

    if #chainPath > 1 then
        -- self:SendMovePathDoneCommand(chainPath, pieceType)
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                -- 防止下一帧数据被改变
                -- local _chainPath = table.shallowcopy(chainPath)
                -- 新手引导 玩家操作结束（播放动画之前） 1：连线操作结束 ↓----
                local guideService = world:GetService("Guide")
                local guideTaskId =
                    guideService:Trigger(GameEventType.GuidePlayerHandleFinish, GuidePlayerHandle.LinkEnd)
                while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
                    YIELD(TT)
                end
                -- 新手引导 玩家操作结束（播放动画之前） 1：连线操作结束 ↑----
                previewChainPathCmpt:SetPreviewChainPath(chainPath, pieceType)
                self:SendMovePathDoneCommand(chainPath, pieceType)
                self:_LinkDone(chainPath)
                --self:_PlayEndDragEffect(chainPath)
                self.world:GetService("LinkageRender"):ClearLinkRender()

                linkLineService:ShowChainPathCancelArea(false)
            end,
            self
        )
    else
        ---@type CanMoveArrowService
        local arrowService = self.world:GetService("CanMoveArrow")
        arrowService:ShowCanMoveArrow(true)

        --离开连线的格子动画
        if #chainPath == 1 then
            ---@type PieceServiceRender
            local pieceSvc = self._world:GetService("Piece")
            local pieceEntity = pieceSvc:FindPieceEntity(chainPath[#chainPath])
            if not pieceEntity then
                Log.fatal("连线坐标：" .. tostring(chainPath[#chainPath]) .. " 位置的格子无法获取到！")
            else
                pieceSvc:SetPieceAnimLinkOut(chainPath[#chainPath])
            end
            ---@type Entity
            local previewEntity = self._world:GetPreviewEntity()
            previewEntity:ReplacePreviewChainPath({}, PieceType.None, PieceType.None)

            GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem, true, 0, nil)

            ---@type LinkageRenderService
            local linkageRenderService = self.world:GetService("LinkageRender")
            linkageRenderService:ShowLinkageInfo({})
            linkageRenderService:ClearLinkRender()
            linkageRenderService:HideBenumbTips()
            --如果连线能穿怪，需要把怪物脚下格子再压暗
            linkLineService:SetMonsterShadowPosListDown(true)
        end

        linkLineService:ShowChainPathCancelArea(false)
    end
end

function GridEndDragSystem_Render:Filter(world)
    --Log.debug("GridEndDragSystem_Render Filter")
    return true
end

function GridEndDragSystem_Render:SendMovePathDoneCommand(chainPath, elementType)
    local cmd = MovePathDoneCommand:New()
    cmd:SetChainPath(chainPath)
    cmd:SetElementType(elementType)
    self.world:Player():SendCommand(cmd)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curstateid = utilDataSvc:GetCurMainStateID()

    Log.debug("GridEndDragSystem_Render:SendMovePathDoneCommand gamefsm state ", curstateid)
end

function GridEndDragSystem_Render:_ClearLinkageNum()
    ---@type EntityPoolServiceRender
    local entityPoolService = self.world:GetService("EntityPool")
    ---@type Entity
    local reBoard = self.world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()
    ---@type LinkageRenderService
    local linkageRenderService = self.world:GetService("LinkageRender")
    local remove_list = {}
    for _, linkageNumEntity in ipairs(allEntities) do
        table.insert(remove_list, linkageNumEntity)
    end

    for _, e in ipairs(remove_list) do
        linkageRenderService:DestroyLinkNum(e)
    end
end

function GridEndDragSystem_Render:_DestroyLinkLine()
    ---@type EntityPoolServiceRender
    local entityPoolService = self.world:GetService("EntityPool")
    ---@type LinkageRenderService
    local linkageRenderService = self.world:GetService("LinkageRender")
    ---@type Entity
    local reBoard = self.world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    for _, linkLineEntity in ipairs(allEntities) do
        linkageRenderService:DestroyLinkLine(linkLineEntity)
    end
end

function GridEndDragSystem_Render:_ClearFlashTarget()
    local flashEnemyEntities = self.world:GetGroup(self.world.BW_WEMatchers.MaterialAnimation):GetEntities()
    for _, v in ipairs(flashEnemyEntities) do
        --if v:MaterialAnimationComponent():IsPlayingSelect() then
        v:StopAnimFlashAlpha()
        --end
    end
end

function GridEndDragSystem_Render:_ClearLinkIn()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()

    for _, pos in ipairs(chainPath) do
        self.world:GetService("Piece"):SetPieceAnimLinkOut(pos)
    end
end

function GridEndDragSystem_Render:_LinkDone(chainPath)
    ---@type PieceServiceRender
    local pieceService = self.world:GetService("Piece")
    for i = 1, #chainPath do
        pieceService:SetPieceAnimLinkDone(chainPath[i])
    end
end

--function GridEndDragSystem_Render:_PlayEndDragEffect(chainPath)
--    if #chainPath >1 then
--        ---@type EffectService
--        local effectService = self.world:GetService("Effect")
--        ---@type BoardServiceRender
--        local boardServiceR = self._world:GetService("BoardRender")
--        local pos =chainPath[#chainPath]
--        local renderPos = boardServiceR:GridPos2RenderPos(pos)
--        effectService:CreatePositionEffect(BattleConst.EndDragEffect,renderPos)
--    end
--end
