---处理耀晶兑换光珀，兑换成功后：
---1.跳转到StateAssetExchangeGp2Xb（用星标抽卡）
---2.跳转到StateAssetExchangeDrawCard（用光珀抽卡）
---@class StateAssetExchangeYj2Gp : State
_class("StateAssetExchangeYj2Gp", State)
StateAssetExchangeYj2Gp = StateAssetExchangeYj2Gp

function StateAssetExchangeYj2Gp:Init()
    self._fsm = self:GetFsm()
    ---@type UIDrawCardPoolItem
    self._ui = self._fsm:GetData()
    self._uiData = self._ui:GetUIData()
end

function StateAssetExchangeYj2Gp:OnEnter(TT, ...)
    self:Init()
    local costYJ, diffGP, diffXB = table.unpack({...})
    local strContent = ""
    if diffXB then
        strContent =
            StringTable.Get(
            "str_pay_drawcard_yj_2_gp_2_xb",
            costYJ,
            diffGP,
            diffXB,
            self._uiData:GetXBName(self._ui:GetIsSingle())
        )
    else
        strContent = string.format(StringTable.Get("str_pay_drawcard_yj_2_gp", costYJ, diffGP))
    end
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        strContent,
        function(param)
            if self._fsm then
                self:RequestYJ2GP(costYJ, diffGP, diffXB)
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

function StateAssetExchangeYj2Gp:OnExit(TT)
end

function StateAssetExchangeYj2Gp:Destroy()
    self._fsm = nil
    self._ui = nil
    self._uiData = nil
end

---请求耀晶换光珀
function StateAssetExchangeYj2Gp:RequestYJ2GP(count, diffGP, diffXB)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            local mShop = GameGlobal.GetModule(ShopModule)
            local clientShop = mShop:GetClientShop()
            local guangpo = count * clientShop:GetDiamondExchangeGlowRate()
            local ret = mShop:ApplyDiamondExchangeGlow(TT, count, guangpo)
            if ClientShop.CheckShopCode(ret:GetResult()) then
                if diffXB then
                    self._fsm:ChangeState(StateAssetExchange.Gp2Xb, diffGP, diffXB, false)
                else
                    self._fsm:ChangeState(StateAssetExchange.DrawCard)
                end
            else
                self._fsm:ChangeState(StateAssetExchange.Init)
            end
        end,
        self
    )
end
