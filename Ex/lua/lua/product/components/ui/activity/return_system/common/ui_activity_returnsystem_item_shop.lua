--[[
    回归活动：商品UI
]]
---@class UIActivityReturnSystemItemShop:UICustomWidget

_class("UIActivityReturnSystemItemShop", UICustomWidget)
UIActivityReturnSystemItemShop = UIActivityReturnSystemItemShop

function UIActivityReturnSystemItemShop:Constructor()
    --物品颜色品质对应图片名称
    self._itemColorFrame = {
        [ItemColor.ItemColor_White] = "shop_shenmi_pin1",
        [ItemColor.ItemColor_Green] = "shop_shenmi_pin2",
        [ItemColor.ItemColor_Blue] = "shop_shenmi_pin3",
        [ItemColor.ItemColor_Purple] = "shop_shenmi_pin4",
        [ItemColor.ItemColor_Yellow] = "shop_shenmi_pin5",
        [ItemColor.ItemColor_Golden] = "shop_shenmi_pin6"
    }

    self._itemClickLock = "UIShopSecretGoodSelectItemLock"

    self._inited = false
end
function UIActivityReturnSystemItemShop:OnShow()
    self._nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self._itemCountTxt = self:GetUIComponent("UILocalizationText", "itemcount")
    self._countPanelGO = self:GetGameObject("countpanel")
    self._price1Txt = self:GetUIComponent("UILocalizationText", "price")

    self._remainTxt = self:GetUIComponent("UILocalizationText", "remain")
    self._remainGO = self:GetGameObject("remaingo")
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._qualityIcon = self:GetUIComponent("Image", "qualityIcon")
    self._tag = {}
    -- 2 是必买 3是折扣
    for i = 1, 3 do
        self._tag[i] = {}
        self._tag[i].tagGO = self:GetGameObject("tag" .. i)
        self._tag[i].txt = self:GetUIComponent("UILocalizationText", "tag" .. i .. "txt")
    end
    self._tag[1].tagGO:SetActive(false)

    self._moneyIcon1 = self:GetUIComponent("RawImageLoader", "moneyicon1")
    self._moneyIcon1GO = self:GetGameObject("moneyicon1")

    self._yuanjiaTxt = self:GetUIComponent("UILocalizationText", "yuanjia")
    self._xianjiaTxt = self:GetUIComponent("UILocalizationText", "xianjia")

    self._isSellGO = self:GetGameObject("issell")
    self._isSellTr = self:GetUIComponent("RectTransform","issell")
    self._rectTrans = self:GetGameObject().transform:GetComponent("RectTransform")
    self._tagPanelGO = self:GetGameObject("alltag")
    self._alltagRect = self:GetUIComponent("RectTransform","alltag")

    self._atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self._uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._trans = self:GetGameObject().transform

    self._animation = self._trans:GetComponent("Animation")
    self._lockGo = self:GetGameObject("lock")
    self._maskTxt = self:GetUIComponent("UILocalizationText","maskTxt")
    self:AttachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)
end

