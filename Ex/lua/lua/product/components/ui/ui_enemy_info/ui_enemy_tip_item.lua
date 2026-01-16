---@class UIEnemyTipItem:UICustomWidget
_class("UIEnemyTipItem", UICustomWidget)
UIEnemyTipItem = UIEnemyTipItem

function UIEnemyTipItem:OnShow() ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "head")
    ---@type UnityEngine.UI.Image
    self._imgElement = self:GetUIComponent("Image", "element")
    self._idx = nil
    self._select = self:GetGameObject("select")
end
---@param idx number 索引
---@param v Enemy 敌人
function UIEnemyTipItem:Flush(idx, v, callback)
    self._idx = idx
    self._callback = callback
    self._imgIcon:LoadImage(v.head)
    self._imgElement.sprite =
        self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(v.prop.icon))
end

function UIEnemyTipItem:Select(idx)
    self._select:SetActive(idx == self._idx)
end

function UIEnemyTipItem:headOnClick(go)
    if self._callback then
        self._callback(self._idx)
    end
end
