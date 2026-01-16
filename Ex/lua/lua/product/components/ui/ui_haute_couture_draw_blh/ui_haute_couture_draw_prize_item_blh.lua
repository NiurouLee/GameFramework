---@class UIHauteCoutureDrawPrizeItemBLH : UIHauteCoutureDrawPrizeItemBase
_class("UIHauteCoutureDrawPrizeItemBLH", UIHauteCoutureDrawPrizeItemBase)
UIHauteCoutureDrawPrizeItemBLH = UIHauteCoutureDrawPrizeItemBLH

function UIHauteCoutureDrawPrizeItemBLH:Constructor()
end

--初始化
function UIHauteCoutureDrawPrizeItemBLH:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIHauteCoutureDrawPrizeItemBLH:InitWidget()
    self._atlas = self:GetAsset("UIHauteCoutureBLH.spriteatlas", LoadType.SpriteAtlas)
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UnityEngine.UI.Image
    self.coinBg = self:GetGameObject("coinBg")
    ---@type UILocalizationText
    self.coinNum = self:GetUIComponent("UILocalizationText", "coinNum")
    ---@type RawImageLoader
    self.image = self:GetUIComponent("RawImageLoader", "Image")
    ---@type UnityEngine.RectTransform
    self.imageRt = self:GetUIComponent("RectTransform", "Image")
    ---@type UnityEngine.UI.Image
    self.receiveImg = self:GetGameObject("receiveImg")
    ---@type UnityEngine.UI.Image
    self.gray = self:GetGameObject("gray")
    ---@type UILocalizationText
    self.amountText = self:GetUIComponent("UILocalizationText", "amountText")
    --generated end--
    self.review_Image = self:GetGameObject("Review_Image")
end

function UIHauteCoutureDrawPrizeItemBLH:_OnValue()
    if not self._specail then
        if self._coinNum > 0 then
            self.coinBg:SetActive(true)
            self.coinNum:SetText(self._coinNum)
        else
            self.coinBg:SetActive(false)
        end
 
        local cfg = Cfg.cfg_item[self._itemId]
        if cfg == nil then
            Log.fatal("cfg_item is nil." .. self._itemId)
        else
            local icon = cfg.Icon
            --local quality = cfg.Color
            --local text1 = self._itemCount
            self.image:LoadImage(icon)
        end

        --bg
        local uiType = self._data.UIType
        if uiType == 2 then
            self.bg.sprite = self._atlas:GetSprite("blhsenior_zjm_kuang02")
            local color = Color(224 / 255, 211 / 255, 168 / 255)
            self.coinNum.color = color
            self.amountText.color = color
        elseif uiType == 3 then
            self.bg.sprite = self._atlas:GetSprite("blhsenior_zjm_kuang03")
            local color = Color(224 / 255, 239 / 255, 245 / 255)
            self.coinNum.color = color
            self.amountText.color = color
        elseif uiType == 4 then
            self.bg.sprite = self._atlas:GetSprite("blhsenior_zjm_kuang04")
            local color = Color(244 / 255, 213 / 255, 192 / 255)
            self.coinNum.color = color
            self.amountText.color = color
        end

        --rewardCount
        local rewardCount = self._data.RewardCount
        if rewardCount > 1 then
            local str = ""
            if rewardCount < 1000 then
                str = rewardCount
            else
                str = math.floor(rewardCount / 1000) .. "k"
            end
            self.amountText:SetText("×" .. str)
        else
            self.amountText:SetText("")
        end

        --判断是否是头像，头像比例190 X 160
        local cfg = Cfg.cfg_global["SeniorSkinhead"]
        local headIds = cfg and cfg.ArrayValue
        for k, v in pairs(headIds) do
            if v == self._itemId then
                --修正尺寸
                local sz = self.imageRt.sizeDelta
                sz.x = 190 * sz.y / 160
                self.imageRt.sizeDelta = sz
                break
            end
        end
    else
        --特殊奖励
        self.review_Image:SetActive(self._replaced)
    end
end

---@param state boolean
function UIHauteCoutureDrawPrizeItemBLH:Flush(state)
    self.receiveImg:SetActive(state)
    -- if not self._specail then
    -- end
end

---@param gray boolean
function UIHauteCoutureDrawPrizeItemBLH:SetGray(gray)
    self.gray:SetActive(gray)
end

--按钮点击
function UIHauteCoutureDrawPrizeItemBLH:BgOnClick(go)
    if self._itemId > RoleAssetID.RoleAssetPetSkinBegin and self._itemId < RoleAssetID.RoleAssetPetSkinEnd then
        self:ShowDialog("UIPetSkinsMainController", PetSkinUiOpenType.PSUOT_TIPS, self._itemId - 4000000)
    else
        self:ShowDialog(
            "UIHauteCoutureDrawGetItemV2Controller",
            self._assetList,
            StringTable.Get(self._data.DesName),
            true,
            nil,
            self._ctx
        )
    end

end
