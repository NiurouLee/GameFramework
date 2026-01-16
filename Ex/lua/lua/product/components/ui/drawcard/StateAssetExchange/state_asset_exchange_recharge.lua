---@class StateAssetExchangeRecharge : State
_class("StateAssetExchangeRecharge", State)
StateAssetExchangeRecharge = StateAssetExchangeRecharge

function StateAssetExchangeRecharge:Init()
    self._fsm = self:GetFsm()
end

function StateAssetExchangeRecharge:OnEnter(TT, ...)
    self:Init()
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_pay_res_not_enough_goto_recharge"), --资源不足，是否前往充值
        function(param)
            if self._fsm then
                local mShop = GameGlobal.GetModule(ShopModule)
                mShop:GetClientShop():OpenRechargeShop()
                self._fsm:ChangeState(StateAssetExchange.Init)
            end
        end,
        nil,
        function(param)
            if self._fsm then
                self._fsm:ChangeState(StateAssetExchange.Init)
            end
        end,
        nil
    )
end

function StateAssetExchangeRecharge:OnExit(TT)
end

function StateAssetExchangeRecharge:Destroy()
    self._fsm = nil
end
