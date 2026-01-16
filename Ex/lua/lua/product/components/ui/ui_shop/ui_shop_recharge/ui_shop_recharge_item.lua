---@class UIShopRechargeItem:UICustomWidget
_class("UIShopRechargeItem", UICustomWidget)
UIShopRechargeItem = UIShopRechargeItem

function UIShopRechargeItem:OnShow()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetRechargeShopData()

    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._label = self:GetGameObject("label")
    ---@type UILocalizationText
    self.label = self:GetUIComponent("UILocalizationText", "label")
    ---@type UILocalizationText
    self._txtLabel = self:GetUIComponent("UILocalizationText", "txtLabel")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self._txtPaid = self:GetUIComponent("UILocalizationText", "txtPaid")
    self._txtFree = self:GetUIComponent("UILocalizationText", "txtFree")
    self._txtPrice = self:GetUIComponent("UILocalizationText", "txtPrice")
    self._txtPrice:SetText("")

    self._offset = self:GetGameObject( "offset")
    self._giftGo = self:GetGameObject( "gift")

    self._gift = self:GetUIComponent("UISelectObjectPath", "gift")
    self:AttachEvent(GameEventType.UpdateRechargeItemPrice, self.FlushPrice)
    self:AttachEvent(GameEventType.UpdateRechargeItemPresent, self.FlushPresent)
end
function UIShopRechargeItem:OnHide()
    self:DetachEvent(GameEventType.UpdateRechargeItemPrice, self.FlushPrice)
    self:DetachEvent(GameEventType.UpdateRechargeItemPresent, self.FlushPresent)
end

---@param id number
function UIShopRechargeItem:Flush(id)
    self._isGift = false
    self._offset:SetActive(true)
    self._giftGo:SetActive(false)
    self._itemData = self._data:GetGoodBuyId(id)
    self._txtName:SetText(self._itemData:GetName())
    self._imgIcon:LoadImage(self._itemData:GetIcon())
    self._txtPaid:SetText(self._itemData:GetCount())
    self:FlushPrice()
    self:FlushPresent()
end

---@param id number
function UIShopRechargeItem:FlushGift(id)
   self._isGift = true
   self._offset:SetActive(false)
   self._giftGo:SetActive(true)
   self.shopGiftPackItem =  self._gift:SpawnObject("UIShopGiftPackItem")
   self.shopGiftPackItem:Flush(id)
end

function UIShopRechargeItem:FlushPrice()
    if not self._itemData then
       return 
    end 
    self._txtPrice:SetText(self._itemData:GetPrice())
end

function UIShopRechargeItem:FlushPresent()
    if not self._itemData then
        return 
    end 
    local hasBuy = self._itemData:GetHasBuy()
    if hasBuy then
        self._label:SetActive(false)
    else
        self._label:SetActive(true)
        local label = self._itemData:GetLabel()
        self.label:SetText(label)
        self._txtLabel:SetText(label)
    end
    self._txtFree:SetText(self._itemData:GetCountFree())
end

---点击商品进入充值流程
function UIShopRechargeItem:bgOnClick()
    self:CanCharge()
end
function UIShopRechargeItem:btnPriceOnClick()
    self:CanCharge()
end

function UIShopRechargeItem:CanCharge()
    if string.isnullorempty(self._txtPrice.text) then
        return
    end
    self:Lock("UIShopRechargeItem_CanCharge")
    GameGlobal.TaskManager():StartTask(self.CanChargeCoro, self)
end

function UIShopRechargeItem:CanChargeCoro(TT)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    if not roleModule:IsJapanZone() then
        self:Charge()
        self:UnLock("UIShopRechargeItem_CanCharge")
        return
    end
    ---@type PayModule
    local payModule = GameGlobal.GetModule(PayModule)
    --判断是否选择了年龄
    if payModule:NeedSelectAge(TT) then
        self:ShowDialog("UISetAgeConfirmController")
        self:UnLock("UIShopRechargeItem_CanCharge")
        return
    end
    self:Charge()
    -- --判断是否可以充值
    -- local res, replyEvent = payModule:CanPay(TT, self._itemData:GetCount())
    -- if replyEvent.result == 0 then --可以充值
    --     self:Charge()
    -- elseif replyEvent.result == 3 then --充值已经达到上限
    --     local res1, replyEvent1 = self._payModule:GetAgeId(TT)
    --     local id = 0
    --     if res1:GetSucc() then
    --         id = replyEvent1.cfg_id
    --     end
    --     self:ShowDialog("UIPayLawTipsController", id)
    -- else --未知错误
    --     Log.error("can pay msg error")
    -- end
    self:UnLock("UIShopRechargeItem_CanCharge")
end

function UIShopRechargeItem:Charge()
    if not self._itemData then
        Log.fatal("### self._itemData is nil.")
        GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.LaunchPurchaseUI, false, -1, "nil")
        return
    end    
    GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.LaunchPurchaseUI, true, 0, "Charge"..tostring(self._itemData:GetCount()))
    local mPay = self:GetModule(PayModule)
    mPay:Recharge(self._itemData)
end
