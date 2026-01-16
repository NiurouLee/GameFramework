--[[------------------------------------------------------------------------------------------
    GuideServiceRender 处理实体的公共服务对象 
]] --------------------------------------------------------------------------------------------

---@class GuideServiceRender:BaseService
_class("GuideServiceRender", BaseService)
GuideServiceRender = GuideServiceRender

function GuideServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._eventListener = GuideServiceListenerRender:New(self)
end

function GuideServiceRender:Initialize()
    self._eventListener:RegEvents()
end

function GuideServiceRender:Dispose()
    self._eventListener:UnregEvents()
    self:FinishGuideShadowEntity(true)
end

function GuideServiceRender:SetNeedYield(need)
    if NOGUIDE then
        self.needYield = false
    else
        self.needYield = need
    end
end

---局内引导触发
-- self.needYield 1.不是当前关卡当前回合不触发
--                 2.不是激活引导不触发
--                3.不是特定guideType不触发
function GuideServiceRender:Trigger(gameEventType, ...)
    local param = {...}
    self.taskId =
        TaskManager:GetInstance():CoreGameStartTask(
        function(TT)
            if gameEventType == GameEventType.GuideBattleStart then -- 战斗开始触发（刷怪前）
                local levelId = self:_GetLevelID()
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    levelId,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.GuideBattleFinish then --战斗结束后，结算开始前
                local levelId = self:_GetLevelID()
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    levelId,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.GuideRound then -- 某回合触发
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                local mOrEAction = param[1]
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    curRoundIndex,
                    mOrEAction,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.GuidePlayerHandleFinish then -- 玩家操作结束（播放动画之前）
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                local playerHandleType = param[1]
                local petTempId = self:GetPetTempIdByEntry(param[2])
                if playerHandleType == GuidePlayerHandle.MainSkillFinish then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Button)
                end
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    curRoundIndex,
                    playerHandleType,
                    petTempId,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.GuidePlayerSkillFinish then --  释放技能完毕（播放动画之后，已过期）
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                local levelId = self:_GetLevelID()
                local PlaySkillFinishType = param[1]
                local petTempId = self:GetPetTempIdByEntry(param[2])
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    curRoundIndex,
                    PlaySkillFinishType,
                    petTempId,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.GuidePlayerSkillRealFinish then --  释放技能完毕（播放动画之后）
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                local levelId = self:_GetLevelID()
                local PlaySkillFinishType = param[1]
                local petTempId = self:GetPetTempIdByEntry(param[2])
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    curRoundIndex,
                    PlaySkillFinishType,
                    petTempId,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.ShowGuideCancelArea then --  显示取消连线按钮
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            elseif gameEventType == GameEventType.ShowGuidePowerReady then --  能量满
                local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
                local petTempId = self:GetPetTempIdByEntry(param[1])
                self._eventDispatcher:Dispatch(
                    gameEventType,
                    curLevelID,
                    curWaveIndex,
                    function(needYield)
                        self:SetNeedYield(needYield)
                    end
                )
            end
            if NOGUIDE then
                return
            end
            while self.needYield do
                YIELD(TT)
            end
        end
    )
    return self.taskId
end

---当前关卡状态信息
function GuideServiceRender:GetCurLevelState()
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")

    -- 当前关卡id
    local curLevelID = self:_GetLevelID()
    ---当前的波次
    local curWaveIndex = utilStatSvc:GetStatCurWaveIndex()
    ---当前是第几次连线
    local curRoundIndex = utilStatSvc:GetStatCurWaveRoundNum()

    return curLevelID, curWaveIndex, curRoundIndex
end

function GuideServiceRender:_GetLevelID()
    local _configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelData = _configService:GetLevelConfigData()
    local levelID = levelData:GetLevelID()
    return levelID
end

function GuideServiceRender:GetPetTempIdByEntry(entry)
    if not entry then
        return 0
    end

    ---@type PetPstIDComponent
    local petPstIDCmpt = entry:PetPstID()
    if petPstIDCmpt then
        local petTempId = petPstIDCmpt:GetTemplateID()
        return petTempId
    end

    return 0
end

----------------------------- 强连线引导 ↓------------------------------------
function GuideServiceRender:IsGuidePathInvokeType()
    return self:GetInvokeType() == GuideInvokeType.GuidePath
