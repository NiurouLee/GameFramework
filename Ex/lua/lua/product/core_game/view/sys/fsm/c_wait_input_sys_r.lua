--[[------------------------------------------------------------------------------------------
    ClientWaitInputSystem_Render：客户端实现的等待输入表现
]] --------------------------------------------------------------------------------------------

require "wait_input_system"

---@class ClientWaitInputSystem_Render:WaitInputSystem
_class("ClientWaitInputSystem_Render", WaitInputSystem)
ClientWaitInputSystem_Render = ClientWaitInputSystem_Render

function ClientWaitInputSystem_Render:_DoRenderStopPortalPreview(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local hasDoor = utilDataSvc:HasDimensionDoor()
    if not hasDoor then
        return
    end

    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
    sPreviewSkill:StopPreviewChainSkill(TT)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
end

function ClientWaitInputSystem_Render:_DoRenderPieceAnimation(TT)
    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    if piece_service then
        piece_service:RefreshPieceAnim()
        piece_service:RefreshMonsterAreaOutLine(TT)
    end
end

function ClientWaitInputSystem_Render:_DoRenderGuidePlayer(TT)
    -- 新手引导触发 玩家行动
    local guideService = self._world:GetService("Guide")

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    local guideTaskId
    if utilStatSvc:GetStatIsRoundAuroraTime() then
        guideTaskId = guideService:Trigger(GameEventType.GuideRound, GuideRoundTurn.AuroraTime)
    end

    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
end

function ClientWaitInputSystem_Render:_DoRenderWaitStun(TT)
    YIELD(TT, BattleConst.StunWaitTime)
end

--大地图模式用的函数
function ClientWaitInputSystem_Render:_DoRenderCameraFollowHero()
    -- local camaraService = self._world:GetService("Camera")
    -- ---@type UtilDataServiceShare
    -- local utilDataSvc = self._world:GetService("UtilData")
    -- camaraService:CameraFollowHero(utilDataSvc:GetLastBoardCenterPos(), utilDataSvc:GetBoardCenterPos())
end

function ClientWaitInputSystem_Render:_DoRenderShowPlayerTurnInfo(TT, teamEntity)
    if teamEntity == nil then
        return
    end

    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        self:_DoRenderShowLocalPlayerTurnUI(TT, teamEntity)
    else
        self:_DoRenderShowRemotePlayerTurnUI(TT, teamEntity)
    end
end

function ClientWaitInputSystem_Render:_DoRenderShowLocalPlayerTurnUI(TT, teamEntity)
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    if innerStoryService:CheckStoryBanner(StoryShowType.WaveAndRoundBeginPlayerRound) then
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
    innerStoryService:CheckStoryTips(StoryShowType.WaveAndRoundBeginPlayerRound)

    ---检查是否需要显示箭头
    local showArrow = self:_IsShowArrow()
    if showArrow == true then
        ---@type CanMoveArrowService
        local arrowService = self._world:GetService("CanMoveArrow")
        arrowService:ShowCanMoveArrow(true)
    end

    -- 检测触发弱连线引导
    ---@type  GuideServiceRender
    local guideService = self._world:GetService("Guide")
    guideService:HandleWaitInputTrigger()
    guideService:ShowGuideWeakLine(TT)

    --玩家被围困 提示双击原地
    self:_DoRenderShowHideBesiegedTips(TT, teamEntity)

    ---这个地方等于是强制 取出所有的Pet，然后把头像缩进去，解决MSG25412
    local petEntities = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID):GetEntities()
    for _, e in ipairs(petEntities) do
        ---@type PetPstIDComponent
        local pstIDCmpt = e:PetPstID()
        local pstID = pstIDCmpt:GetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.InOutQueue, pstID, false)
    end
end

function ClientWaitInputSystem_Render:_DoRenderShowRemotePlayerTurnUI(TT)
    --TODO 黑拳赛UI没有需求
end

function ClientWaitInputSystem_Render:_DoRenderShowPetHeadUI(TT)
    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowPetInfo, 1)
    else
        --TODO 黑拳赛UI没有需求
    end
end

function ClientWaitInputSystem_Render:_IsShowArrow()
    ---如果已经切出等待输入状态，就可以不显示箭头等逻辑
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curMainStateID = utilDataSvc:GetCurMainStateID()

    if curMainStateID ~= GameStateID.WaitInput then
        Log.notice("has exit wait input state,should not show arrow")
        return false
    end

    ---@type GridTouchComponent
    local gridTouchComponent = self._world:GridTouch()
    local touchState = gridTouchComponent:GetGridTouchStateID()
    if touchState == GridTouchStateID.BeginDrag or touchState == GridTouchStateID.Drag then
        Log.notice("drag,should not show arrow")
        return false
    end

    return true
end

--极光时刻表现
function ClientWaitInputSystem_Render:_DoRenderShowAuroraTime(TT)
    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    if not utilStatSvc:GetStatIsRoundAuroraTime() then
        return
    end
    local isReEnter = utilStatSvc:GetStatIsReEnterAuroraTime()
    if not isReEnter then
        if battleRenderCmpt:IsWaitInputAuroraTime() then
            return
        end
    else
        if battleRenderCmpt:IsReEnterAuroraTimePlayed() then
            return
        end
    end
    self:_DoRenderGuidePlayer(TT)

    battleRenderCmpt:SetWaitInputAuroraTime(true)

    if isReEnter then
        self:_DoRenderCloseAuroraTime(TT)
    end
    local playbuffsvc = self._world:GetService("PlayBuff")
    playbuffsvc:PlayBuffView(TT, NTEnterAuroraTime:New())
    ---@type RenderEntityService
    local renderEntitySvc = self._world:GetService("RenderEntity")
    renderEntitySvc:ShowUITurnTips(true, true)

    self._world:MainCamera():SetAuroaTimeObjActive(true)
    self._world:MainCamera():ToggleAuroraTime(true)
    --背景显示星空
    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideAuroraTime, true)
    if isReEnter then
        battleRenderCmpt:SetReEnterAuroraTimePlayed(true)
    end
    YIELD(TT, BattleConst.RefreshPetInfoTick)
