--[[
    商城：秘境页签商品UI
]]
---@class UIShopSecretGood:UICustomWidget

_class("UIShopSecretGood", UICustomWidget)
UIShopSecretGood = UIShopSecretGood

function UIShopSecretGood:Constructor()
    --物品颜色品质对应图片名称
    self.ItemColorFrame = {
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
function UIShopSecretGood:OnShow()
    self.canvasGroup = self:GetUIComponent("CanvasGroup", "item")
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.itemCountTxt = self:GetUIComponent("UILocalizationText", "itemcount")
    self.countPanelGO = self:GetGameObject("countpanel")
    self.price1Txt = self:GetUIComponent("UILocalizationText", "price")

    self.remainTxt = self:GetUIComponent("UILocalizationText", "remain")
    self.remainGO = self:GetGameObject("remaingo")
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    self.qualityIcon = self:GetUIComponent("Image", "qualityIcon")
    self.tag = {}
    -- 2 是必买 3是折扣
    for i = 1, 3 do
        self.tag[i] = {}
        self.tag[i].tagGO = self:GetGameObject("tag" .. i)
        self.tag[i].txt = self:GetUIComponent("UILocalizationText", "tag" .. i .. "txt")
    end
    self.tag[1].tagGO:SetActive(false)

    self.moneyIcon1 = self:GetUIComponent("Image", "moneyicon1")
    self.moneyIcon1GO = self:GetGameObject("moneyicon1")

    self.moneyIcon2 = self:GetUIComponent("Image", "moneyicon2")
    self.moneyIcon2GO = self:GetGameObject("moneyicon2")
    self.yuanjiaTxt = self:GetUIComponent("UILocalizationText", "yuanjia")
    self.xianjiaTxt = self:GetUIComponent("UILocalizationText", "xianjia")

    self.isSellGO = self:GetGameObject("issell")
    self.isSellTr = self:GetUIComponent("RectTransform","issell")
    self.rectTrans = self:GetGameObject().transform:GetComponent("RectTransform")
    self.tagPanelGO = self:GetGameObject("alltag")
    self.alltagRect = self:GetUIComponent("RectTransform","alltag")

    self.module = self:GetModule(ResDungeonModule)
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self.trans = self:GetGameObject().transform
    -- self.anim = self.trans:GetComponent("Animator")
    self.animation = self.trans:GetComponent("Animation")
    self:AttachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)