end

function GuideServiceRender:GetInvokeType()
    local reBoard = self._world:GetRenderBoardEntity()
    local guidePathCmpt = reBoard:GuidePath()
    return guidePathCmpt and guidePathCmpt:GetInvokeType() or GuideInvokeType.None
end

-- cfg_inner_guide
function GuideServiceRender:ShowGuideLine(guideParam)
    self:_ShowGuideLine(GuideRefreshType.StartGuidePath, guideParam)
end

---在需要引导的时刻调用此方法
function GuideServiceRender:_ShowGuideLine(guideRefreshType, guideParam)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local curGuideRefreshType = guidePathCmpt:GetGuideRefreshType()
    if curGuideRefreshType ~= GuideRefreshType.StartGuidePath then
        if guideParam then
            local path = guideParam.LogicParams
            guidePathCmpt:SetGuidePath(path)
            guidePathCmpt:SetInvokeType(guideParam.InvokeType)
        end
        guidePathCmpt:SetGuideRefreshType(guideRefreshType)
        reBoard:ReplaceGuidePath()
        self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, true)
    end
end

---处理相机回到正常点后的处理流程
function GuideServiceRender:HandleCameraMoveToNormalTrigger()
    local invokeType = self:GetInvokeType()
    if invokeType ~= GuideInvokeType.GuidePath then
        return false
    end
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()

    local finishGuide = self:CheckGuidePathFinish(chainPath)
    if finishGuide == false then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        previewEntity:ReplacePreviewChainPath({}, PieceType.None, PieceType.None)

        self._eventDispatcher:Dispatch(GameEventType.FlushPetChainSkillItem, true, 0, nil)

        self:_ReShowGuideLine()
        return true
    end

    return false
end

---划线引导是否结束
---@param chainPath Array 当前的划线队列
function GuideServiceRender:CheckGuidePathFinish(chainPath)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local guidePath = guidePathCmpt:GetGuidePath()
    if chainPath == nil or guidePath == nil then
        return true
    end

    if #chainPath ~= #guidePath then
        return false
    end

    for index, pathPoint in ipairs(chainPath) do
        local curGuidePoint = guidePath[index]
        if curGuidePoint ~= pathPoint then
            return false
        end
    end

    return true
end

function GuideServiceRender:_ReShowGuideLine()
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local curGuideRefreshType = guidePathCmpt:GetGuideRefreshType()
    guidePathCmpt:SetGuideRefreshType(GuideRefreshType.RestartGuidePath)
    reBoard:ReplaceGuidePath()
end

function GuideServiceRender:HandleCameraMoveToFocusTrigger()
    local invokeType = self:GetInvokeType()
    if invokeType ~= GuideInvokeType.GuidePath then
        return
    end
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local curGuideRefreshType = guidePathCmpt:GetGuideRefreshType()
    if curGuideRefreshType ~= GuideRefreshType.ShowGuideLine then
        guidePathCmpt:SetGuideRefreshType(GuideRefreshType.ShowGuideLine)
        reBoard:ReplaceGuidePath()
    end
end

function GuideServiceRender:HandleWaitInputTrigger()
    local invokeType = self:GetInvokeType()
    if invokeType == GuideInvokeType.GuidePath then
        ---@type GridTouchComponent
        local gridTouchCmpt = self._world:GridTouch()
        local isTouchPlayer = gridTouchCmpt:IsTouchPlayer()
        --只要开始划线，就不能启动引导
        if isTouchPlayer ~= true then
            self:_ShowGuideLine(GuideRefreshType.RestartGuidePath)
        end
    end
end

---返回值代表是否可以继续执行原有流程
function GuideServiceRender:HandleBeginDragTrigger(newGridPos)
    self:PauseGuideWeakLine()
    local invokeType = self:GetInvokeType()
    if invokeType == GuideInvokeType.GuidePath then
        local reBoard = self._world:GetRenderBoardEntity()
        ---@type GuidePathComponent
        local guidePathCmpt = reBoard:GuidePath()
        guidePathCmpt:SetGuideRefreshType(GuideRefreshType.ShowGuideLine)
        reBoard:ReplaceGuidePath()
        return self:_CheckGuidePathHasPos(newGridPos)
    end

    return true
end