end

--玩家被围困 提示双击原地
function ClientWaitInputSystem_Render:_DoRenderShowHideBesiegedTips(TT, teamEntity)
    local playerPos = teamEntity:GetGridPosition()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local listTotalData = ComputeScopeRange.ComputeRange_SquareRing(playerPos, 1, 1)
    local listAttackData = {}
    for key, value in pairs(listTotalData) do
        local isValidGrid = (not utilDataSvc:IsPosBlockLinkLineForChain(value))
        if isValidGrid == true then
            listAttackData[#listAttackData + 1] = value
        end
    end

    if #listAttackData == 0 then
        self._world:EventDispatcher():Dispatch(GameEventType.ShowHideBesiegedTips, true)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.ShowHideBesiegedTips, false)
    end
end

function ClientWaitInputSystem_Render:_DoRenderCompareHPLog(TT)
    ---暂时关闭，等稳定再打开
    local openException = false
    --比对逻辑表现血量
    self:_CompareLogicRenderHP(openException)
end

function ClientWaitInputSystem_Render:_DoRenderPlayWaitInputBuff(TT)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTWaitInput:New())
end

function ClientWaitInputSystem_Render:_DoRenderComparePieceType(TT)
    if not EDITOR then
        return
    end

    local cPreviewEnv = self._world:GetPreviewEntity():PreviewEnv()

    local cPreviewPieceTypeIndexMap = cPreviewEnv._pieceTypes
    local cPreviewAllPiece = cPreviewEnv:GetAllPieceType()

    local previewPieceDiff = {}
    for posIndex, pieceType in pairs(cPreviewPieceTypeIndexMap) do
        local x = posIndex // 100
        local y = posIndex - (x * 100)

        if (not cPreviewAllPiece[x]) then
            table.insert(previewPieceDiff, { posIndex = posIndex, err = "not found in all piece table" })
        elseif cPreviewAllPiece[x][y] ~= pieceType then
            table.insert(
                previewPieceDiff,
                {
                    posIndex = posIndex,
                    err = string.format(
                        "different color: _pieceType->%s, _allPieceTable->%s",
                        tostring(pieceType),
                        tostring(cPreviewAllPiece[x][y])
                    )
                }
            )
        end
    end

    local piecePosList = {}
    local tePiece = self._world:GetGroupEntities(self._world.BW_WEMatchers.Piece)
    for _, ePiece in ipairs(tePiece) do
        --这里不判断其他棋盘面的格子颜色
        if not ePiece:HasOutsideRegion() then
            local cPiece = ePiece:Piece()
            local pos = ePiece:GetGridPosition()
            local pieceType = cPiece:GetPieceType()
            local previewEnvType = cPreviewEnv:GetPieceType(pos)
            if pieceType ~= previewEnvType then
                if pieceType == 0 and previewEnvType == 5 then
                    Log.fatal("player at any piece pos")
                else
                    table.insert(
                        previewPieceDiff,
                        {
                            posIndex = pos:Pos2Index(),
                            err = string.format(
                                "different piece color: piece->%s, previewEnv->%s",
                                pieceType,
                                previewEnvType
                            )
                        }
                    )
                end
            end
            if not table.icontains(piecePosList, pos) then
                table.insert(piecePosList, pos)
            else
                table.insert(
                    previewPieceDiff,
                    {
                        posIndex = pos:Pos2Index(),
                        err = "piece entity pos repeat"
                    }
                )
            end
        end
    end

    if #previewPieceDiff ~= 0 then
        for _, exception in ipairs(previewPieceDiff) do
            Log.error(
                "[PieceTypeDiff] err: posIndex=",
                tostring(exception.posIndex),
            " desc: ",
                tostring(exception.err)
            )
        end
        Log.exception("[PieceTypeDiff] PieceType conflict. Check log for more information. ")
    end

end

function ClientWaitInputSystem_Render:ClearPreviewChainPathData()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    previewChainPathCmpt:ClearPreviewChainPath()
end

function ClientWaitInputSystem_Render:_DoRenderAutoFight(TT, teamEntity)
    local svcTest = self._world:GetService("AutoTest")
    if svcTest and svcTest:IsRunning() then
        return
    end
    local svc = self._world:GetService("AutoFight")
    GameGlobal.TaskManager():CoreGameStartTask(svc.AutoFight, svc, teamEntity)
end

function ClientWaitInputSystem_Render:_DoRenderSetPreviewTeam(teamEntity)
    self._world:Player():SetPreviewTeamEntity(teamEntity)
end

function ClientWaitInputSystem_Render:_DoRenderPlayerBuffDelayed(TT, teamEntity)
    YIELD(TT, BattleConst.PlayerStunRenderYieldTimeMS)

    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:PlayPlayerTurnStartBuff(TT, teamEntity, nil, true)
end
