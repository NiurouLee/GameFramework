---@class UIHomelandBreedItem : UICustomWidget
_class("UIHomelandBreedItem", UICustomWidget)
UIHomelandBreedItem = UIHomelandBreedItem

function UIHomelandBreedItem:Constructor()
    ---@type cfg_item
    self._data = nil
end

function UIHomelandBreedItem:OnShow(uiParams)
    self:_GetComponents()
end
function UIHomelandBreedItem:_GetComponents()
    ---@type UnityEngine.RectTransform
    self._backgroundRect = self:GetUIComponent("RectTransform", "Background")
    ---@type UnityEngine.UI.Image
    self._quality = self:GetUIComponent("Image", "Quality")
    ---@type RawImageLoader
    self._icon = self:GetUIComponent("RawImageLoader", "Icon")
    ---@type UnityEngine.RectTransform
    self._iconRect = self:GetUIComponent("RectTransform", "Icon")
    ---@type UnityEngine.UI.Image
    self._flag = self:GetUIComponent("Image", "Flag")
end
function UIHomelandBreedItem:SetData(data, backgroundSize, iconSize)
    self._data = data
    self.view.gameObject:SetActive(self._data ~= nil)
    if self._data then
        self._icon:LoadImage(self._data.Icon)
    end
    if backgroundSize then
        self._backgroundRect.sizeDelta = backgroundSize
    end
    if iconSize then
        self._iconRect.sizeDelta = iconSize
    end
end