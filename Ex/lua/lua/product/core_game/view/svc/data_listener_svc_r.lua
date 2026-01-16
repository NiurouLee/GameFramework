--[[------------------
    表现层监听数据变更事件服务，处理所有从逻辑层过来的数据变更通知
    为了方便维护，禁止在这个Service对象里使用数据成员，数据都应该放在组件里
--]] ------------------
_class("DataListenerServiceRender", BaseService)
---@class DataListenerServiceRender:BaseService
DataListenerServiceRender = DataListenerServiceRender

function DataListenerServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world

    self._autoBinder = AutoEventBinder:New(self._world:EventDispatcher())
    --注册事件
    Log.notice("DataListenerServiceRender start")

    --logic step结果
    self._autoBinder:BindEvent(GameEventType.DataLogicResult, self, self._OnDataLogicResult)

    ---buff逻辑结果
    self._autoBinder:BindEvent(GameEventType.DataBuffRoundCount, self, self._OnDataBuffRoundCount)
    self._autoBinder:BindEvent(GameEventType.DataBuffMaxRoundCount, self, self._OnDataBuffMaxRoundCount)
    self._autoBinder:BindEvent(GameEventType.DataBuffValue, self, self._OnDataBuffValue)

    self._autoBinder:BindEvent(GameEventType.DataTrapAppearSkill, self, self._OnDataTrapAppearSkill)
    self._autoBinder:BindEvent(GameEventType.DataTrapTriggerSkill, self, self._OnDataTrapTriggerSkill)

    self._autoBinder:BindEvent(GameEventType.DataRenderNTSelectRoundTeamNormalBefore, self, self._OnDataNTSelectRoundTeamNormalBefore)
end

function DataListenerServiceRender:Dispose()
    self._autoBinder:UnBindAllEvents()
end

--logic step是result产生并有效的阶段，填0表示阶段无关，另存为状态数据
function DataListenerServiceRender:_OnDataLogicResult(logicStep, result)
    --Log.debug("OnDataLogicResult() logicStep=", logicStep, " result=", result._className)

    if logicStep == 0 then
        local funcname = "_On" .. result._className
        local func = self[funcname]
        if not func then
            Log.fatal("OnDataLogicResult not find handler for ", funcname)
            return
        end
        func(self, result)
        return
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    renderBoardEntity:LogicResult():SetLogicResult(logicStep, result)
end

--状态数据存储在组件里

---@param data DataChainPathResult
function DataListenerServiceRender:_OnDataChainPathResult(data)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    local l_role_module = GameGlobal.GetModule(RoleModule)
    -- 已过了UA打点上报强引导关卡 就不要上报了
    if not l_role_module:CheckModuleUnlock(GameModuleID.MD_ForceGuideEnd) then
        local match = GameGlobal.GetModule(MatchModule)
        local enterData = match:GetMatchEnterData()
        if enterData._match_type == MatchType.MT_Mission then --主线
            local l_path = data:GetChainPathResult()
            local l_team = data:GetChainTeamResult()
            local missionID = enterData:GetMissionCreateInfo().mission_id
            local pet_template_id = ""
            local teamEntity = self._world:Player():GetLocalTeamEntity()
            ---@type Entity[]
            local ePets = teamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(ePets) do
                local bInTable = table.intable(l_team, e:GetID())
                if bInTable then
                    local l_templateId = e:PetPstID():GetTemplateID()
                    pet_template_id = pet_template_id .. "," .. l_templateId
                end
            end
            GameGlobal.UAReportForceGuideEvent(
                "FightChainDone",
                {
                    missionID,
                    data:GetChainElementResult(),
                    l_path and #l_path or 0,
                    pet_template_id,
                    1
                }
            )
        end
    end

    renderBoardEntity:ReplaceRenderChainPath(
        data:GetChainPathResult(),
        data:GetChainElementResult(),
        data:GetCutChainPathResult(),
        data:GetPathChainRate()
    )
    renderBoardEntity:ReplaceRenderRoundTeam(data:GetChainTeamResult())
end

---@param data DataWaveEnterResult
function DataListenerServiceRender:_OnDataWaveEnterResult(data)
    ---@type Entity
    local viewDataEntity = self._world:GetRenderBoardEntity()
    ---@type WaveDataComponent
    local waveDataCmpt = viewDataEntity:WaveData()
    waveDataCmpt:SetWaveIndex(data:GetWaveIndex())
    waveDataCmpt:SetExitWave(data:IsExit())
    waveDataCmpt:SetExitWavePos(data:GetExitPos())
