--[[
    商城神秘页签（一级页签）
]]
---@class UIShopSecretTab:UICustomWidget

_class("UIShopSecretTab", UICustomWidget)
UIShopSecretTab = UIShopSecretTab
local modf = math.modf

function UIShopSecretTab:Constructor()
    self.tabNames = {
        [MarketType.Shop_BlackMarket] = StringTable.Get("str_shop_secret_black_name"),
        [MarketType.Shop_MysteryMarket] = StringTable.Get("str_shop_secret_secret_name"),
        [MarketType.Shop_WorldBoss] = StringTable.Get("str_shop_secret_worldboss_name")
    }
    self.SortTab = Cfg.cfg_shop_main_tab[ShopMainTabType.Secret].SubTab
    self.subTabType = 1
    self.time = 0
    --一多少个
    self.itemCountPerRow = 2
    self.itemTable = {}
    self.uiGoods = {}
    self.first = true
    self.remainSecond = 0
    self._countdownTimer = 0

    self._refreshTaskID = nil
    self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end
---targetShopId 如果存在则打开对应商品购物窗
function UIShopSecretTab:SetData(param)
    self.show = true
    self.gotoType = param and param[1]
    local mainTabType = param and param[2]
    local subTabType = param and param[3] or self.SortTab[1]
    self.targetShopId = param and param[4]
    self:OnClickTabBtn(subTabType, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeShopBg, ShopMainTabType.Secret)
    self:AddListener()
end

function UIShopSecretTab:ExcuteHideLogic(callBack)
    self.show = false
    -- self.hideTaskId =
    --     self:StartTask(
    --     function(TT)
    --         -- self:Lock("UIShopSecretAnimOut")
    --         self.animator:SetTrigger("out")
    --         YIELD(TT, 567)
    --         if self.show == false then
    --             callBack(self)
    --         -- self:UnLock("UIShopSecretAnimOut")
    --         end
    --     end
    -- )
    if callBack then
        callBack(self)
    end
    self:ClearFlag()
    for i, toggle in ipairs(self.allToggle) do
        if i == 1 then
            self.subTabType = self.SortTab[1]
            if toggle then
                toggle:Select(true)
            end
        else
            if toggle then
                toggle:Select(false)
            end
        end
    end
 
    self:DetachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)
end

function UIShopSecretTab:Update(deltaTimeMS)
    -- 00 00 00 刷新
    if self.startTime then
        self._countdownTimer = self._countdownTimer + deltaTimeMS
        if self._countdownTimer > 1000 then
            self._countdownTimer = 0
            self:countDown()
        end
    end
end

function UIShopSecretTab:countDown()
    local remainTime = self.data:GetRemainSecond()
    if not remainTime then
        return
    end
    local time = remainTime + 1 --比服务器晚1秒
    local timeStr = HelperProxy:GetInstance():FormatTime_2(math.floor(time))
    local showStr = StringTable.Get("str_shop_black_refresh", timeStr)
    self.timeTxt:SetText(showStr)
    if time <= 0 then
        self:StartTask(
            function(TT)
                if not self.clientShop:SendProtocal(TT, ShopMainTabType.Secret, self.subTabType) then
                    return
                end
                self:RefreshPanel()
            end
        )
    end
end

function UIShopSecretTab:OnShow()
    self._refreshTaskID = nil
    self.tglGroup = self:GetUIComponent("ToggleGroup", "toggle")
    self.timeTxt = self:GetUIComponent("UILocalizationText", "time")
    self.timeRect = self:GetUIComponent("RectTransform", "time")
    self.priceTxt = self:GetUIComponent("UILocalizationText", "price")
    self.moneyIcon = self:GetUIComponent("Image", "moneyicon")
    self.curCountTxt = self:GetUIComponent("UILocalizationText", "curcount")
    self.maxCountTxt = self:GetUIComponent("UILocalizationText", "maxcount")
    self.refreshGO = self:GetGameObject("refreshpanel")
    local toggle = self:GetUIComponent("UISelectObjectPath", "toggle")
    local len = #self.SortTab
    toggle:SpawnObjects("UIShopSecretTabBtn", len)
    self.allToggle = toggle:GetAllSpawnList()
    for i, v in ipairs(self.allToggle) do
        v:Init(self.SortTab[i], self.tabNames[self.SortTab[i]], self.tglGroup, self.OnClickTabBtn, self)
    end
    self.scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")
    self.scrollViewRect = self:GetUIComponent("ScrollRect", "ScrollView")
    self.contentRect = self:GetUIComponent("RectTransform", "btnrefresh")
    self.btnRefreshGO = self:GetGameObject("btnrefresh")
    self.reftimeGO = self:GetGameObject("reftime")
    self.reftimeRect = self:GetUIComponent("RectTransform", "reftime")
    self.countTxtGO = self:GetGameObject("refcount")

    self.refreshLayoutCS = self:GetUIComponent("ContentSizeFitter", "refreshlayout")
    self.refreshLayoutHL = self:GetUIComponent("HorizontalLayoutGroup", "refreshlayout")
    self.refreshLayoutRect = self:GetUIComponent("RectTransform", "refreshlayout")
    self.refreshLayoutGo = self:GetGameObject("refreshlayout")
    self.scrollView:InitListView(
        5,
        function(_scrollView, index)
            return self:CreateItem(_scrollView, index)
        end
    )
    -- self.animator = self:GetGameObject().transform:GetComponent("Animator")
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
end

