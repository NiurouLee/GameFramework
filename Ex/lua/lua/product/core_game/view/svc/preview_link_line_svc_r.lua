--[[------------------------------------------------------------------------------------------
    主动技预览阶段连线服务
]]
--------------------------------------------------------------------------------------------
---@class PreviewLinkLineService:LinkLineService
_class("PreviewLinkLineService", LinkLineService)
PreviewLinkLineService = PreviewLinkLineService

function PreviewLinkLineService:StartLinkLine(touchPos, offset)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPBuffButtonRayCast, false)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return false
    end

    -- --隐藏箭头
    -- ---@type CanMoveArrowService
    -- local canMoveArrowService = self._world:GetService("CanMoveArrow")
    -- if canMoveArrowService then
    --     canMoveArrowService:ShowCanMoveArrow(false)
    -- end

    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    guideService:HandlePLLBeginDragTrigger(touchPos)

    --清除之前的连线结果
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:HideAllLinkDot()
    linkageRenderService:DestroyAllLinkLine()
    linkageRenderService:DestroyLinkedGridEffect()

    --还原连线路径的格子颜色
    if #chainPath > 0 then
        self:CancelAllLinkPosPieceType(chainPath)
    end

    self:_DoDrag(touchPos, offset)

    self:_StartCameraMove()

    --如果连线能穿怪，需要把怪物脚下格子抬起来
    self:SetMonsterShadowPosListDown(false)

    ---开始子弹时间
    self:StartBulletTime()
end

---获取点选参数
function PreviewLinkLineService:GetCurPickUpParam()
    -- --测试数据
    -- if true then
    --     return { 4, 1, 1 }
    -- end
    ---@type PickUpComponent
    local pickUpCmpt = self._world:PickUp()
    local skillID = pickUpCmpt:GetCurActiveSkillID()
    local pstID = pickUpCmpt:GetCurActiveSkillPetPstID()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type Entity
    local petEntity = utilData:GetEntityByPstID(pstID)
    if not petEntity then
        local entityID = pickUpCmpt:GetEntityID()
        petEntity = self._world:GetEntityByID(entityID)
    end

    if not petEntity then
        return
    end

    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local cfgData = cfgSvc:GetSkillConfigData(skillID, petEntity)
    if not cfgData then
        return
    end

    return cfgData:GetSkillPickParam()
end

---如果连线能穿怪，需要把怪物脚下格子抬起来/压暗
function PreviewLinkLineService:SetMonsterShadowPosListDown(animDown)
    local pickUpParam = self:GetCurPickUpParam()
    local isLinkMonster = pickUpParam[3] or 0
    if isLinkMonster ~= 1 then
        ---不能穿怪，直接返回
        return
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local renderChainPathComponent = renderBoardEntity:RenderChainPath()

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

    --第一次抬起以后 就不再刷新抬起动画
    if animDown then
        renderChainPathComponent:SetConnectAreaRenderCantRefresh(true)
    end
end

function PreviewLinkLineService:_DoDrag(touchPos, offset)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

    local playerPosition = self._world:Player():GetLocalTeamEntity():GetGridPosition()

    --格子是否可连线
    if not self:IsPosCanLink(touchPos, chainPath) then
        return
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    ---@type Entity
    local pieceEntity = pieceSvc:FindPieceEntity(touchPos)
    if not pieceEntity then
        Log.fatal("[touch] 连线坐标：" .. tostring(touchPos) .. " 位置的格子无法获取到！")
        return
    end

    if #chainPath == 0 then
        self:_InitChainPath(chainPath, playerPosition)
        self:CalcPathPoint(touchPos, offset)
    end
end

function PreviewLinkLineService:_StartCameraMove(TT)
    ---@type GridTouchComponent
    local gridTouchComponent = self._world:GridTouch()
    local touchState = gridTouchComponent:GetGridTouchStateID()
    if touchState == GridTouchStateID.PLLEndDrag then
        Log.notice("current is end drag state,stop insert chain path")
        return
    end

    ---@type MainCameraComponent
    local cameraCmpt = self._world:MainCamera()
    cameraCmpt:DoMoveCamera(true)
    self:AllMonsterAndTrapTrans(true)
