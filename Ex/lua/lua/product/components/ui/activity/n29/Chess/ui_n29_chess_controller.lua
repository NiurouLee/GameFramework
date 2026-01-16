---@class UIN29ChessController:UIController
_class("UIN29ChessController", UIController)
UIN29ChessController = UIN29ChessController
-------------------initial-------------------
function UIN29ChessController:Constructor()
    self._deltaTime = 0
    self._missionModule = self:GetModule(MissionModule)
    self._campModule = GameGlobal.GetModule(CampaignModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
end
--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN29ChessController:LoadDataOnEnter(TT, res, uiParams)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_N29)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
    if res and res:GetSucc() then
        ---@type ChessComponent
        self._chess_cpt = self._campaign:GetComponent(ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS)
        --- @type ChessComponentInfo
        self._chess_info = self._chess_cpt:GetComponentInfo()

        if not self._campaign:CheckComponentOpen(ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS) then
            res.m_result = self._campaign:CheckComponentOpenClientError(ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS)
            self._campModule:ShowErrorToast(res.m_result, true)
            return
        end
    end
    -- 错误处理
    if res and not res:GetSucc() then
        self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end
-- onshow
function UIN29ChessController:OnShow(uiParams)
    self._txt_desc = self:GetUIComponent("UILocalizationText", "_txt_desc")
    self:_InitParams()
    self:_AttachEvents()
    self:_InitWidget()
    self:_Refresh()
    self:_OnShow()
end
-- 初始化参数
function UIN29ChessController:_InitParams()
    self._timerHolder = UITimerHolder:New()
    self._introState = false
    UIN29ChessController.NodeCfg = {
        [MatchType.MT_Chess] = {
            [1] = {
                normal = "N15_warchessxxg_normal",
                press = "N15_warchessxxg_normal",
                lock = "N15_warchessxxg_locking",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "N15_warchessxxg_star2",
                passStar = "N15_warchessxxg_star1"
            } --普通样式
        }
    }
end
--show
function UIN29ChessController:_OnShow()
    -- 进场锁定
    local lockName = "UIN29ChessControllerEnter"
    self:Lock(lockName)
    self._timerHolder:StartTimer(
        lockName,
        500,
        function()
            self:UnLock(lockName)
        end
    )
    self:_ClearNewFlag()
end

---@private
---清除步数
function UIN29ChessController:_ClearNewFlag()
    if not self._campaign:GetSample():GetStepStatus(ECampaignStep.CAMPAIGN_STEP_NEW) then
        return
    end
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            GameGlobal.GetModule(CampaignModule):CampaignClearNewFlag(TT, res, self._campaign._id)
            if res:GetSucc() then
            end
        end,
        self
    )
end

-- component
function UIN29ChessController:_InitWidget()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    local cfg = Cfg.cfg_chess[1]
    self._backBtns:SetData(
        function()
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityN29MainController,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end,
        function()
            self:ShowDialog("UIN29ChessIntro",cfg.ChessIntroTitle,cfg.ChessIntro)
        end
    )
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "MapContent")
    self._contentRect = self:GetUIComponent("RectTransform", "Content")

    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    self._nodesPool = self:GetUIComponent("UISelectObjectPath", "Nodes")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    --安全区宽度,没有找到框架的接口,直接从RectTransform上取
    self._safeAreaSize = self:GetUIComponent("RectTransform", "SafeArea").rect.size
    self._shot.width = self._safeAreaSize.x
    self._shot.height = self._safeAreaSize.y

    self._title = self:GetUIComponent("UILocalizationText", "title")
    self._intro = self:GetUIComponent("UILocalizationText", "intro")
    self._Img = self:GetUIComponent("RawImageLoader", "Img")
    self._introContent = self:GetUIComponent("UILocalizationText", "introContent")

    self._introObj = self:GetGameObject("introObj")
end
-- 销毁
function UIN29ChessController:OnHide()
    UIN29ChessController.NodeCfg = nil
    self._timerHolder:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIN29ChessController.super:Dispose()
    -- self._scroller:Dispose()
end
function UIN29ChessController:_Refresh()
    self:FlushNodes()
    self:_SetRemainTime()
    self:_RefCfgView()
end

---@private
---刷新配置显示
function UIN29ChessController:_RefCfgView()
    local cfg = Cfg.cfg_chess[1]
    self._intro:SetText(StringTable.Get(cfg.ChessContent))
end

function UIN29ChessController:_SetRemainTime()
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local endtime = self._chess_info.m_close_time
    if endtime > curtime then
        self._txt_desc:SetText(StringTable.Get("str_chess_remain_time", N15ToolFunctions.GetRemainTime(endtime - curtime, "f7155b")))
    else
        if self._campaign:CheckCampaignOpen() then
            self:SwitchState(UIStateType.UIActivityN29MainController)
        else
            self:SwitchState(UIStateType.UIMain)
        end
    end