end

---@param data DataPetDeadResult
function DataListenerServiceRender:_OnDataPetDeadResult(data)
    local deadList = data:DataGetDeadPetEntityIDList()
    for _, v in ipairs(deadList) do
        ---@type Entity
        local petEntity = self._world:GetEntityByID(v)
        if not petEntity:HasPetDeadFlag() then
            petEntity:AddPetDeadFlag()
        end
    end
end

---@param data DataAILogicResult
function DataListenerServiceRender:_OnDataAILogicResult(data)
    local aiRecorderCmpt = data:GetAIRecorder()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    renderBoardEntity:ReplaceAIRecorder(aiRecorderCmpt)
end

---@param data DataSkillRoutineResult
function DataListenerServiceRender:_OnDataSkillRoutineResult(data)
    local res = data:GetResult()
    local eid = data:GetEntityID()
    local key = data:GetKey()
    local e = self._world:GetEntityByID(eid)
    e:SkillRoutine():SetResultContainer(res, key)
end

---@param data DataTrapCreationResult
function DataListenerServiceRender:_OnDataTrapCreationResult(data)
    local entityID = data:GetTrapEntityID()
    local trapEntity = self._world:GetEntityByID(entityID)
    ---@type TrapRenderComponent
    local trapRenderCmpt = trapEntity:TrapRender()
    trapRenderCmpt:SetTrapCreationResult(data)

    ---这里拿到结果后，可以先将配置数据写到表现组件里
    local trapID = data:GetTrapCreationResult_TrapID()
    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()

    local trapData = trapConfigData:GetTrapData(trapID)
    trapRenderCmpt:SetTrapType(trapData.TrapType)
end

---@param data DataAttributeResult
function DataListenerServiceRender:_OnDataAttributeResult(data)
    local entityID = data:GetEntityID()
    local entity = self._world:GetEntityByID(entityID)
    ---@type RenderAttributesComponent
    local renderAttrCmpt = entity:RenderAttributes()
    renderAttrCmpt:SetAttribute(data:GetAttrName(), data:GetAttrValue())
end

---@param buffResult DataBuffLogicResult
function DataListenerServiceRender:_OnDataBuffLogicResult(buffResult)
    local logicName = buffResult:GetBuffLogicName()
    local result = buffResult:GetBuffResult()
    local notify = buffResult:GetNotify()
    local seq = buffResult:GetBuffSeq()
    local eid = buffResult:GetEntityID()
    local triggers = buffResult:GetTriggers()
    local entity = self._world:GetEntityByID(eid)
    local viewInstance = entity:BuffView():GetBuffViewInstance(seq)
    --Log.debug("buffviewinstance logic entity=", eid, " buffseq=", seq, " has viewInstance=", viewInstance ~= nil)
    if viewInstance then
        viewInstance:AddBuffView(notify, logicName, result, triggers)
    end
end

---@param data DataBuffAddResult
function DataListenerServiceRender:_OnDataBuffAddResult(data)
    local eid = data:GetEntityID()
    local buffseq = data:GetBuffSeq()
    local buffid = data:GetBuffID()
    local context = data:GetBuffContext()
    local entity = self._world:GetEntityByID(eid)
    local view = BuffViewInstance:New(entity, buffseq, buffid, context)
    --Log.debug("buffviewinstance load! entity=", eid, " buffseq=", buffseq, " buffid=", buffid)
    entity:BuffView():AddBuffViewInstance(view)
end

---@param data DataBuffDelResult
function DataListenerServiceRender:_OnDataBuffDelResult(data)
    local eid = data:GetEntityID()
    local buffseq = data:GetBuffSeq()
    local nt = data:GetNotifyType()
    local buffid = data:GetBuffID()
    -- Log.debug(
    --     "buffviewinstance unload! entity=",
    --     eid,
    --     " buffseq=",
    --     buffseq,
    --     " buffid=",
    --     buffid,
    --     " notify=",
    --     GetEnumKey("NotifyType", nt)
    -- )
    local entity = self._world:GetEntityByID(eid)
    local viewInstance = entity:BuffView():GetBuffViewInstance(buffseq)
    if viewInstance then
        viewInstance:SetUnload(nt)
    end
end

