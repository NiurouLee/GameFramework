--[[------------------
    连线
--]] ------------------
local GridRadiusType = {
    Default = 1, ---默认半径
    NearBy = 2, ---临近半径
    Diagonal = 3 ---对角圆半径
}
---@class GridRadiusType
_enum("GridRadiusType", GridRadiusType)

_class("LinkLineService", Object)
---@class LinkLineService:Object
LinkLineService = LinkLineService

function LinkLineService:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param touchPos Vector2[]
---@param offset number
---@return boolean
function LinkLineService:IsTouchInPlayerTouchArea(touchPos, offset)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    if
        not utilData:IsValidPiecePos(touchPos) or utilData:IsPosBlockLinkLineForChain(touchPos) or
            (table.count(self:_FindTrapByPos(touchPos)) > 0 and not utilScopeSvc:IsPosHaveMonsterOrPet(touchPos))
     then
        return false
    end

    ---@type Vector2
    local playerPosition = self._world:Player():GetLocalTeamEntity():GetGridPosition()
    local diff = touchPos - playerPosition
    if math.abs(diff.x) > 1 or math.abs(diff.y) > 1 then
        return false
    end
    if touchPos == playerPosition then
        return true
    end

    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    if guideService:IsGuidePathInvokeType() then
        local inGuidePath = guideService:_CheckGuidePathHasPos(touchPos)
        if inGuidePath ~= true then
            ---引导过程中，如果要连的点不在引导路径里，禁止连线
            ---todo 需要判断顺序
            return false
        end
        if touchPos ~= playerPosition then
            return false
        end
    end

    local touchRealPos = touchPos + offset
    local distance = Vector2.Distance(touchRealPos, playerPosition)

    --四方向的
    if touchPos.x == playerPosition.x or touchPos.y == playerPosition.y then
        return distance < 1
    else
        --斜方向
        return distance < Mathf.Sqrt(2)
    end
end

function LinkLineService:StartLinkLine(touchPos, offset)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPBuffButtonRayCast, false)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return false
    end

    --隐藏箭头
    ---@type CanMoveArrowService
    local canMoveArrowService = self._world:GetService("CanMoveArrow")
    if canMoveArrowService then
        canMoveArrowService:ShowCanMoveArrow(false)
    end

    local guideService = self._world:GetService("Guide")
    guideService:HandleBeginDragTrigger(touchPos)
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:DestroyAllLinkedNum()
    linkageRenderService:DestroyAllLinkLine()
    linkageRenderService:DestroyLinkedGridEffect()
    self:_DoDrag(touchPos, offset)

    self:_StartCameraMove()

    --如果连线能穿怪，需要把怪物脚下格子抬起来
    self:SetMonsterShadowPosListDown(false)

    --处理连线过程中映射颜色
    self:ShowBoardPieceMap()

    ---开始子弹时间
    self:StartBulletTime()
end

--显示连接阶段的格子颜色映射
function LinkLineService:ShowBoardPieceMap()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local mapByPosition = utilData:GetMapByPosition()

    if not mapByPosition or table.count(mapByPosition) == 0 then
        return
    end

    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    --处理十字棱镜的特效
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    for posIndex, piece in pairs(mapByPosition) do
        local pos = Vector2.Index2Pos(posIndex)
        --刷新预览层数据
        env:SetPieceType(pos, piece)
        boardServiceR:ReCreateGridEntity(piece, pos, false, false, true)
        trapServiceRender:OnClosePreviewPrismEffectTrap(pos)
        trapServiceRender:SetPrismEffectTrapShow(pos, nil, piece, true)
    end
end

--还原连接阶段的格子颜色映射
function LinkLineService:CancelBoardPieceMap(chainPath)
    self:StopMapPieceFirstChainPathEffect()

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local mapByPosition = utilData:GetMapByPosition()

    if not mapByPosition or table.count(mapByPosition) == 0 then
        return
    end

    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    --处理十字棱镜的特效
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    for posIndex, piece in pairs(mapByPosition) do
        local pos = Vector2.Index2Pos(posIndex)
        --不在连线路径中的还原颜色，在的就保持当前的显示状态
        if not table.intable(chainPath, pos) then
            --该位置原本的颜色

            local pieceType = utilData:GetPieceType(pos)

            --刷新预览层数据
            env:SetPieceType(pos, pieceType)
            boardServiceR:ReCreateGridEntity(pieceType, pos, false, false, true)
            trapServiceRender:OnClosePreviewPrismEffectTrap(pos)
            trapServiceRender:SetPrismEffectTrapShow(pos, nil, pieceType, true)
        end
    end
end

---如果连线能穿怪，需要把怪物脚下格子抬起来/压暗
function LinkLineService:SetMonsterShadowPosListDown(animDown)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local renderChainPathComponent = renderBoardEntity:RenderChainPath()
    local chainAcrossMonster = renderChainPathComponent:GetChainAcrossMonster()
    if chainAcrossMonster then
        --获取所有怪物坐标，刷新格子成normal
        ---@type PieceServiceRender
        local pieceSvc = self._world:GetService("Piece")

        local monsterShadowPosList = renderChainPathComponent:GetChainMonsterShadowPosList()
        if not monsterShadowPosList or table.count(monsterShadowPosList) == 0 then
            monsterShadowPosList = pieceSvc:GetMonsterShadowPosList()
        end
        renderChainPathComponent:SetChainMonsterShadowPosList(monsterShadowPosList)

        for i, pos in ipairs(monsterShadowPosList) do
            if animDown then
                pieceSvc:SetPieceAnimDown(pos)
            else
                pieceSvc:SetPieceAnimNormal(pos)
            end
        end
    end

    --第一次抬起以后 就不再刷新抬起动画
    if animDown then
        renderChainPathComponent:SetConnectAreaRenderCantRefresh(true)
    end
end

--子弹时间开始
function LinkLineService:StartBulletTime()
    ---@type Entity
    local prvwEntity = self._world:GetPreviewEntity()
    prvwEntity:ReplaceBulletTime(true)
end

--子弹时间结束
function LinkLineService:FinishBulletTime()
    ---@type Entity
    local prvwEntity = self._world:GetPreviewEntity()
    prvwEntity:ReplaceBulletTime(false)