function GuideServiceRender:_CheckGuidePathHasPos(gridPos)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local guidePath = guidePathCmpt:GetGuidePath()
    if guidePath == nil then
        return false
    end

    for _, v in ipairs(guidePath) do
        if v == gridPos then
            return true
        end
    end

    return false
end

function GuideServiceRender:HandleEndDragTrigger()
    local invokeType = self:GetInvokeType()
    if invokeType == GuideInvokeType.GuidePath then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        ---@type PreviewChainPathComponent
        local previewChainPathCmpt = previewEntity:PreviewChainPath()

        local chainPath = previewChainPathCmpt:GetPreviewChainPath()

        local reBoard = self._world:GetRenderBoardEntity()
        ---@type GuidePathComponent
        local guidePathCmpt = reBoard:GuidePath()

        local finishGuide = self:CheckGuidePathFinish(chainPath)
        if finishGuide == true then
            ---引导结束
            guidePathCmpt:SetInvokeType(GuideInvokeType.None)
            guidePathCmpt:SetGuideRefreshType(GuideRefreshType.StopGuidePath)
            guidePathCmpt:SetGuidePath({})
            reBoard:ReplaceGuidePath()
            self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, false)
            ---重置当前引导数据
            self._eventDispatcher:Dispatch(GameEventType.FinishGuideStep, GuideType.Line)
        else
            ToastManager.ShowToast(StringTable.Get("str_guide_link_warn"))
            local match = GameGlobal.GetModule(MatchModule)
            local enterData = match:GetMatchEnterData()
            if enterData._match_type == MatchType.MT_Mission then --主线
                local missionID = enterData:GetMissionCreateInfo().mission_id
                GameGlobal.UAReportForceGuideEvent(
                    "FightChainDone",
                    {
                        missionID,
                        previewChainPathCmpt:GetPreviewPieceType(),
                        chainPath and #chainPath or 0,
                        "",
                        0
                    }
                )
            end

            return false
        end
    end

    return true
end

--endregion
---返回值代表是否可以继续执行原有流程
function GuideServiceRender:HandleDragTrigger(newGridPos)
    local invokeType = self:GetInvokeType()
    if invokeType ~= GuideInvokeType.GuidePath then
        return true
    end
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    local newPosIndex = #chainPath + 1
    return self:_CheckChainPosMatchGuidPath(newPosIndex, newGridPos)
end

---检测当前连线的点是否和要引导的路径匹配
function GuideServiceRender:_CheckChainPosMatchGuidPath(index, gridPos)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local guidePath = guidePathCmpt:GetGuidePath()
    if guidePath == nil then
        return false
    end

    if #guidePath < index then
        return false
    end

    local guidePoint = guidePath[index]
    if guidePoint ~= gridPos then
        return false
    end

    return true
end

function GuideServiceRender:HandleDoubleClickTrigger()
    local invokeType = self:GetInvokeType()
    if invokeType ~= GuideInvokeType.None then
        return true
    end
    return false
end

----------------------------- 强连线引导 ↑------------------------------------

----------------------------- 弱连线引导 ↓ ------------------------------------
function GuideServiceRender:CanShowGuideWeakLine()
    local invokeType = self:GetInvokeType()
    return invokeType ~= GuideInvokeType.GuidePath
    --  and self._curChaper <= 2
end

-- 检查显示弱连线的必要条件
function GuideServiceRender:CheckGuideWeakLine()
    if not self:CanShowGuideWeakLine() then
        return false
    end
    local curLevelID, curWaveIndex, curRoundIndex = self:GetCurLevelState()
    local levelConfigData = ConfigServiceHelper.GetLevelConfigData()

    local data = levelConfigData:GetLevelWeakLineData()
    if not data then
        return false
    end
    if data.dontShowRounds then
        for _, value in ipairs(data.dontShowRounds) do
            if value.wave == curWaveIndex and value.round == curRoundIndex then
                return false
            end
        end
    end
    return true
end

