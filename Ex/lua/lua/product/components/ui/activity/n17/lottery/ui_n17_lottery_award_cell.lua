---@class UIN17LotteryAwardCell : UICustomWidget
_class("UIN17LotteryAwardCell", UICustomWidget)
UIN17LotteryAwardCell = UIN17LotteryAwardCell

--
function UIN17LotteryAwardCell:OnShow(uiParams)
    self:_GetComponents()
end

--
function UIN17LotteryAwardCell:_GetComponents()
    self._animation = self.view.gameObject:GetComponent("Animation")
    self.itemIcon = self:GetUIComponent("RawImageLoader", "ItemIcon")
    self.itemIconRawImg = self:GetUIComponent("RawImage", "ItemIcon")
    self.itemNumText = self:GetUIComponent("UILocalizationText", "ItemNumText")
    self.itemNumArea = self:GetGameObject("ItemNumArea")
    self.restNumText = self:GetUIComponent("UILocalizationText", "RestNumText")
    self.blackMask = self:GetGameObject("BlackMask")
    self._normalBgImg = self:GetUIComponent("Image", "NormalBg")
    self._itemNumBgImg = self:GetUIComponent("Image", "ItemNumBg")
end

--
function UIN17LotteryAwardCell:InitData(data, itemInfoCallback, showBlackMask, delayTime)
    ---@type DCampaignDrawShopItem
    self._data = data
    self._itemId = self._data:GetItemId()
    self._itemCount = self._data:GetTotalNum()
    self._itemRestCount = self._data:GetRestNum()
    self._itemInfoCallback = itemInfoCallback
    self._showBlackMask = showBlackMask
    self:_fillUi()
    if delayTime > 0 then
        self:StartTask(
            function(TT)
                YIELD(TT, delayTime * 33)
                self._animation:Play("uieff_ShopCell")
            end
        )
    end
end

--
function UIN17LotteryAwardCell:_fillUi()
    local itemCfg = Cfg.cfg_item[self._itemId]
    if itemCfg then
        local res = itemCfg.Icon
        self.itemIcon:LoadImage(res)
        -- self.itemIconRawImg.material = UnityEngine.Material:New(self.itemIconRawImg.material)
        -- self:SetStencil()
        local itemCount = self._data:GetItemCount()
        if itemCount > 1 then
            self.itemNumArea:SetActive(true)
            self.itemNumText:SetText(itemCount)
        else
            self.itemNumArea:SetActive(false)
        end

        self:_SetState()
        self:_SetRestNumText()

        self.blackMask:SetActive(self._itemRestCount <= 0 and self._showBlackMask)

        -- if not self._data:IsBigReward() then
        --     self._normalBgImg.sprite = self._atlas:GetSprite(ShopTheme.JackPotCellBg[ShopTheme.Theme])
        --     self._itemNumBgImg.color = ShopTheme.JackPotCellNumberColor[ShopTheme.Theme]
        -- else
        --     self._itemNumBgImg.color = Color(231 / 255, 138 / 255, 48 / 255)
        -- end
    end
end

--
function UIN17LotteryAwardCell:OnHide()
    -- UnityEngine.Object.Destroy(self.itemIconRawImg.material)
end

--
function UIN17LotteryAwardCell:_SetState()
    -- 设置是否大奖
    self._bigRewardObjs = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            { "NormalBg", "ItemNumBg_Normal" },
            { "SpecialBg", "ItemNumBg_Special" }
        },
        self._bigRewardObjs
    )
    UIWidgetHelper.SetObjGroupShow(self._bigRewardObjs, self._data:IsBigReward() and 2 or 1)
end

--
function UIN17LotteryAwardCell:_SetRestNumText()
    local color_big = "#3a3a3a"
    local color_normal = "#666666"
    local color_zero = "#e95959"

    local c1 = (self._itemRestCount == 0) and color_zero or (self._data:IsBigReward() and color_big or color_normal)
    local c2 = self._data:IsBigReward() and color_big or color_normal
    local s1 = self._itemRestCount
    local s2 = "/" .. self._itemCount
    local str = UIActivityHelper.GetColorText(c1, s1, c2, s2)
    UIWidgetHelper.SetLocalizationText(self, "RestNumText", str)
end

--
function UIN17LotteryAwardCell:ItemIconOnClick(go)
    if self._itemInfoCallback then
        self._itemInfoCallback(self._data)
    end
end

--
function UIN17LotteryAwardCell:NormalBgOnClick(go)
    if self._itemInfoCallback then
        self._itemInfoCallback(self._data)
    end
end

--
function UIN17LotteryAwardCell:SpecialBgOnClick(go)
    if self._itemInfoCallback then
        self._itemInfoCallback(self._data)
    end
end

--
function UIN17LotteryAwardCell:SetStencil()
    self.itemIconRawImg.material:SetFloat("_Stencil", 18)
    self.itemIconRawImg.material:SetFloat("_StencilComp", 4)
    self.itemIconRawImg.material:SetFloat("_StencilOp", 0)
end