end

function LinkLineService:_DoDrag(touchPos, offset)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()

    local playerPosition = self._world:Player():GetLocalTeamEntity():GetGridPosition()

    --格子进入连线动画
    Log.notice("begin touch in touchPlayer")
    local pieceService = self._world:GetService("Piece")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    if not boardServiceRender:IsPosCanLinkLine(touchPos, chainPath) or utilDataSvc:IsPosBlockLinkLineForChain(touchPos) then
        return
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local pieceEntity = pieceSvc:FindPieceEntity(touchPos)
    if not pieceEntity then
        Log.fatal("[touch] 连线坐标：" .. tostring(touchPos) .. " 位置的格子无法获取到！")
        return
    elseif touchPos ~= playerPosition then
        pieceService:SetPieceAnimLinkIn(touchPos)
    end

    if #chainPath == 0 then
        self:_InitChainPath(chainPath, playerPosition)
        self:CalcPathPoint(touchPos, offset)
        ---@type LinkageRenderService
        local linkageRenderService = self._world:GetService("LinkageRender")
        linkageRenderService:ShowLinkageInfo(chainPath)

        --纯表现
        local reBoard = self._world:GetRenderBoardEntity()
        ---@type PreviewChainSkillRangeComponent
        local previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()
        previewChainSkillRangeCmpt:EnablePreviewChainSkillRange(true)
    end
end

function LinkLineService:_StartCameraMove(TT)
    --YIELD(TT, BattleConst.FocusWaitTime)

    ---@type GridTouchComponent
    local gridTouchComponent = self._world:GridTouch()
    local touchState = gridTouchComponent:GetGridTouchStateID()
    if touchState == GridTouchStateID.EndDrag or touchState == GridTouchStateID.DoubleClick then
        Log.notice("current is end drag state,stop insert chain path")
        return
    end

    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    cameraCmpt:DoMoveCamera(true)
    self:AllMonsterAndTrapTrans(true)
end

function LinkLineService:_InitChainPath(chainPath, touchPosition)
    table.insert(chainPath, touchPosition)
    Log.debug("[touch] Init chain path insert ", table.tostring(chainPath))

    --开始无颜色
    local elementType = PieceType.None
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewChainPath(chainPath, elementType, PieceType.None)

    local isLocal = self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem, isLocal, #chainPath, elementType)
end

