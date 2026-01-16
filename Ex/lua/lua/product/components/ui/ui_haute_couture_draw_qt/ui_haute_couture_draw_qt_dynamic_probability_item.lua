--
---@class UIHauteCoutureDraw_QT_DynamicProbabilityItem : UICustomWidget
_class("UIHauteCoutureDraw_QT_DynamicProbabilityItem", UICustomWidget)
UIHauteCoutureDraw_QT_DynamicProbabilityItem = UIHauteCoutureDraw_QT_DynamicProbabilityItem

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:Constructor()
    self._drawTimes = 0
    self._rareLevel = 0
    self._atlas = self:GetAsset("UIHauteCoutureQT.spriteatlas", LoadType.SpriteAtlas)
end

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:OnShow(uiParams)
    self:InitWidget()
end

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.prizeName = self:GetUIComponent("UILocalizationText", "prizeName")
    self.prize1 = self:GetGameObject("prize1")
    self.prize2 = self:GetGameObject("prize2")
    ---@type RawImageLoader
    self.prizeImg1 = self:GetUIComponent("RawImageLoader", "prizeImg1")
    ---@type RawImageLoader
    self.prizeImg2 = self:GetUIComponent("RawImageLoader", "prizeImg2")
    ---@type UILocalizationText
    self.count1 = self:GetUIComponent("UILocalizationText", "count1")
    ---@type UILocalizationText
    self.count2 = self:GetUIComponent("UILocalizationText", "count2")
    ---@type UnityEngine.UI.Image
    self.detailbg = self:GetUIComponent("Image", "detailbg")
    ---@type UILocalizationText
    self.detail = self:GetUIComponent("UILocalizationText", "detail")
    ---@type UILocalizationText
    self.detailTips = self:GetUIComponent("UILocalizationText", "detailTips")
    --generated end--
end

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:SetData(prizeData, drawTimes, hasGot, probablity)
    self.prizeName:SetText(StringTable.Get(prizeData.Name))

    if drawTimes then
        self._drawTimes = drawTimes
    end
    if prizeData.RareLevel then
        self._rareLevel = prizeData.RareLevel
    end

    if hasGot then
        self.detail:SetText(StringTable.Get("str_senior_skin_draw_got"))

        self.detailTips:SetText(StringTable.Get("str_senior_skin_draw_rule_get_probability"))
        self.detailbg.sprite = self._atlas:GetSprite("qtsenior_rule_di05")
    elseif self._rareLevel - 1 > self._drawTimes then
        self.detail:SetText(
            StringTable.Get("str_senior_skin_draw_rule_probability_5_times_kr", self._rareLevel - self._drawTimes - 1)
        )
        self.detailTips:SetText(StringTable.Get("str_senior_skin_draw_rule_show_get_probability"))
        self.detailbg.sprite = self._atlas:GetSprite("qtsenior_rule_di03")
    else
        self.detailTips:SetText(StringTable.Get("str_senior_skin_draw_rule_get_probability"))
        self.detailbg.sprite = self._atlas:GetSprite("qtsenior_rule_di04")
        --概率
        if probablity then
            self.detail:SetText(string.format("%.2f", probablity) .. "%")
        end
    end

    self:_SetPrizeImg1(prizeData)

    if prizeData.AppendGlow and prizeData.AppendGlow > 0 then
        --icon_item_3000003 光珀
        self.prize2:SetActive(true)
        self.prizeImg2:LoadImage("icon_item_3000003")
        self.count2:SetText(self:FormatCount(prizeData.AppendGlow))
    else
        self.prize2:SetActive(false)
    end
end

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:FormatCount(count)
    if count < 1000 then
        return count
    end
    return math.floor(count / 1000) .. "k"
end

function UIHauteCoutureDraw_QT_DynamicProbabilityItem:_SetPrizeImg1(prizeData)
    local cfg = Cfg.cfg_item[prizeData.RewardID]
    if cfg == nil then
        Log.fatal("cfg_item is nil.")
    else
        self.prizeImg1:LoadImage(cfg.Icon)
    end
    self.count1:SetText(self:FormatCount(prizeData.RewardCount))

    --修正尺寸
    if prizeData.RareLevel then
        ---@type UnityEngine.RectTransform
        local rt = self:GetUIComponent("RectTransform", "prizeImg1")
        rt.anchoredPosition = Vector3(rt.anchoredPosition.x, 0, 0)
        rt:DOScaleX(0.8, 0)
        rt:DOScaleY(0.8, 0)
    end
end