--127.0.0.1
--- 检测触发弱连线引导
function GuideServiceRender:ShowGuideWeakLine(TT)
    if not self:CheckGuideWeakLine() then
        return
    end
    local reBoard = self._world:GetRenderBoardEntity()

    local autoFightService = self._world:GetService("AutoFight")
    local guidePathCmpt = reBoard:GuideWeakPath()
    local curGuideRefreshType = guidePathCmpt:GetGuideRefreshType()
    if curGuideRefreshType == GuideRefreshType.PauseGuidePath then
        -- ---@type GuidePathComponent
        local path = guidePathCmpt:GetGuidePath()
        guidePathCmpt:SetGuideRefreshType(GuideRefreshType.RestartGuidePath)
        guidePathCmpt:SetGuidePath(path)
        reBoard:ReplaceGuideWeakPath()
    else
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        local path = autoFightService:GetAutoChainPath(TT, teamEntity)
        guidePathCmpt:SetGuideRefreshType(GuideRefreshType.StartGuidePath)
        guidePathCmpt:SetGuidePath(path)
        reBoard:ReplaceGuideWeakPath()
    end
end

---@type PauseGuideWeakLine
function GuideServiceRender:PauseGuideWeakLine()
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    local guidePathCmpt = reBoard:GuideWeakPath()
    guidePathCmpt:SetGuideRefreshType(GuideRefreshType.PauseGuidePath)
    reBoard:ReplaceGuideWeakPath()
end

-- 弱连线引导达成
function GuideServiceRender:FinishGuideWeakLine()
    -- 强连线存在 或者章节大于2 return
    -- if not self:CanShowGuideWeakLine() then
    --     return
    -- end
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuideWeakPathComponent
    local guidePathCmpt = reBoard:GuideWeakPath()
    guidePathCmpt:SetGuideRefreshType(GuideRefreshType.StopGuidePath)
    guidePathCmpt:SetGuidePath({})
    reBoard:ReplaceGuideWeakPath()
end
----------------------------- 弱连线引导 ↑ ------------------------------------

----------------------------- UI引导↓--------------------------------
---返回值代表外部流程是否继续
function GuideServiceRender:HandleActiveSkillTrigger()
    if true then
        return true
    end
end

----------------------------- UI引导↑--------------------------------

----------------------------- 格子引导 ↓------------------------------------
function GuideServiceRender:ShowGuidePiece(guideParam)
    local invokeType = guideParam and guideParam.InvokeType
    if
        invokeType == GuideInvokeType.GuidePiece or invokeType == GuideInvokeType.GuidePieceInfinity or 
            GuideInvokeType.GuidePieceInfinityDontYield
     then -- 格子引导
        local posList = guideParam.LogicParams
        local grids = {}
        for _, value in ipairs(posList) do
            table.insert(grids, Vector2(value[1], value[2]))
        end
        TaskManager:GetInstance():CoreGameStartTask(self.CreateGuidePieceEntity, self, grids, invokeType)
        if invokeType == GuideInvokeType.GuidePiece then
            self:ChangeGridColor(grids)
            GameGlobal.Timer():AddEvent(
                3000,
                function()
                    -- GameGlobal.UIStateManager():UnLock("GuidePieceLock")
                    self:ResetNormal()
                    self:DestroyGuidePieceEntity()
                    self._eventDispatcher:Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                end
            )
        end
    end
end

---销毁格子引导entity
function GuideServiceRender:DestroyGuidePieceEntity()
    local guidePieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuidePiece)
    local remove_list = {}
    for _, entity in ipairs(guidePieceGroup:GetEntities()) do
        table.insert(remove_list, entity)
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
    self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, false)
end

-- 删除所有的格子引导
function GuideServiceRender:ChangeGridColor(grids)
    local pieceService = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local connect_piece_grid_list = grids
    local count = #connect_piece_grid_list
    if count > 0 then
        ---回到原点，联通区为零所有格子恢复正常显示
        local piece_group = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
        for _, piece_entity in ipairs(piece_group:GetEntities()) do
            local grid_location_cmpt = piece_entity:GridLocation()
            local is_blocked = utilDataSvc:IsPosBlockLinkLineForChain(grid_location_cmpt.Position)
            if not is_blocked then
                pieceService:SetPieceAnimDark(grid_location_cmpt.Position)
            end
        end
        for k, pos in pairs(connect_piece_grid_list) do
            local is_blocked = utilDataSvc:IsPosBlockLinkLineForChain(pos)
            if not is_blocked then
                pieceService:SetPieceAnimNormal(pos)
            end
        end
    end
end

