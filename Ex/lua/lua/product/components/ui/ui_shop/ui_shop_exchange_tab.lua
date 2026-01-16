--[[
    商店，兑换子页签
]]
---@class UIShopExchangeTab:UICustomWidget
_class("UIShopExchangeTab", UICustomWidget)
UIShopExchangeTab = UIShopExchangeTab

function UIShopExchangeTab:OnShow()
    ---@type ShopModule
    self._shopModule = self:GetModule(ShopModule)
    ---@type ClientShop
    self._clienShop = self._shopModule:GetClientShop()

    ---@type SvrTimeModule
    self._timeModule = self:GetModule(SvrTimeModule)

    self._curShop = nil

    self._remainTime = self:GetUIComponent("UILocalizationText", "time")
    self._refreshPanal = self:GetGameObject("refreshpanel")
    self.itemCountPerRow = 2
    self.scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")
    self.scrollView:InitListView(
        1,
        function(_scrollView, index)
            return self:createItem(_scrollView, index)
        end
    )

    --3个商店页签，没有配置需求
    local tglGroup = self:GetUIComponent("ToggleGroup", "toggle")
    local shopPool = self:GetUIComponent("UISelectObjectPath", "toggle")
    shopPool:SpawnObjects("UIShopSecretTabBtn", 4)
    ---@type table<number,UIShopSecretTabBtn>
    local shopBtns = shopPool:GetAllSpawnList()
    shopBtns[1]:Init(
        nil,
        StringTable.Get("str_shop_xingzuan"),
        tglGroup,
        function()
            self:onChangeShop(MarketType.Shop_XingZuan)
        end
    )
    shopBtns[2]:Init(
        nil,
        StringTable.Get("str_shop_huiyao"),
        tglGroup,
        function()
            self:onChangeShop(MarketType.Shop_HuiYao)
        end
    )
    shopBtns[3]:Init(
        nil,
        StringTable.Get("str_shop_hongpiao"),
        tglGroup,
        function()
            self:onChangeShop(MarketType.Shop_HongPiao)
        end
    )
    shopBtns[4]:Init(
        nil,
        StringTable.Get("str_shop_guangpo"),
        tglGroup,
        function()
            self:onChangeShop(MarketType.Shop_GuangPo)
        end
    )

    ---@type table<number,UIShopSecretTabBtn>
    self._shopBtns = {
        [MarketType.Shop_XingZuan] = shopBtns[1],
        [MarketType.Shop_HuiYao] = shopBtns[2],
        [MarketType.Shop_GuangPo] = shopBtns[4],
        [MarketType.Shop_HongPiao] = shopBtns[3]
    }

    self._countDownTimer = nil
end

function UIShopExchangeTab:OnHide()
    if self._countDownTimer then
        GameGlobal.Timer():CancelEvent(self._countDownTimer)
        self._countDownTimer = nil
    end
end

function UIShopExchangeTab:SetData(params)
    --默认选中星钻
    local default = MarketType.Shop_XingZuan
    if params and params[3] then
        default = params[3]
    end
    self:onChangeShop(default)
    self:AttachEvent(GameEventType.ShopBuySuccess, self.onBuySuccess)
end

function UIShopExchangeTab:Update()
end

function UIShopExchangeTab:onChangeShop(shop)
    if self._curShop == shop then
        return
    end
    for key, btn in pairs(self._shopBtns) do
        btn:Select(false)
    end
    self._shopBtns[shop]:Select(true)
    self:StartTask(self.reqRefreshShop, self, shop)
end

function UIShopExchangeTab:reqRefreshShop(TT, shop)
    local success = self:requestShopData(TT, shop)
    if success then
        self:showShop(shop)
    end
end

function UIShopExchangeTab:showShop(shop)
    self._curShop = shop
    self._refreshPanal:SetActive(false)
    if self._countDownTimer then
        GameGlobal.Timer():CancelEvent(self._countDownTimer)
        self._countDownTimer = nil
    end
    if self._curShop == MarketType.Shop_XingZuan then
        self:showCountDown()
        self._refreshPanal:SetActive(true)
    elseif self._curShop == MarketType.Shop_HuiYao then
        self:showCountDown()
        self._refreshPanal:SetActive(true)
    elseif self._curShop == MarketType.Shop_GuangPo then
    end
    self:refreshGoods(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopTabChange, ShopMainTabType.Exchange, self._curShop)
