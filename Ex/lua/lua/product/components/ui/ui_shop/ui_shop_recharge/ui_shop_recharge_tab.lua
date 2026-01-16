--[[
    商城充值页签（一级页签）
]]
---@class UIShopRechargeTab:UICustomWidget
_class("UIShopRechargeTab", UICustomWidget)
UIShopRechargeTab = UIShopRechargeTab

function UIShopRechargeTab:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetRechargeShopData()
    self._giftData = self.clientShop:GetGiftPackShopData()
end

function UIShopRechargeTab:OnShow()
    self:AttachEvent(GameEventType.UpdateRechargeShop, self.Flush)
    self:AttachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
    ---@type UICustomWidgetPool
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self:Flush()
    self:OpenSelectAgePanel()
end
function UIShopRechargeTab:OnHide()
    self:DetachEvent(GameEventType.UpdateRechargeShop, self.Flush)
    self:DetachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
end

function UIShopRechargeTab:Flush()
    local items = self._data:GetGoods()
    local giftItems = self._giftData:GetRechargeGiftGoods()
    local count = table.count(items) + table.count(giftItems)
    self._content:SpawnObjects("UIShopRechargeItem", count)
    ---@type UIShopRechargeItem[]
    local uiItems = self._content:GetAllSpawnList()
    local index = 0

    for i, uiItem in ipairs(giftItems) do
        index = index + 1
        uiItems[index]:FlushGift(giftItems[i]:GetId())
    end
    for i, uiItem in ipairs(items) do
        index = index + 1 
        uiItems[index]:Flush(items[i]:GetId())
    end
end

function UIShopRechargeTab:OpenSelectAgePanel()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    if roleModule:IsJapanZone() then
        ---@type PayModule
        local payModule = GameGlobal.GetModule(PayModule)
        if payModule:IsShowSelectAgePanel() then
            self:ShowDialog("UISetAgeConfirmController")
        end
        payModule:OpenSelectAgePanel()
    end
end

--region ...
function UIShopRechargeTab:Update(deltaTimeMS)
end
function UIShopRechargeTab:SetData(param)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopTabChange, ShopMainTabType.Recharge)
end
function UIShopRechargeTab:RefreshPanel(subTabType)
end
function UIShopRechargeTab:ExcuteHideLogic(callBack)
    if callBack then
        callBack(self)
    end
end
--endregion
