--[[
    商城礼包页签（一级页签）
]]
---@class UIShopGiftPackTab:UICustomWidget
_class("UIShopGiftPackTab", UICustomWidget)
UIShopGiftPackTab = UIShopGiftPackTab

function UIShopGiftPackTab:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._dataRecharge = self.clientShop:GetRechargeShopData()
    self._data = self.clientShop:GetGiftPackShopData()
    self._mRole = GameGlobal.GameLogic():GetModule(RoleModule)
end

function UIShopGiftPackTab:OnShow()
    self:AttachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
    ---@type UICustomWidgetPool
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self:Flush()
    self:OpenSelectAgePanel()

    ---@type UIShopController
    local controller = self:RootUIOwner()
    controller:_CheckMonthCardTips(true)
end
function UIShopGiftPackTab:OnHide()
    self:DetachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
end

function UIShopGiftPackTab:Flush()
    self._items = self._data:GetGoods()
    local newItems = {}
    for k, v in pairs(self._items) do
        if not v:IsShowInSkinsTab() and (not v:GetRechargeGift()) then
            table.insert(newItems, v)
        end
    end

    self._items = newItems
    self._content:SpawnObjects("UIShopGiftPackItemContainer", table.count(self._items))
    ---@type UIShopGiftPackItemContainer[]
    self.uiItems = self._content:GetAllSpawnList()
    for i, uiItem in ipairs(self.uiItems) do
        local item = self._items[i]
        if item then
            uiItem:Flush(self._items[i]:GetId())
        else
            Log.fatal("### item nil. i=", i)
        end
    end
end

function UIShopGiftPackTab:OpenSelectAgePanel()
    -- ---@type RoleModule
    -- local roleModule = GameGlobal.GetModule(RoleModule)
    -- if roleModule:IsJapanZone() then
    --     ---@type PayModule
    --     local payModule = GameGlobal.GetModule(PayModule)
    --     if payModule:IsShowSelectAgePanel() then
    --         self:ShowDialog("UISetAgeConfirmController")
    --     end
    --     payModule:OpenSelectAgePanel()
    -- end
end

function UIShopGiftPackTab:JumpItem()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    if roleModule:IsJapanZone() then
        ---@type PayModule
        local payModule = GameGlobal.GetModule(PayModule)
        if payModule:IsShowSelectAgePanel() then
            self:ShowDialog("UISetAgeConfirmController")
            payModule:OpenSelectAgePanel()
            return
        end
    end

    if self._param then
        local jumpId = self._param[4] or 0
        if jumpId then
            for i, item in ipairs(self._items) do
                if item and item:GetId() == jumpId then
                    self.uiItems[i]:OpenUIShopGiftPackDetail()
                end
            end
        end
    end
end

--region ...
function UIShopGiftPackTab:Update(deltaTimeMS)
end
function UIShopGiftPackTab:SetData(param)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopTabChange, ShopMainTabType.Gift)
    self._param = param
    self:JumpItem()
end
function UIShopGiftPackTab:RefreshPanel(subTabType)
end
function UIShopGiftPackTab:ExcuteHideLogic(callBack)
    if callBack then
        callBack(self)
    end
    self._param = nil
end
--endregion
