---@class UIActivityReturnSystemQuestListItem:UICustomWidget
_class("UIActivityReturnSystemQuestListItem", UICustomWidget)
UIActivityReturnSystemQuestListItem = UIActivityReturnSystemQuestListItem

function UIActivityReturnSystemQuestListItem:_GetComponents()
    self._anim = self:GetUIComponent("Animation", "ani")
    self._root = self:GetGameObject("root")

    self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

    self._desTex = self:GetUIComponent("UILocalizationText", "desTex")

    self._progressValueImg = self:GetUIComponent("Image", "progressValueImg")
    self._progressValueTex = self:GetUIComponent("UILocalizationText", "progressValueTex")

    self._stateCountTxt = {
        self:GetUIComponent("UILocalizationText", "text_count_NotStart"),
        self:GetUIComponent("UILocalizationText", "text_count_Accepted"),
        self:GetUIComponent("UILocalizationText", "text_count_Completed"),
        self:GetUIComponent("UILocalizationText", "text_count_Taken"),
        self:GetUIComponent("UILocalizationText", "text_count_Over")
    }
end

function UIActivityReturnSystemQuestListItem:OnShow(uiParams)
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("[quest] erro --> module is nil !")
        return
    end

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIBattlePass.spriteatlas", LoadType.SpriteAtlas)
end

function UIActivityReturnSystemQuestListItem:SetData(index, campaign, quest, status, info, callback, tipsCallback)
    self:_GetComponents()

    self._index = index
    self._campaign = campaign
    ---@type MobileQuestInfo
    self._quest = quest:QuestInfo()
    ---@type CampaignQuestStatus
    self._state = status or CampaignQuestStatus.CQS_Over
    ---@type CamQuestComponentInfo
    self._info = info
    self._callback = callback
    self._tipsCallback = tipsCallback

    self:_Refresh()

    -- 切换数据时，视野外的 item 错位问题
    local trans = self:GetUIComponent("RectTransform", "root")
    trans.anchoredPosition = Vector2(0, trans.anchoredPosition.y)
end

function UIActivityReturnSystemQuestListItem:OnHide(stamp)
    self._root = nil
end

function UIActivityReturnSystemQuestListItem:_Refresh()
    self:_SetTitle()
    self:_SetProgress()
    self:_SetState(self._state)
    self:_SetStateCount(self._state)
    -- self:_SetRemainingTime()

    self:_SetDynamicList()
end

function UIActivityReturnSystemQuestListItem:PlayAnimationInSequence(index)
    local delay = index * 30
    UIWidgetHelper.PlayAnimationInSequence(self,
        "ani",
        "ani",
        "uieff_Return_QuestListItem_in",
        delay,
        333,
        nil)
end

function UIActivityReturnSystemQuestListItem:_SetTitle()
    self._desTex:SetText(StringTable.Get(self._quest.CondDesc))
end

function UIActivityReturnSystemQuestListItem:_SetProgress()
    local progress = ""
    if self._quest.ShowType == 1 then
        local c, d = math.modf(self._quest.cur_progress * 100 / self._quest.total_progress)
        if c < 1 and d > 0 then
            c = 1
        end
        progress = c .. "%"
    else
        progress = self._quest.cur_progress .. "/" .. self._quest.total_progress
    end
    self._progressValueTex:SetText(progress)

    local rate = self._quest.cur_progress / self._quest.total_progress
    self._progressValueImg.fillAmount = rate
end

-- function UIActivityReturnSystemQuestListItem:_SetRemainingTime()
--     local remainingTimeObj = self:GetGameObject("remainingTimePool")

--     --------------------------------------------------------------------------------
--     -- endTime
--     local questId = self._quest.quest_id
--     local timeInfo = self._info.m_quest_time_param_map[questId]
--     local state2time = {
--         [CampaignQuestStatus.CQS_NotStart] = timeInfo.m_open_time,
--         [CampaignQuestStatus.CQS_Accepted] = timeInfo.m_end_time,
--         [CampaignQuestStatus.CQS_Completed] = timeInfo.m_end_time
--     }
--     if timeInfo.m_need_daily_reset then -- 每日任务的已领取状态需要显示下一次开始时间
--         state2time[CampaignQuestStatus.CQS_Taken] = timeInfo.m_end_time
--     end

--     local endTime = state2time[self._state]
--     if endTime and endTime ~= 0 then
--         remainingTimeObj:SetActive(true)
--     else
--         remainingTimeObj:SetActive(false)
--         return
--     end

--     --------------------------------------------------------------------------------
--     -- iconSprite
--     local state2icon = {
--         [CampaignQuestStatus.CQS_NotStart] = "pass_renwu_icon1",
--         [CampaignQuestStatus.CQS_Accepted] = "pass_renwu_icon2",
--         [CampaignQuestStatus.CQS_Completed] = "pass_renwu_icon2",
--         [CampaignQuestStatus.CQS_Taken] = "pass_renwu_icon1" -- 每日任务的已领取状态
--     }
--     local iconId = state2icon[self._state]
--     local iconSprite = self._atlas:GetSprite(iconId)