end
-- 刷新节点
function UIN29ChessController:FlushNodes()
    local cmpID = self._chess_cpt:GetComponentCfgId()
    local extra_cfg = Cfg.cfg_component_line_mission_extra {ComponentID = cmpID}
    local extra_width = extra_cfg[1].MarginRight
    local missionCfgs_temp = Cfg.cfg_component_chess {ComponentID = cmpID}
    --所有配置,以id为索引
    local missionCfgs = {}
    for _, cfg in pairs(missionCfgs_temp) do
        missionCfgs[cfg.MissionID] = cfg
    end
    self._allMissionCfgs = missionCfgs
    --所有关卡的解锁关系
    local unlockInfo = {}
    local firstMissionID = nil
    for _, cfg in pairs(missionCfgs) do
        if unlockInfo[cfg.NeedMissionId] == nil then
            unlockInfo[cfg.NeedMissionId] = {}
        end
        unlockInfo[cfg.NeedMissionId][cfg.MissionID] = cfg
        if cfg.NeedMissionId == 0 then
            firstMissionID = cfg.MissionID
        end
    end
    local showMission = {}
    local levelCount, lineCount = 0, 0
    local lastMissionID = firstMissionID
    if next(self._chess_info.m_pass_mission_info) then
        for missionID, passInfo in pairs(self._chess_info.m_pass_mission_info) do
            if not showMission[missionID] then
                showMission[missionID] = missionCfgs[missionID]
                levelCount = levelCount + 1
            end
            if unlockInfo[missionID] then
                for id, cfg in pairs(unlockInfo[missionID]) do
                    if not showMission[id] then
                        showMission[id] = missionCfgs[id]
                        levelCount = levelCount + 1
                    end
                    --第1关不需要连线
                    if cfg.NeedMissionId ~= 0 then
                        lineCount = lineCount + 1
                    end
                end
            end
        end
    else
        --没有通关信息则显示第一关
        showMission[firstMissionID] = missionCfgs[firstMissionID]
        levelCount = 1
    end
    --显示未解锁下一关
    local flag = true
    while flag do
        lastMissionID = self:_GetLastMissionID(lastMissionID)
        if not showMission[lastMissionID] then
            flag = false
        end
    end
    if (not (lastMissionID == 0)) and lastMissionID then
        levelCount = levelCount + 1
        lineCount = lineCount + 1
        showMission[lastMissionID] = missionCfgs[lastMissionID]
    end

    self._nodesPool:SpawnObjects("UIN29ChessMapNode", levelCount)
    local nodes = self._nodesPool:GetAllSpawnList()
    self._linesPool:SpawnObjects("UIN29ChessMapLine", lineCount)
    ---@type table<number,UIN29ChessMapLine>
    local lines = self._linesPool:GetAllSpawnList()

    local nodeIdx, lineIdx = 1, 1
    for missionID, cfg in pairs(showMission) do
        ---@type UIN29ChessMapNode
        local uiNode = nodes[nodeIdx]
        local last = false
        local func = nil
        if lastMissionID == missionID then
            last = true
        else
            last = false
            func = function(stageId, worldPos)
                self:_OnNodeClick(stageId, worldPos)
                end
        end
        local last2 = false
        if (not (lastMissionID == 0)) and lastMissionID then
            if missionCfgs[lastMissionID].NeedMissionId ==  missionID and missionID ~= firstMissionID then
                last2 = true
            end
        end
        uiNode:SetData(
                cfg,
                self._chess_info.m_pass_mission_info[missionID],
                func,
                last,
                last2
            )
        nodeIdx = nodeIdx + 1

        if cfg.NeedMissionId ~= 0 then
            local n1 = showMission[cfg.NeedMissionId]
            local n2 = cfg
            ---@type UIN29ChessMapLine
            local line = lines[lineIdx]
            line:Flush(Vector2(n2.MapPosX, n2.MapPosY), Vector2(n1.MapPosX, n1.MapPosY))
            lineIdx = lineIdx + 1
        end
    end

    local top = -99999999
    for _, cfg in pairs(showMission) do
        top = math.max(top, cfg.MapPosY)
    end
    --滚动列表总高度=最上边路点+上边距
    local high = math.abs(top + extra_width)
    high = math.max(self._safeAreaSize.y, high)
    self._contentRect.sizeDelta = Vector2(self._contentRect.sizeDelta.x, high)
    self._contentRect.anchoredPosition = Vector2(0, self._safeAreaSize.y - high)
end

function UIN29ChessController:_GetLastMissionID(missionID)
    for id, cfg in pairs(self._allMissionCfgs) do
        if cfg.NeedMissionId == missionID then
            return id
        end
    end
    return nil
end

-- 节点点击
function UIN29ChessController:_OnNodeClick(stageId, worldPos)
    --战斗关
    local pos = self._allMissionCfgs[stageId].MapPosY
    local curPos = self._contentRect.anchoredPosition.y
    local areaHeight = 125
    local targetPos = nil
    local down, top = -curPos + areaHeight, -curPos + self._safeAreaSize.y - areaHeight
    if pos < down then
        targetPos = curPos + down - pos
    elseif pos > top then
        targetPos = curPos + top - pos
    end
    self._scrollRect:StopMovement()
    if self._tweener then
        self._tweener:Kill()
        self._tweener = nil
    end
    if targetPos then
        local moveTime = 0.5
        self._tweener = self._contentRect:DOAnchorPosY(targetPos, moveTime)
        -- 移动关卡锁定
        local moveLockName = "UIActivityLineMissionController_MoveToStage"
        self:Lock(moveLockName)
        self._timerHolder:StartTimer(
            moveLockName,
            moveTime * 1000,
            function()
                self:UnLock(moveLockName)
                self:_EnterStage(stageId) -- 移动后，进入关卡
            end
        )
    else
        self:_EnterStage(stageId) -- 直接进入关卡
    end
end
-- 进入关卡
function UIN29ChessController:_EnterStage(stageId)
    local pointComponent = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_ACTION_POINT, 1)
    self:ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        self._chess_info.m_pass_mission_info[stageId],
        self._chess_cpt,
        false,
        pointComponent, --行动点组件
        true,
        true,
        false,
        false,
        true
    )
end
-------------------AttachEvent-------------------
function UIN29ChessController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end
--- close
function UIN29ChessController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN29ChessController:OnUpdate(deltaTimeMS)
    self._deltaTime = self._deltaTime + deltaTimeMS
    if self._deltaTime >= 1000 then
        self._deltaTime = 0
        self:_SetRemainTime()
    end
end