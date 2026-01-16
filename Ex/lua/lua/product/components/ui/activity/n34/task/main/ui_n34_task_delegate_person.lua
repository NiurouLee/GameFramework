---@class UIN34TaskDelegatePerson: UIController
_class("UIN34TaskDelegatePerson", UIController)
UIN34TaskDelegatePerson = UIN34TaskDelegatePerson

function UIN34TaskDelegatePerson:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_N34,
        ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY,
        ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST)

    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        res:SetSucc(false)
        return
    end

    local localProcess = self._campaign:GetLocalProcess()
    if not localProcess then
        res:SetSucc(false)
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --调查玩法组件
    ---@type SurveyComponent
    self._surveyComponent = localProcess:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY)
    ---@type SurveyComponentInfo
    self._surveyComponentInfo = localProcess:GetComponentInfo(ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY)
    --任务组件
    ---@type CampaignQuestComponent
    self._questComponent = localProcess:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST)
    ---@type CamQuestComponentInfo
    self._questComponentInfo = localProcess:GetComponentInfo(ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST)

    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)

    --活动结束时间
    local sample = self._campaign:GetSample()
    if not sample then
        return
    end

    --活动时间
    self._activeEndTime = sample.end_time
end

function UIN34TaskDelegatePerson:OnShow(uiParams)
    ---@type UIActivityN34TaskData
    self._taskData = uiParams[1]
    ---@type UIActivityN34DelegatePersonData
    self._currentDelegatePerson = uiParams[2]

    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN34TaskRefreshEvent)
            self:CloseDialog()
        end,
        nil,
        nil,
        false
    )
    self._itemCountLabel = self:GetUIComponent("UILocalizationText", "ItemCount")
    self._itemTips = self:GetGameObject("ItemTips")
    self._delegatePersonLoader = self:GetUIComponent("SpineLoader","DelegatePersonLoader")
    self._delegatePersonNameLabel = self:GetUIComponent("UILocalizationText", "DelegatePersonName")
    self._delegateProgress = self:GetUIComponent("Image", "DelegateProgress")
    self._progressLabel = self:GetUIComponent("UILocalizationText", "ProgressLabel")
    self._complete = self:GetGameObject("Complete")

    self._panelType = 1
    self._taskPanel = self:GetGameObject("TaskPanel")
    self._personInfoPanel = self:GetGameObject("PersonInfoPanel")
    self._taskSelect = self:GetGameObject("TaskSelect")
    self._personSelect = self:GetGameObject("PersonSelect")
    ---@type UIActivityN34DelegateTaskData
    self._currentTask = nil
    self._currentTaskItem = nil
    self._acceptAllBtn = self:GetGameObject("AcceptAllBtn")
    self._acceptBtn = self:GetGameObject("AcceptBtn")
    self._taskLoader = self:GetUIComponent("UISelectObjectPath", "TaskList")
    self._acceptAllCountLabel = self:GetUIComponent("UILocalizationText", "AcceptAllCount")
    self._acceptCountLabel = self:GetUIComponent("UILocalizationText", "AcceptCount")
    self._empty = self:GetGameObject("Empty")
    self._scroll = self:GetGameObject("Scroll View")
    
    self._personDesLabel = self:GetUIComponent("UILocalizationText", "PersonDes")
    self._completeTaskCountLabel = self:GetUIComponent("UILocalizationText", "CompleteTaskCount")
    self._rewardDesLabel = self:GetUIComponent("UILocalizationText", "RewardDes")
    self._rewardGetBtn = self:GetGameObject("RewardGetBtn")
    self._rewardUnComplete = self:GetGameObject("RewardUnComplete")
    self._rewardHasGet = self:GetGameObject("RewardHasGet")
    self._rewardIconLoader = self:GetUIComponent("RawImageLoader", "RewardIcon")
    self._progressLoader = self:GetUIComponent("UISelectObjectPath", "Progress")
    self._acceptAllRed = self:GetGameObject("AcceptAllRed")
    local s = self:GetUIComponent("UISelectObjectPath", "itemTips")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")
    self:Init()
end

function UIN34TaskDelegatePerson:OnHide()
end

function UIN34TaskDelegatePerson:Init()
    self._itemTips:SetActive(false)
    self:Refresh()
    self:RefreshPanelStatus()
end

function UIN34TaskDelegatePerson:Refresh()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local num = itemModule:GetItemCount(self._taskData:GetItemId())
    if num > 9999999 then
        num = 9999999
    end
    self._itemCountLabel:SetText(UIActivityCustomHelper.GetItemCountStr(7, num, "#CFCFCF", "#CFCFCF"))
    self:RefreshDelegatePersonUI()
    self:RefreshTaskUI()
    self:RefreshProgressUI()
    self:RefreshRed()
end

