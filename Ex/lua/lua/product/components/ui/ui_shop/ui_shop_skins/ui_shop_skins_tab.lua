---@class UIShopSkinsTab : UICustomWidget
_class("UIShopSkinsTab", UICustomWidget)
UIShopSkinsTab = UIShopSkinsTab
function UIShopSkinsTab:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetSkinsShopData()
    self._giftData = self.clientShop:GetGiftPackShopData()
    self._mRole = GameGlobal.GameLogic():GetModule(RoleModule)
    self._countPerPage = 4 --超过4个 可滑动
end
function UIShopSkinsTab:OnShow(uiParams)
    self:InitWidget()
    self:AttachEvent(GameEventType.UpdateSkinsShop, self.Flush)
    self:AttachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
    ---@type UICustomWidgetPool
    self:Flush()
end
function UIShopSkinsTab:OnHide()
    self:DetachEvent(GameEventType.UpdateSkinsShop, self.Flush)
    self:DetachEvent(GameEventType.UpdateGiftPackShop, self.Flush)
end
function UIShopSkinsTab:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._emptyTipsGo = self:GetGameObject("EmptyTips")
    self._scrollRect = self:GetUIComponent("ScrollRect", "ScrollView")

    --generated end--
end

function UIShopSkinsTab:Flush()
    self._items = {}

    local skinsItems = self:FilterFlush()
    local giftItems = self._giftData:GetGoods()
    for k, v in pairs(skinsItems) do
        local item = ShopUnionSkinsGiftItem:New(v, nil)
        table.insert(self._items, item)
    end

    for k, v in pairs(giftItems) do
        if v:IsShowInSkinsTab() then
            local item = ShopUnionSkinsGiftItem:New(nil, v)
            table.insert(self._items, item)
        end
    end

    self:SortFlush()

    local itemCount = #self._items

    --没有可显示的
    self._emptyTipsGo:SetActive(itemCount == 0)

    ---@type table<number, UIShopSkinsItem>
    self._uiItems = self._content:SpawnObjects("UIShopUnionSkinsGiftItem", itemCount)
    for i = 1, itemCount, 1 do
        local uiItem = self._uiItems[i]
        local dataItem = self._items[i]
        uiItem:Flush(dataItem, function(uiSubItem)
            uiSubItem:Flush(dataItem:GetId())
            uiSubItem:SetOutTimeClickFunc(function() self:_ConfirmSkinOverTimeBox() end)
        end, function(uiSubItem)
            uiSubItem:Flush(dataItem:GetId())
        end)
    end

    if itemCount > self._countPerPage then
        self._scrollRect.horizontal = true
    else
        self._scrollRect.horizontal = false
    end
end

function UIShopSkinsTab:FlushOld()
    if self._data:IsEmpty() then--没有可显示的
        self._emptyTipsGo:SetActive(true)
    else
        self._emptyTipsGo:SetActive(false)
    end

    self._items = {}
    local cfg = Cfg.cfg_shop_common_goods{}
    local filterItems = self._data:GetGoods()
    for i = 1, #filterItems do
        local item = filterItems[i]
        local id = item:GetId()
        local _cfg = cfg[id]
        local binderSkinID = _cfg.CurrencySkinID
        if binderSkinID then
            for j = 1, #filterItems do
                local binderItem = filterItems[j]
                local binderItemID = binderItem:GetId()
                if binderItemID == binderSkinID then
                    binderItem:SetBinderSkin(item)
                    break
                end
            end
        else
            table.insert(self._items,item)
        end
    end
    
    local itemCount = table.count(self._items)
    self._content:SpawnObjects("UIShopSkinsItem", itemCount)
    ---@type UIShopSkinsItem[]
    self._uiItems = self._content:GetAllSpawnList()
    for i, uiItem in ipairs(self._uiItems) do
        local item = self._items[i]
        if item then
            uiItem:Flush(self._items[i]:GetId())
            uiItem:SetOutTimeClickFunc(function()
                    self:_ConfirmSkinOverTimeBox()
                end
            )
        else
            Log.fatal("### item nil. i=", i)
        end
    end
    
    if itemCount > self._countPerPage then
        self._scrollRect.horizontal = true
    else
        self._scrollRect.horizontal = false
    end
end

function UIShopSkinsTab:FilterFlush()
    local filterItems = self._data:GetGoods()

    local lookup = {}
    for i = 1, #filterItems do
        local binderItem = filterItems[i]
        local binderItemID = binderItem:GetId()
        lookup[binderItemID] = binderItem
    end

    local skinsItems = {}
    local cfg = Cfg.cfg_shop_common_goods{}
    for i = 1, #filterItems do
        local item = filterItems[i]
        local id = item:GetId()
        local localCfg = cfg[id]
        local binderSkinID = localCfg.CurrencySkinID

        local binderItem = nil
        if binderSkinID then
            binderItem = lookup[binderSkinID]
        end

        if binderItem ~= nil then
            binderItem:SetBinderSkin(item)
        else
            table.insert(skinsItems, item)
        end
    end

    return skinsItems
end

function UIShopSkinsTab:SortFlush()
    ---@type ShopUnionSkinsGiftItem
    table.sort(self._items, function(a, b)
        local aId = a:GetId()
        local aOrder = a:GetOrder()
        local aResident = a:IsResident()
        local aSoldOut = a:HasSoldOut()

        local bId = b:GetId()
        local bOrder = b:GetOrder()
        local bResident = b:IsResident()
        local bSoldOut = b:HasSoldOut()

        -- 1、限时时装＞常驻时装
        if not aResident and bResident then
            return true
        elseif aResident and not bResident then
            return false
        end

        -- 2、可购买＞已购买
        if not aSoldOut and bSoldOut then
            return true
        elseif aSoldOut and not bSoldOut then
            return false
        end

        -- 3、顺序配置 min＞max
        if aOrder < bOrder then
            return true
        elseif aOrder > bOrder then
            return false
        end

        -- 4、id配置 min＞max
        return aId < bId
    end)
end

function UIShopSkinsTab:_ConfirmSkinOverTimeBox()
    local strTitle = StringTable.Get("str_login_msdk_tip")--提示
    local strText = StringTable.Get("str_shop_skin_off_shelf")
    local okCb = function()
        self:StartTask(
                        function(TT)
                            self.clientShop:SendProtocal(TT, ShopMainTabType.Skins)
                        end)
    end
    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, strTitle, strText, okCb, nil)
end
--region ...
function UIShopSkinsTab:Update(deltaTimeMS)
end

function UIShopSkinsTab:SetData(param)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopTabChange, ShopMainTabType.Skins)
    self._param = param
    self:JumpItem()
end
function UIShopSkinsTab:RefreshPanel(subTabType)
end
function UIShopSkinsTab:ExcuteHideLogic(callBack)
    if callBack then
        callBack(self)
    end
    self._param = nil
end
function UIShopSkinsTab:JumpItem()
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
                    local uiJumpItem = self._uiItems[i]
                    uiJumpItem:JumpItem()
                    break
                end
            end
        end
    end
end
--endregion
