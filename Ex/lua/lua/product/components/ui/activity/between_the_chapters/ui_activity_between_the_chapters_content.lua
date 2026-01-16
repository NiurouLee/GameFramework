---@class UIActivityBetweenTheChaptersContent : UISideEnterCenterContentBase
require("ui_side_enter_center_content_base")
_class("UIActivityBetweenTheChaptersContent", UISideEnterCenterContentBase)
UIActivityBetweenTheChaptersContent = UIActivityBetweenTheChaptersContent

function UIActivityBetweenTheChaptersContent:InitWidget()
    self._refreshTaskID = nil

    ---@type UILocalizationText
    self._boardCastText = self:GetUIComponent("UILocalizationText", "broadcastText")
    ---@type UILocalizationText
    self._processText = self:GetUIComponent("UILocalizationText", "processText")

    ---@type UIDynamicScrollView
    self._rewardList = self:GetUIComponent("UIDynamicScrollView", "DayRewardList")
end

function UIActivityBetweenTheChaptersContent:_SetRemainingTime(widgetName, descId, endTime, customTimeStr)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")

    if customTimeStr then
        obj:SetCustomTimeStr_Common_1()
    end
    obj:SetAdvanceText(descId)
    obj:SetData(
        endTime,
        nil,
        function()
            self:_UpdateRemainingTime()
        end
    )
end

-----------------------------------------------------------------------------------

function UIActivityBetweenTheChaptersContent:DoInit(params)
    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id

    -- self._campaignType = ECampaignType.CAMPAIGN_TYPE_CELEBRATION
    self._componentId_drop = ECampaignCelebrationComponentID.ECAMPAIGN_CELEBRATION_MISSION_DROP
    self._componentId_person = ECampaignCelebrationComponentID.ECAMPAIGN_CELEBRATION_PERSON_PROGRESS

    ---@type UIActivityCampaign
    self._campaign = self._data
end

function UIActivityBetweenTheChaptersContent:DoShow()
    -- 检查活动关闭，根据时间计算错误码，发送事件
    if self._campaign:CheckCampaignClose_ShowClientError() then
        return
    end

    -- 清除 new
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)

    ---------------------------------------------------

    self:AddListener()

    self._clientCfg = Cfg.cfg_campaign_between_the_chapters {}
    self:InitWidget()
    
    self:_Refresh()
end

function UIActivityBetweenTheChaptersContent:DoHide()
    UIWidgetHelper.ClearWidgets(self, "_tipsPool")
    self:DetachListener()

    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end
end

function UIActivityBetweenTheChaptersContent:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIActivityBetweenTheChaptersContent:_ForceRefresh()
    self._refreshTaskID =
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self:_InitCmpt(TT, res, true)
            if res and res:GetSucc() then
                self:_Refresh(true)
            end
            self._refreshTaskID = nil
        end,
        self
    )
end

function UIActivityBetweenTheChaptersContent:_Refresh(notFirst)
    --- @type CampaignMissionDropComponent
    self._component_drop = self._campaign:GetComponent(self._componentId_drop)
    if not self._component_drop then
        Log.exception("UIActivityBetweenTheChaptersContent:_InitCmpt() drop component == nil")
    end

    --- @type PersonProgressComponent
    self._component_person = self._campaign:GetComponent(self._componentId_person)
    if not self._component_person then
        Log.exception("UIActivityBetweenTheChaptersContent:_InitCmpt() person progress component == nil")
    end

    ---------------------------------------------------

    self:_SetUI()
    self:_InitData()

    self:_InitRewardList()
    self._rewardList:RefreshAllShownItem()
    if not notFirst then
        self:_InitScrollPos()
        self:_FlushRewardListItems() -- 依次播放动效
    end

    self:_UpdateRemainingTime()
end

function UIActivityBetweenTheChaptersContent:_InitCmpt(TT, res, forceSend)
    local campaignModule = GameGlobal.GetModule(CampaignModule)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, self._componentId_drop)
    if not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    if forceSend then --重新拉一次数据
        self._campaign:ReLoadCampaignInfo_Force(TT, res)
        if not res:GetSucc() then
            campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
            return
        end
    end

    if not res:GetSucc() then
        return
    end
end

function UIActivityBetweenTheChaptersContent:_SetUI()
    local maxCount = self._clientCfg[#self._clientCfg].NeedValue
    local curCount = self._component_drop:GetComponentInfo().m_total_count
    curCount = math.min(curCount, maxCount)

    local c_gray = "#4C4C4B"
    local c_yellow = "#FEA226"

    local c1 = (curCount == maxCount) and c_yellow or c_gray
    local s1 = UIActivityHelper.GetColorText(c1, curCount)
    local c2 = c_yellow
    local s2 = UIActivityHelper.GetColorText(c2, maxCount)

    self._processText:SetText(StringTable.Get("str_between_chapters_num", s1, s2))
    self._boardCastText:SetText(StringTable.Get("str_between_chapters_title"))

    self:_SetHourGlass(curCount)
end

function UIActivityBetweenTheChaptersContent:_SetHourGlass(curCount)
    local state = (curCount <= 4) and 1 or (curCount <= 9) and 2 or 3

    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, {{"hourglass_1"}, {"hourglass_2"}, {"hourglass_3"}})
    UIWidgetHelper.SetObjGroupShow(objs, state)
