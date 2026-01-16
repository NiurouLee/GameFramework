---@class UIQuestAchievementAchieveTypeItem:UICustomWidget
_class("UIQuestAchievementAchieveTypeItem", UICustomWidget)
UIQuestAchievementAchieveTypeItem = UIQuestAchievementAchieveTypeItem

function UIQuestAchievementAchieveTypeItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
end

function UIQuestAchievementAchieveTypeItem:SetData(index, sprite, name, nameEn, nowValue, allValue, count)
    self:_GetComponents()
    self._index = index
    self._count = count
    self._sprite = sprite
    self._name = name
    self._nameEn = nameEn

    self._nowValue = nowValue
    self._allValue = allValue
    self:_OnValue()
end

function UIQuestAchievementAchieveTypeItem:OnHide()
end

function UIQuestAchievementAchieveTypeItem:_GetComponents()
    self._icon = self:GetUIComponent("Image", "icon")
    self._nameTex = self:GetUIComponent("UILocalizationText", "nameTex")
    self._rateImg = self:GetUIComponent("Image", "rateImg")
    self._rateTex = self:GetUIComponent("UILocalizationText", "rateTex")
    self._nameTexEn = self:GetUIComponent("UILocalizationText", "nameTexEn")

    self._lineLeft = self:GetUIComponent("RectTransform", "lineLeft")
    self._lineRight = self:GetUIComponent("RectTransform", "lineRight")
end

function UIQuestAchievementAchieveTypeItem:_OnValue()
    self._icon.sprite = self._atlas:GetSprite(self._sprite)
    self._nameTex:SetText(StringTable.Get(self._name))
    self._nameTexEn:SetText(StringTable.Get(self._nameEn))

    local rate = self._nowValue / self._allValue
    self._rateImg.fillAmount = rate

    local str
    if self._nowValue >= self._allValue then
        str = "<color=#fdd100>" .. self._nowValue .. "/" .. self._allValue .. "</color>"
    else
        str = "<color=#fdd100>" .. self._nowValue .. "</color>" .. "/" .. self._allValue
    end
    self._rateTex:SetText(str)

    if self._index == 1 then
        self._lineLeft.sizeDelta = Vector2(166, 3)
    else
        self._lineLeft.sizeDelta = Vector2(150, 3)
    end
    if self._index == self._count then
        self._lineRight.gameObject:SetActive(true)
    else
        self._lineRight.gameObject:SetActive(false)
    end
end
