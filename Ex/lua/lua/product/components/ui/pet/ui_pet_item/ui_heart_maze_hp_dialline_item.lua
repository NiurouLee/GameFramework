---@class UIHeartMazeHpDialLineItem : UICustomWidget
_class("UIHeartMazeHpDialLineItem", UICustomWidget)
UIHeartMazeHpDialLineItem = UIHeartMazeHpDialLineItem
function UIHeartMazeHpDialLineItem:Constructor()
    --self._atlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
end
function UIHeartMazeHpDialLineItem:OnShow()
    ---@type UnityEngine.UI.Image
    self._img = self:GetUIComponent("Image", "img")
    self._rect = self:GetUIComponent("RectTransform", "img")
end
function UIHeartMazeHpDialLineItem:SetData(idx, posx, sp, show)
    self._index = idx
    self._rect.anchoredPosition = Vector2(posx, 0)
    self._img.enabled = show
    --[[

        if middleImg then
            self._img.sprite = self._atlas:GetSprite("map_biandui_xuetiao5")
        else
            self._img.sprite = self._atlas:GetSprite("map_biandui_xuetiao4")
        end
        ]]
    self._img.sprite = sp
    self._img:SetNativeSize()
end
