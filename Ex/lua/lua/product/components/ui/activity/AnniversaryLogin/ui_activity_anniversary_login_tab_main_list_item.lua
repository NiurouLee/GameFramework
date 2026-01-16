---@class UIActivityAnniversaryLoginTabMainListItem:UICustomWidget
_class("UIActivityAnniversaryLoginTabMainListItem", UICustomWidget)
UIActivityAnniversaryLoginTabMainListItem = UIActivityAnniversaryLoginTabMainListItem


--region help
--
function UIActivityAnniversaryLoginTabMainListItem:_SetRemainingTime(widgetName, descId, endTime, customTimeStr)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")

    if customTimeStr then
        obj:SetCustomTimeStr_Common_1()
    end
    obj:SetExtraRollingText()
    -- obj:SetExtraText("txtDesc", nil, extraId)
    obj:SetAdvanceText(descId)

    obj:SetData(endTime, nil, function(first)
        if not first then
            self._refreshCallback(1, true)
        end
    end)
end

--endregion

--
function UIActivityAnniversaryLoginTabMainListItem:OnShow(uiParams)
end

--
function UIActivityAnniversaryLoginTabMainListItem:OnHide()
end

--
---@param timeReward TimeRewardInfo
function UIActivityAnniversaryLoginTabMainListItem:SetData(component, index, timeReward, refreshCallback, tipsCallback, btnCallback)
    self._component = component
    self._index = index
    self._timeReward = timeReward
    self._refreshCallback = refreshCallback
    self._tipsCallback = tipsCallback
    self._btnCallback = btnCallback

    self:_SetState(timeReward.rec_reward_status)
    self:_SetRemainingTime("_timePool", "", timeReward.unlock_time, true)

    ---@type list<RoleAsset>
    self._infos = timeReward.rewards
    self:_SetDynamicList()
end

function UIActivityAnniversaryLoginTabMainListItem:_SetState(state)
    -- 依据 ETimeRewardRewardStatus
    self._stateObj = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            [ETimeRewardRewardStatus.E_TIME_REWARD_UNKNOW] = {},
            [ETimeRewardRewardStatus.E_TIME_REWARD_CAN_RECV] = { "state_Completed" }, -- 可领取
            [ETimeRewardRewardStatus.E_TIME_REWARD_RECVED] = { "state_Taken" }, -- 已领取
            [ETimeRewardRewardStatus.E_TIME_REWARD_LOCK] = { "state_NotStart" } -- 未解锁
        },
        self._stateObj
    )
    UIWidgetHelper.SetObjGroupShow(self._stateObj, state)
end

--
function UIActivityAnniversaryLoginTabMainListItem:_SetDynamicList()
    if not self._dynamicListHelper then
        ---@type UIActivityDynamicListHelper
        self._dynamicListHelper = UIActivityDynamicListHelper:New(
            self,
            self:GetUIComponent("UIDynamicScrollView", "_dynamicList"),
            "UIActivityAnniversaryLoginItem",
            function(listItem, itemIndex)
                listItem:SetData(self._infos[itemIndex], self._timeReward.rec_reward_status, self._tipsCallback)
            end
        )
    end

    local itemCount = #self._infos
    local itemCountPerRow = 1
    self._dynamicListHelper:Refresh(itemCount, itemCountPerRow)
end

--region Event Callback

--
function UIActivityAnniversaryLoginTabMainListItem:ClaimBtnOnClick(go)
    if self._btnCallback then
        self._btnCallback(self._component, self._index)
    end
end

--endregion