function UIN34TaskDelegatePerson:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end

function UIN34TaskDelegatePerson:RefreshRed()
    self._acceptAllRed:SetActive(self._currentDelegatePerson:ShowAcceptAllRed())
end

function UIN34TaskDelegatePerson:SwitchPanel(panelType)
    if panelType == self._panelType then
        return
    end

    self._panelType = panelType
    self:RefreshPanelStatus()
end

function UIN34TaskDelegatePerson:RefreshPanelStatus()
    self._taskPanel:SetActive(self._panelType == 1)
    self._personInfoPanel:SetActive(self._panelType == 2)
    self._taskSelect:SetActive(self._panelType == 1)
    self._personSelect:SetActive(self._panelType == 2)
end

function UIN34TaskDelegatePerson:RefreshProgressUI()
    self._personDesLabel:SetText(self._currentDelegatePerson:GetDes())
    local str = self._currentDelegatePerson:GetCompleteTaskCount() .. "/" .. self._currentDelegatePerson:GetAllTaskCount()
    self._completeTaskCountLabel:SetText(StringTable.Get("str_n34_task_person_progress_tips", str))
    self._rewardDesLabel:SetText(self._currentDelegatePerson:GetFinaleRewardDes())
    self._rewardIconLoader:LoadImage(self._currentDelegatePerson:GetFinaleRewardIcon())
    local status = self._currentDelegatePerson:GetFinaleRewardStatus() --0:未达成, 1:完成未领取, 2:已领取
    self._rewardGetBtn:SetActive(false)
    self._rewardUnComplete:SetActive(false)
    self._rewardHasGet:SetActive(false)
    if status == 0 then
        self._rewardUnComplete:SetActive(true)
    elseif status == 1 then
        self._rewardGetBtn:SetActive(true)
    elseif status == 2 then
        self._rewardHasGet:SetActive(true)
    end

    local progress = self._currentDelegatePerson:GetProgress()
    self._progressLoader:SpawnObjects("UIN34TaskDelegatePersonProgressItem", #progress)
    local items = self._progressLoader:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetData(progress[i], function(data)
            self:StartTask(self.GetProgressRewardCoro, self, data)
        end,
        function(id, pos)
            self:ShowTips(id, pos)
        end)
    end
end

---@param data UIActivityN34DelegateProgressData
function UIN34TaskDelegatePerson:GetProgressRewardCoro(TT, data)
    self:Lock("UIN34TaskDelegatePerson_GetProgressRewardCoro")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._questComponent:HandleQuestTake(TT, res, data:GetQuestId())
    if not res:GetSucc() then
        Log.error("Get reward failed. res : ", res:GetResult())
    else
        local awards = data:GetRewards()
        self:ShowDialog("UIGetItemController", awards)
        self._taskData:RefreshPersonInfo()
        self:Refresh()
    end
    self:UnLock("UIN34TaskDelegatePerson_GetProgressRewardCoro")
end

function UIN34TaskDelegatePerson:RefreshTaskUI()
    local tasks = self._currentDelegatePerson:GetShowTask(3)
    self._taskLoader:SpawnObjects("UIN34TaskDelegatePersonTaskItem", #tasks)
    local items = self._taskLoader:GetAllSpawnList()

    if #tasks <= 0 then
        self._currentTaskItem = nil
        self._currentTask = nil
        self._acceptAllBtn:SetActive(false)
        self._acceptBtn:SetActive(false)
        self._empty:SetActive(true)
        self._scroll:SetActive(false)
    else
        self._empty:SetActive(false)
        self._scroll:SetActive(true)
        self._currentTask = tasks[1]

        self._acceptAllBtn:SetActive(true)
        self._acceptBtn:SetActive(true)
        local totalCost = 0
        for i = 1, #tasks do
            local cost = tasks[i]:GetCost()
            totalCost = totalCost + cost
        end

        self._acceptAllCountLabel:SetText(totalCost)
        self._acceptCountLabel:SetText(self._currentTask:GetCost())

    end

    for i = 1, #items do
        local selected = false
        local task = tasks[i]
        if task then
            selected = task == self._currentTask
            if selected then
                self._currentTaskItem = items[i]
            end
        end
        
        items[i]:SetData(tasks[i], selected, function(data)
            if self._currentTask == data then
                return
            end

            self._currentTaskItem:UnSelect()
            self._currentTask = data
            self._currentTaskItem = items[i]
            self._currentTaskItem:Select()
        end,
        function(id, pos)
            self:ShowTips(id, pos)
        end)
    end
end

function UIN34TaskDelegatePerson:RefreshDelegatePersonUI()
    self._delegatePersonLoader:LoadSpine(self._currentDelegatePerson:GetSpine())
    self._delegatePersonNameLabel:SetText(self._currentDelegatePerson:GetName())
    local totalTrust = self._currentDelegatePerson:GetTotalTrust()
    local trustValue = self._currentDelegatePerson:GetTrustValue()
    local progress = trustValue / totalTrust
    self._delegateProgress.fillAmount = progress
    self._progressLabel:SetText(math.floor(progress * 100) .. "%")
    if progress >= 1 then
        self._complete:SetActive(true)
        -- self._delegateProgress.color = Color(0, 1, 0)
    else
        self._complete:SetActive(false)
        -- self._delegateProgress.color = Color(1, 0, 0)
    end
end

function UIN34TaskDelegatePerson:ItemBtnOnClick()
    self._itemTips:SetActive(true)
end

function UIN34TaskDelegatePerson:TipsMaskOnClick()
    self._itemTips:SetActive(false)
end

function UIN34TaskDelegatePerson:TaskBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    self:SwitchPanel(1)
end

function UIN34TaskDelegatePerson:PersonBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    self:SwitchPanel(2)
end

function UIN34TaskDelegatePerson:AcceptAllBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    local tasks = self._currentDelegatePerson:GetShowTask(3)

    if #tasks <= 0 then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_task_empty_tips"))
        return
    end

    local totalCost = 0
    for i = 1, #tasks do
        local cost = tasks[i]:GetCost()
        totalCost = totalCost + cost
    end

    local itemModule = GameGlobal.GetModule(ItemModule)
    local num = itemModule:GetItemCount(self._taskData:GetItemId())
    if totalCost > num then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_task_not_enought_tips"))
        return
    end

    self:StartTask(self.AcceptAllBtnOnClickCoro, self, tasks)
end

function UIN34TaskDelegatePerson:AcceptAllBtnOnClickCoro(TT, tasks)
    self:Lock("UIN34TaskDelegatePerson_AcceptAllBtnOnClickCoro")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    for i = 1, #tasks do
        self._questComponent:HandleQuestTake(TT, res, tasks[i]:GetQuestId())
        if not res:GetSucc() then
            Log.error("Get reward failed. res : ", res:GetResult())
            self:UnLock("UIN34TaskDelegatePerson_AcceptAllBtnOnClickCoro")
            return
        end
    end
    
    local awards = {}
    local items = {}
    for i = 1, #tasks do
        local rewards = self._currentTask:GetRewards()
        for j = 1, #rewards do
            local reward = rewards[j]
            if not items[reward.assetid] then
                items[reward.assetid] = 0
            end
            items[reward.assetid] = items[reward.assetid] + reward.count
        end
    end
    for id, count in pairs(items) do
        awards[#awards + 1] = { assetid = id, count = count }
    end
    
    self:ShowDialog("UIGetItemController", awards)
    self._taskData:RefreshPersonInfo()
    self:Refresh()
    self:UnLock("UIN34TaskDelegatePerson_AcceptAllBtnOnClickCoro")
end

function UIN34TaskDelegatePerson:AcceptBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    if self._currentTask == nil then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_task_empty_tips"))
        return
    end

    local cost = self._currentTask:GetCost()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local num = itemModule:GetItemCount(self._taskData:GetItemId())
    if cost > num then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_task_not_enought_tips"))
        return
    end
    self:StartTask(self.AcceptBtnOnClickCoro, self)
end

function UIN34TaskDelegatePerson:AcceptBtnOnClickCoro(TT)
    self:Lock("UIN34TaskDelegatePerson_AcceptBtnOnClickCoro")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._questComponent:HandleQuestTake(TT, res, self._currentTask:GetQuestId())
    if not res:GetSucc() then
        Log.error("Get reward failed. res : ", res:GetResult())
    else
        local awards = self._currentTask:GetRewards()
        self:ShowDialog("UIGetItemController", awards)
        self._taskData:RefreshPersonInfo()
        self:Refresh()
    end
    self:UnLock("UIN34TaskDelegatePerson_AcceptBtnOnClickCoro")
end

function UIN34TaskDelegatePerson:RewardGetBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    self._currentDelegatePerson:GetFinalReward()
    self:RefreshProgressUI()
    self:ShowDialog("UIN34DelegatePersonTips", self._currentDelegatePerson)
end

function UIN34TaskDelegatePerson:RewardUnCompleteOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_person_uncomplete_tips"))
end

function UIN34TaskDelegatePerson:IsActivityEnd()
    if not self._activeEndTime then
       return true 
    end
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

function UIN34TaskDelegatePerson:CheckActivityStatus()
    if self:IsActivityEnd() then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_activity_end"))
        self:SwitchState(UIStateType.UIMain)
        return false
    end

    if not self._surveyComponent:ComponentIsOpen() then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_activity_end"))
        self:SwitchState(UIStateType.UIActivityN34MainController)
        return false
    end

    return true
end
