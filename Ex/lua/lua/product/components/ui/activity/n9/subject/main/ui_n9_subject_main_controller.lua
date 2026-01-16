---@class UIN9SubjectMainController: UIController
_class("UIN9SubjectMainController", UIController)
UIN9SubjectMainController = UIN9SubjectMainController

function UIN9SubjectMainController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N9,
        ECampaignN9ComponentID.ECAMPAIGN_N9_ANSWER_GAME
    )
    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end

    ---@type CCampaignN9
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        self:SubjectEnd()
        return
    end

    ---答题组件
    ---@type CampaignSubjectComponent
    self._cumulativeSubjectComponent = self._localProcess:GetComponent(ECampaignN9ComponentID.ECAMPAIGN_N9_ANSWER_GAME)
    ---@type SubjectComponentInfo
    self._subjectComponentInfo = self._localProcess:GetComponentInfo(ECampaignN9ComponentID.ECAMPAIGN_N9_ANSWER_GAME)

    --结束时间
    self._endTime = self._subjectComponentInfo.m_close_time
    self:RefreshData()
end

function UIN9SubjectMainController:RefreshData()
    self._levelDatas = UIN9SubjectLevelDatas:New(self._subjectComponentInfo)
end

function UIN9SubjectMainController:_GetComponent()
    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    self._timeBgLabel = self:GetUIComponent("UILocalizationText", "TimeBg")
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            GameGlobal.TaskManager():StartTask(
                function(TT)
                    self:Lock("UIN9SubjectMainController_CloseCoro")
                    self:CloseDialog()
                    self:UnLock("UIN9SubjectMainController_CloseCoro")
                end,
                self
            )
        end
    )
    local levelRoot = self:GetGameObject("Levels").transform
    self._levelItems = {}
    for i = 1, levelRoot.childCount do
        local item = levelRoot:GetChild(i - 1)
        local loader = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        ---@type UIN9SubjectLevelItem
        local levelItem = loader:SpawnObject("UIN9SubjectLevelItem")
        self._levelItems[#self._levelItems + 1] = levelItem
        levelItem:Refresh()
    end
end

function UIN9SubjectMainController:OnShow(uiParams)
    self:_GetComponent()
    self:InitRemainTime()
    self:RefreshLevel()
    self:AttachEvent(GameEventType.OnN9SubjectRefresh, self.RefreshSubject)

    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstid = roleModule:GetPstId()
    LocalDB.SetInt("UIActivityN9Subject" .. pstid, 1)
    UIN9Const.ResetNewOpenSubjectLevelStatus()

    local callback = uiParams[1]
    if callback then
        callback()
    end
end

function UIN9SubjectMainController:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:DetachEvent(GameEventType.OnN9SubjectRefresh, self.RefreshSubject)
end

function UIN9SubjectMainController:RefreshSubject()
    self:RefreshData()
    self:RefreshLevel()
end

function UIN9SubjectMainController:RefreshLevel()
    if not self._levelDatas then
        return
    end
    local levelDatas = self._levelDatas:GetLevelDatas()
    for i = 1, #levelDatas do
        ---@type UIN9SubjectLevelData
        local levelData = levelDatas[i]
        ---@type UIN6SubjectLevelItem
        local item = self._levelItems[levelData:GetPositionIndex()]
        if item then
            item:Refresh(levelData)
        end
    end
end

function UIN9SubjectMainController:InitRemainTime()
    self:RefreshRemainTime()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:RefreshRemainTime()
        end
    )
end

function UIN9SubjectMainController:RefreshRemainTime()
    if not self._endTime then
        self:SubjectEnd()
        return
    end
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._endTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end
    if seconds == 0 then
        --活动结束
        self:SubjectEnd()
        return
    end

    local timeStr = ""
    -- 剩余时间超过24小时，显示N天XX小时。
    -- 剩余时间超过1分钟，显示N小时XX分钟。
    -- 剩余时间小于1分数，显示＜1分钟。
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_activity_n9_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_activity_n9_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_activity_n9_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_activity_n9_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_activity_n9_less_minus")
        end
    end
    self._timeLabel:SetText(timeStr)
    self._timeBgLabel:SetText(timeStr)
end

function UIN9SubjectMainController:SubjectEnd()
    --self:SwitchState(UIStateType.UIActivityN9MainController)
    self:CloseDialog()
end

function UIN9SubjectMainController:InfoBtnOnClick()
    self:ShowDialog("UIN9SubjecIntroduce")
end
