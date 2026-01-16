---@class UIActivityN34TaskInfomationMainController: UIController
_class("UIActivityN34TaskInfomationMainController", UIController)
UIActivityN34TaskInfomationMainController = UIActivityN34TaskInfomationMainController

---@class RewardState
local RewardState = {
    Unlock = 1,
    CanGet = 2,
    Got = 3
}
_enum("RewardState", RewardState)

function UIActivityN34TaskInfomationMainController:LoadDataOnEnter(TT, res, uiParams)
    self._itemModule = GameGlobal.GetModule(ItemModule)
    -- ---@type SvrTimeModule
    -- self._timeModule = GameGlobal.GetModule(SvrTimeModule)
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

    ---@type UIActivityCustomConst
    self._activityConst = UIActivityCustomConst:New(self:GetCampaignType(), self:GetComponentIds())
    self._activityConst:LoadData(TT, res)
    if res and not res:GetSucc() then
        ---@type CampaignModule
        local campModule = GameGlobal.GetModule(CampaignModule)
        campModule:CheckErrorCode(res.m_result, self._activityConst:GetCampaignId(), nil, nil)
    end
    self._questComponent = self._activityConst:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST)
    self._component,self._componentInfo = self._activityConst:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY)
end

function UIActivityN34TaskInfomationMainController:OnShow()
    self._animClip = 
    {
       [1] = {"uieff_UIActivityN34TaskInfomationMainController_in",667},
       [2] = {"uieff_UIActivityN34TaskInfomationMainController_in",700},
       [3] = {"uieff_UIActivityN34TaskInfomationMainController_in",700},
       [4] = {"uieff_UIActivityN34TaskInfomationMainController_in",700},
       [5] = {"uieff_UIActivityN34TaskInfomationMainController_in",700},
    }
    self:GetComponents()
    self:Init()
    self:PlayAnimCoro(1)
end

function UIActivityN34TaskInfomationMainController:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN34TaskRefreshEvent)
end

function UIActivityN34TaskInfomationMainController:GetComponents()
    self._reward = self:GetGameObject("reward")
    self._rewardRedPoint = self:GetGameObject( "rewardRedPoint")
    self._anim = self:GetUIComponent("Animation", "anim")
    self._items = {}
    self._itemWeights = {}
    self._itemsStar = {}
    local len = #self:GetSurveyCfg()
    for i = 1, len, 1 do
        self._items[i] = self:GetUIComponent("UISelectObjectPath", "item"..i)
    end
    for i = 1, len, 1 do
        self._itemsStar[i] = self:GetGameObject("star"..i)
    end
end 

function UIActivityN34TaskInfomationMainController:Init()
    self._rewardRedPoint:SetActive(false)
    self._reward:SetActive(true)
    local callBack = function () 

    end 
    for index, value in ipairs(self._items) do
        local sp = value:SpawnObject("UIActivityN34TaskInfomationItem")
        sp:SetData(self:GetSurveyCfg(index),self._itemModule,self._component,self._componentInfo)
        table.insert(self._itemWeights,sp)
        local cfg = self:GetSurveyCfg(index)
        local count = self._itemModule:GetItemCount(cfg.TrustItem)
        self._itemsStar[index]:SetActive(count >= cfg.TrustTotal )
        self:PlayAnimCoro(index + 1)
    end
end


function UIActivityN34TaskInfomationMainController:RefreshRewardItem()
    local rewardstate  = self:CheckItemState()
    -- rewardstate == RewardState.CanGet
    self._reward:SetActive(true)
    self._rewardRedPoint:SetActive(rewardstate > 0 )
    --self._rewardLock:SetActive(rewardstate == RewardState.Unlock)
    --self._rewardGot:SetActive(rewardstate == RewardState.Got )
end

function UIActivityN34TaskInfomationMainController:Refresh()
    for index, value in ipairs(self._itemWeights) do
        value:Refresh()
    end
end

function UIActivityN34TaskInfomationMainController:CheckAllFinish()
    if not self._component then
       return false
    end
    return #self._componentInfo.info.pet_unlock >= #self:GetSurveyCfg()
end

function UIActivityN34TaskInfomationMainController:CheckItemState()
    local questModule = GameGlobal.GetModule(QuestModule)
    local cfg = Cfg.cfg_global["survey_main_task_id"]
    local mainTaskId 
    if cfg and cfg.IntValue then
        mainTaskId = cfg.IntValue
    end
    local state = RewardState.Unlock
    local quest = questModule:GetQuest(mainTaskId)
    if self._questComponent:CheckCampaignQuestStatus(quest:QuestInfo()) == QuestStatus.QUEST_Taken then
        state =  RewardState.Got
    elseif  self._questComponent:CheckCampaignQuestStatus(quest:QuestInfo()) == QuestStatus.QUEST_Completed then
        state =  RewardState.CanGet
    end 
    return state
end

function UIActivityN34TaskInfomationMainController:RewardOnClick()
    if self:CheckAllFinish() and self:CheckItemState() == RewardState.CanGet then  
        self:StartTask(function (TT) 
            local asyncRes = AsyncRequestRes:New()
            local cfg = Cfg.cfg_global["survey_main_task_id"]
            local mainTaskId 
            if cfg and cfg.IntValue then
                mainTaskId = cfg.IntValue
            end
            if not mainTaskId then 
               return 
            end 
            local ret, rewards = self._questComponent:HandleQuestTake(TT, asyncRes,mainTaskId)
            if ret:GetSucc() then 
                self:ShowRewards(rewards)
                self:RefreshRewardItem()
            end 
        end )
    else 
        --ToastManager.ShowToast(StringTable.Get("str_mission_error_invalid_power"))
    end 
end

function UIActivityN34TaskInfomationMainController:ShowRewards(rewards)
    local petIdList = {}
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    for _, reward in pairs(rewards) do
        if petModule:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        self:ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", rewards)
            end
        )
        return
    end
    self:ShowDialog("UIGetItemController", rewards)
end

function UIActivityN34TaskInfomationMainController:CloseOnClick()
    self:CloseDialog()
end

function UIActivityN34TaskInfomationMainController:GetSurveyCfg(index)
    if  index then 
       return  Cfg.cfg_component_survey[index]
    end 
    return Cfg.cfg_component_survey{}
end

function UIActivityN34TaskInfomationMainController:GetCampaignType()
    return ECampaignType.CAMPAIGN_TYPE_N34
end

function UIActivityN34TaskInfomationMainController:GetComponentIds()
    local componentIds = {}
    componentIds[#componentIds + 1] = ECampaignN34ComponentID.ECAMPAIGN_N34_SURVEY 
    componentIds[#componentIds + 1] = ECampaignN34ComponentID.ECAMPAIGN_N34_QUEST 
    return componentIds
end

function UIActivityN34TaskInfomationMainController:PlayAnimCoro(index,callback)
    self:StartTask(function(TT) 
        self:Lock("UIActivityN34TaskInfomationMainController:PlayAnimCoro")
        self._anim:Play( self._animClip[index][1])
        YIELD(TT, self._animClip[index][2])
        if callback then 
            callback()
        end 
        self:UnLock("UIActivityN34TaskInfomationMainController:PlayAnimCoro")
    end , self)
end







