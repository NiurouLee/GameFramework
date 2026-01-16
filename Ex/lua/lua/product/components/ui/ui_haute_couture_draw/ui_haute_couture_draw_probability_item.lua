---@class UIHauteCoutureDrawProbabilityItem:UICustomWidget
_class("UIHauteCoutureDrawProbabilityItem", UICustomWidget)
UIHauteCoutureDrawProbabilityItem = UIHauteCoutureDrawProbabilityItem

function UIHauteCoutureDrawProbabilityItem:Constructor()
    self._drawTimes = 0
    self._rareLevel = 0
end
function UIHauteCoutureDrawProbabilityItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIHauteCotureDraw.spriteatlas", LoadType.SpriteAtlas)
    self._prizeName = self:GetUIComponent("UILocalizationText", "prizeName")
    self._guangBoObj = self:GetGameObject("guangboIcon")
    self._prizeImg = self:GetUIComponent("RawImageLoader", "prizeImg")
    self._detail = self:GetUIComponent("UILocalizationText", "detail")
    self._bg = self:GetUIComponent("Image", "bg")
    self._nameBg = self:GetUIComponent("RawImage", "nameBg")
    self._count1 = self:GetUIComponent("UILocalizationText", "count1")
    self._count2 = self:GetUIComponent("UILocalizationText", "count2")
end

function UIHauteCoutureDrawProbabilityItem:SetData(prizeData, drawTimes, hasGot, probablity, replace)
    self._prizeName:SetText(StringTable.Get(prizeData.Name))

    if drawTimes then
        self._drawTimes = drawTimes
    end
    if prizeData.RareLevel then
        self._rareLevel = prizeData.RareLevel
    end
    if hasGot then
        self._detail:SetText(StringTable.Get("str_senior_skin_draw_got"))
    elseif self._rareLevel - 1 > self._drawTimes then
        self._detail:SetText(StringTable.Get("str_senior_skin_draw_left_times", self._rareLevel - self._drawTimes - 1))
    else
        --概率
        self._detail:SetText(StringTable.Get("str_senior_skin_draw_probablity", string.format("%.2f", probablity)))
    end
    local cfg = Cfg.cfg_item[prizeData.RewardID]
    if replace then
        --需要替换奖励
        cfg = Cfg.cfg_item[prizeData.ReplaceRewardID]
    end
    if cfg == nil then
        Log.fatal("cfg_item is nil.")
    else
        self._prizeImg:LoadImage(cfg.Icon)
    end

    if replace then
        self._count1:SetText(self:formatCount(prizeData.ReplaceRewardCount))
    else
        self._count1:SetText(self:formatCount(prizeData.RewardCount))
    end
    self._count2:SetText(self:formatCount(prizeData.AppendGlow))

    if prizeData.AppendGlow > 0 then
        self._guangBoObj:SetActive(true)
    else
        self._guangBoObj:SetActive(false)
    end
    self._nameBg.color = Color(1, 1, 1, 1)
    if prizeData.UIType == 1 then
        self._bg.sprite = self._atlas:GetSprite("senior_rule_di10")
    elseif prizeData.UIType == 2 then
        self._bg.sprite = self._atlas:GetSprite("senior_rule_di11")
    elseif prizeData.UIType == 3 then
        self._bg.sprite = self._atlas:GetSprite("senior_rule_di12")
    elseif prizeData.UIType == 4 then
        self._nameBg.color = Color(1, 1, 1, 0)
        self._bg.sprite = self._atlas:GetSprite("senior_rule_di06")
    end
end

function UIHauteCoutureDrawProbabilityItem:formatCount(count)
    if count < 1000 then
        return count
    end
    return math.floor(count / 1000) .. "k"
end
