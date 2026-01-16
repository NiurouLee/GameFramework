---@class UIHomelandMinimapDetailFishItem:UICustomWidget
_class("UIHomelandMinimapDetailFishItem", UICustomWidget)
UIHomelandMinimapDetailFishItem = UIHomelandMinimapDetailFishItem

function UIHomelandMinimapDetailFishItem:OnShow()
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.probText = self:GetUIComponent("UILocalizationText", "probText")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIHomelandMap.spriteatlas", LoadType.SpriteAtlas)
end

---@param itemID number
---@param prob number
function UIHomelandMinimapDetailFishItem:SetData(itemID, prob)
    self.itemID = itemID
    local cfg = Cfg.cfg_item[itemID]
    self.imgIcon:LoadImage(cfg.Icon)
    self.bg.sprite = self.atlas:GetSprite("n17_dt_dykuang0" .. cfg.Color)
    self.probText:SetText(StringTable.Get("str_homeland_minimap_detail_drop_prob_"..prob))
end

function UIHomelandMinimapDetailFishItem:bgOnClick(go)
    self:ShowDialog("UIItemTipsHomeland", self.itemID, go)
end
