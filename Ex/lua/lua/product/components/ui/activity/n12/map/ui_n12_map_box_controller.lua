require "ui_n12_map_controller"

---@class UIN12MapBoxController : UIN12MapController
_class("UIN12MapBoxController", UIN12MapController)
UIN12MapBoxController = UIN12MapBoxController

function UIN12MapBoxController:GetComponents()
end
function UIN12MapBoxController:OnValue()
    --检查该宝箱是否领取
    local got = self:CheckFinish()
    if got then
        --飘字
        local tips = StringTable.Get("str_n12_map_box_got_tips")
        ToastManager.ShowToast(tips)
        self:CloseDialog()
    else
        self:RequestFinishEvent()
    end
end
function UIN12MapBoxController:OnFinishEvent(rewards)
    self:ShowDialog("UIN12MapGetRewardsController",StringTable.Get("str_activity_battlepass_buy_deluxe_claim"),rewards,function()
        self:CloseDialog()
    end)
end