--TODO 下面三个buff操作不合规范，需要想办法去掉
function DataListenerServiceRender:_OnDataBuffRoundCount(eid, buffseq, roundcount)
    local entity = self._world:GetEntityByID(eid)
    ---@type BuffViewInstance
    local viewInstance = entity:BuffView():GetBuffViewInstance(buffseq)
    ---N23做容错处理，主支有任务MSG51268
    if not viewInstance then
        return
    end
    viewInstance:SetRoundCount(roundcount)

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.BuffRoundCountChanged,
        buffseq,
        viewInstance:RemainRoundCount(),
        (viewInstance:GetMaxRoundCount() == 0)
    )
end

function DataListenerServiceRender:_OnDataBuffMaxRoundCount(eid, buffseq, roundcount)
    local entity = self._world:GetEntityByID(eid)
    local viewInstance = entity:BuffView():GetBuffViewInstance(buffseq)
    viewInstance:SetMaxRoundCount(roundcount)

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.BuffRoundCountChanged,
        buffseq,
        viewInstance:RemainRoundCount(),
        (viewInstance:GetMaxRoundCount() == 0)
    )
end

function DataListenerServiceRender:_OnDataBuffValue(eid, key, value)
    local entity = self._world:GetEntityByID(eid)
    entity:BuffView():SetBuffValue(key, value)
end

--------------------------------------------------------------------------------

---@param data DataDeadMarkResult
function DataListenerServiceRender:_OnDataDeadMarkResult(data)
    local list = data:GetDeadEntityIDList()
    for i, id in ipairs(list) do
        local e = self._world:GetEntityByID(id)
        e:AddDeadFlag()
    end
end

---@param data DataBoardLogicResult
function DataListenerServiceRender:_OnDataBoardLogicResult(data)
    ---@type Entity
    local e = self._world:GetPreviewEntity()
    ---@type PreviewEnvComponent
    local env = e:PreviewEnv()
    env:ResetPreviewEnv()
    env:ResetPieceTypes(data:GetPieceTypes())
    env:ResetPrismPieces(data:GetPrismPieces())
    env:ResetPrismEntityIDs(data:GetPrismEntityIDs())
    env:ResetPieceBlocks(data:GetBlockFlags())
    env:ResetPieceTable(data:GetPieceTable())
    env:ResetImmuneHitbacks(data:GetImmuneHitbacks())
    env:ResetPieceEntities(data:GetPieceEntities())
end

---@param data DataPieceTypeResult
function DataListenerServiceRender:_OnDataPieceTypeResult(data)
    ---@type Entity
    local e = self._world:GetPreviewEntity()
    ---@type PreviewEnvComponent
    local env = e:PreviewEnv()
    env:ResetPieceTypes(data:GetPieceTypes())
    env:ResetPieceTable(data:GetPieceTable())
    ---@type RenderBoardComponent
    local renderBoard = self._world:GetRenderBoardEntity():RenderBoard()
    ---@type BoardServiceRender
    local renderBoardSvc = self._world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosList = utilData:GetExtraBoardPosList()
    for posIdx, pieceType in pairs(data:GetPieceTypes()) do
        local pos = Vector2.Index2Pos(posIdx)
        --筛选坐标 棋盘外的额外坐标不检测
        if not table.intable(extraBoardPosList, pos) then
            local e = renderBoard:GetGridRenderEntity(pos)
            if e then
                if e:Piece():GetPieceType() ~= pieceType then
                    renderBoardSvc:ReCreateGridEntity(pieceType, pos)
                end
            else
                Log.fatal("_OnDataPieceTypeResult,can not find piece entity,pos:", pos)
                if EDITOR then
                    Log.exception("SyncPieceType failed")
                end
            end
        end
    end
end

---@param data DataChessPathResult
function DataListenerServiceRender:_OnDataChessPathResult(data)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local chessPathResult = data:GetChessPathResult()
    local chessPetEntityID = data:GetChessPetEntityID()
    local walkResultList = data:GetChessWalkResultList()
    local pickUpPos = data:GetChessPickUpPos()

    renderBoardEntity:ReplaceRenderChessPath(chessPathResult, chessPetEntityID, walkResultList, pickUpPos)
end

---@param data DataSanRoundDecreaseResult
function DataListenerServiceRender:_OnDataSanRoundDecreaseResult(data)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderFeatureComponent
    local renderFeature = renderBoardEntity:RenderFeature()
    if renderFeature then
        renderFeature:SetCurRoundDecreaseSanValue(
            1,
            data:GetModifyVal(),
            data:GetCurVal(),
            data:GetOldVal(),
            data:GetDebtVal(),
            data:GetModifyTimes()
        )
    end
end

