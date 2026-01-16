--
---@class UIWorldBossElement : UICustomWidget
_class("UIWorldBossElement", UICustomWidget)
UIWorldBossElement = UIWorldBossElement
--初始化
function UIWorldBossElement:OnShow(uiParams)
    self:InitWidget()
    self._atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
end
--获取ui组件
function UIWorldBossElement:InitWidget()
    self._element1 = self:GetUIComponent("Image", "e1")
    --self._element2 = self:GetUIComponent("Image", "e2")
end
--设置数据
function UIWorldBossElement:SetData(cfg_monster)
    if cfg_monster then
        local element = cfg_monster.ElementType
        self._element1.sprite = self._atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(ElementIcon[element]))
    end
end
