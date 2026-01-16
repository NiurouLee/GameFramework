---@class UIActivityN34TaskInfomationRewardPreview: UIController
_class("UIActivityN34TaskInfomationRewardPreview", UIController)
UIActivityN34TaskInfomationRewardPreview = UIActivityN34TaskInfomationRewardPreview

function UIActivityN34TaskInfomationRewardPreview:LoadDataOnEnter(TT, res)
    ---@type SvrTimeModule
    self._itemModule = GameGlobal.GetModule(ItemModule)
    ---@type UIActivityCustomConst
    self._activityConst = UIActivityCustomConst:New(self:GetCampaignType(), self:GetComponentIds())
    self._activityConst:LoadData(TT, res)
    if res and not res:GetSucc() then
        ---@type CampaignModule
        local campModule = GameGlobal.GetModule(CampaignModule)
        campModule:CheckErrorCode(res.m_result, self._activityConst:GetCampaignId(), nil, nil)
    end
    ---@type CampaignQuestComponent
    self._questComponent = self._activityConst:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST)
    self._component,self._componentInfo = self._activityConst:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY)
    self._questModule = GameGlobal.GetModule(QuestModule)
end

function UIActivityN34TaskInfomationRewardPreview:OnShow(params)
    self._cfg = params[1]
    self._rewardPage = params[2]
    self._evaluated = params[3]
    self:GetComponents()
    self:Init()
    self:StartTimer()
end

function UIActivityN34TaskInfomationRewardPreview:OnHide()
    if self._timeEvent then
        UIActivityHelper.CancelTimerEvent(self._timeEvent)
    end 
end

function UIActivityN34TaskInfomationRewardPreview:GetComponents()
    self._backBtn = self:GetUIComponent("UISelectObjectPath", "BackBtn")
    self._commonTopBtn = self._backBtn:SpawnObject("UICommonTopButton")
    self._commonTopBtn:SetData(
        function()
           self:CloseDialog()
        end,
        nil,
        nil,
        false
    )

    self._previewBtn = self:GetGameObject("previewBtn")
    self._evaluateBtn = self:GetGameObject("evaluateBtn")
    self._evaluate = self:GetGameObject("evaluate")
    self._preview = self:GetGameObject("preview")

    self._evaluateText = self:GetUIComponent("UILocalizationText", "EvaluateText")
    self._spineTipText = self:GetUIComponent("UILocalizationText", "spineTipText")
    ---@type UISelectObjectPath
    self._previewContent = self:GetUIComponent("UISelectObjectPath", "previewContent")
    self._tipTextGo = self:GetGameObject("tipText")
    self._evaluatedGo = self:GetGameObject("evaluated")

    self._previewSelectGo = self:GetGameObject("previewBtnSelect")
    self._evaluatedSelectGo = self:GetGameObject("evaluateBtnSelect")

    self._name = self:GetUIComponent("UILocalizationText", "name")
    self._progressLabel = self:GetUIComponent("UILocalizationText", "progressLabel")
    self._process = self:GetUIComponent("Slider", "process")
    self._itemText = self:GetUIComponent("UILocalizationText", "itemText")
    local s = self:GetUIComponent("UISelectObjectPath", "itemTips")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")
end 

function UIActivityN34TaskInfomationRewardPreview:Init()
    self._preview:SetActive(self._rewardPage)
    self._evaluate:SetActive(not self._rewardPage)

    self._previewItems =  self._previewContent:SpawnObjects("UIActivityN34TaskInfomationRewardPreviewItem",#self._cfg.TaskList)
    local list = self:SortList()
    for index, value in ipairs(self._previewItems) do
        local quest =  list[index]
        local state = QuestStatus.QUEST_NotStart
        if quest then
            state = self:GetTaskState(quest)
        end 
        value:SetData(index,self._cfg,quest,state ,function(id, pos)
            self:ShowTips(id, pos)
        end)
    end
    
    self._tipTextGo:SetActive(not self._evaluated)
  
    self._evaluateText:SetText(self._cfg.EvaluatedInfo)
    self._previewSelectGo:SetActive(true)
    self._evaluatedGo:SetActive(self._evaluated)
    self._evaluatedSelectGo:SetActive(false)

    local num = self._itemModule:GetItemCount(self._cfg.TrustItem)
    local value =  num/self._cfg.TrustTotal
    self._process.value = value
    self._progressLabel:SetText((num/self._cfg.TrustTotal*100).."%")
    self._name:SetText(StringTable.Get(self._cfg.Name))

    local str = Cfg.cfg_global["survey_tokens_item"].StrValue
    local a, b = string.match(str, "(.*)%|(.*)")
    local num = self._itemModule:GetItemCount(tonumber(a))
    if num > 9999999 then
        num = 9999999
    end
    self._itemText:SetText(UIActivityCustomHelper.GetItemCountStr(7, num, "#CFCFCF", "#CFCFCF"))
end

function UIActivityN34TaskInfomationRewardPreview:Refresh()
    self._preview:SetActive(true)
    self._evaluate:SetActive(false)
    self._previewSelectGo:SetActive(self._rewardPage)
    self._evaluatedGo:SetActive(false)
    self._evaluatedSelectGo:SetActive(not self._rewardPage)
    local callBack = function () 
        self._rewardPage = true 
        self:Refresh()
    end 

    if not self._rewardPage then 
        self:ShowDialog("UIActivityN34TaskInfomationPasteTips",callBack)
    end 
end


function UIActivityN34TaskInfomationRewardPreview:GetTaskState(quest)
    local state = RewardState.Unlock
    state =  self._questComponent:CheckCampaignQuestStatus(quest:QuestInfo())
    return state
end

function UIActivityN34TaskInfomationRewardPreview:GetCampaignType()
    return ECampaignType.CAMPAIGN_TYPE_N34
end

function UIActivityN34TaskInfomationRewardPreview:GetComponentIds()
    local componentIds = {}
    componentIds[#componentIds + 1] = ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY
    componentIds[#componentIds + 1] = ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST  
    return componentIds
end

function UIActivityN34TaskInfomationRewardPreview:CloseOnClick()
    self:CloseDialog()
end

function UIActivityN34TaskInfomationRewardPreview:PreviewBtnOnClick()
    self._rewardPage = true
    self:Refresh()
end 

function UIActivityN34TaskInfomationRewardPreview:EvaluateBtnOnClick()
    self._rewardPage = false
    self:Refresh()
end

function UIActivityN34TaskInfomationRewardPreview:StartTimer()
    if self._timeEvent then
        UIActivityHelper.CancelTimerEvent(self._timeEvent)
    end 
    self._addTime = 0 
    self._timeEvent = UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function() 
            self._addTime = self._addTime  + 1 
            if self._addTime > 5 then 
                self._addTime = 0 
            end 
        end
    )
end

function UIActivityN34TaskInfomationRewardPreview:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end

function UIActivityN34TaskInfomationRewardPreview:SortList()
    local questList ,finished = {},{}
    for index, value in ipairs(self._cfg.TaskList) do
        local quest =  self._questModule:GetQuest(self._cfg.TaskList[index])
        local state = QuestStatus.QUEST_NotStart
        if quest then
            state = self:GetTaskState(quest)
            if state == QuestStatus.QUEST_Completed then
                table.insert(finished,quest)
            else 
                table.insert(questList,quest)
            end
        end 
    end
    for index, value in ipairs(finished) do
        table.insert(questList,value)
    end
    return questList
end


