---@class UIQuestAchievementAchieveItemAwardItem:UICustomWidget
_class("UIQuestAchievementAchieveItemAwardItem", UICustomWidget)
UIQuestAchievementAchieveItemAwardItem = UIQuestAchievementAchieveItemAwardItem

function UIQuestAchievementAchieveItemAwardItem:OnShow(uiParams)
end

function UIQuestAchievementAchieveItemAwardItem:SetData(idx, itemAsset, callback)
    self:_GetComponents()
    self._matid = itemAsset[1]
    self._matCount = itemAsset[2]
    self._callback = callback
    self:_OnValue()
end

function UIQuestAchievementAchieveItemAwardItem:OnHide()
end

function UIQuestAchievementAchieveItemAwardItem:_GetComponents()
    self._rect = self:GetUIComponent("RectTransform", "rect")
    self._awardImg = self:GetUIComponent("RawImageLoader", "awardImg")
    self._awardCountTex = self:GetUIComponent("UILocalizationText", "awardCountTex")
    self._awardCountTexGo = self:GetGameObject("awardCountTex")
end

function UIQuestAchievementAchieveItemAwardItem:_OnValue()
    local cfg = Cfg.cfg_item[self._matid]
    if not cfg then
        Log.fatal("[quest] error --> cfg_item is nil ! is --> " .. self._matid)
        return
    end

    self._awardImg:LoadImage(cfg.Icon)
    self._awardCountTex:SetText(self._matCount)
    self._awardCountTexGo:SetActive(self._matCount > 1)
end

function UIQuestAchievementAchieveItemAwardItem:bgOnClick()
    if self._callback then
        local pos = self._rect.position
        self._callback(self._matid, pos)
    end
end