end

function UIActivityBetweenTheChaptersContent:_InitData()
    local rewards = self._component_person:GetComponentInfo().m_progress_rewards
    for key, value in ipairs(self._clientCfg) do
        value._id = value.ID
        value._title = value.Title
        value._valueNum = value.NeedValue
        value._state = self:_GetReceivedState(value.NeedValue)
        value._items = rewards[value.ID]
    end
end

function UIActivityBetweenTheChaptersContent:_UpdateRemainingTime()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local lineComponent = self._campaign:GetComponent(ECampaignCelebrationComponentID.ECAMPAIGN_CELEBRATION_MISSION_DROP)
    local endTime = lineComponent:GetComponentInfo().m_close_time
    local stamp = endTime - curTime
    if stamp > 0 then
        self:_SetRemainingTime("reminetime", nil, endTime, true)
        return
    end
end

function UIActivityBetweenTheChaptersContent:_FlushRewardListItems()
    local showTab = self._rewardList:GetVisibleItemIDsInScrollView()

    for index = 0, showTab.Count - 1 do
        local id = math.floor(showTab[index])
        local item = self._rewardList:GetShownItemByItemIndex(id)
        local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        local rowList = rowPool:GetAllSpawnList()
        for i = 1, self._itemCountPerRow do
            local listItem = rowList[i]
            local itemIndex = index * self._itemCountPerRow + i
            listItem:PlayAnimationInSequence(itemIndex)
        end
    end
end

function UIActivityBetweenTheChaptersContent:_InitRewardList()
    self._itemCountPerRow = 1

    if not self._initRewardList then
        self._initRewardList = true
        self._rewardList:InitListView(
            #self._clientCfg,
            function(scrollview, index)
                return self:_SpawnListItem(scrollview, index)
            end,
            nil
        )
    else
        self._rewardList:SetListItemCount(#self._clientCfg, false)
    end
end

function UIActivityBetweenTheChaptersContent:_SpawnListItem(scrollview, index)
    local item = scrollview:NewListViewItem("CellItem")
    local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        cellPool:SpawnObjects("UIActivityBetweenTheChaptersAwardCell", 1)
    end
    local rowList = cellPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    if itemWidget then
        local itemIndex = index + 1
        local cellData = self._clientCfg[itemIndex]
        itemWidget:SetData(
            cellData,
            function(matid, pos)
                UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
            end,
            function(index)
                self:GetTotalAward(index)
            end
        )
        
        if itemIndex > #self._clientCfg then
            itemWidget:GetGameObject():SetActive(false)
        else
        end
    end
    UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end

function UIActivityBetweenTheChaptersContent:_InitScrollPos()
    local firstItemIndex = self:_GetFirstShowItemIndex()
    if firstItemIndex < 0 then
        firstItemIndex = 0
    end
    self:_MoveScrollToItemIndex(firstItemIndex)
end

function UIActivityBetweenTheChaptersContent:_MoveScrollToItemIndex(itemIndex)
    self._rewardList:MovePanelToItemIndex(itemIndex, 0)
    self._rewardList:FinishSnapImmediately()
end

function UIActivityBetweenTheChaptersContent:_GetFirstShowItemIndex()
    local cellIndex = 1
    for index, value in ipairs(self._clientCfg) do
        local received = self:_GetReceivedState(value.NeedValue) ==
            ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED
        if self:_CheckCanReceive(value.NeedValue) and (not received) then
            cellIndex = index
            break
        end
    end
    return cellIndex - 1
end

function UIActivityBetweenTheChaptersContent:GetTotalAward(index)
    self._component_person:Start_HandleReceiveReward(
        index,
        function(res, rewards)
            self:_OnReceiveRewards(res, rewards)
        end
    )
end

function UIActivityBetweenTheChaptersContent:_OnReceiveRewards(res, rewards)
    if (self.view == nil) then
        return
    end
    if res:GetSucc() then
        UIActivityHelper.ShowUIGetRewards(rewards)
    else
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
    end
end

function UIActivityBetweenTheChaptersContent:_CheckCanReceive(count)
    local corCount = self._component_drop:GetComponentInfo().m_total_count
    return corCount >= count
end

function UIActivityBetweenTheChaptersContent:_GetReceivedState(count)
    local state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
    local process = self._component_person:GetComponentInfo().m_received_progress
    if self:_CheckCanReceive(count) then
        state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV
    end
    for index, value in pairs(process) do
        if count == value then
            state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED
            break
        end
    end
    return state
end

--region AttachEvent
function UIActivityBetweenTheChaptersContent:AddListener()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityBetweenTheChaptersContent:DetachListener()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
end

function UIActivityBetweenTheChaptersContent:OnUIGetItemCloseInQuest()
    self:_Refresh(true)
end
--endregion