end
---targetShopId 外界传入的目标商品id 如果存在则打开购买框
function UIShopSecretGood:Refresh(subTabType, goodData, targetShopId)
    -- Log.fatal("###[UIShopSecretGood] subTabType --> ",subTabType ,"| targetShopId --> ",targetShopId)
    self.subTabType = subTabType
    self.goodData = goodData
    self.targetShopId = targetShopId
    if not self.goodData then
        return
    end

    local cfgItem = Cfg.cfg_item[self.goodData:GetItemId()]
    if not cfgItem then
        return
    end
    if self.targetShopId and self.targetShopId == self.goodData:GetGoodId() then
        self:bgOnClick()
    end
    self.icon:LoadImage(cfgItem.Icon)
    if self.qualityIcon then
        local frameName = self.ItemColorFrame[cfgItem.Color]
        if frameName ~= "" then
            -- local _uiItemAtlas = self:GetAsset("UICommonItem.spriteatlas", LoadType.SpriteAtlas)
            self.qualityIcon.gameObject:SetActive(true)
            self.qualityIcon.sprite = self.atlas:GetSprite(frameName)
        else
            self.qualityIcon.gameObject:SetActive(false)
        end
    end
    self.nameTxt:SetText(StringTable.Get(cfgItem.Name))
    local count = self.goodData:GetItemCount()
    if count <= 1 then
        self.countPanelGO:SetActive(false)
    else
        self.countPanelGO:SetActive(true)
        -- self.itemCountTxt:SetText(StringTable.Get("str_shop_good_count") .. count)
        self.itemCountTxt:SetText(count)
    end

    local showRemain = self.goodData:ShowRemain()
    local remainCount = self.goodData:GetRemainCount()
    if showRemain == false then
        self.remainGO:SetActive(false)
    else
        if self.goodData:IsUnLimit() then
            self.remainGO:SetActive(false)
        else
            if remainCount <= 0 then
                self.remainGO:SetActive(false)
            else
                local max = self.goodData:GetRemainTotalCount()
                self.remainGO:SetActive(true)
                -- 限购10
                self.remainTxt:SetText(StringTable.Get("str_shop_secret_good_remain") .. remainCount)
            end
        end
    end
    if remainCount <= 0 then
        self.isSellGO:SetActive(true)
        self.canvasGroup.alpha = 0.5
        self.canvasGroup.blocksRaycasts = false
    else
        self.isSellGO:SetActive(false)
        self.canvasGroup.alpha = 1
        self.canvasGroup.blocksRaycasts = true
    end
    local showTag = self.goodData:ShowSaleTag()
    if showTag then
        -- self.tagPanelGO:SetActive(true)
        local saleTag = self.goodData:GetSaleTag()
        Log.debug("saleTag discount: ", saleTag)
        --必买
        if saleTag == 1 then
            self.tag[2].tagGO:SetActive(true)
            self.tag[3].tagGO:SetActive(false)
        elseif saleTag > 0 and saleTag < 100 then
            self.tag[2].tagGO:SetActive(false)
            self.tag[3].tagGO:SetActive(true)
            local showDiscount = 100 - saleTag
            self.tag[3].txt:SetText("-" .. showDiscount .. "%")
        elseif saleTag == 0 then
            self.tag[2].tagGO:SetActive(false)
            self.tag[3].tagGO:SetActive(false)
        end
    else
        self.tag[2].tagGO:SetActive(false)
        self.tag[3].tagGO:SetActive(false)
    end
    local discount = self.goodData:GetDiscount()
    if discount > 0 and discount < 100 then
        self.moneyIcon1GO:SetActive(false)
        self.moneyIcon2GO:SetActive(true)
        self.moneyIcon2.sprite =
            self.uiCommonAtlas:GetSprite(ClientShop.GetCurrencyImageName(self.goodData:GetSaleType()))
        self.yuanjiaTxt:SetText(self.goodData:GetOriginalSalePrice())
        self.xianjiaTxt:SetText(self.goodData:GetSalePrice())
    else
        self.moneyIcon1GO:SetActive(true)
        self.moneyIcon2GO:SetActive(false)
        self.moneyIcon1.sprite =
            self.uiCommonAtlas:GetSprite(ClientShop.GetCurrencyImageName(self.goodData:GetSaleType()))
        self.price1Txt:SetText(self.goodData:GetSalePrice())
    end

    --切页签也播动画
    -- if self._animSubTabType == subTabType then
    -- else
    --     self._animSubTabType = subTabType
    --     self._inited = false
    -- end
    --第一次播
    if self._inited == false then
        self.animation:Play("uieff_ShopItem_In")
        self._inited = true
    else
        self.isSellTr.anchoredPosition = Vector2(self.isSellTr.anchoredPosition.x,17.5)
        self.alltagRect.anchoredPosition = Vector2(self.alltagRect.anchoredPosition.x,124.5)
        local state = self.animation:get_Item("uieff_ShopItem_In")
        if state then
           state.normalizedTime = 1
        end
    end
end

function UIShopSecretGood:OnHide()
    self:DetachEvent(GameEventType.ShopBuySuccess, self.ShopBuySuccess)
end

function UIShopSecretGood:ShopBuySuccess(goodId)
    if self.goodData and self.goodData:GetGoodId() == goodId then
        local remainCount = self.goodData:GetRemainCount()
        if remainCount <= 0 then
        -- self.anim:SetTrigger("in")
        end
    end
end
function UIShopSecretGood:bgOnClick()
    local remainCount = self.goodData:GetRemainCount()
    if remainCount <= 0 then
        return
    end
    --不在这里手动做点击反馈动画 靳策修改 2021.5.4
    -- self:StartTask(
    --     function(TT)
    --         self:Lock(self._itemClickLock)
    --         self.trans:DOScale(Vector3(0.95, 0.95, 1), 0.1):SetEase(DG.Tweening.Ease.Linear):OnComplete(
    --             function()
    --                 self.trans:DOScale(Vector3.one, 0.1):SetEase(DG.Tweening.Ease.Linear)
    --             end
    --         )
    --         YIELD(TT, 300)
    if self.goodData:GetRemainCount() <= 1 then
        self:ShowDialog("UIShopConfirmNormalController", self.goodData, self.subTabType)
    else
        self:ShowDialog("UIShopConfirmDetailController", self.goodData, self.subTabType)
    end
    --         self:UnLock(self._itemClickLock)
    --     end
    -- )
end