function UIShopSecretTab:OnHide()
    if self._refreshTaskID then
        GameGlobal.TaskManager():KillTask(self._refreshTaskID)
        self._refreshTaskID = nil
    end
end

function UIShopSecretTab:AddListener()
    self:AttachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)
end

function UIShopSecretTab:GetTabBtnBySubType(subTabType)
    for k, v in pairs(self.allToggle) do
        if v:GetSubType() == subTabType then
            return v
        end
    end
    return nil
end

function UIShopSecretTab:OnClickTabBtn(subTabType, force, noAni)
    if not force then
        if self.subTabType == subTabType then
            return
        end
    end
    if self.subTabType then
        -- local toggle = self.allToggle[self.SortTab[self.subTabType]]
        local toggle = self:GetTabBtnBySubType(self.subTabType)
        if toggle then
            toggle:Select(false)
        end
    end
    self.subTabType = subTabType
    if self.subTabType then
        -- local toggle = self.allToggle[self.SortTab[self.subTabType]]
        local toggle = self:GetTabBtnBySubType(self.subTabType)
        if toggle then
            toggle:Select(true)
        end
    end
    if self.first then
        -- self:StartTask(
        --     function(TT)
        --         -- self:Lock("UIShopSecretAnimIn")
        --         self.animator:SetTrigger("in")
        --         YIELD(TT, 567)
        --         -- self:UnLock("UIShopSecretAnimIn")
        --     end
        -- )
        self:RefreshPanel(subTabType)
        self.first = false
    else
        self:Lock("UIShopSecretTab_OnClickTabBtn")
        self._refreshTaskID =
            self:StartTask(
            function(TT)
                if not self.clientShop:SendProtocal(TT, ShopMainTabType.Secret, subTabType) then
                    self:UnLock("UIShopSecretTab_OnClickTabBtn")
                    return
                end
                if not noAni then
                -- self:StartTask(
                --     function(TT)
                --         -- self:Lock("UIShopSecretAnimIn")
                --         self.animator:SetTrigger("in")
                --         YIELD(TT, 567)
                --         -- self:UnLock("UIShopSecretAnimIn")
                --     end
                -- )
                end
                self:RefreshPanel(subTabType)
                self:UnLock("UIShopSecretTab_OnClickTabBtn")
            end,
            self
        )
    end
