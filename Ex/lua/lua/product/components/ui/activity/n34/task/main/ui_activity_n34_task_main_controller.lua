---@class UIActivityN34TaskMainController: UIController
_class("UIActivityN34TaskMainController", UIController)
UIActivityN34TaskMainController = UIActivityN34TaskMainController

function UIActivityN34TaskMainController:LoadDataOnEnter(TT, res, uiParams)
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

    ---@type UIActivityN34TaskData
    self._taskData = UIActivityN34TaskData:New(self._campaign, self._surveyComponent, self._surveyComponentInfo, self._questComponent, self._questComponentInfo)
end

function UIActivityN34TaskMainController:OnShow(uiParams)
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            self:CloseDialog()
        end,
        function()
            self:InfoOnClick()
        end,
        nil,
        false
    )
    self._place = self:GetGameObject("Place")
    self._placeBtn = self:GetGameObject("PlaceBtn")
    self._placeComplete = self:GetGameObject("PlaceComplete")
    self._placing = self:GetGameObject("Placing")
    self._recoveryTimeLabel = self:GetUIComponent("UILocalizationText", "RecoveryTime")
    self._recoveryCountLabel = self:GetUIComponent("UILocalizationText", "RecoveryCount")
    self._placeRemainCountLabel = self:GetUIComponent("UILocalizationText", "PlaceRemainCount")
    self._itemCountLabel = self:GetUIComponent("UILocalizationText", "ItemCount")
    self._itemTips = self:GetGameObject("ItemTips")
    self._bossSpine = self:GetUIComponent("SpineLoader","Boss")
    self._bossSpine:LoadSpine(self._taskData:GetSpineName())
    self:PlayBossSpineAnimation(self._taskData:GetIdleAnim())
    self._bossAnimTimer = 0
    self._bossAnimLength = self._taskData:GetIdleAnimLength()
    self._startBtn = self:GetGameObject("StartBtn")
    self._delegatePerson = self:GetGameObject("DelegatePerson")
    self._delegatePersonLoader = self:GetUIComponent("SpineLoader","DelegatePersonLoader")
    self._delegatePersonNameLabel = self:GetUIComponent("UILocalizationText", "DelegatePersonName")
    self._delegateProgress = self:GetUIComponent("Image", "DelegateProgress")
    self._complete = self:GetGameObject("Complete")
    self._delegateSpeek = self:GetGameObject("DelegateSpeek")
    self._speekLabel = self:GetUIComponent("UILocalizationText", "Speek")
    self._currentTipsId = -1
    self._currentTipsTimer = 0
    self._currentTipsLength = 0
    self._currentTipsInterval = 1000
    self._nextBtn = self:GetGameObject("NextBtn")
    self._completes = {}
    self._completes[#self._completes + 1] = self:GetGameObject("1")
    self._completes[#self._completes + 1] = self:GetGameObject("2")
    self._completes[#self._completes + 1] = self:GetGameObject("3")
    self._completes[#self._completes + 1] = self:GetGameObject("4")
    self:AttachEvent(GameEventType.OnN34TaskRefreshEvent, self.RefreshData)
    self._startRed = self:GetGameObject("StartRed")
    self._nextPersonRed = self:GetGameObject("NextPersonRed")
    self._informationRed = self:GetGameObject("InformationRed")
    self._progressLabel = self:GetUIComponent("UILocalizationText", "ProgressLabel")
    self:Init()
end

function UIActivityN34TaskMainController:OnUpdate(deltaTimeMS)
    self:RefreshPlaceUI()
    if self._bossAnimTimer >= self._bossAnimLength then
        self:RandomPlayBossAnim()
    else
        self._bossAnimTimer = self._bossAnimTimer + deltaTimeMS
    end

    if self._currentTipsId >= 0 then
        self._currentTipsTimer = self._currentTipsTimer + deltaTimeMS
        if self._currentTipsTimer >= self._currentTipsLength then
            self._delegateSpeek:SetActive(false)
            self._currentTipsId = -1
            self._currentTipsTimer = 0
            self._currentTipsLength = 0
        end
    else
        self._currentTipsTimer = self._currentTipsTimer + deltaTimeMS
        if self._currentTipsTimer > self._currentTipsInterval then
            self:DelegatePersonSpeek()           
        end
    end
end

function UIActivityN34TaskMainController:OnHide()
    self:DetachEvent(GameEventType.OnN34TaskRefreshEvent, self.RefreshData)
end

function UIActivityN34TaskMainController:RandomPlayBossAnim()
    local index = math.random(1, 2)
    self._bossAnimTimer = 0
    if index == 1 then
        self:PlayBossSpineAnimation(self._taskData:GetIdleAnim())
        self._bossAnimLength = self._taskData:GetIdleAnimLength()
    else
        self:PlayBossSpineAnimation(self._taskData:GetRandomAnim())
        self._bossAnimLength = self._taskData:GetRandomAnimLenth()
    end
end

function UIActivityN34TaskMainController:Init()
    self._itemTips:SetActive(false)
    self:PlayPlot()
    self:RefreshPlaceUI()
    self:Refresh()
end

function UIActivityN34TaskMainController:RefreshData()
    self._taskData:Refresh()
    self:Refresh()
end

function UIActivityN34TaskMainController:Refresh()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local num = itemModule:GetItemCount(self._taskData:GetItemId())
    if num > 9999999 then
        num = 9999999
    end
    self._itemCountLabel:SetText(UIActivityCustomHelper.GetItemCountStr(7, num, "#F2F2F2", "#F2F2F2"))
    self._startBtn:SetActive(self._taskData:GetCurrentDelegatePerson() ~= nil)
    self:RefreshDelegatePersonUI()
    self:RefreshInfomation()
    self:RefreshRed()
end

function UIActivityN34TaskMainController:ShowInformationRed()
    self._itemModule = GameGlobal.GetModule(ItemModule)
    -- 
    local red = false 
    local cfgs =  Cfg.cfg_component_survey{}
    local checkFun = function (cfg) 
        for index, value in ipairs(self._surveyComponentInfo.info.pet_unlock) do
            if value == cfg.PetID then 
                return true
            end 
        end
    end 
    for key, cfg in pairs(cfgs) do
        local count = self._itemModule:GetItemCount(cfg.TrustItem)
        if count >= cfg.TrustTotal and not checkFun(cfg) then 
            red = true
            return red 
        end 
    end

    local questModule = GameGlobal.GetModule(QuestModule)
    local cfg = Cfg.cfg_global["survey_main_task_id"]
    local mainTaskId 
    if cfg and cfg.IntValue then
        mainTaskId = cfg.IntValue
    end

    local quest = questModule:GetQuest(mainTaskId)
    if self._questComponent:CheckCampaignQuestStatus(quest:QuestInfo()) == QuestStatus.QUEST_Completed then
        red = true 
    end 

    return red 
end

function UIActivityN34TaskMainController:ShowStartRed()
    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if currentDelegatePerson then
        if currentDelegatePerson:ShowAcceptAllRed() then
            return true
        end

        if currentDelegatePerson:HasCanGetProgressReward() then
            return true
        end

        if currentDelegatePerson:GetFinaleRewardStatus() == 1 then
            return true
        end
    end

    return false
end

function UIActivityN34TaskMainController:ShowNextPersonRed()
    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if currentDelegatePerson then
        if currentDelegatePerson:IsComplete() and currentDelegatePerson:IsPaste() == false then
            return true
        end
    end

    return false
end

function UIActivityN34TaskMainController:RefreshRed()
    self._startRed:SetActive(self:ShowStartRed())
    self._nextPersonRed:SetActive(self:ShowNextPersonRed())
    self._informationRed:SetActive(self:ShowInformationRed())
end

function UIActivityN34TaskMainController:RefreshInfomation()
    local persons = self._taskData:GetDelegatePersons()
    local count = 0
    for i = 1, #persons do
        if persons[i]:IsPaste() then
            count = count + 1
        end
    end
    
    for i = 1, #self._completes do
        if i <= count then
            self._completes[i]:SetActive(true)
        else
            self._completes[i]:SetActive(false)
        end
    end
end

function UIActivityN34TaskMainController:RefreshDelegatePersonUI()
    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if currentDelegatePerson then
        self._delegatePerson:SetActive(true)
        self._delegatePersonLoader:LoadSpine(currentDelegatePerson:GetSpine())
        self._delegatePersonNameLabel:SetText(currentDelegatePerson:GetName())
        local totalTrust = currentDelegatePerson:GetTotalTrust()
        local trustValue = currentDelegatePerson:GetTrustValue()
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
        if currentDelegatePerson:IsComplete() then
            self._nextBtn:SetActive(true)
        else
            self._nextBtn:SetActive(false)
        end
    else
        self._delegatePerson:SetActive(false)
        self._delegateSpeek:SetActive(false)
        self._nextBtn:SetActive(false)
    end
end

function UIActivityN34TaskMainController:RefreshPlaceUI()
    local remainCount = self._taskData:GetRemainRewardCount()
    if remainCount > 0 then
        self._place:SetActive(true)
        local rewardRemainTime = self._taskData:GetRewardRemainTime()
        if rewardRemainTime > 0 then --恢复中
            self._placeBtn:SetActive(false)
            self._placeComplete:SetActive(false)
            self._placing:SetActive(true)
            local timestr = UIActivityCustomHelper.GetTimeString(rewardRemainTime, "str_n34_task_day", "str_n34_task_hour", "str_n34_task_minus", "str_n34_task_less_one_minus")
            self._recoveryTimeLabel:SetText(StringTable.Get("str_n34_task_place_recovery_time_tips", timestr))
        else
            self._placeBtn:SetActive(true)
            self._placeComplete:SetActive(true)
            self._placing:SetActive(false)
            local recoveryCount = self._taskData:GetRewardCount()
            self._recoveryCountLabel:SetText(StringTable.Get("str_n34_task_place_recovery_count_tips", recoveryCount))
            self._placeRemainCountLabel:SetText(StringTable.Get("str_n34_task_place_remain_count_tips", remainCount))
        end
    else
        self._place:SetActive(false)
    end
end

function UIActivityN34TaskMainController:PlayBossSpineAnimation(spineAnim)
    self._bossSpine:SetAnimation(0, spineAnim, true)
end

function UIActivityN34TaskMainController:PlayPlot(callback)
    if self._taskData:CanPlayPlot() == false then
        if callback then
            callback()
        end
        return
    end

    GameGlobal.UIStateManager():ShowDialog("UIStoryController", self._taskData:GetPlotId(), function()
        self._taskData:PlayPlot()
        if callback then
            callback()
        end
    end)
end

function UIActivityN34TaskMainController:IsActivityEnd()
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

function UIActivityN34TaskMainController:CheckActivityStatus()
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

function UIActivityN34TaskMainController:PlotOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    GameGlobal.UIStateManager():ShowDialog("UIStoryController", self._taskData:GetPlotId())
end

function UIActivityN34TaskMainController:PlaceBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    
    self:StartTask(self.PlaceCoro, self)
end

function UIActivityN34TaskMainController:PlaceCoro(TT)
    self:Lock("UIActivityN34TaskMainController_PlaceCoro")
    
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._surveyComponent:HandleSurveyClientDataReq(TT, res, SurveyOperateType.SurveyOperateType_GetToken, 0)
    if not res:GetSucc() then
        self:UnLock("UIActivityN34TaskMainController_PlaceCoro")
        Log.error("get failed")
        return
    end

    local awards = {}
    awards[1] = { assetid = self._taskData:GetItemId(), count = self._taskData:GetRewardCount() }
    self:ShowDialog("UIGetItemController", awards)
    self._taskData:RefreshRewardInfo()
    self:Refresh()

    self:UnLock("UIActivityN34TaskMainController_PlaceCoro")
end

function UIActivityN34TaskMainController:ItemBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    self._itemTips:SetActive(true)
end

function UIActivityN34TaskMainController:TipsMaskOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    self._itemTips:SetActive(false)
end

function UIActivityN34TaskMainController:InfoOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    self:ShowDialog("UIIntroLoader", "UIN34TaskIntro")
end

function UIActivityN34TaskMainController:StartBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end
    self:ShowDialog("UIN34TaskDelegatePerson", self._taskData, self._taskData:GetCurrentDelegatePerson())
end

function UIActivityN34TaskMainController:DelegateBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    if self._taskData == nil then
        return
    end
    
    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if not currentDelegatePerson then
        return
    end

    self:DelegatePersonSpeek()
end

function UIActivityN34TaskMainController:DelegatePersonSpeek()
    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if currentDelegatePerson == nil then
        return
    end

    local tips = currentDelegatePerson:GetTips()
    local totalTrust = currentDelegatePerson:GetTotalTrust()
    local trustValue = currentDelegatePerson:GetTrustValue()
    local progress = trustValue / totalTrust

    for i = 1, #tips do
        local tip = tips[i]
        if tip.min <= progress and tip.max > progress then
            local contents = {}
            for j = 1, #tip.tips do
                if tip.tips[j]:GetId() ~= self._currentTipsId then
                    contents[#contents + 1] = tip.tips[j]
                end            
            end
            if #contents > 0 then
                local index = math.random(1, #contents)
                self._currentTipsTimer = 0
                self._currentTipsLength = contents[index]:GetLength()
                self._currentTipsInterval = contents[index]:GetInterval()
                self._currentTipsId = contents[index]:GetId()
                self._delegateSpeek:SetActive(true)
                self._speekLabel:SetText(contents[index]:GetTips())
            end
            break
        end
    end
end

function UIActivityN34TaskMainController:InformationBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    self:ShowDialog("UIActivityN34TaskInfomationMainController")
end

function UIActivityN34TaskMainController:NextBtnOnClick()
    if not self:CheckActivityStatus() then
        return
    end

    ---@type UIActivityN34DelegatePersonData
    local currentDelegatePerson = self._taskData:GetCurrentDelegatePerson()
    if not currentDelegatePerson then
        return
    end

    if not currentDelegatePerson:IsComplete() then
        return
    end

    if currentDelegatePerson:IsPaste() == false then
        ToastManager.ShowToast(StringTable.Get("str_n34_task_delegate_person_not_paste_tips"))
        return
    end

    self:StartTask(self.NextBtnOnClickCoro, self)
end

function UIActivityN34TaskMainController:NextBtnOnClickCoro(TT)
    self:Lock("UIActivityN34TaskMainController_NextBtnOnClickCoro")

    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._surveyComponent:HandleSurveyClientDataReq(TT, res, SurveyOperateType.SurveyOperateType_Next, 0)
    if not res:GetSucc() then
        self:UnLock("UIActivityN34TaskMainController_NextBtnOnClickCoro")
        Log.error("next delegate person failed, res ", res:GetResult())
        return
    end
    
    self._taskData:Refresh()
    self:Refresh()

    self:UnLock("UIActivityN34TaskMainController_NextBtnOnClickCoro")
end