---@param campaignShopItem DCampaignShopItemBase
---@param targetShopId number 外界传入的目标商品id 如果存在则打开购买框
---@param max number 累计获得的货币数量
function UIActivityReturnSystemItemShop:Refresh(campaignShopItem,targetShopId,max)
    self.campaignShopItem = campaignShopItem
    self.targetShopId = targetShopId
    if not self.campaignShopItem then
        return
    end
    local cfgItem = Cfg.cfg_item[self.campaignShopItem:GetItemId()]
    if not cfgItem then
        return
    end
    if self.targetShopId and self.targetShopId == self.campaignShopItem:GetGoodsId() then
        self:bgOnClick()
    end
    --设置限制
    local lockItem = self.campaignShopItem:UnlockItems()
    if lockItem then
        --此处只采用一个解锁条件
        local unlockID = 0  --解锁道具ID
        local unlockNum = 0 --解锁需要数量
        for i,v in pairs(lockItem) do
            unlockID = i
            unlockNum = v
        end
        
        local historyCount = max--历史拥有最大数量

        if historyCount < unlockNum then
            self._maskTxt:SetText(StringTable.Get("str_shop_returnsystem_limit",unlockNum))
            self._isLock = true
            self._lockGo:SetActive(true)
        else
            self._isLock = false
            self._lockGo:SetActive(false)
        end
    else
        self._isLock = false
        self._lockGo:SetActive(false)
    end

    --商品图标以及稀有度
    self._icon:LoadImage(cfgItem.Icon)
    if self._qualityIcon then
        local frameName = self._itemColorFrame[cfgItem.Color]
        if frameName ~= "" then
            -- local _uiItemAtlas = self:GetAsset("UICommonItem.spriteatlas", LoadType.SpriteAtlas)
            self._qualityIcon.gameObject:SetActive(true)
            self._qualityIcon.sprite = self._atlas:GetSprite(frameName)
        else
            self._qualityIcon.gameObject:SetActive(false)
        end
    end

    --商品名
    self._nameTxt:SetText(StringTable.Get(cfgItem.Name))

    --商品单次数量
    local count = self.campaignShopItem:GetItemCount()
    if count <= 1 then
        self._countPanelGO:SetActive(false)
    else
        self._countPanelGO:SetActive(true)
        self._itemCountTxt:SetText(count)
    end

    --商品剩余
    local showRemain = self.campaignShopItem:ShowRemain()
    local remainCount = self.campaignShopItem:GetRemainCount()
    if not showRemain then
        self._remainGO:SetActive(false)
    else
        if self.campaignShopItem:IsUnLimit() then
            self._remainGO:SetActive(false)
        else
            if remainCount <= 0 then
                self._remainGO:SetActive(false)
            else
                local max = self.campaignShopItem:GetRemainTotalCount()
                self._remainGO:SetActive(true)
                -- 限购10
                self._remainTxt:SetText(StringTable.Get("str_shop_secret_good_remain") .. remainCount)
            end
        end
    end
    if remainCount == 0 then
        self._isSellGO:SetActive(true)
    else
        self._isSellGO:SetActive(false)
    end

    --打折
    local showTag = self.campaignShopItem:ShowSaleTag()
    if showTag then
        local saleTag = self.campaignShopItem:GetSaleTag()
        if saleTag == 1 then
            self._tag[2].tagGO:SetActive(true)
            self._tag[3].tagGO:SetActive(false)
        elseif saleTag > 0 and saleTag < 100 then
            self._tag[2].tagGO:SetActive(false)
            self._tag[3].tagGO:SetActive(true)
            local showDiscount = 100 - saleTag
            self._tag[3].txt:SetText("-" .. showDiscount .. "%")
        elseif saleTag == 0 then
            self._tag[2].tagGO:SetActive(false)
            self._tag[3].tagGO:SetActive(false)
        end
    else
        self._tag[2].tagGO:SetActive(false)
        self._tag[3].tagGO:SetActive(false)
    end

    --价格
    self._moneyIcon1GO:SetActive(true)
    self._moneyIcon1:LoadImage("icon_item_3000291")
    self._price1Txt:SetText(self.campaignShopItem:GetSalePrice())

    --第一次播
    if self._inited == false then
        self._animation:Play("uieff_ShopItem_In")
        self._inited = true
    else
        self._isSellTr.anchoredPosition = Vector2(self._isSellTr.anchoredPosition.x,17.5)
        self._alltagRect.anchoredPosition = Vector2(self._alltagRect.anchoredPosition.x,124.5)
    end
end

function UIActivityReturnSystemItemShop:OnHide()
    self:DetachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)--此处需要修改
end

function UIActivityReturnSystemItemShop:ShopBuySuccess(goodId)
    if self.campaignShopItem and self.campaignShopItem:GetGoodsId() == goodId then
        local remainCount = self.campaignShopItem:GetRemainCount()
        if remainCount <= 0 then
        -- self.anim:SetTrigger("in")
        end
    end
end

function UIActivityReturnSystemItemShop:BgOnClick()
    if self._isLock then
        Log.debug("未达到该商品解锁目标")
        local lockItem = self.campaignShopItem:UnlockItems()
        local unlockID = 0  --解锁道具ID
        local unlockNum = 0 --解锁需要数量
        for i,v in pairs(lockItem) do
            unlockID = i
            unlockNum = v
        end
        local cfgItem = Cfg.cfg_item[self.campaignShopItem:GetItemId()]
        local name = StringTable.Get(cfgItem.Name)
        --数量 道具名
        ToastManager.ShowToast(StringTable.Get("str_shop_returnsystem_lock", unlockNum,name))
        return
    end
    local remainCount = self.campaignShopItem:GetRemainCount()
    if remainCount == 0 then
        ToastManager.ShowToast(StringTable.Get("str_shop_returnsystem_empty"))
        return
    end

    if not self.campaignShopItem:ShowRemain() then
        self:ShowDialog("UICampaignShopConfirmDetailController", self.campaignShopItem, self.subTabType)
    else
        self:ShowDialog("UICampaignShopConfirmDetailController", self.campaignShopItem, self.subTabType)
    end
end