end
-- function UIShopSecretTab:RefreshPanel(subTabType)
--     self:SendProtocol()
-- end
function UIShopSecretTab:RefreshPanel(subTabType)
    self.refreshGO:SetActive(true)
    if self.subTabType == MarketType.Shop_BlackMarket then
        -- self.timeRect.anchoredPosition = Vector2(-348, -444)
        self.btnRefreshGO:SetActive(true)
        self.reftimeGO:SetActive(true)
        self.countTxtGO:SetActive(true)
        self.refreshLayoutGo:SetActive(true)
        self.refreshLayoutCS.enabled = true
        self.refreshLayoutHL.enabled = true
    elseif self.subTabType == MarketType.Shop_MysteryMarket then -- 秘境探索
        self.btnRefreshGO:SetActive(false)
        self.reftimeGO:SetActive(true)
        self.countTxtGO:SetActive(false)
        -- self.refreshLayoutCS.enabled = false
        -- self.refreshLayoutHL.enabled = false
        self.refreshLayoutGo:SetActive(true)
        self.refreshLayoutRect.sizeDelta = Vector2(820, 57)
        self.reftimeRect.anchoredPosition = Vector2(550, -30)
    elseif self.subTabType == MarketType.Shop_WorldBoss then -- 世界Boss
        self.btnRefreshGO:SetActive(false)
        self.reftimeGO:SetActive(false)
        self.countTxtGO:SetActive(false)
        self.refreshLayoutGo:SetActive(false)
        -- self.refreshLayoutCS.enabled = false
        -- self.refreshLayoutHL.enabled = false
        -- self.refreshLayoutRect.sizeDelta = Vector2(820, 57)
        -- self.reftimeRect.anchoredPosition = Vector2(550, -30)
    end
    -- 黑市
    if self.subTabType == MarketType.Shop_BlackMarket then
        self.startTime = true
        self:RefreshStore()
        self:countDown()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.ShopTabChange,
            ShopMainTabType.Secret,
            MarketType.Shop_BlackMarket
        )
    elseif self.subTabType == MarketType.Shop_MysteryMarket then -- 秘境探索
        self.startTime = true
        self:RefreshStore()
        self:countDown()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.ShopTabChange,
            ShopMainTabType.Secret,
            MarketType.Shop_MysteryMarket
        )
    elseif self.subTabType == MarketType.Shop_WorldBoss then -- 世界boss
        self.startTime = false
        self:RefreshStore()
       -- self:countDown()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.ShopTabChange,
            ShopMainTabType.Secret,
            MarketType.Shop_WorldBoss
        )
    end
end

function UIShopSecretTab:RefreshStore(noResetTime)
    if self.gotoType == ShopGotoType.SortGoods then
        self.clientShop:ReSortSecretGoods(self.subTabType, self.targetShopId)
        self:ClearFlag()
    end
    -- fromserver
    self.data = self.clientShop:GetSecretTabData(self.subTabType)
    if self.data then
        if not noResetTime then
            self.remainSecond = self.data:GetRemainSecond()
            if not self.remainSecond then
                self.remainSecond = 0
            end
        end
        self.curCountTxt:SetText(self.data:GetMaxCount() - self.data:GetCurCount())
        self.maxCountTxt:SetText(self.data:GetMaxCount())
        self.priceTxt:SetText(self.data:GetConsume())
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.contentRect)

        self.uiGoods = self.data:GetSecretGoods()
        local _cfg = Cfg.cfg_top_tips[self.data:GetCostType()]
        self.moneyIcon.sprite = self.uiCommonAtlas:GetSprite(_cfg.Icon)
        self:RefreshScroll()
    end
end

function UIShopSecretTab:btnrefreshOnClick()
    local cur = self.data:GetCurCount()
    local max = self.data:GetMaxCount()
    if cur >= max then
        ToastManager.ShowToast(StringTable.Get("str_shop_black_refresh_no_count"))
        return
    end
    local consume = self.data:GetConsume()
    local costType = self.data:GetCostType()
    local ownMoney = ClientShop.GetMoney(costType)
    if ownMoney < consume then
        if costType == RoleAssetID.RoleAssetGlow then --消耗光珀
            GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", consume - ownMoney)
        else
            ToastManager.ShowToast(StringTable.Get("str_shop_black_refresh_no_diamond"))
        end
        return
    end

    --"是否消耗%d刷新黑市商店的物品？"
    local moneyCfg = Cfg.cfg_top_tips[costType]
    local str
    if self.subTabType == MarketType.Shop_BlackMarket then -- 黑市
        str = StringTable.Get("str_shop_black_refresh_box", consume, StringTable.Get(moneyCfg.Title))
    elseif self.subTabType == MarketType.Shop_MysteryMarket then -- 秘境探索
        str = StringTable.Get("str_shop_maze_refresh_box", consume, StringTable.Get(moneyCfg.Title))
    elseif self.subTabType == MarketType.Shop_WorldBoss then -- 世界boss
        str = StringTable.Get("str_shop_maze_refresh_box", consume, StringTable.Get(moneyCfg.Title)) --todo
    end

    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        str,
        function(param)
            self:StartTask(
                function(TT)
                    self:Lock("UIShopSecretTab.Refresh")
                    local shopCode, marketinfo
                    if self.subTabType == MarketType.Shop_BlackMarket then -- 黑市
                        shopCode, marketinfo = self.shopModule:ApplyRefreshBlackMarket(TT)
                    elseif self.subTabType == MarketType.Shop_MysteryMarket then -- 秘境探索
                        shopCode, marketinfo = self.shopModule:ApplyRefreshMysteryMarket(TT)
                    elseif self.subTabType == MarketType.Shop_WorldBoss then -- 秘境探索
                      --  shopCode, marketinfo = self.shopModule:ApplyRefreshMysteryMarket(TT)
                    end
                    self:UnLock("UIShopSecretTab.Refresh")
                    if marketinfo ~= {} and marketinfo ~= nil then
                        local result = ClientShop.CheckShopCode(shopCode)
                        if result then
                            local goodsconfig
                            if self.subTabType == MarketType.Shop_BlackMarket then
                                goodsconfig = self.shopModule:GetBlackMarketConfig()
                            elseif self.subTabType == MarketType.Shop_MysteryMarket then -- 秘境探索
                                goodsconfig = self.shopModule:GetMysteryMarketConfig()
                            elseif self.subTabType == MarketType.Shop_WorldBoss then -- worldboss
                                goodsconfig = self.shopModule:RequestWorldBossMarket()
                            end

                            self.clientShop:SetSecretTabData(marketinfo, goodsconfig, self.subTabType)
                            self:RefreshStore(true)
                        end
                    end
                end,
                self
            )
        end,
        nil,
        function(param)
            Log.debug("sale cancel. .")
        end,
        nil
    )