---@param data DataDayNightRoundChangeResult
function DataListenerServiceRender:_OnDataDayNightRoundChangeResult(data)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderFeatureComponent
    local renderFeature = renderBoardEntity:RenderFeature()
    if renderFeature then
        renderFeature:SetCurRoundDayNightRouncChangeValue(
            1,
            data:GetCurState(),
            data:GetOldState(),
            data:GetRestRound()
        )
    end
end

---@param data DataSyncMovePathResult
function DataListenerServiceRender:_OnDataSyncMovePathResult(data)
    ---@type Entity
    local eid = data:GetEntityID()
    local entity = self._world:GetEntityByID(eid)
    if entity then
        ---@type RenderSyncMoveWithTeamComponent
        local syncMoveCmptRender = entity:RenderSyncMoveWithTeam()
        if syncMoveCmptRender then
            syncMoveCmptRender:RecordSyncMovePath(data:GetSyncMovePathResult())
        end
    end
end

---@param data DataTrapAppearSkill
function DataListenerServiceRender:_OnDataTrapAppearSkill(data)
    local eTrap = data:GetTrapEntity()
    eTrap:TrapRender():SetAppearSkillResultContainer(data:GetResultContainer())
end

---@param data DataTrapTriggerSkill
function DataListenerServiceRender:_OnDataTrapTriggerSkill(data)
    local eTrap = data:GetTrapEntity()
    local cTrapRender = eTrap:TrapRender()
    cTrapRender:SetTriggerSkillResultContainer(data:GetResultContainer())
    cTrapRender:SetTriggerSkillTriggeredEntity(data:GetTriggerEntity())
end
-- ---@param data DataChoosePartnerResult
-- function DataListenerServiceRender:_OnDataChoosePartnerResult(data)
--     local partnerID = data:GetChoosePartnerID()
-- end
-- ---@param data DataAddPartnerResult
-- function DataListenerServiceRender:_OnDataAddPartnerResult(data)
--     ---@type PartnerServiceRender
--     local renderPartnerService = self._world:GetService("PartnerRender")
--     renderPartnerService:AddPartnerRender(data)
-- end

-- ---@param data DataAddRelicResult
-- function DataListenerServiceRender:_OnDataAddRelicResult(data)
--     local taskId = TaskManager:GetInstance():CoreGameStartTask(
--         function(TT)
--             ---@type PlayBuffService
--             local svc = self._world:GetService("PlayBuff")
--             svc:PlayBuffSeqs(TT, data:GetBuffSeqList())
--             local state = data:GetSwitchState()
--             Log.debug("[MiniMaze] _OnDataAddRelicResult task after play buff seqs,switch state: ",state)
--             if state == WaveResultAwardNextStateType.WaveSwitch then
--                 self._world:EventDispatcher():Dispatch(GameEventType.WaveResultAwardFinish, 1)
--             elseif state == WaveResultAwardNextStateType.WaitInput then
--                 self._world:EventDispatcher():Dispatch(GameEventType.WaveResultAwardFinish, 2)
--             end
--         end
--     )
-- end

---@param data DataTrapTriggerSkill
function DataListenerServiceRender:_OnDataNTSelectRoundTeamNormalBefore(elementType, chainPath)
    --这个通知仍然不可以用来做表现，因为当前设计下没有合理的地方提供状态机TT来让它执行表现
    --这里添加是因为用到它的是一个修改表现数据的位置
    local ntSelectRoundTeamNormalBefore = NTSelectRoundTeamNormalBefore:New(elementType, chainPath)
    GameGlobal.TaskManager():CoreGameStartTask(function (TT)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, ntSelectRoundTeamNormalBefore)
    end)
end

---@param data DataPickUpComponentResult
function DataListenerServiceRender:_OnDataPickUpComponentResult(data)
    --点选组件拆分暂时屏蔽
    -- local eid = data:GetEntityID()
    -- local castEntity = self._world:GetEntityByID(eid)
    -- if not castEntity then
    --     return
    -- end
    -- ---@type RenderPickUpComponent
    -- local renderPickUpComponent = castEntity:RenderPickUpComponent()
    -- if not renderPickUpComponent then
    --     castEntity:AddRenderPickUpComponent()
    --     renderPickUpComponent = castEntity:RenderPickUpComponent()
    -- end
    -- renderPickUpComponent:ClearGridPos()
    -- renderPickUpComponent:AddGridPosList(data:GetPickUpGridList())
    -- renderPickUpComponent:AddDirectionList(data:GetDirectionPickupData())
    -- renderPickUpComponent:SetReflectDir(data:GetReflectDir())
    -- renderPickUpComponent:AddPickExtraParamList(data:GetPickUpExtraParam())
end