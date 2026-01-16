---@class UIActivityReturnSystemTabQuest:UICustomWidget
_class("UIActivityReturnSystemTabQuest", UICustomWidget)
UIActivityReturnSystemTabQuest = UIActivityReturnSystemTabQuest

function UIActivityReturnSystemTabQuest:SetData(campaign, remainingTimeCallback, tipsCallback)
    self._campaign = campaign
    self._remainingTimeCallback = remainingTimeCallback
    self._tipsCallback = tipsCallback

    --- @type CampaignQuestComponent
    self._component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "quest", 1)

    self:_Refresh()
    self:_CheckQuestDailyReset()
end

function UIActivityReturnSystemTabQuest:OnShow(uiParams)
    self._isOpen = true
end

function UIActivityReturnSystemTabQuest:OnHide()
end

function UIActivityReturnSystemTabQuest:_ReLoadData(TT, res)
    -- 强制刷新组件数据
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    self:_Refresh()
end

function UIActivityReturnSystemTabQuest:_Refresh()
    self:_SetRemainingTime()

    self:_SetProgress()
    self:_SetDynamicList(true)
end

function UIActivityReturnSystemTabQuest:_SetProgress()
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", "progressPool")
    ---@type UIActivityReturnSystemProgress
    local obj = sop:SpawnObject("UIActivityReturnSystemProgress")
    obj:SetData(self._campaign, self._tipsCallback)
end

function UIActivityReturnSystemTabQuest:_CheckQuestDailyReset()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local nextTime = self._component:GetEarliestEndTimeInDailyQuest()
    local stamp = nextTime - curTime

    if stamp > 0 then
        return
    end

    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            self._component:HandleCamQuestDailyReset(TT, res)
            if res:GetSucc() then
                self:_ReLoadData(TT, res)
            end
        end,
        self
    )
end

function UIActivityReturnSystemTabQuest:_SetRemainingTime()
    -- 设置倒计时
    if self._remainingTimeCallback then
        --- @type SvrTimeModule
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        local endTime = self._component:GetEarliestEndTimeInDailyQuest()
        local stamp = endTime - curTime

        if stamp <= 0 then
            self._remainingTimeCallback(endTime, true)
        else
            self._remainingTimeCallback(endTime)
        end
    end
end

function UIActivityReturnSystemTabQuest:_FlushQuestItems()
    local showTab = self._dynamicList:GetVisibleItemIDsInScrollView()

    for index = 0, showTab.Count - 1 do
        local id = math.floor(showTab[index])
        local item = self._dynamicList:GetShownItemByItemIndex(id)
        local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        ---@type UIActivityReturnSystemQuestListItem[]
        local rowList = rowPool:GetAllSpawnList()
        for i = 1, self._itemCountPerRow do
            local listItem = rowList[i]
            local itemIndex = index * self._itemCountPerRow + i
            listItem:PlayAnimationInSequence(itemIndex)
        end
    end
end

--region DynamicList
function UIActivityReturnSystemTabQuest:_SetDynamicListData()
    self._dynamicListInfo = self._component:GetQuestInfo()
    self._questStatus = self._component:GetCampaignQuestStatus(self._dynamicListInfo)
    self._component:SortQuestInfoByCampaignQuestStatus(self._dynamicListInfo)

    self._dynamicListSize = table.count(self._dynamicListInfo)
    self._dynamicListSize = self._dynamicListSize + 1 -- 空 item 占位，使列表滑到最下方时，最后一个 item 不会被阴影遮挡
    self._itemCountPerRow = 1
    self._dynamicListRowSize = math.floor((self._dynamicListSize - 1) / self._itemCountPerRow + 1)
end

function UIActivityReturnSystemTabQuest:_SetDynamicList(resetPos)
    self:_SetDynamicListData()

    if not self._isDynamicInited then
        self._isDynamicInited = true

        ---@type UIDynamicScrollView
        self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

        self._dynamicList:InitListView(
            self._dynamicListRowSize,
            function(scrollView, index)
                return self:_SpawnListItem(scrollView, index)
            end
        )
    else
        self:_RefreshList(self._dynamicListRowSize, self._dynamicList, resetPos)
    end

    self:_FlushQuestItems()