--     --------------------------------------------------------------------------------
--     -- color
--     local state2color = {
--         [CampaignQuestStatus.CQS_NotStart] = "47D3E6",
--         [CampaignQuestStatus.CQS_Accepted] = "FFFFFF",
--         [CampaignQuestStatus.CQS_Completed] = "FFFFFF",
--         [CampaignQuestStatus.CQS_Taken] = "47D3E6" -- 每日任务的已领取状态
--     }
--     local color = state2color[self._state]

--     --------------------------------------------------------------------------------
--     ---@type UICustomWidgetPool
--     local remainingTimePool = self:GetUIComponent("UISelectObjectPath", "remainingTimePool")
--     ---@type UIActivityCommonRemainingTime
--     self._remainingTime = remainingTimePool:SpawnObject("UIActivityCommonRemainingTime")

--     -- 设置自定义时间文字
--     self._remainingTime:SetCustomTimeStr(
--         {
--             ["day"] = "str_activity_battlepass_day",
--             ["hour"] = "str_activity_battlepass_hour",
--             ["min"] = "str_activity_battlepass_minute",
--             ["zero"] = "str_activity_battlepass_less_minute",
--             ["over"] = "str_activity_battlepass_less_minute" -- 超时后还显示小于 1 分钟
--         }
--     )
--     self._remainingTime:SetExtraSprite("icon", iconSprite)
--     self._remainingTime:SetTimeColor(color)
--     self._remainingTime:SetData(endTime, nil, nil)
-- end

function UIActivityReturnSystemQuestListItem:_SetState(state)
    self._stateObj = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            { "state_NotStart", "state_NotStart_bg" },
            { "state_Accepted", "state_Accepted_bg" },
            { "state_Completed", "state_Completed_bg" },
            { "state_Taken", "state_Taken_bg" },
            { "state_Over", "state_Over_bg" }
        },
        self._stateObj
    )
    UIWidgetHelper.SetObjGroupShow(self._stateObj, state)
end

function UIActivityReturnSystemQuestListItem:_SetStateCount(state)
    ---@type PersonProgressComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "quest", 2)

    local itemId = component:GetItemId()

    -- 获取 个人进度组件 关键物品的数量
    local count = component:GetProgressItemCountInTable(self._quest.rewards)
    self._stateCountTxt[state]:SetText(count)
end

--region DynamicList
function UIActivityReturnSystemQuestListItem:_SetDynamicListData()
    self._dynamicListInfo = self._quest.rewards

    -- 去掉 个人进度组件 的关键物品
    ---@type PersonProgressComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "quest", 2)
    self._dynamicListInfo = component:RemoveProgressItemInTable(self._dynamicListInfo)

    self._itemCountPerRow = 1
    self._dynamicListSize = math.floor((table.count(self._dynamicListInfo) - 1) / self._itemCountPerRow + 1)
end

function UIActivityReturnSystemQuestListItem:_SetDynamicList()
    self:_SetDynamicListData()

    if not self._isDynamicInited then
        self._isDynamicInited = true

        ---@type UIDynamicScrollView
        self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

        self._dynamicList:InitListView(
            self._dynamicListSize,
            function(scrollView, index)
                return self:_SpawnListItem(scrollView, index)
            end
        )
    else
        self:_RefreshList(self._dynamicListSize, self._dynamicList)
    end
end

function UIActivityReturnSystemQuestListItem:_RefreshList(count, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityReturnSystemQuestListItem:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIActivityReturnSystemItemQuest", self._itemCountPerRow)
    end
    ---@type UIActivityReturnSystemItemQuest[]
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
    return item
end

---@param listItem UIActivityReturnSystemItemQuest
function UIActivityReturnSystemQuestListItem:_SetListItemData(listItem, index)
    local info = self._dynamicListInfo[index]
    listItem:SetData(index, info, self._tipsCallback)
end

--endregion

--region Event Callback
function UIActivityReturnSystemQuestListItem:state_AcceptedOnClick()
    self._module = GameGlobal.GetModule(QuestModule)

    ---@type UIJumpModule
    local jumpModule = self._module.uiModule
    if jumpModule == nil then
        Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
        return
    end
    --FromUIType.NormalUI
    local fromParam = {}
    table.insert(fromParam, QuestType.QT_Daily)
    jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
    local jumpType = self._quest.JumpID
    local jumpParams = self._quest.JumpParam
    jumpModule:SetJumpUIData(jumpType, jumpParams)
    jumpModule:Jump()
end

function UIActivityReturnSystemQuestListItem:state_CompletedOnClick()
    if self._callback then
        self._callback(self._quest)
    end
end

--endregion