function LinkLineService:_OnPieceInsertIntoChain(chainPath)
    ---@type BoardServiceRender
    local boardsvc = self._world:GetService("BoardRender")
    local piecesvc = self._world:GetService("Piece")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    --检查棱镜触发
    if #chainPath > 1 then
        local prismPos = chainPath[#chainPath]
        local prePos = chainPath[#chainPath - 1]
        if env:IsPrismPiece(prismPos) then
            --local eid = env:GetPrismChangedPieces()
            boardsvc:ApplyPrism(prePos, prismPos)
        --piecesvc:RefreshPieceAnim()
        end
    end
end

function LinkLineService:_OnPieceRemoveFromChain(pos)
    ---@type BoardServiceRender
    local boardsvc = self._world:GetService("BoardRender")
    local piecesvc = self._world:GetService("Piece")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --检查棱镜还原
    if env:IsPrismPiece(pos) then
        boardsvc:UnapplyPrism(pos)
    --piecesvc:RefreshPieceAnim()
    end
end

function LinkLineService:CancelChainPath()
    if not self._world then
        return
    end
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end
    local ePreview = self._world:GetPreviewEntity()
    if not ePreview then
        return
    end
    local cPreviewChainPath = ePreview:PreviewChainPath()
    if not cPreviewChainPath then
        return
    end
    local chainPath = cPreviewChainPath:GetPreviewChainPath()
    --检查棱镜还原
    if chainPath then
        ---@type BoardServiceRender
        local sBoardRender = self._world:GetService("BoardRender")
        local cPreviewEnv = ePreview:PreviewEnv()
        local count = #chainPath
        for i = count, 1, -1 do--要反序
            local pos = chainPath[i]
            if cPreviewEnv and cPreviewEnv:IsPrismPiece(pos) then
                sBoardRender:UnapplyPrism(pos)
            end
        end
        -- for i, pos in ipairs(chainPath) do
        --     if cPreviewEnv and cPreviewEnv:IsPrismPiece(pos) then
        --         sBoardRender:UnapplyPrism(pos)
        --     end
        -- end
    end

    --还原连接阶段的格子颜色映射
    self:CancelBoardPieceMap(chainPath)

    self:AllMonsterAndTrapTrans(false)
end

---@param chainpath Vector2[]
---@param touchpos Vector2
function LinkLineService:QuickResponse(chainpath, touchpos, pieceType)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if not chainpath then
        return nil
    end
    if not boardServiceRender:IsSameCrossPos(chainpath[#chainpath], touchpos) then
        return nil
    end
    local lastPos = chainpath[#chainpath]

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type Vector2[]
    --local retPostList = {}
    --Log.fatal("QuickResponse PieceType:",pieceType)
    if lastPos.x == touchpos.x then
        local step = lastPos.y > touchpos.y and -1 or 1
        for y = lastPos.y + step, touchpos.y, step do
            local pos = Vector2(lastPos.x, y)
            --Log.fatal("竖着 X:"..lastPos.x.."Y:"..y..">>>>>>>>>>>>>>1")
            if table.icontains(chainpath, pos) then
                break
            end
            if not utilData:IsValidPiecePos(pos) then
                break
            end
            if not boardServiceRender:IsPosCanLinkLine(pos, chainpath) then
                break
            end
            if utilData:IsPosBlockLinkLineForChain(pos) then
                break
            end
            --Log.fatal("竖着 X:"..lastPos.x.."Y:"..y..">>>>>>>>>>>>>>2")
            ----由于该优化会连接多个格子 所以会出现在连接过程中 出现修改格子类型的问题 所以插入格子后要更新连线类型
            local newPieceType = self:InsertPieceToChainPath(chainpath, pos, pieceType)
            if not newPieceType then
                break
            end
            if newPieceType and pieceType ~= newPieceType then
                Log.info("QuickResponse ChangeChainPath PieceType  OldTYpe:", pieceType, "NewType:", newPieceType)
                pieceType = newPieceType
            end
        end
    elseif lastPos.y == touchpos.y then
        local step = lastPos.x > touchpos.x and -1 or 1
        for x = lastPos.x + step, touchpos.x, step do
            local pos = Vector2(x, lastPos.y)
            --Log.fatal("横着 X:"..x.."Y:"..lastPos.y..">>>>>>>>>>>>>>1")
            if table.icontains(chainpath, pos) then
                break
            end
            if not utilData:IsValidPiecePos(pos) then
                break
            end
            if not boardServiceRender:IsPosCanLinkLine(pos, chainpath) then
                break
            end
            if utilData:IsPosBlockLinkLineForChain(pos) then
                break
            end
            --Log.fatal("横着 X:"..x.."Y:"..lastPos.y..">>>>>>>>>>>>>>2")
            ----由于该优化会连接多个格子 所以会出现在连接过程中 出现修改格子类型的问题 所以插入格子后要更新连线类型
            local newPieceType = self:InsertPieceToChainPath(chainpath, pos, pieceType)
            if not newPieceType then
                break
            end
            if newPieceType and pieceType ~= newPieceType then
                Log.info("QuickResponse ChangeChainPath PieceType  OldTYpe:", pieceType, "NewType:", newPieceType)
                pieceType = newPieceType
            end
        end
    end
    --Log.fatal("Size:"..#retPostList..">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    --return retPostList
end

function LinkLineService:CalcPathPoint(touchPos, offset)
    local playerPosition = self._world:Player():GetLocalTeamEntity():GetGridPosition()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    local pieceType = previewChainPathCmpt:GetPreviewPieceType()

    previewChainPathCmpt:SetMoveBack(false)

    if chainPath == nil or #chainPath == 0 then
        return
    end
    local chainPathCount = #chainPath
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    if not boardServiceRender:IsPosCanLinkLine(touchPos, chainPath) or utilDataSvc:IsPosBlockLinkLineForChain(touchPos) then
        --Log.debug("Touch Is No Can Move ")
        return
    end
    local radiusType = previewChainPathCmpt:GetGridRadius(touchPos)
    --Log.fatal("<color=#38b0f4> GridPos", tostring(touchPos),"</color>")
    --滑动偏移的半径
    local radius = self:GetRadius(radiusType) --Cfg.cfg_link_line_sensing_area[1].DefaultRadius
    local offsetLen = Vector2.Magnitude(offset)

    --倒数第一个格子
    local lastLinkPosition = chainPath[chainPathCount]
    --倒数第二个格子，只有当移动到这个格子里时，才会触发回退
    local lastButOneLinkPosition = chainPath[chainPathCount - 1]
    local isLocal = self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn
    --处理回退
    if chainPathCount > 1 and touchPos == lastButOneLinkPosition then
        previewChainPathCmpt:SetMoveBack(true)
        if offsetLen < radius then
            --如果在倒数第二个格子的圆内，就可以触发回退
            local lastElementType = nil
            lastElementType, pieceType = self:_UndoLink(chainPath, pieceType)
            self:UpdateLastPathAroundRadius(chainPath, pieceType, lastElementType)

            local firstElementType, firstElementIndex = previewChainPathCmpt:GetFirstElementData()
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.FlushPetChainSkillItem,
                isLocal,
                chainPathCount,
                pieceType,
                firstElementType
            )

            ---@type LinkageRenderService
            local linkageRenderService = self._world:GetService("LinkageRender")
            linkageRenderService:ShowLinkageInfo(chainPath, pieceType)
            linkageRenderService:HideBenumbTips()
        end

        return
    end

    local goBackCount = self:QuickGoBack(chainPath, touchPos)

    if goBackCount and goBackCount ~= 0 then
        previewChainPathCmpt:SetMoveBack(true)
        local lastElementType = nil
        for i = 1, goBackCount do
            --Log.fatal("RemoveFromChainPath Pos:", tostring(chainPath[#chainPath]))
            lastElementType, pieceType = self:_UndoLink(chainPath, pieceType)
        end
        self:UpdateLastPathAroundRadius(chainPath, pieceType, lastElementType)

        local firstElementType, firstElementIndex = previewChainPathCmpt:GetFirstElementData()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FlushPetChainSkillItem,
            isLocal,
            chainPathCount,
            pieceType,
            firstElementType
        )

        ---@type LinkageRenderService
        local linkageRenderService = self._world:GetService("LinkageRender")
        linkageRenderService:ShowLinkageInfo(chainPath, pieceType)
        linkageRenderService:HideBenumbTips()
        return
    end
    if touchPos == lastLinkPosition then
        return
    else
        --判断格子是最后一个点的相邻点
        if utilDataSvc:IsAdjacentPos(lastLinkPosition, touchPos) then
            if offsetLen >= radius then
                return
            end
            local autoLinkPos = nil
            --判断是否要吸附
            if chainPathCount > 0 then
                autoLinkPos = self:_NeedAutoLink(touchPos, chainPath[chainPathCount], pieceType, offset)
                if autoLinkPos ~= nil then
                    --Log.fatal("autolink pos ",autoLinkPos.x," ",autoLinkPos.y)
                    if playerPosition == autoLinkPos then
                        --Log.fatal("autolink  pos ",autoLinkPos.x," ",autoLinkPos.y.."Invalid Equal PlayerPos")
                        return
                    end
                    touchPos = autoLinkPos
                else
                    if offsetLen > radius then
                        --在一个新格子的圆外不连
                        return
                    end
                end
            end
            self:InsertPieceToChainPath(chainPath, touchPos, pieceType)
        else
            self:QuickResponse(chainPath, touchPos, pieceType)
        end
    end
end

---@param touchPosition Vector2 要检查的目标位置
---@param pieceType PieceType 要匹配的元素类型
---@return boolean  是否能匹配
function LinkLineService:_IsElementMatch(touchPosition, pieceType)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local elementType = env:GetPieceType(touchPosition)

    if utilDataSvc:IgnoreElementMatchOnPos(touchPosition) then
        return true
    end

    if pieceType == PieceType.None then
        return false --空白色不能匹配
    end

    --其中有一个万色就可以匹配
    if pieceType == PieceType.Any or elementType == PieceType.Any then
        return true
    end

    --该位置可以映射为其他颜色
    if utilDataSvc:IsPosCanMapOtherPiece(touchPosition, pieceType, elementType) then
        return true
    end

    if elementType ~= pieceType then
        return false
    end

    return true
end

---第一个参数返回回退前的连线类型，第二个参数返回最新的连线类型
---@return PieceType,PieceType
function LinkLineService:_UndoLink(chainPath, pieceType)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local lastPieceType = pieceType

    --播放离开连线音效 播放是前一个格子对应的音效
    local linkLineIndex = #chainPath - 2
    if linkLineIndex > superChainCount then
        linkLineIndex = superChainCount
    end
    if linkLineIndex >= 1 then
        --AudioManager.Instance:PlayInnerGameSfx(AudioHelper.GetAudioResName(CriAudioIDConst.SoundCoreGameUndoLink))
        AudioHelperController.PlayInnerGameSfx(linkLineIndex + CriAudioIDConst.SoundCoreGameLinkLineStart - 1)
    end

    local pos = chainPath[#chainPath]

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    --离开连线的格子动画
    local pieceEntity = pieceSvc:FindPieceEntity(pos)
    if pieceEntity then
        self:_OnPieceRemoveFromChain(pos)
    end

    table.remove(chainPath, #chainPath)
    ---@type Vector2
    local lastpos = chainPath[#chainPath]
    ---@type PieceType
    local lastElementType = env:GetPieceType(lastpos)
    local isFirstStepUseMapPiece = false
    if #chainPath == 2 then --连线第一步视为某种颜色
        local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
        if firstLinkMapPiece then
            lastElementType = firstLinkMapPiece
            isFirstStepUseMapPiece = true
        end
    end

    --该位置可以映射为其他颜色
    local canMapOtherPiece = false
    if not isFirstStepUseMapPiece then
        canMapOtherPiece = utilDataSvc:IsPosCanMapOtherPiece(lastpos, pieceType, lastElementType)
    end

    --删空了格子颜色重置
    if #chainPath == 1 then
        --Log.fatal("SetPieceNone!!!!!!!!!!!!!!!!!!!!!!!!!!")
        --如果退回坐标后,连线上最后一个格子是万色格子,要遍历判断是否要重新设置连线颜色
        pieceType = PieceType.None

        self:StopMapPieceFirstChainPathEffect()
    elseif lastElementType == PieceType.Any or canMapOtherPiece then
        local pos = Vector2(0, 0)
        local elementType = PieceType.None
        local needreplace = true
        for index = 2, #chainPath, 1 do
            pos = chainPath[index]
            elementType = env:GetPieceType(pos)
            if index == 2 then --连线第一步视为某种颜色
                local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
                if firstLinkMapPiece then
                    elementType = firstLinkMapPiece
                end
            end
            if elementType ~= PieceType.Any then
                needreplace = false
                break
            end
        end
        if needreplace then
            pieceType = PieceType.Any
        --Log.fatal("SetPieceType Any")
        end
    end

    local isTwoColorChain = self:IsTwoColorChain()
    if isTwoColorChain then
        if lastElementType ~= pieceType and #chainPath == 2 then
            pieceType = lastElementType
        end
    end

    return lastPieceType, pieceType
end

function LinkLineService:_NeedAutoLink(touchPosition, lastPosition, pieceType, offset)
    local autoLinkPos = nil

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    local isElementMatch = self:_IsElementMatch(touchPosition, pieceType)
    if isElementMatch == true then
        --Log.fatal("_NeedAutoLink element match")
        return autoLinkPos
    end

    local deltaPos = lastPosition - touchPosition
    if
        not ((math.abs(deltaPos.x) == 0 and math.abs(deltaPos.y) == 1) or
            (math.abs(deltaPos.x) == 1 and math.abs(deltaPos.y) == 0))
     then
        --如果连的不是上下左右的格子，就不需要自动连接了
        --Log.fatal("_NeedAutoLink element no need to connect")
        return autoLinkPos
    end

    if math.abs(deltaPos.y) == 1 then
        --Log.fatal("_NeedAutoLink check y dir: ",offset.x)
        local leftPos = Vector2(touchPosition.x - 1, touchPosition.y)
        local rightPos = Vector2(touchPosition.x + 1, touchPosition.y)
        local leftPieceType = env:GetPieceType(leftPos)
        local rightPieceType = env:GetPieceType(rightPos)
        if leftPieceType == pieceType then
            if offset.x < 0 then
                autoLinkPos = leftPos
            end
        elseif rightPieceType == pieceType then
            if offset.x > 0 then
                autoLinkPos = rightPos
            end
        end
    elseif math.abs(deltaPos.x) == 1 then
        local topPos = Vector2(touchPosition.x, touchPosition.y + 1)
        local downPos = Vector2(touchPosition.x, touchPosition.y - 1)
        local topPieceType = env:GetPieceType(topPos)
        local downPieceType = env:GetPieceType(downPos)
        if topPieceType == pieceType then
            if offset.y > 0 then
                autoLinkPos = topPos
            end
        elseif downPieceType == pieceType then
            if offset.y < 0 then
                autoLinkPos = downPos
            end
        end
    --Log.fatal("_NeedAutoLink check x dir: ",offset.y," topPieceType:",topPieceType," downPieceType:",downPieceType," curPiectType",pieceType)
    end
    if autoLinkPos then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        ---@type PreviewChainPathComponent
        local previewChainPathCmpt = previewEntity:PreviewChainPath()
        local chainPath = previewChainPathCmpt:GetPreviewChainPath()

        if
            not utilDataSvc:IsValidPiecePos(autoLinkPos) or
                not boardServiceRender:IsPosCanLinkLine(autoLinkPos, chainPath) or
                utilDataSvc:IsPosBlockLinkLineForChain(autoLinkPos)
         then
            --Log.fatal("_NeedAutoLink new pos is Invalid ",autoLinkPos.x," ",autoLinkPos.y)
            return nil
        end
    end
    return autoLinkPos
end

function LinkLineService:_CalcNextGrid(offset, touchPosition)
    local up = Vector3(0, 0, 1)
    local newOffset = Vector3(offset.x, 0, offset.y)
    local angle = Vector3.Angle(up, newOffset)

    local crossVal = Vector3.Cross(up, newOffset)
    --Log.fatal("angle: ",angle," cross:",crossVal.y)
    if crossVal.y < 0 then
        return self:_SelectLeftGrid(angle, touchPosition)
    else
        return self:_SelectRightGrid(angle, touchPosition)
    end
end

---通过配置取到角度
---@return number[]
function LinkLineService:_CreateSensingArea(direction)
    local str_angle = Cfg.cfg_link_line_sensing_area[1].angle
    local angles = string.split(str_angle, "|")
    ---@type number[]
    local line_angles = {}
    local count_angles = 0

    count_angles = tonumber(angles[1]) / 2
    table.insert(line_angles, count_angles)
    if direction == "Right" then
        count_angles = count_angles + tonumber(angles[2])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[3])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[4])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[5]) / 2
        table.insert(line_angles, count_angles)
    elseif direction == "Left" then
        count_angles = count_angles + tonumber(angles[8])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[7])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[6])
        table.insert(line_angles, count_angles)
        count_angles = count_angles + tonumber(angles[5]) / 2
        table.insert(line_angles, count_angles)
    end
    --count_angles = tonumber(angles[3])
    --table.insert(line_angles, count_angles)
    --count_angles = count_angles + tonumber(angles[2])
    --table.insert(line_angles, count_angles)
    --count_angles = count_angles + tonumber(angles[1] * 2)
    --table.insert(line_angles, count_angles)
    --count_angles = count_angles + tonumber(angles[2])
    --table.insert(line_angles, count_angles)
    --count_angles = count_angles + tonumber(angles[3])
    --table.insert(line_angles, count_angles)
    return line_angles
end

function LinkLineService:_SelectRightGrid(angle, touchPosition)
    local angles = self:_CreateSensingArea("Right")
    --Log.fatal("Left Angle:"..angle..">>>>>>>>>>>>>>>>>")
    local nextTouchPosition = nil
    if angle >= 0 and angle < angles[1] then
        --Log.fatal("select up")
        nextTouchPosition = Vector2(touchPosition.x, touchPosition.y + 1)
    elseif angle >= angles[1] and angle < angles[2] then
        --Log.fatal("select right up")
        nextTouchPosition = Vector2(touchPosition.x + 1, touchPosition.y + 1)
    elseif angle >= angles[2] and angle < angles[3] then
        --Log.fatal("select right ")
        nextTouchPosition = Vector2(touchPosition.x + 1, touchPosition.y)
    elseif angle >= angles[3] and angle < angles[4] then
        --Log.fatal("select right down")
        nextTouchPosition = Vector2(touchPosition.x + 1, touchPosition.y - 1)
    elseif angle >= angles[4] and angle <= angles[5] then
        --Log.fatal("select down")
        nextTouchPosition = Vector2(touchPosition.x, touchPosition.y - 1)
    else
        --Log.fatal("_SelectRightGrid failed: ",angle)
    end
    --Log.fatal("select X:"..nextTouchPosition.x.."  Y:"..nextTouchPosition.y..">>>>>>>>>>>>>")
    --Log.fatal("source X:"..touchPosition.x.."  Y:"..touchPosition.y..">>>>>>>>>>>>>")

    return nextTouchPosition
end

function LinkLineService:_SelectLeftGrid(angle, touchPosition)
    --Log.fatal("Left Angle:"..angle..">>>>>>>>>>>>>>>>>")
    local angles = self:_CreateSensingArea("Left")
    local nextTouchPosition = nil
    if angle >= 0 and angle < angles[1] then
        --Log.fatal("select up")
        nextTouchPosition = Vector2(touchPosition.x, touchPosition.y + 1)
    elseif angle >= angles[1] and angle < angles[2] then
        --Log.fatal("select left up")
        nextTouchPosition = Vector2(touchPosition.x - 1, touchPosition.y + 1)
    elseif angle >= angles[2] and angle < angles[3] then
        --Log.fatal("select left ")
        nextTouchPosition = Vector2(touchPosition.x - 1, touchPosition.y)
    elseif angle >= angles[3] and angle < angles[4] then
        --Log.fatal("select left down")
        nextTouchPosition = Vector2(touchPosition.x - 1, touchPosition.y - 1)
    elseif angle >= angles[4] and angle <= angles[5] then
        --Log.fatal("select down")
        nextTouchPosition = Vector2(touchPosition.x, touchPosition.y - 1)
    else
        --Log.fatal("_SelectLeftGrid failed: ",angle)
    end
    --Log.fatal("select X:"..nextTouchPosition.x.."  Y:"..nextTouchPosition.y..">>>>>>>>>>>>>")
    --Log.fatal("source X:"..touchPosition.x.."  Y:"..touchPosition.y..">>>>>>>>>>>>>")
    return nextTouchPosition
end

---@param chainPath Vector2[]
---@param piecePos Vector2
---@param pieceType PieceType
---@return PieceType 正确执行的情况下会返回新的pieceType
function LinkLineService:InsertPieceToChainPath(chainPath, piecePos, pieceType)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --是否与连线最后的格子相连
    if not utilDataSvc:IsAdjacentPos(chainPath[#chainPath], piecePos) then
        return
    end
    --是否为有效格子，这个函数里面的实现需要改下
    if not boardServiceRender:IsInPlayerArea(piecePos) then
        --Log.fatal("touch pos is not valid piece pos-----"..tostring(piecePos))
        return
    end
    if utilDataSvc:IsPosBlockLinkLineForChain(piecePos) then --判断格子阻挡连线
        return
    end
    local lastPieceType = pieceType
    ---当前触碰位置的格子颜色
    local elementType = env:GetPieceType(piecePos)
    if elementType == PieceType.None then --敌方光灵脚下灰格子
        return
    end
    if #chainPath == 1 then
        ---当前的连线队列是1，就是队列里只有玩家脚下格子
        ---此时设置连线队列颜色是当前触碰的格子颜色
        --Log.fatal("First SetPieceType Type",pieceType)
        local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
        if firstLinkMapPiece then
            elementType = firstLinkMapPiece
            --引导bug MSG63426 连线引导时，如果第一个格子不在引导路径上，会导致一直触发特效播放，这里判断下
            local guideService = self._world:GetService("Guide")
            ---@type GuideServiceRender
            local isMatchGuidePath = guideService:HandleDragTrigger(piecePos)
            if isMatchGuidePath == true then
                --播格子特效
                self:PlayMapPieceFirstChainPathEffect(piecePos)
            end
        end
        pieceType = elementType
    elseif #chainPath > 1 then
        if #chainPath >= 2 then
            if pieceType == PieceType.Any then
                pieceType = env:GetPieceType(piecePos)
            --Log.fatal("FirstNot Any SetPieceType Type:",pieceType)
            end
        end

        local isTwoColorChain = self:IsTwoColorChain()
        if isTwoColorChain then
            ---如果是双色队走特殊逻辑
            local isElementMatch, resetPieceType = self:_IsElementMatchForTwoColorChain(piecePos, pieceType, chainPath)
            if not isElementMatch then
                --Log.fatal("Not_IsElementMatch: ","touch:",tostring(piecePos),"  ",pieceType)
                return
            end

            if resetPieceType then
                pieceType = elementType
            end
        else
            local isElementMatch = self:_IsElementMatch(piecePos, pieceType)
            if not isElementMatch then
                --Log.fatal("Not_IsElementMatch: ","touch:",tostring(piecePos),"  ",pieceType)
                return
            end
        end
    end
    --判断path不含此坐标，加入path
    if table.icontains(chainPath, piecePos) then
        --Log.fatal("touch pos already in path--------"..tostring(piecePos))
        return
    end

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    if #chainPath > 1 and teamEntity:BuffView():HasBuffEffect(BuffEffectType.Benumb) then
        Log.debug("player is benumb!!")
        return
    end

    ---检测引导是否匹配
    local guideService = self._world:GetService("Guide")
    ---@type GuideServiceRender
    local isMatchGuidePath = guideService:HandleDragTrigger(piecePos)
    if isMatchGuidePath ~= true then
        return
    end

    --Log.fatal("InsertPos X:"..piecePos.x.." Y:"..piecePos.y..">>>>>>1")
    --坐标加入path
    table.insert(chainPath, piecePos)

    --播放连线音效
    local linkLineIndex = #chainPath - 1
    if linkLineIndex > superChainCount then
        linkLineIndex = superChainCount
    end
    if linkLineIndex >= 1 then
        AudioHelperController.PlayInnerGameSfx(linkLineIndex + CriAudioIDConst.SoundCoreGameLinkLineStart - 1)
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    --格子进入连线动画
    local pieceEntity = pieceSvc:FindPieceEntity(piecePos)
    if pieceEntity then
        self:_OnPieceInsertIntoChain(chainPath)
    else
        ---@type Entity
        local viewDataEntity = self._world:GetRenderBoardEntity()
        ---@type WaveDataComponent
        local waveDataCmpt = viewDataEntity:WaveData()
        local isExitWave = waveDataCmpt:IsExitWave()
        local exitPos = waveDataCmpt:GetExitWavePos()

        if isExitWave and exitPos == piecePos then
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            effectService:CreateWorldPositionEffect(GameResourceConst.EffLinkLine2Exit, piecePos) --TODO临时在此创建个特效表示连到出口，等美术效果出来后修改
        else
            Log.fatal("连线坐标：" .. tostring(piecePos) .. " 位置的格子无法获取到！", Log.traceback())
            return
        end
    end
    lastPieceType = env:GetPieceType(chainPath[#chainPath])
    ---本地立即更新连线
    self:UpdateLastPathAroundRadius(chainPath, pieceType, lastPieceType)
    local isLocal = self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local prvwCmpt = previewEntity:PreviewChainPath()
    local firstElementType, firstElementIndex = prvwCmpt:GetFirstElementData()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.FlushPetChainSkillItem,
        isLocal,
        #chainPath,
        pieceType,
        firstElementType
    )

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:ShowLinkageInfo(chainPath, pieceType)
    return pieceType
end

function LinkLineService:_FindTrapByPos(posTouch)
    local listFindTrapID = {}
    local teTrap = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, eTrap in ipairs(teTrap) do
        if eTrap:TrapRender():IsHasShow() and eTrap:IsViewVisible() then
            local cBodyArea = eTrap:BodyArea()
            local tv2Relative = cBodyArea and cBodyArea:GetArea() or {Vector2.zero}
            local v2GridPos = eTrap:GetGridPosition()
            for __, v2Relative in ipairs(tv2Relative) do
                if posTouch == v2GridPos + v2Relative then
                    table.insert(listFindTrapID, eTrap:GetID())
                end
            end
        end
    end
    return listFindTrapID
end

--处理当
---@return number
---@param chainpath Vector2[]
---@param touchpos Vector2
function LinkLineService:_QuickStayGoBack(chainpath, touchpos)
    if not table.icontains(chainpath, touchpos) then
        return nil
    end
    if touchpos == chainpath[#chainpath] then
        return nil
    end
    ---@type  TimeBaseService
    local timeService = self._world:GetService("Time")
    ---@type GridTouchComponent
    local gridTouchComponent = self._world:GridTouch()

    if gridTouchComponent:GetStayTouchDuration(timeService:GetCurrentTimeMs()) < BattleConst.GoBackStayTime then
        return nil
    end
    local goBackCount = 0
    --获得回退的数量
    for i = #chainpath, 1, -1 do
        ---@type Vector2
        local pos = chainpath[i]
        if pos ~= touchpos then
            goBackCount = goBackCount + 1
        else
            break
        end
    end
    goBackCount = goBackCount - 1
    return goBackCount
end

---@return number
---@param chainpath Vector2[]
---@param touchpos Vector2
function LinkLineService:QuickGoBack(chainpath, touchpos)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if not chainpath then
        return nil
    end
    if table.icontains(chainpath, touchpos) then
        return self:_QuickStayGoBack(chainpath, touchpos)
    end
    if not boardServiceRender:IsSameCrossPos(chainpath[#chainpath], touchpos) then
        return nil
    end
    if #chainpath == 1 then
        return nil
    end
    local lastPos = chainpath[#chainpath]

    if touchpos == lastPos then
        return nil
    end

    local goBackCount = 0
    ---@type Vector2[]
    local goBackPosList = {}
    ---@type Vector2[]
    local tmpPosList = {}
    if lastPos.x == touchpos.x then
        local step = lastPos.y > touchpos.y and -1 or 1
        for y = lastPos.y, touchpos.y, step do
            local pos = Vector2(lastPos.x, y)
            table.insert(tmpPosList, pos)
        end
    elseif lastPos.y == touchpos.y then
        local step = lastPos.x > touchpos.x and -1 or 1
        for x = lastPos.x, touchpos.x, step do
            ---@type Vector2
            local pos = Vector2(x, lastPos.y)
            table.insert(tmpPosList, pos)
        end
    end
    if #tmpPosList > 0 then
        for i = #chainpath, 1, -1 do
            ---@type Vector2
            local pos = chainpath[i]
            if table.icontains(tmpPosList, pos) then
                ---空列表或者 pos与列表最后一个相连才加入 否则break
                if #goBackPosList == 0 or math.abs(i - goBackPosList[#goBackPosList][2]) == 1 then
                    table.insert(goBackPosList, {pos, i})
                    goBackCount = goBackCount + 1
                else
                    break
                end
            end
        end
        --Log.fatal("TouchPostion :",tostring(touchpos),"Begin goBackCount",goBackCount ,str)
        --if not table.icontains(chainpath,touchpos) then
        ---chainpath[1] 应该就是玩家所在格子的位置
        --if goBackPosList[#goBackPosList] ~= chainpath[1] then
        --    table.removev(goBackPosList,goBackPosList[#goBackPosList])
        --    goBackCount = goBackCount -1
        --end
        --end
        table.removev(goBackPosList, goBackPosList[#goBackPosList])
        goBackCount = goBackCount - 1
    --if #goBackPosList ~= 0 then
    --    local str = ""
    --    for i, v in ipairs(goBackPosList) do
    --        str = str .. tostring(i) .. ": ".. tostring(v[1]).." Index:".. tostring(v[2])
    --    end
    --    Log.fatal("TouchPostion :",tostring(touchpos),"goBackCount",goBackCount ,str)
    --end
    end
    return goBackCount
end

---每次链接新格子后搞一下最后一个格子周边可连接格子的感应区半径
function LinkLineService:UpdateLastPathAroundRadius(chainPath, chainPieceType, chainLastElementType)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewChainPath(chainPath, chainPieceType, chainLastElementType)
    local isTwoColorTeam = self:IsTwoColorChain()
    if isTwoColorTeam then
        ---如果支持双色连线，需要查询第一个非万色格子的颜色
        ---@type PreviewEnvComponent
        local env = self._world:GetPreviewEntity():PreviewEnv()

        ---@type PreviewChainPathComponent
        local prvwCmpt = previewEntity:PreviewChainPath()

        ---每次更新需要先清空，再设置
        local firstElementType = PieceType.None
        local firstElementIndex = -1

        if #chainPath >= 2 then
            for index = 2, #chainPath do
                local curPos = chainPath[index]
                local curPieceType = env:GetPieceType(curPos)
                if index == 2 then --连线第一步视为某种颜色
                    local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
                    if firstLinkMapPiece then
                        curPieceType = firstLinkMapPiece
                    end
                end
                --Log.fatal("index:",index," pos:",curPos," type:",curPieceType)
                if curPieceType ~= PieceType.Any then
                    firstElementType = curPieceType
                    firstElementIndex = index
                    break
                end
            end

            prvwCmpt:SetFirstElementData(firstElementType, firstElementIndex)
        else
            prvwCmpt:SetFirstElementData(firstElementType, firstElementIndex)
        end

    --Log.fatal("FirstElement type ",firstElementType," index:",firstElementIndex)
    end

    local endGridPos = chainPath[#chainPath]
    local endNearbyGridPosList =
        utilDataSvc:GetRoundGrid(
        endGridPos,
        function(gridPos)
            if self:_IsElementMatch(gridPos, chainPieceType) then
                return true
            end
            return false
        end
    )
    ---@type table<Vector2,number>
    local nearbyGridRadius = {}

    for _, v in pairs(endNearbyGridPosList) do
        local gridPos = Vector2(v.x, v.y)
        local gridRoundPosList =
            utilDataSvc:GetRoundGrid(
            gridPos,
            function(pos)
                if table.icontains(endNearbyGridPosList, pos) and self:_IsElementMatch(pos, chainPieceType) then
                    return true
                end
                return false
            end
        )

        ---四方向相邻
        if gridPos.x == endGridPos.x or gridPos.y == endGridPos.y then
            if #gridRoundPosList ~= 0 then
                nearbyGridRadius[gridPos] = GridRadiusType.NearBy
            else
                nearbyGridRadius[gridPos] = GridRadiusType.Default
            end
        else
            if #gridRoundPosList ~= 0 then
                nearbyGridRadius[gridPos] = GridRadiusType.Diagonal
            else
                nearbyGridRadius[gridPos] = GridRadiusType.Default
            end
        end
    end
    for pos, radiusType in pairs(nearbyGridRadius) do
        --Log.fatal("<color=#38b0f4> Pos:", tostring(pos),"RadiusType:",radiusType,"</color>")
    end

    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    previewChainPathCmpt:SetGridRadius(nearbyGridRadius)
end

---@param radiusType GridRadiusType
function LinkLineService:GetRadius(radiusType)
    local config = Cfg.cfg_link_line_sensing_area[1]

    if radiusType == GridRadiusType.Default then
        --Log.fatal("<color=#38b0f4>DefaultRadius</color>")
        return config.DefaultRadius
    elseif radiusType == GridRadiusType.Diagonal then
        --Log.fatal("<color=#38b0f4>DiagonalRadius</color>")
        return config.DiagonalRadius
    elseif radiusType == GridRadiusType.NearBy then
        --Log.fatal("<color=#38b0f4>NearbyRadius</color>")
        return config.NearbyRadius
    end
    return config.DefaultRadius
end

---播放所有怪物和陷阱的透明动画
function LinkLineService:AllMonsterAndTrapTrans(show)
    local flashEnemyEntities = self._world:GetGroup(self._world.BW_WEMatchers.MaterialAnimation):GetEntities()
    for _, v in pairs(flashEnemyEntities) do
        if (v:HasMonsterID() or v:HasTrapID()) then
            if not (v:BuffView() and v:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation)) then
                if show then
                    v:NewEnableGhost()
                else
                    v:StopGhostAnim()
                end
            end
        end
    end
end

function LinkLineService:ShowChainPathCancelArea(isShow)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    renderBoardCmpt:SetChainPathCancelAreaActive(isShow)

    if isShow then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowChainPathCancelArea)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HideChainPathCancelArea)
    end
end

function LinkLineService:IsTwoColorChain()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local useTwoColorTeam = utilDataSvc:GetEntityBuffValue(teamEntity, "TwoColorChain")

    return useTwoColorTeam
end

---@param touchPosition Vector2 要检查的目标位置
---@param pieceType PieceType 要匹配的元素类型
---@return boolean  是否能匹配
function LinkLineService:_IsElementMatchForTwoColorChain(touchPosition, pieceType, chainPath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---当前连线点的颜色
    local elementType = env:GetPieceType(touchPosition)

    if utilDataSvc:IgnoreElementMatchOnPos(touchPosition) then
        return true
    end

    if pieceType == PieceType.None then
        return false --空白色不能匹配
    end

    --其中有一个万色就可以匹配
    if pieceType == PieceType.Any or elementType == PieceType.Any then
        return true
    end

    --该位置可以映射为其他颜色
    if utilDataSvc:IsPosCanMapOtherPiece(touchPosition, pieceType, elementType) then
        --直接返回true会导致：第2第3的格子连的是被映射为万色的格子就直接范围会匹配了，在可以连双色的情况下，没有设置第二个颜色
        -- return true

        --不是万色的格子数量（被映射的不算）
        local noPieceTypeAnyCount = 0
        for checkIndex = 1, #chainPath do
            local checkPos = chainPath[checkIndex]
            ---当前连线点的颜色
            local curPieceType = env:GetPieceType(checkPos)
            if checkIndex == 2 then --连线第一步视为某种颜色
                local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
                if firstLinkMapPiece then
                    curPieceType = firstLinkMapPiece
                end
            end
            if curPieceType ~= PieceType.Any then
                noPieceTypeAnyCount = noPieceTypeAnyCount + 1
            end
        end

        --连了2个不是万色的格子 and 当前格子不是万色
        if noPieceTypeAnyCount == 2 and elementType ~= PieceType.Any then
            return true, true
        end
        --不符合上面就只是匹配颜色，并不重置连线颜色
        return true
    end

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local prvwCmpt = previewEntity:PreviewChainPath()
    local firstElementType, firstElementIndex = prvwCmpt:GetFirstElementData()

    local isSecondColor = self:IsSecondColorForTwoColorChain(chainPath)
    if isSecondColor then
        ---如果上一个点就是第一个非万色格子点，那么这个颜色要作为连线颜色
        return true, true
    else
        if elementType ~= pieceType then
            return false
        end

        return true
    end
end

function LinkLineService:IsSecondColorForTwoColorChain(chainPath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local prvwCmpt = previewEntity:PreviewChainPath()
    local firstElementType, firstElementIndex = prvwCmpt:GetFirstElementData()

    if firstElementIndex == #chainPath then
        ---紧挨着第一个非万色的话，可以连，作为第二色
        return true
    end

    if firstElementIndex < 0 then 
        ---这时，没有找到第一个非万色的格子
        return false
    end

    local isAllAny = true
    ---从第一个非万色开始，到当前的最后一个点，全是都是万色，才能连
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local startIndex = firstElementIndex + 1
    if startIndex <= #chainPath then 
        for checkIndex = startIndex,#chainPath do 
            local checkPos = chainPath[checkIndex]
            ---当前连线点的颜色
            local curPieceType = env:GetPieceType(checkPos)
            if checkIndex == 2 then --连线第一步视为某种颜色
                local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
                if firstLinkMapPiece then
                    curPieceType = firstLinkMapPiece
                end
            end
            if curPieceType ~= PieceType.Any then 
                isAllAny = false
                break
            end
        end
    else
        return false
    end

    if isAllAny then 
        return true
    end

    return false
end
function LinkLineService:PlayMapPieceFirstChainPathEffect(piecePos)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    --local eid = 290510104--GameResourceConst.EffLinkLine2Exit
    local eid = renderBoardCmpt:GetMapPieceFirstChainPathEffectID()
    if eid and eid > 0 then
        local effEntity = effectService:CreateWorldPositionEffect(eid, piecePos)
        if effEntity then
            ---@type Entity
            local renderBoardEntity = self._world:GetRenderBoardEntity()
            ---@type RenderBoardComponent
            local renderBoardCmpt = renderBoardEntity:RenderBoard()
            renderBoardCmpt:SetMapPieceFirstChainPathEffectEntityID(effEntity:GetID())
        end
    end
end
function LinkLineService:StopMapPieceFirstChainPathEffect()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local effEntityID = renderBoardCmpt:GetMapPieceFirstChainPathEffectEntityID()
    if effEntityID then
        local effEntity = self._world:GetEntityByID(effEntityID)
        if effEntity then
            local outAnim = renderBoardCmpt:GetMapPieceFirstChainPathEffectOutAnim()
            if outAnim then
                local ego = effEntity:View():GetGameObject()
                if ego then
                    ---@type UnityEngine.Animation
                    local anim = ego.gameObject:GetComponent("Animation")
                    --anim:Play("eff_2905101_skill3_gezi_red_out")
                    anim:Play(outAnim)
                end
            else
                self._world:DestroyEntity(effEntity)
            end
        end
    end
    renderBoardCmpt:SetMapPieceFirstChainPathEffectEntityID(nil)
end