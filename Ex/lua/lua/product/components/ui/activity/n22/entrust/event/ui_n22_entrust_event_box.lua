---@class UIN22EntrustEventBox : UIN22EntrustEventBase
_class("UIN22EntrustEventBox", UIN22EntrustEventBase)
UIN22EntrustEventBox = UIN22EntrustEventBox

-- 虚函数
function UIN22EntrustEventBox:Refresh()
    self:_SetRoot(false)

    --检查该宝箱是否领取
    local pass = self._component:IsEventPass(self._levelId, self._eventId)
    if pass then
        local tips = StringTable.Get("str_n22_entrust_event_box_got_tips")
        ToastManager.ShowToast(tips) -- 飘字
        self:CloseDialog()
    else
        self:RequestEvent()
    end
end

-- 虚函数
function UIN22EntrustEventBox:OnEventFinish(rewards)
    Log.info("UIN22EntrustEventBox:OnEventFinish()")

    local title = StringTable.Get("str_activity_battlepass_buy_deluxe_claim")
    self:ShowDialog("UIN22EntrustRewardsController", title, rewards,
        function()
            self:CloseDialog()
        end
    )
end