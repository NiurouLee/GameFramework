--高级时装购买基类
---@class UIHauteCoutureDrawChargeBase:UICustomWidget
---@field controller UIHauteCoutureDrawChargeV2Controller 控制器
_class("UIHauteCoutureDrawChargeBase", UICustomWidget)
UIHauteCoutureDrawChargeBase = UIHauteCoutureDrawChargeBase

function UIHauteCoutureDrawChargeBase:Constructor()
    self.controller = nil
end

function UIHauteCoutureDrawChargeBase:InitWidgetsBase()
    self.controller = self.uiOwner
    ---@type UIHauteCoutureDataBase
    self._ctx = self.controller._ctx

    local btns = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self.controller:CloseDialog()
        end,
        nil,
        nil,
        true
    )

    local currency = self:GetUIComponent("UISelectObjectPath", "currencyMenu")
    ---@type UICurrencyMenu
    self._topTips = currency:SpawnObject("UICurrencyMenu")
    self._topTips:SetData({HauteCouture:GetInstance().CostCoinId}, true)
    self._topTips:ShowHideTSFBtn(true)

    self._itemPool = self:GetUIComponent("UISelectObjectPath", "Content")
end

function UIHauteCoutureDrawChargeBase:_OnValueBase()
    local ids = self.controller._buyComponet:GetAllGiftIDByType(CampaignGiftType.ECGT_SENIOR_SKIN)
    local onclick = function(id)
        self:buyGift(id)
    end

    ---@type table<number, UIHauteCoutureDrawChargeItemBase>
    self._items = self._itemPool:SpawnObjects(self:GetItemImpl(), table.count(ids))
    local closeTime = self.controller._buyComponet:GetComponentInfo().m_close_time
    for i, uiItem in ipairs(self._items) do
        uiItem:SetData(ids[i], onclick, closeTime)
    end

    self:RefreshPrice()
    self:AttachEvent(GameEventType.PayGetLocalPriceFinished, self.RefreshPrice)
    -- self:AttachEvent(GameEventType.ActivityCurrencyBuySuccess, self.OnBuySuccess)
end

--子类实现
function UIHauteCoutureDrawChargeBase:GetItemImpl()
    Log.error("UIHauteCoutureDrawChargeBase:GetItemImpl should be inherited")
    return ""
end

function UIHauteCoutureDrawChargeBase:RefreshPrice()
    for i, uiItem in ipairs(self._items) do
        -- 显示用带货币符号的字符串
        local price = self.controller._buyComponet:GetGiftPriceForShowById(uiItem:GetID())
        uiItem:SetPrice(price)
    end
end

function UIHauteCoutureDrawChargeBase:buyGift(id)
    local type = CampaignGiftType.ECGT_SENIOR_SKIN
    self._buyID = id
    Log.debug("请求购买礼包:", self._buyID)
    self.controller._buyComponet:BuyGift(id, 1, type)
end

function UIHauteCoutureDrawChargeBase:OnBuySuccess(id)
    Log.debug("购买礼包成功:", self._buyID)
    local cfg = Cfg.cfg_component_buy_gift {GiftID = self._buyID}[1]
    self._buyID = nil
    local id = cfg.ExtraAward[1][1]
    local count = cfg.ExtraAward[1][2]
    local asset = RoleAsset:New()
    asset.assetid = id
    asset.count = count
    local awards = {asset}

    self:ShowDialog(
        "UIHauteCoutureDrawGetItemV2Controller",
        awards,
        StringTable.Get("str_pay_gain_goods"),
        true,
        function()
        end,
        self._ctx
    )
end