---生成包裹格子特效
function GuideServiceRender:CreateGuidePieceEntity(TT, grids, invokeType)
    GuideHelper.GuideLoadLock(false, "Piece")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local activeSkill = invokeType ~= GuideInvokeType.GuidePiece
    local guidePieceEntity = self:_CreateGuidePieceEntity(activeSkill)
    local guidePieceCmp = guidePieceEntity:GuidePiece()
    guidePieceCmp:SetValidGrids(grids)
    guidePieceCmp:SetUnValidGrids(boardServiceRender:GetExceptGrids(grids))
    guidePieceEntity:ReplaceGuidePiece()
    --YIELD(TT)
    if guidePieceEntity and guidePieceEntity:View() then
        local go = guidePieceEntity:View():GetGameObject()
        if go then
            ---@type UnityEngine.LineRenderer
            local lineRender = go.transform:GetComponent("LineRenderer")
            ---@type RenderEntityService
            local renderEntityService = self._world:GetService("RenderEntity")
            local packageGrids = renderEntityService:GetGridPackagePosList(grids)
            local count = #packageGrids
            lineRender.positionCount = count
            for index = 1, count do
                local realPos = boardServiceRender:GridPos2RenderPos(packageGrids[index])
                lineRender:SetPosition(index - 1, realPos)
            end
            if activeSkill and #grids > 0 then
                go.transform.position = boardServiceRender:GridPos2RenderPos(grids[1])
            end
            self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, true)
        end
    end
end

function GuideServiceRender:_CreateGuidePieceEntity(activeSkill)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local dotEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.GuidePiece)
    if activeSkill then
        dotEntity:ReplaceAsset(NativeUnityPrefabAsset:New("Eff_Ingame_jnyd_kuang.prefab", true))
    end
    return dotEntity
end

function GuideServiceRender:ResetNormal()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pieceService = self._world:GetService("Piece")
    local piece_group = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, piece_entity in ipairs(piece_group:GetEntities()) do
        local grid_location_cmpt = piece_entity:GridLocation()
        local is_blocked = utilDataSvc:IsPosBlockLinkLineForChain(grid_location_cmpt.Position)
        if not is_blocked then
            pieceService:SetPieceAnimNormal(grid_location_cmpt.Position)
        end
    end
end

function GuideServiceRender:IsValidGuidePiecePos(x, y)
    local guidePieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuidePiece)
    local isGuide = false
    local es = guidePieceGroup:GetEntities()
    if guidePieceGroup and table.count(es) <= 0 then
        return true, isGuide
    end
    for _, e in ipairs(es) do
        local guidePieceCmp = e:GuidePiece()
        ---@type GuidePieceComponent
        for _, gridPos in ipairs(guidePieceCmp:GetValidGrids()) do
            if x == gridPos.x and y == gridPos.y then
                isGuide = true
                return true, isGuide
            end
        end
        return false, isGuide
    end
    return false, isGuide
end

---@return boolean 是否是格子引导
---@return boolean 当前点击格子是否有效
function GuideServiceRender:IsGuideAndPieceValid(x, y)
    local guidePieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuidePiece)
    local es = guidePieceGroup:GetEntities()
    if guidePieceGroup and table.count(es) <= 0 then
        return false, false
    end
    for _, e in ipairs(es) do
        local guidePieceCmp = e:GuidePiece()
        ---@type GuidePieceComponent
        for _, gridPos in ipairs(guidePieceCmp:GetValidGrids()) do
            if x == gridPos.x and y == gridPos.y then
                return true, true
            end
        end
    end
    return true, false
end
----------------------------- 格子引导 ↑------------------------------------
---
-------------------------------buff ------------------------

function GuideServiceRender:ShowBuff(buffId)
end
--------------------------------buff
function GuideServiceRender:ShowEntity(guideParam)
    local target, entity, entityType = self:_ShowEntity(guideParam, true)
    if not entity then
        return
    end
    local UI = GameGlobal.UIStateManager()
    UI:ShowDialog(
        "UIGuideModelController",
        target,
        entity:GetID(),
        entityType,
        function()
            self:ResetShowEntity("UIGuideModelController")
        end
    )
end

function GuideServiceRender:ResetShowEntity(controllerName)
    self._world:MainCamera():EnableEffectCamera(true)
    local effCamera = self._world:MainCamera():EffectCamera()
    if effCamera then
        local UI = GameGlobal.UIStateManager()
        local camera = UI:GetControllerCamera(controllerName)
        local targetDepth = camera.depth - 1
        self.effDepth = effCamera.depth
        effCamera.depth = targetDepth
    -- effCamera.depth = 30
    end