end

function UIShopSecretTab:RefreshScroll()
    self._listItemTotalCount = #self.uiGoods
    local row = self:_CalcTotalRow(self._listItemTotalCount)
    -- if row < 3 then
    --     self.scrollViewRect.enabled = false
    -- else
    --     self.scrollViewRect.enabled = true
    -- end
    self.scrollView:SetListItemCount(row)
    self.scrollView:RefreshAllShownItem()
    if self.dontMove then
        self.dontMove = false
    else
        self.scrollView:MovePanelToItemIndex(0, 0)
    end
end

function UIShopSecretTab:CreateItem(_scrollView, _index)
    if _index < 0 then
        return nil
    end
    local item = _scrollView:NewListViewItem("item")
    local pool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        pool:SpawnObjects("UIShopSecretGood", self.itemCountPerRow)
    end
    local rowList = pool:GetAllSpawnList()
    for i = 1, self.itemCountPerRow do
        ---@type UIShopSecretGood
        local item = rowList[i]
        local itemIndex = _index * self.itemCountPerRow + i
        local data = self.uiGoods[itemIndex]
        if data then
            item:Enable(true)
            local targetShopId = nil
            if self.gotoType == ShopGotoType.OpenShopConfirm then
                targetShopId = self.targetShopId
                self:ClearFlag()
            end
            item:Refresh(self.subTabType, data, targetShopId)
            self.itemTable[itemIndex] = item
        else
            item:Enable(false)
        end
    end
    return item
end

---@private
--计算行数
---@type itemTotalCount number
function UIShopSecretTab:_CalcTotalRow(itemTotalCount)
    --不能整除的就多一
    local row, mod = modf(itemTotalCount / self.itemCountPerRow)
    if mod ~= 0 then
        row = row + 1
    end

    self._listItemTotalRow = row

    return self._listItemTotalRow
end

function UIShopSecretTab:ShopBuySuccess()
    self.dontMove = true
    self:OnClickTabBtn(self.subTabType, true, true)
end
function UIShopSecretTab:ChangeSecondToTime(second)
    local timeTable = {["hour"] = 0, ["min"] = 0, ["sec"] = 0}

    if second == 0 then
        return timeTable
    end

    local sec = modf(second % 60)
    local minAll = modf((second - sec) / 60)
    local min = modf(minAll % 60)
    local hour = modf((minAll - min) / 60)
    if hour < 10 then
        hour = "0" .. hour
    end
    if min < 10 then
        min = "0" .. min
    end
    if sec < 10 then
        sec = "0" .. sec
    end
    timeTable["hour"] = hour
    timeTable["min"] = min
    timeTable["sec"] = sec

    return timeTable
end

--- 以后有功能了记得清理下标记位
function UIShopSecretTab:ClearFlag()
    self.gotoType = nil
    self.targetShopId = nil
end

function UIShopSecretTab:GetGood(index)
    return self.uiGoods and self.uiGoods[index]:GetGameObject("bg")
end
