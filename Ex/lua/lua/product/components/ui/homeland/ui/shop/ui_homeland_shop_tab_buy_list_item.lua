---@class UIHomelandShopTabBuyListItem:UICustomWidget
_class("UIHomelandShopTabBuyListItem", UICustomWidget)
UIHomelandShopTabBuyListItem = UIHomelandShopTabBuyListItem


--region help
--
function UIHomelandShopTabBuyListItem:_SetRemainingTime(widgetName, descId, endTime, customTimeStr)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")

    if customTimeStr then
        obj:SetCustomTimeStr_Common_1()
    end
    -- obj:SetExtraRollingText()
    -- obj:SetExtraText("txtDesc", nil, extraId)
    obj:SetAdvanceText(descId)

    obj:SetData(endTime, nil, nil)
end

--endregion

--
function UIHomelandShopTabBuyListItem:OnShow(uiParams)
end

--
function UIHomelandShopTabBuyListItem:OnHide()
end

--
function UIHomelandShopTabBuyListItem:SetData(index, data)
    self._index = index
    self._data = data

    self:_SetItemInfo(data.cfg.ItemID, data.cfg.ItemNum)
    self:_SetPriceInfo(data.cfg.CostID, self:_GetCost())

    local time = self:_GetRefreshTime(data.cfg.Type, data.week_time, data.moth_time)

    self:_SetLimitMode(data.cfg.Type)
    self:_SetLimitText(data.cfg.Type, data.soldCount, data.cfg.Limit)
    self:_SetLimitTime(data.cfg.Type, time)

    self:_SetSoldout(data.soldout, time)
end

--
function UIHomelandShopTabBuyListItem:_SetItemInfo(itemId, itemNum)
    UIWidgetHelper.SetItemIcon(self, itemId, "_icon")
    UIWidgetHelper.SetItemText(self, itemId, "_txtTitle")

    local strNum = "x" .. itemNum
    UIWidgetHelper.SetLocalizationText(self, "_txtCount", strNum)
end

--
function UIHomelandShopTabBuyListItem:_SetPriceInfo(itemId, itemNum)
    UIWidgetHelper.SetItemIcon(self, itemId, "_iconPrice")
    UIWidgetHelper.SetItemIcon(self, itemId, "_iconPriceLimit")

    UIWidgetHelper.SetLocalizationText(self, "_txtPriceCount", itemNum)
    UIWidgetHelper.SetLocalizationText(self, "_txtPriceCountLimit", itemNum)
end

-- 设置是否是限时商品样式
function UIHomelandShopTabBuyListItem:_SetLimitMode(type)
    -- cfg_homeland_shop 中限购类型的定义 [1] = 周 [2] = 永久 [3] = 月
    local mode = (type ~= 1 and type ~= 2 and type ~= 3) and 1 or 2

    self._modeObjs = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            { "_bg_normal", "BuyBtn" },
            { "_bg_limit", "_limitRoot", "LimitBuyBtn" }
        },
        self._modeObjs
    )
    UIWidgetHelper.SetObjGroupShow(self._modeObjs, mode)
end

-- 设置限时商品
function UIHomelandShopTabBuyListItem:_SetLimitText(type, soldCount, limitCount)
    -- cfg_homeland_shop 中限购类型的定义 [1] = 周 [2] = 永久 [3] = 月
    if type ~= 1 and type ~= 2 and type ~= 3 then
        self:GetGameObject("_txtLimit"):SetActive(false)
        return
    end

    self:GetGameObject("_txtLimit"):SetActive(true)

    local tb = {
        [1] = "str_homeland_shop_buy_limit_week",
        [2] = "str_homeland_shop_buy_limit_forever",
        [3] = "str_homeland_shop_buy_limit_month"
    }

    local text = string.format(" %d/%d", limitCount - soldCount, limitCount)
    UIWidgetHelper.SetLocalizationText(self, "_txtLimit", StringTable.Get(tb[type], text))
end

-- 设置限时商品
function UIHomelandShopTabBuyListItem:_SetLimitTime(type, time)
    -- cfg_homeland_shop 中限购类型的定义 [1] = 周 [2] = 永久 [3] = 月
    if type ~= 1 and type ~= 3 then
        self:GetGameObject("_remainingTimePool"):SetActive(false)
        return
    end

    self:GetGameObject("_remainingTimePool"):SetActive(true)

    if time then
        self:_SetRemainingTime("_remainingTimePool", "", time, true)
    end
end

-- 设置售罄
function UIHomelandShopTabBuyListItem:_SetSoldout(soldout, time)
    self:GetGameObject("_soldout"):SetActive(soldout)

    if not soldout then
        return
    end

    if time then
        self:_SetRemainingTime("_remainingTimePool2", "", time, true)
    end

    local mode = time and 2 or 1
    if not self._soldoutObjs then
        self._soldoutObjs = UIWidgetHelper.GetObjGroupByWidgetName(self, {
            { "_soldout_element_1", "_soldout_element_2" },
            { "_soldout_element_1", "_soldout_element_3", "_soldout_element_4" }
        })
    end
    UIWidgetHelper.SetObjGroupShow(self._soldoutObjs, mode)
end

-- 获得刷新时间
function UIHomelandShopTabBuyListItem:_GetRefreshTime(type, weekTime, monthTime)
    local tb = {
        [1] = weekTime,
        [3] = monthTime
    }
    return tb[type]
end

--
function UIHomelandShopTabBuyListItem:_GetCost()
    -- cfg_homeland_shop
    return self._data.cfg.CostNum * self._data.cfg.ItemNum
end

--
function UIHomelandShopTabBuyListItem:_CheckEnough(buyCount)
    local cost = self:_GetCost() * buyCount
    local have = UIHomelandShopHelper.GetCoinItemCount()
    return have >= cost
end

--
function UIHomelandShopTabBuyListItem:_CalcReward(count)
    local roleAsset = RoleAsset:New()
    roleAsset.assetid = self._data.cfg.ItemID
    roleAsset.count = self._data.cfg.ItemNum * count

    return roleAsset
end

--region Event Callback

function UIHomelandShopTabBuyListItem:BgBtnOnClick(go)
    self:ShowDialog("UIItemTipsHomeland", self._data.cfg.ItemID, go, true)
end

function UIHomelandShopTabBuyListItem:LimitBuyBtnOnClick(go)
    self:BuyBtnOnClick(go)
end

function UIHomelandShopTabBuyListItem:BuyBtnOnClick(go)
    if not self:_CheckEnough(1) then
        ToastManager.ShowToast(StringTable.Get("str_homeland_shop_tab_buy_not_enough_coin"))
        return
    end

    local limit = (self._data.cfg.Limit ~= 0) and self._data.cfg.Limit - self._data.soldCount or 0
    local limitOnce = self._data.cfg.OnceLimit
    -- cfg_homeland_shop
    self:ShowDialog(
        "UIHomelandShopBuyConfirm",
        self._data.cfg.ItemID, -- 商品id
        self:_GetCost(), -- 单价
        limit, -- 剩余可购买数量
        limitOnce, -- 配置中单词可购买限制
        function(itemId, buyCount)
            local reward = self:_CalcReward(buyCount)
            UIHomelandShopHelper.Start_HomelandShopReq(self._data.cfg.ID, buyCount, { reward })
        end
    )
end

--endregion


-- 对外提供按钮
function UIHomelandShopTabBuyListItem:GetBuyBtn()
    return self:GetGameObject("BuyBtn")
end