end

function UIShopExchangeTab:showCountDown()
    if self._countDownTimer then
        GameGlobal.Timer():CancelEvent(self._countDownTimer)
        self._countDownTimer = nil
    end
    local refresh = function()
        local time = self._clienShop:GetExchangeShopResetTime()
        self._remainTime:SetText(HelperProxy:GetInstance():FormatTime_2(time))
        if time <= 0 then
            self:onTimeUp()
        end
    end
    refresh()
    self._countDownTimer = GameGlobal.Timer():AddEventTimes(1000, TimerTriggerCount.Infinite, refresh)
end

function UIShopExchangeTab:onTimeUp()
    if self._countDownTimer then
        GameGlobal.Timer():CancelEvent(self._countDownTimer)
        self._countDownTimer = nil
    end
    self:StartTask(self.reqRefreshShop, self, self._curShop)
end

function UIShopExchangeTab:refreshGoods(reScroll)
    local row = math.ceil(table.count(self._clienShop:GetExchangeShopData(self._curShop)) / self.itemCountPerRow)
    self.scrollView:SetListItemCount(row)
    self.scrollView:RefreshAllShownItem()
    if reScroll then
        self.scrollView:MovePanelToItemIndex(0, 0)
    end
end

function UIShopExchangeTab:createItem(_scrollView, _index)
    if _index < 0 or not self._curShop then
        return nil
    end
    local item = _scrollView:NewListViewItem("item")
    local pool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        pool:SpawnObjects("UIShopSecretGood", self.itemCountPerRow)
    end

    local goods = self._clienShop:GetExchangeShopData(self._curShop)

    local rowList = pool:GetAllSpawnList()
    for i = 1, self.itemCountPerRow do
        ---@type UIShopSecretGood
        local item = rowList[i]
        local itemIndex = _index * self.itemCountPerRow + i
        local data = goods[itemIndex]
        if data then
            -- self.itemTable[itemIndex] = item
            item:Enable(true)
            local targetShopId = nil
            if self.gotoType == ShopGotoType.OpenShopConfirm then
                targetShopId = self.targetShopId
                self:ClearFlag()
            end
            item:Refresh(self._curShop, data, targetShopId)
        else
            item:Enable(false)
        end
    end
    return item
end
function UIShopExchangeTab:ExcuteHideLogic(cb)
    if cb then
        cb(self)
    end
    if self._countDownTimer then
        GameGlobal.Timer():CancelEvent(self._countDownTimer)
        self._countDownTimer = nil
    end
    self._curShop = nil
    self:DetachEvent(GameEventType.ShopBuySuccess, self.onBuySuccess)
end

function UIShopExchangeTab:ClearFlag()
    self.gotoType = nil
    self.targetShopId = nil
end

function UIShopExchangeTab:onBuySuccess()
    self:StartTask(self.refreshCurShop, self)
end

function UIShopExchangeTab:refreshCurShop(TT)
    local success = self:requestShopData(TT, self._curShop)
    if success then
        self:refreshGoods(false)
    end
end

function UIShopExchangeTab:requestShopData(TT, shop)
    self:Lock(self:GetName())
    local res = nil
    local success = false
    if shop == MarketType.Shop_XingZuan then
        res = self._shopModule:RequestXingzuanMarket(TT)
    elseif shop == MarketType.Shop_HuiYao then
        res = self._shopModule:RequestHuiyaoMarket(TT)
    elseif shop == MarketType.Shop_GuangPo then
        res = self._shopModule:RequestGlowMarket(TT)
    elseif shop == MarketType.Shop_HongPiao then
        res = self._shopModule:RequestHongPiaoMarket(TT)
    end
    if res then
        if res:GetSucc() then
            self._clienShop:RefreshExchangeShopData(shop)
            success = true
        elseif res:GetResult() == SHOP_CODE.SHOP_SHOPTYPE_ERROR then
            ToastManager.ShowToast(StringTable.Get("str_shop_subtype_error"))
        else
            ToastManager.ShowToast(StringTable.Get("str_shop_unkown_error", res:GetResult()))
        end
    end
    self:UnLock(self:GetName())
    return success
end
