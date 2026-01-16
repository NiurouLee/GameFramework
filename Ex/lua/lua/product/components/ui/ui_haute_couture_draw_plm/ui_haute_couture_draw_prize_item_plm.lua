--普律玛时装奖励item
---@class UIHauteCoutureDrawPrizeItemPLM : UIHauteCoutureDrawPrizeItemBase
_class("UIHauteCoutureDrawPrizeItemPLM", UIHauteCoutureDrawPrizeItemBase)
UIHauteCoutureDrawPrizeItemPLM = UIHauteCoutureDrawPrizeItemPLM

function UIHauteCoutureDrawPrizeItemPLM:Constructor()
end

--初始化
function UIHauteCoutureDrawPrizeItemPLM:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIHauteCoutureDrawPrizeItemPLM:InitWidget()
    self._atlas = self:GetAsset("UIHauteCoutureDrawPLM.spriteatlas", LoadType.SpriteAtlas)
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
    --self._review = self:GetGameObject("Review")
    self._bgCanvas = self:GetUIComponent("CanvasGroup", "bg")
    
end


function UIHauteCoutureDrawPrizeItemPLM:PlayAnim(time)
    self._anim = self:GetUIComponent("Animation", "anim")
    self:StartTask(
        function(TT)
            YIELD(TT, time * 15)
            self._bgCanvas.alpha = 1
            --self._anim:Play("uieff_UIHauteCoutureDrawPrizeItemPLM_in")
        end
    )

end

function UIHauteCoutureDrawPrizeItemPLM:_OnValue()

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
            self.bg.sprite = self._atlas:GetSprite("plmsenior_zjm_kuang02")
        elseif uiType == 3 then
            self.bg.sprite = self._atlas:GetSprite("plmsenior_zjm_kuang03")
        elseif uiType == 4 then
            self.bg.sprite = self._atlas:GetSprite("plmsenior_zjm_kuang04")
        end

        --rewardCount
        local rewardCount = self._itemCount
        if rewardCount > 1 then
            self.amountText:SetText("×" .. rewardCount)
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
        local icon
        local cfg = Cfg.cfg_senior_skin_draw { ComponentId = self._data.ComponentID }[1] --只有一个
        if self._replaced then
            icon = cfg.ReplaceSpecailIcon
            --self._review:SetActive(true)
            local count = self:GetUIComponent("UILocalizationText", "ReviewCount")
            count:SetText(self._itemCount)
        else
            icon = cfg.SpecailIcon
            --self._review:SetActive(false)
        end
        self.image:LoadImage(icon)
    end
end

---@param state boolean
function UIHauteCoutureDrawPrizeItemPLM:Flush(state)
    self.receiveImg:SetActive(state)
    -- if not self._specail then
    -- end
end

---@param gray boolean
function UIHauteCoutureDrawPrizeItemPLM:SetGray(gray)
    self.gray:SetActive(gray)
end

--按钮点击
function UIHauteCoutureDrawPrizeItemPLM:BgOnClick(go)
    -- if self._specail then --特殊奖励也不一定是时装
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