end

function UIActivityReturnSystemTabQuest:_RefreshList(count, list, resetPos)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:MovePanelToItemIndex(0, 0)
    if not resetPos then
        list.ScrollRect.content.localPosition = contentPos
    end
end

function UIActivityReturnSystemTabQuest:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end

    local item = nil

    -- 空 item 占位，使列表滑到最下方时，最后一个 item 不会被阴影遮挡
    -- 此处判断是最后一个 item ，基于 self._itemCountPerRow == 1
    if index == self._dynamicListSize - 1 then
        item = scrollView:NewListViewItem("EmptyItem")
    else
        item = scrollView:NewListViewItem("RowItem")
        local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        if item.IsInitHandlerCalled == false then
            item.IsInitHandlerCalled = true
            rowPool:SpawnObjects("UIActivityReturnSystemQuestListItem", self._itemCountPerRow)
        end
        ---@type UIActivityReturnSystemQuestListItem[]
        local rowList = rowPool:GetAllSpawnList()
        for i = 1, self._itemCountPerRow do
            local listItem = rowList[i]
            local itemIndex = index * self._itemCountPerRow + i
            if itemIndex > self._dynamicListSize then
                listItem:GetGameObject():SetActive(false)
            else
                listItem:GetGameObject():SetActive(true)
                self:_SetListItemData(listItem, itemIndex)
            end
        end
    end

    return item
end

---@param listItem UIActivityReturnSystemQuestListItem
function UIActivityReturnSystemTabQuest:_SetListItemData(listItem, index)
    local componentInfo = self._component:GetComponentInfo()

    local quest = self._dynamicListInfo[index]
    local status = self._questStatus[quest]
    listItem:GetGameObject():SetActive(true)
    if (quest ~= nil) then
        listItem:SetData(
            index,
            self._campaign,
            quest,
            status,
            componentInfo,
            function(questInfo)
                self:ListItemOnClick(questInfo)
            end,
            self._tipsCallback
        )
    end
end

function UIActivityReturnSystemTabQuest:ListItemOnClick(questInfo)
    if questInfo.status <= QuestStatus.QUEST_Accepted then --未完成
        ---@type UIJumpModule
        local jumpModule = self._questModule.uiModule
        if jumpModule == nil then
            Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
            return
        end
        --FromUIType.NormalUI
        local fromParam = {}
        table.insert(fromParam, QuestType.QT_Daily)
        jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
        local jumpType = questInfo.JumpID
        local jumpParams = questInfo.JumpParam
        jumpModule:SetJumpUIData(jumpType, jumpParams)
        jumpModule:Jump()
    elseif questInfo.status == QuestStatus.QUEST_Completed then --未领取
        self:_GetListItemReward(questInfo.quest_id)
    end
end

function UIActivityReturnSystemTabQuest:_GetListItemReward(id)
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    self:Lock("UIActivityReturnSystemTabQuest:_GetListItemRewardReq")
    self:StartTask(self._GetListItemRewardReq, self, id)
end

function UIActivityReturnSystemTabQuest:_GetListItemRewardReq(TT, id)
    if self._component then
        local res = AsyncRequestRes:New()
        local ret, rewards = self._component:HandleQuestTake(TT, res, id)
        self:UnLock("UIActivityReturnSystemTabQuest:_GetListItemRewardReq")

        if (self.view == nil) then
            return
        end
        if res:GetSucc() then
            rewards = self:_RemoveProgressItemInGetItems(rewards)
            UIActivityHelper.ShowUIGetRewards(rewards)
        else
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CheckErrorCode(
                res.m_result,
                self._campaign._id,
                function()
                    self:_Refresh()
                end,
                function()
                    self:SwitchState(UIStateType.UIMain)
                end
            )
        end
    end
end
--endregion

function UIActivityReturnSystemTabQuest:_RemoveProgressItemInGetItems(rewards)
    -- 去掉 个人进度组件 的关键物品

    --- @type PersonProgressComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "quest", 2)
    return component:RemoveProgressItemInTable(rewards)
end
