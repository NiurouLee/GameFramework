---@class UIShopCurrency1To2:UIController
_class("UIShopCurrency1To2", UIController)
UIShopCurrency1To2 = UIShopCurrency1To2

function UIShopCurrency1To2:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetRechargeShopData()

    self._rateYJ2GP = self.clientShop:GetDiamondExchangeGlowRate()

    self._curCount = 1
end

function UIShopCurrency1To2:OnShow(uiParams)
    ---@type UILocalizationText
    self._txtExchange = self:GetUIComponent("UILocalizationText", "txtExchange")
    ---@type UILocalizationText
    self._txtGuangpo = self:GetUIComponent("UILocalizationText", "txtGuangpo")
    ---@type UILocalizationText
    self._txtYaojing = self:GetUIComponent("UILocalizationText", "txtYaojing")
    ---@type UILocalizationText
    self._txtBuyCount = self:GetUIComponent("UILocalizationText", "txtBuyCount")
    ---@type UnityEngine.UI.Button
    self._btnBottom = self:GetUIComponent("Button", "btnBottom")
    ---@type UnityEngine.UI.Button
    self._btnMinus = self:GetUIComponent("Button", "btnMinus")
    ---@type UnityEngine.UI.Button
    self._btnAdd = self:GetUIComponent("Button", "btnAdd")
    ---@type UnityEngine.UI.Button
    self._btnTop = self:GetUIComponent("Button", "btnTop")

    local count1, _ = self.shopModule:GetDiamondCount()
    local diff = uiParams[1] --光珀差额
    if diff and diff > self._rateYJ2GP then
        local ceil = math.ceil(diff / self._rateYJ2GP)
        local max = count1
        if max < 1 then
            max = 1
        end
        self._curCount = Mathf.Clamp(ceil, 1, max) --最小1，最大当前耀晶数
    end
    self:Flush()
end

function UIShopCurrency1To2:OnHide()
end

function UIShopCurrency1To2:Flush()
    self:FlushBtns()
    self:FlushCurCount()
end

function UIShopCurrency1To2:FlushBtns()
    local count1, _ = self.shopModule:GetDiamondCount()
    local interactable = count1 > 0
    self._btnBottom.interactable = interactable
    self._btnMinus.interactable = interactable
    self._btnAdd.interactable = interactable
    self._btnTop.interactable = interactable
end

---刷新当前购买数量
function UIShopCurrency1To2:FlushCurCount()
    local count1, _ = self.shopModule:GetDiamondCount()
    local guangpo = self._curCount * self._rateYJ2GP
    self._txtGuangpo:SetText(guangpo)
    self._txtYaojing:SetText(string.format(self._curCount .. "/" .. count1))
    if count1 <= 0 then
        self._txtExchange:SetText(StringTable.Get("str_pay_yj_not_enough_cant_exchange"))
        self._txtBuyCount:SetText(0)
    else
        self._txtExchange:SetText(
            string.format(StringTable.Get("str_pay_cost_n_yj_exchange_m_gp", self._curCount, guangpo))
        )
        self._txtBuyCount:SetText(self._curCount)
    end
end

function UIShopCurrency1To2:bgOnClick(go)
    self:CloseDialog()
end

function UIShopCurrency1To2:btnCancelOnClick(go)
    self:CloseDialog()
end

function UIShopCurrency1To2:btnEnsureOnClick(go)
    local count1, freeCount1 = self.shopModule:GetDiamondCount()
    if count1 <= 0 then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            "",
            StringTable.Get("str_pay_yj_not_enough_goto_recharge"),
            function(param)
                self.clientShop:OpenRechargeShop()
                self:CloseDialog()
            end,
            nil,
            function(param)
            end,
            nil
        )
        return
    end
    local mShop = self:GetModule(ShopModule)
    self:StartTask(
        function(TT)
            self:Lock("ApplyDiamondExchangeGlow")
            local guangpo = self._curCount * self._rateYJ2GP
            local ret = mShop:ApplyDiamondExchangeGlow(TT, self._curCount, guangpo)
            if ClientShop.CheckShopCode(ret:GetResult()) then
                local toast =
                    string.format(StringTable.Get("str_pay_cost_n_yj_exchange_m_gp_success", self._curCount, guangpo))
                ToastManager.ShowToast(toast)
                self:CloseDialog()
            end
            self:UnLock("ApplyDiamondExchangeGlow")
        end,
        self
    )
end

function UIShopCurrency1To2:btnRechargeOnClick(go)
    if not UIShopController.CheckIsOpen(ShopMainTabType.Recharge) then
        return
    end
    self.clientShop:OpenRechargeShop()
    self:CloseDialog()
end

function UIShopCurrency1To2:btnBottomOnClick(go)
    local count1, _ = self.shopModule:GetDiamondCount()
    if count1 <= 0 then
        return
    end
    self._curCount = 1
    self:FlushCurCount()
end
function UIShopCurrency1To2:btnTopOnClick(go)
    local count1, _ = self.shopModule:GetDiamondCount()
    if count1 <= 0 then
        return
    end
    self._curCount = count1
    self:FlushCurCount()
end

function UIShopCurrency1To2:btnMinusOnClick(go)
    local count1, _ = self.shopModule:GetDiamondCount()
    if count1 <= 0 then
        return
    end
    if self._curCount <= 1 then
        self._curCount = 1
        self:FlushCurCount()
        return
    end
    self._curCount = self._curCount - 1
    self:FlushCurCount()
end
function UIShopCurrency1To2:btnAddOnClick(go)
    local count1, _ = self.shopModule:GetDiamondCount()
    if count1 <= 0 then
        return
    end
    if self._curCount >= count1 then
        self._curCount = count1
        self:FlushCurCount()
        return
    end
    self._curCount = self._curCount + 1
    self:FlushCurCount()
end
