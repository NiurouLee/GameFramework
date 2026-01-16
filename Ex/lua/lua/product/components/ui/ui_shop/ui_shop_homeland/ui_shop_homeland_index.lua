--
---@class UIShopHomelandIndex : UICustomWidget
_class("UIShopHomelandIndex", UICustomWidget)
UIShopHomelandIndex = UIShopHomelandIndex
--初始化
function UIShopHomelandIndex:OnShow(uiParams)
    self._atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self:_GetComponents()
end
--获取ui组件
function UIShopHomelandIndex:_GetComponents()
    ---@type UnityEngine.UI.Image
    self._image = self:GetUIComponent("Image", "Image")
end
--设置数据
function UIShopHomelandIndex:SetData(selected)
    if selected then
        self._image.sprite = self._atlas:GetSprite("base_shop_di19")
    else
        self._image.sprite = self._atlas:GetSprite("base_shop_di18")
    end
end