end

function GuideServiceRender:_ShowEntity(guideParam, createShadow)
    local entityType = guideParam[1]
    local cfgId = guideParam[2]
    ---@type Entity
    local entity
    if entityType == GuideModelType.Monster or entityType == GuideModelType.ChessMonster then
        local _group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(_group:GetEntities()) do
            local monsterId = e:MonsterID():GetMonsterID()
            if monsterId == cfgId then
                entity = e
                break
            end
        end
    elseif entityType == GuideModelType.Trap then
        local _group = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        for _, e in ipairs(_group:GetEntities()) do
            local monsterId = e:TrapRender():GetTrapID()
            if monsterId == cfgId then
                entity = e
                break
            end
        end
    elseif entityType == GuideModelType.ChessPet then
        local _group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
        for _, e in ipairs(_group:GetEntities()) do
            ---@type ChessPetComponent
            local chessPetCmpt = e:ChessPet()
            local chessPetID = chessPetCmpt:GetChessPetID()
            if chessPetID == cfgId then
                entity = e
                break
            end
        end
    end
    if not entity then
        return nil, nil, nil
    end
    if createShadow then
        self.shadowEntity = self:CreateGuideGhostEntity(entityType, entity)
    end
    local target = entity:View():GetGameObject().transform
    return target, entity, entityType
end
--全息投影
function GuideServiceRender:CreateGuideGhostEntity(entityType, entity)
    if not entity then
        return
    end
    ---创建一个shadow
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local ghostEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.GuideGhost)

    local enemyPos = entity:GridLocation().Position
    local enemyDir = entity:GridLocation().Direction
    local enemyOffset = entity:GridLocation().Offset

    local ghostPos = Vector2(enemyPos.x, enemyPos.y)
    local ghostDir = Vector2(enemyDir.x, enemyDir.y)
    local ghostOffset = Vector2(enemyOffset.x, enemyOffset.y)

    local prefabPath = nil
    -- 怪
    if entityType == GuideModelType.Monster or entityType == GuideModelType.ChessMonster then
        if entity:HasMonsterID() then
            local cfg_monster = Cfg.cfg_monster[entity:MonsterID():GetMonsterID()]
            local cfg_monster_class = Cfg.cfg_monster_class[cfg_monster.ClassID]
            prefabPath = cfg_monster_class.ResPath
        end
    elseif entityType == GuideModelType.Trap then
        if entity:TrapRender() then
            local cfg_trap = Cfg.cfg_trap[entity:TrapRender():GetTrapID()]
            prefabPath = cfg_trap.ResPath
        end
    elseif entityType == GuideModelType.ChessPet then
        if entity:ChessPet() then
            local cfg_chesspet = Cfg.cfg_chesspet[entity:ChessPet():GetChessPetID()]
            local cfg_chesspet_class = Cfg.cfg_chesspet_class[cfg_chesspet.ClassID]
            prefabPath = cfg_chesspet_class.ResPath
        end
    end
    if prefabPath then
        ghostEntity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabPath, false))
        ghostEntity:ReplaceBodyArea(entity:BodyArea():GetArea())
    end

    ghostEntity:ReplaceGuideGhost(entity:GetID())
    ghostEntity:SetGridLocationAndOffset(ghostPos, ghostDir, ghostOffset)
    ghostEntity:SetLocation(ghostPos + ghostOffset, ghostDir)
    ghostEntity:SetViewVisible(true)
    TaskManager:GetInstance():CoreGameStartTask(
        function(TT)
            while not ghostEntity:HasView() do
                YIELD(TT)
            end
            GameObjectHelper.SetGameObjectLayer(ghostEntity:View().ViewWrapper.GameObject, GuideConst.EffectLayer)
        end
    )
    return ghostEntity
end

function GuideServiceRender:ChangeGuideGhostLayer()
    if self.shadowEntity and self.shadowEntity:View() and self.shadowEntity:View().ViewWrapper then
        GameObjectHelper.SetGameObjectLayer(self.shadowEntity:View().ViewWrapper.GameObject, 0)
        self._world:DestroyEntity(self.shadowEntity)
    end
    self.shadowEntity = nil