end

function PreviewLinkLineService:_InitChainPath(chainPath, touchPosition)
    table.insert(chainPath, touchPosition)
    Log.debug("[touch] Init chain path insert ", table.tostring(chainPath))

    --开始无颜色
    local elementType = PieceType.None
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewLinkLine(chainPath, elementType, PieceType.None)
    self:NotifyPickUpTargetChange()
end

function PreviewLinkLineService:CancelChainPath()
    if not self._world then
        return
    end
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end

    self:AllMonsterAndTrapTrans(false)
end

---@param chainPath Vector2[]
---@param touchPos Vector2
function PreviewLinkLineService:QuickResponse(chainPath, touchPos, pieceType)
    if not chainPath then
        return nil
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if not boardServiceRender:IsSameCrossPos(chainPath[#chainPath], touchPos) then
        return nil
    end
    local lastPos = chainPath[#chainPath]
    if lastPos.x == touchPos.x then
        local step = lastPos.y > touchPos.y and -1 or 1
        for y = lastPos.y + step, touchPos.y, step do
            local pos = Vector2(lastPos.x, y)
            if table.icontains(chainPath, pos) then
                break
            end
            if not self:IsPosCanLink(pos, chainPath) then
                break
            end
            ----由于该优化会连接多个格子 所以会出现在连接过程中 出现修改格子类型的问题 所以插入格子后要更新连线类型
            local newPieceType = self:InsertPieceToChainPath(chainPath, pos, pieceType)
            if not newPieceType then
                break
            end
            if newPieceType and pieceType ~= newPieceType then
                pieceType = newPieceType
            end
        end
    elseif lastPos.y == touchPos.y then
        local step = lastPos.x > touchPos.x and -1 or 1
        for x = lastPos.x + step, touchPos.x, step do
            local pos = Vector2(x, lastPos.y)
            if table.icontains(chainPath, pos) then
                break
            end
            if not self:IsPosCanLink(pos, chainPath) then
                break
            end
            ----由于该优化会连接多个格子 所以会出现在连接过程中 出现修改格子类型的问题 所以插入格子后要更新连线类型
            local newPieceType = self:InsertPieceToChainPath(chainPath, pos, pieceType)
            if not newPieceType then
                break
            end
            if newPieceType and pieceType ~= newPieceType then
                pieceType = newPieceType
            end
        end
    end
end

function PreviewLinkLineService:CalcPathPoint(touchPos, offset)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()

    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    local pieceType = previewLinkLineCmpt:GetPreviewPieceType()

    previewLinkLineCmpt:SetMoveBack(false)

    if chainPath == nil or #chainPath == 0 then
        return
    end
    local chainPathCount = #chainPath
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    if not self:IsPosCanLink(touchPos, chainPath) then
        --Log.debug("Touch Is No Can Move ")
        return
    end

    local radiusType = previewLinkLineCmpt:GetGridRadius(touchPos)

    --滑动偏移的半径
    local radius = self:GetRadius(radiusType)
    local offsetLen = Vector2.Magnitude(offset)

    --倒数第一个格子
    local lastLinkPosition = chainPath[chainPathCount]
    --倒数第二个格子，只有当移动到这个格子里时，才会触发回退
    local lastButOneLinkPosition = chainPath[chainPathCount - 1]
    --处理回退
    if chainPathCount > 1 and touchPos == lastButOneLinkPosition then
        previewLinkLineCmpt:SetMoveBack(true)
        if offsetLen < radius then
            --如果在倒数第二个格子的圆内，就可以触发回退
            pieceType = self:_UndoLink(chainPath)
            self:UpdateLastPathAroundRadius(chainPath, pieceType)
        end
        return
    end

    local goBackCount = self:_QuickGoBack(chainPath, touchPos)
    if goBackCount and goBackCount ~= 0 then
        previewLinkLineCmpt:SetMoveBack(true)
        for i = 1, goBackCount do
            pieceType = self:_UndoLink(chainPath)
        end
        self:UpdateLastPathAroundRadius(chainPath, pieceType)
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
            self:InsertPieceToChainPath(chainPath, touchPos, pieceType)
        else
            self:QuickResponse(chainPath, touchPos, pieceType)
        end
    end
end

function PreviewLinkLineService:_OnPieceRemoveFromChain(pos)
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --检查棱镜还原
    if env:IsPrismPiece(pos) then
        pieceSvc:SetPieceRenderEffect(pos, PieceEffectType.Prism)

        --处理十字棱镜的特效
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        local pieceType = utilDataSvc:GetPieceType(pos)
        trapServiceRender:SetPrismEffectTrapShow(pos, nil, pieceType, true)
    end
end

function PreviewLinkLineService:_OnPieceInsertIntoChain(piecePos)
    ---@type BoardServiceRender
    local boardsvc = self._world:GetService("BoardRender")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    if env:IsPrismPiece(piecePos) then
        --去除普通棱镜的格子效果
        pieceSvc:SetPieceRenderEffect(piecePos, PieceEffectType.Normal)

        --处理十字棱镜的特效
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        local pieceType = env:GetPieceType(piecePos)
        trapServiceRender:SetPrismEffectTrapShow(piecePos, nil, pieceType, false)
    end
end

---返回最新的连线类型
---@return PieceType
function PreviewLinkLineService:_UndoLink(chainPath)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --播放离开连线音效 播放是前一个格子对应的音效
    local linkLineIndex = #chainPath - 2
    if linkLineIndex > superChainCount then
        linkLineIndex = superChainCount
    end
    if linkLineIndex >= 1 then
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

    return lastElementType
end

---@param chainPath Vector2[]
---@param piecePos Vector2
---@param pieceType PieceType
---@return PieceType
function PreviewLinkLineService:InsertPieceToChainPath(chainPath, piecePos, pieceType)
    --已存在path中，直接返回
    if table.icontains(chainPath, piecePos) then
        return
    end

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
        return
    end

    --当前触碰位置的格子颜色
    pieceType = env:GetPieceType(piecePos)

    ---检测引导是否匹配
    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    local isMatchGuidePath = guideService:HandlePLLDragTrigger(piecePos)
    if isMatchGuidePath ~= true then
        return
    end

    --坐标加入path
    table.insert(chainPath, piecePos)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()
    --播放连线音效
    local linkLineIndex = #chainPath - 1
    if linkLineIndex > superChainCount then
        linkLineIndex = superChainCount
    end
    if linkLineIndex >= 1 then
        AudioHelperController.PlayInnerGameSfx(linkLineIndex + CriAudioIDConst.SoundCoreGameLinkLineStart - 1)
    end

    --格子进入连线动画
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local pieceEntity = pieceSvc:FindPieceEntity(piecePos)
    if pieceEntity then
        self:_OnPieceInsertIntoChain(piecePos)
    end

    --本地立即更新连线
    self:UpdateLastPathAroundRadius(chainPath, pieceType)
    return pieceType
end

---@param chainPath Vector2[]
---@param touchPos Vector2
---@return number
function PreviewLinkLineService:_QuickStayGoBack(chainPath, touchPos)
    if not table.icontains(chainPath, touchPos) then
        return nil
    end
    if touchPos == chainPath[#chainPath] then
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
    for i = #chainPath, 1, -1 do
        ---@type Vector2
        local pos = chainPath[i]
        if pos ~= touchPos then
            goBackCount = goBackCount + 1
        else
            break
        end
    end
    goBackCount = goBackCount - 1
    return goBackCount
end

---@param chainPath Vector2[]
---@param touchPos Vector2
---@return number
function PreviewLinkLineService:_QuickGoBack(chainPath, touchPos)
    if not chainPath then
        return nil
    end

    if table.icontains(chainPath, touchPos) then
        return self:_QuickStayGoBack(chainPath, touchPos)
    end

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if not boardServiceRender:IsSameCrossPos(chainPath[#chainPath], touchPos) then
        return nil
    end

    if #chainPath == 1 then
        return nil
    end

    local lastPos = chainPath[#chainPath]
    if touchPos == lastPos then
        return nil
    end

    local goBackCount = 0
    ---@type Vector2[]
    local goBackPosList = {}
    ---@type Vector2[]
    local tmpPosList = {}

    if lastPos.x == touchPos.x then
        local step = lastPos.y > touchPos.y and -1 or 1
        for y = lastPos.y, touchPos.y, step do
            local pos = Vector2(lastPos.x, y)
            table.insert(tmpPosList, pos)
        end
    elseif lastPos.y == touchPos.y then
        local step = lastPos.x > touchPos.x and -1 or 1
        for x = lastPos.x, touchPos.x, step do
            ---@type Vector2
            local pos = Vector2(x, lastPos.y)
            table.insert(tmpPosList, pos)
        end
    end
    if #tmpPosList > 0 then
        for i = #chainPath, 1, -1 do
            ---@type Vector2
            local pos = chainPath[i]
            if table.icontains(tmpPosList, pos) then
                ---空列表或者 pos与列表最后一个相连才加入 否则break
                if #goBackPosList == 0 or math.abs(i - goBackPosList[#goBackPosList][2]) == 1 then
                    table.insert(goBackPosList, { pos, i })
                    goBackCount = goBackCount + 1
                else
                    break
                end
            end
        end
        table.removev(goBackPosList, goBackPosList[#goBackPosList])
        goBackCount = goBackCount - 1
    end

    return goBackCount
end

---每次链接新格子后搞一下最后一个格子周边可连接格子的感应区半径
function PreviewLinkLineService:UpdateLastPathAroundRadius(chainPath, chainPieceType)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewLinkLine(chainPath, chainPieceType)
    self:NotifyPickUpTargetChange()

    local endGridPos = chainPath[#chainPath]
    local endNearbyGridPosList = utilDataSvc:GetRoundGrid(endGridPos)
    ---@type table<Vector2,number>
    local nearbyGridRadius = {}

    for _, v in pairs(endNearbyGridPosList) do
        local gridPos = Vector2(v.x, v.y)
        local gridRoundPosList =
            utilDataSvc:GetRoundGrid(
                gridPos,
                function(pos)
                    if table.icontains(endNearbyGridPosList, pos) then
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

    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    previewLinkLineCmpt:SetGridRadius(nearbyGridRadius)
end

---@param radiusType GridRadiusType
function PreviewLinkLineService:GetRadius(radiusType)
    local config = Cfg.cfg_link_line_sensing_area[1]

    if radiusType == GridRadiusType.Default then
        return config.DefaultRadius
    elseif radiusType == GridRadiusType.Diagonal then
        return config.DiagonalRadius
    elseif radiusType == GridRadiusType.NearBy then
        return config.NearbyRadius
    end
    return config.DefaultRadius
end

function PreviewLinkLineService:NotifyPickUpTargetChange()
    ---@type PickUpComponent
    local pickUpCmpt = self._world:PickUp()
    local skillID = pickUpCmpt:GetCurActiveSkillID()
    local pstID = pickUpCmpt:GetCurActiveSkillPetPstID()
    local entityID = pickUpCmpt:GetEntityID()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type SkillPickUpType
    local activeSkillPickUpType = skillConfigData:GetSkillPickType()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:SetPickUpTargetType(activeSkillPickUpType)
    pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, pstID)
    pickUpTargetCmpt:SetEntityID(entityID)

    renderBoardEntity:ReplacePickUpTarget()
end

--将连到的格子转色
function PreviewLinkLineService:ConvertLinkPosPieceType(pos)
    local pickUpParam = self:GetCurPickUpParam()
    local pieceType = pickUpParam[2] or PieceType.Blue

    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local curType = env:GetPieceType(pos)

    --若连到怪物脚下，则不转色
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if (utilDataSvc:GetMonsterAtPos(pos)) or
        not utilDataSvc:IsPosCanConvertGridElement(pos) or
        pieceType == curType then
        return curType
    end

    --刷新预览层数据
    env:SetPieceType(pos, pieceType)
    boardServiceR:ReCreateGridEntity(pieceType, pos, false, false, true)
    return pieceType
end

--还原格子颜色
function PreviewLinkLineService:CancelLinkPosPieceType(pos)
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    --格子原本的颜色
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pieceType = utilDataSvc:GetPieceType(pos)

    --对比是否需要还原
    local previewPieceType = env:GetPieceType(pos)
    if previewPieceType == pieceType then
        return
    end

    --刷新预览层数据
    env:SetPieceType(pos, pieceType)
    boardServiceR:ReCreateGridEntity(pieceType, pos, false, false, true)
end

--还原连线路径的格子颜色
function PreviewLinkLineService:CancelAllLinkPosPieceType(chainPath)
    for _, pos in pairs(chainPath) do
        self:CancelLinkPosPieceType(pos)
    end
end

function PreviewLinkLineService:IsPosCanLink(pos, chainPath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    if not utilDataSvc:IsValidPiecePos(pos) then
        return false
    end

    local pickUpParam = self:GetCurPickUpParam()
    if not pickUpParam then
        return false
    end
    local linkCount = pickUpParam[1] or 0
    local linkMonster = pickUpParam[3] == 1

    if #chainPath <= 1 then
        if utilDataSvc:IsPosBlockForPreviewLinkLine(pos, linkMonster) then
            return false
        end
        return true
    end

    local isMaxLink = (#chainPath - 1 >= linkCount)

    --拿到 chainPath 最后一个坐标
    local lastPos = chainPath[#chainPath]
    local isPosMonster = false
    if linkMonster then
        isPosMonster = (utilDataSvc:GetMonsterAtPos(lastPos) ~= nil)
        if utilDataSvc:GetMonsterAtPos(pos) then
            isMaxLink = (#chainPath - 2 >= linkCount)
        end
    end
    local isPosExit = utilDataSvc:IsPosExit(lastPos)
    local isPosDimensionDoor = utilDataSvc:IsPosDimensionDoor(lastPos)

    --连线的最后一个点是：达到上限或怪或出口或任意门，且新的点不在已连线的路径中，则不能连
    local isBreakLastPos = isMaxLink or isPosMonster or isPosExit or isPosDimensionDoor
    if isBreakLastPos and not table.icontains(chainPath, pos) then
        return false
    end

    if utilDataSvc:IsPosBlockForPreviewLinkLine(pos, linkMonster) then
        return false
    end

    return true
end

---@param e Entity
---@param chainPath Vector2[]
function PreviewLinkLineService:CalcReplaceChainPreviewParamsPet1502051(e, chainPath)
    --从这个人身上取第一个连锁技，使用这个连锁技的预览参数计算
    ---@type SkillInfoComponent
    local skillInfoCmpt = e:SkillInfo()
    local chainRule = skillInfoCmpt._chainSkillIDSelector:GetRule()
    local firstChainRule = chainRule[1]
    local chainSkillID = firstChainRule.Skill

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")

    ---@type SkillConfigData 连锁技数据
    local firstChainConfig = configSvc:GetSkillConfigData(chainSkillID)

    local previewType = firstChainConfig:GetSkillPreviewType()
    if previewType ~= SkillPreviewType.Pet1502051Chain then
        return
    end

    local previewParam = firstChainConfig:GetSkillPreviewParam()
    local rangeSkillID = previewParam.SkillID
    local rangeIncludeTrap = previewParam.IsTrapIncluded
    local includedTrapType = previewParam.TrapType

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(rangeSkillID)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local extraCount = 0
    for _, v2 in ipairs(chainPath) do
        if utilData:FindPieceElement(v2) == PieceType.Blue then
            ---@type SkillScopeResult
            local scopeResult = scopeCalc:ComputeScopeRange(
                    skillConfigData:GetSkillScopeType(),
                    skillConfigData:GetSkillScopeParam(),
                    v2,
                    e:BodyArea():GetArea(),
                    e:GetGridDirection(),
                    SkillTargetType.Monster,
                    e:GetGridPosition(),
                    e
            )

            local targetSelector = self._world:GetSkillScopeTargetSelector()
            --注意：需求明确要求【普攻过程中被队友击杀者参与计算】因此此处不论死活，此为故意要求
            local tEntityID = targetSelector:_SelectMonsterDeadOrAlive(
                    e,
                    scopeResult,
                    rangeSkillID,
                    skillConfigData:GetSkillTargetTypeParam()
            ) or {}

            if #tEntityID == 0 then
                if rangeIncludeTrap and includedTrapType then
                    -- 为啥这地方写的是个map........
                    local selected = targetSelector:_SelectTrap(
                            e,
                            scopeResult,
                            rangeSkillID,
                            skillConfigData:GetSkillTargetTypeParam(),
                            false
                    ) or {}

                    tEntityID = {}
                    for id, _ in pairs(selected) do
                        table.insert(tEntityID, id)
                    end

                    for _, id in ipairs(tEntityID) do
                        local trapEntity = self._world:GetEntityByID(id)
                        ---@type TrapRenderComponent
                        local cTrap = trapEntity:TrapRender()
                        local trapType = cTrap:GetTrapType()
                        if table.icontains(includedTrapType, trapType) then
                            extraCount = extraCount + 1
                            Log.info("CalcReplaceChainPreviewParamsPet1502051: trap in range", v2)
                            break
                        end
                    end
                end
            else
                extraCount = extraCount + 1
                Log.info("CalcReplaceChainPreviewParamsPet1502051: monster in range", v2)
            end
        end
    end

    Log.info("CalcReplaceChainPreviewParamsPet1502051: extra count: ", extraCount)

    local fix = e:RenderAttributes():GetAttribute("ChainSkillReleaseFix") or 0
    local chainCountMul = e:RenderAttributes():GetAttribute("ChainSkillReleaseMul") or 0

    ---@type UtilCalcServiceShare
    local utilCalc = self._world:GetService("UtilCalc")

    local chainCount, useless = utilCalc:GetChainDamageRateAtIndex(chainPath, #chainPath)

    local fixedChainCount = math.ceil((chainCount + fix) * (1 + chainCountMul)) + extraCount
    local chainExtraFix = utilData:GetEntityBuffValue(e, "ChangeExtraChainSkillReleaseFixForSkill") or {}
    local skillID = skillInfoCmpt:GetChainSkillConfigID(fixedChainCount, chainExtraFix)

    Log.info("CalcReplaceChainPreviewParamsPet1502051: fixed chain count: ", fixedChainCount)
    Log.info("CalcReplaceChainPreviewParamsPet1502051: skillID: ", skillID)

    if skillID == 0 then
        return
    end

    local replacedChainSkillConfig = configSvc:GetSkillConfigData(skillID)

    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScopeForChainSkillPreview(replacedChainSkillConfig, chainPath[#chainPath], e)

    ---@type SkillScopeTargetSelector
    local selector = SkillScopeTargetSelector:New(self._world)
    local skillTargetType = replacedChainSkillConfig:GetSkillTargetType()

    local entityIDArray = selector:DoSelectSkillTarget(e, skillTargetType, scopeResult, chainSkillID)

    local attackRange = scopeResult:GetAttackRange()
    for _, gridPos in ipairs(attackRange) do
        for _, targetEntityID in ipairs(entityIDArray) do
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            ---@type GridLocationComponent
            local gridLocationCmpt = targetEntity:GridLocation()
            ---@type BodyAreaComponent
            local bodyAreaCmpt = targetEntity:BodyArea()
            local bodyAreaList = bodyAreaCmpt:GetArea()

            for i, bodyArea in ipairs(bodyAreaList) do
                local curBodyPos = Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                if curBodyPos == gridPos then
                    scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                end
            end
        end
    end

    return skillID, scopeResult
end
