---@class UIHauteCoutureDrawPrizeItemKR : UIHauteCoutureDrawPrizeItemBase
_class("UIHauteCoutureDrawPrizeItemKR", UIHauteCoutureDrawPrizeItemBase)
UIHauteCoutureDrawPrizeItemKR = UIHauteCoutureDrawPrizeItemKR

function UIHauteCoutureDrawPrizeItemKR:Constructor()
end

--初始化
function UIHauteCoutureDrawPrizeItemKR:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIHauteCoutureDrawPrizeItemKR:InitWidget()
    self._atlas = self:GetAsset("UIHauteCoutureKR.spriteatlas", LoadType.SpriteAtlas)
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
    ---@type RawImageLoader
    self.receiveRL = self:GetUIComponent("RawImageLoader", "receiveImg")
    ---@type UnityEngine.UI.Image
    self.gray = self:GetGameObject("gray")
    ---@type UILocalizationText
    self.amountText = self:GetUIComponent("UILocalizationText", "amountText")
    --generated end--
end

function UIHauteCoutureDrawPrizeItemKR:_OnValue()
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
            self.image:LoadImage(icon)
        end

        --bg
        local uiType = self._data.UIType
        if uiType == 2 then
            self.bg.sprite = self._atlas:GetSprite("krsenior_zjm_kuang01")
        elseif uiType == 3 then
            self.bg.sprite = self._atlas:GetSprite("krsenior_zjm_kuang02")
        elseif uiType == 4 then
            self.bg.sprite = self._atlas:GetSprite("krsenior_zjm_kuang03")
        end

        --rewardCount
        local rewardCount = self._data.RewardCount
        if rewardCount > 1 then
            self.amountText:SetText("X" .. rewardCount)
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
        self.receiveRL:LoadImage("krsenior_re_zjm_mask1")
    else 
        self.coinBg:SetActive(false)
        if  self._replaced then
            local cfg = Cfg.cfg_senior_skin_draw {ComponentId = self._componentId}[1] --只有一个
            self.image:LoadImage(cfg.ReplaceSpecailIcon)
        end 
        self.receiveRL:LoadImage("krsenior_re_zjm_mask2")
    end
end

---@param state boolean
function UIHauteCoutureDrawPrizeItemKR:Flush(state)
    self.receiveImg:SetActive(state)
    -- if not self._specail then
    -- end
end

---@param gray boolean
function UIHauteCoutureDrawPrizeItemKR:SetGray(gray)
    self.gray:SetActive(gray)
end

--按钮点击
function UIHauteCoutureDrawPrizeItemKR:BgOnClick(go)
    if self._specail and not self._replaced  then
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