end

function GuideServiceRender:FinishGuideShadowEntity(dispose)
    if not dispose and self.effDepth then
        if self._world and self._world:MainCamera() then
            self._world:MainCamera():EnableEffectCamera(false)
            local effCamera = self._world:MainCamera():EffectCamera()
            if effCamera then
                effCamera.depth = self.effDepth
            end
        end
    -- self:ChangeGuideGhostLayer()
    end
end
------------------------------------焦点引导----------------
function GuideServiceRender:ShowCircle(cfg)
    if not cfg then
        return
    end
    local circleType = cfg.type
    local gridPos = Vector2.zero
    -- 引导格子用老界面
    if circleType == GuideCircleType.Grid then
        gridPos.x = cfg.param[1]
        gridPos.y = cfg.param[2]
        GameGlobal.UIStateManager():ShowDialog("UIGuideCircleController", cfg, gridPos)
    elseif circleType == GuideCircleType.ClickGrid then
        self:_ShowClickGrid(cfg)
    else
        local targetId
        if circleType == GuideCircleType.Monster then
            local _group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
            for _, e in ipairs(_group:GetEntities()) do
                local monsterId = e:MonsterID():GetMonsterID()
                targetId = monsterId
                if monsterId == cfg.param[1] then
                    self:FindCircleCenter(gridPos, e)
                    break
                end
            end
        elseif circleType == GuideCircleType.Trap then
            local _group = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
            for _, e in ipairs(_group:GetEntities()) do
                local trapId = e:TrapRender():GetTrapID()
                targetId = trapId
                if trapId == cfg.param[1] then
                    self:FindCircleCenter(gridPos, e)
                    break
                end
            end
        end
        local entityType = GuideCircleType.Monstercfgsa
        if circleType == GuideCircleType.Monster then
            entityType = GuideModelType.Monster
        elseif circleType == GuideCircleType.Trap then
            entityType = GuideModelType.Trap
        end
        local guideParam = {}
        guideParam[1] = entityType
        guideParam[2] = targetId
        local target, entity, entityType = self:_ShowEntity(guideParam)
        GameGlobal.UIStateManager():ShowDialog(
            "UIGuideCircleModelController",
            cfg,
            target
            -- function()
            --     self:ResetShowEntity("UIGuideCircleModelController")
            -- end
        )
    end
end

function GuideServiceRender:FindCircleCenter(gridPos, e)
    gridPos = e:GridLocation():GetGridPos()
    local bodyArea = e:BodyArea()
    if bodyArea and bodyArea:GetAreaCount() > 1 then
        local area = bodyArea:GetArea()
        local xTbl = {}
        local yTbl = {}
        for index, vec2 in ipairs(area) do
            local x = gridPos.x + vec2.x
            local y = gridPos.y + vec2.y
            table.insert(xTbl, x)
            table.insert(yTbl, y)
        end
        local minX = table.min(xTbl)
        local minY = table.min(yTbl)
        local maxX = table.max(xTbl)
        local maxY = table.max(yTbl)
        gridPos = Vector2((minX + maxX) / 2, (minY + maxY) / 2)
    end
end

----------------------------------- circle model ---------------------

function GuideServiceRender:YieldComplete(TT)
    while self.needYield do
        YIELD(TT)
        if not GameGlobal:GetInstance():IsCoreGameRunning() then
            return
        end
    end
end

function GuideServiceRender:_ShowClickGrid(cfg)
    if not cfg then
        return
    end
    local gridPos = Vector2.zero
    gridPos.x = cfg.param[1]
    gridPos.y = cfg.param[2]
    GameGlobal.UIStateManager():ShowDialog(
        "UIGuideGridController",
        cfg,
        gridPos,
        function(gridPos, offset)
            self:_PreViewMonsterAction(gridPos, offset)
        end
    )
end

function GuideServiceRender:_PreViewMonsterAction(touchPosition, offset)
    ---@type BoardServiceRender
    local boardSvcR = self._world:GetService("BoardRender")
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    local v3Pos = boardSvcR:GridPos2RenderPos(touchPosition)
    inputCmpt:SetTouchBeginPosition(v3Pos)
    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:CheckPreviewMonsterAction(touchPosition, offset)
end
