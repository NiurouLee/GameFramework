---@class UIPetForecastViewItem:UICustomWidget
_class("UIPetForecastViewItem", UICustomWidget)
UIPetForecastViewItem = UIPetForecastViewItem

function UIPetForecastViewItem:OnShow()
    ---@type RawImageLoader
    self.logo = self:GetUIComponent("RawImageLoader", "logo")
    ---@type UnityEngine.UI.Image
    self.imgProperty = self:GetUIComponent("Image", "imgProperty")
    self.atlas = self:GetAsset("UIPetForecast.spriteatlas", LoadType.SpriteAtlas)
end
function UIPetForecastViewItem:OnHide()
    self.logo:DestoryLastImage()
    self.logo = nil
    self.imgProperty = nil
    self.atlas = nil
end

function UIPetForecastViewItem:Flush(tplId)
    self.tplId = tplId
    local cfgv = Cfg.cfg_pet[tplId]
    if cfgv then
        self.logo:LoadImage(cfgv.Logo)
        local shsl = {"shui", "huo", "sen", "lei"}
        self.imgProperty.sprite = self.atlas:GetSprite("main_prec_shuxing_" .. (shsl[cfgv.FirstElement] or ""))
    end
end

function UIPetForecastViewItem:bgOnClick(go)
    self:ShowDialog("UIShopPetDetailController", self.tplId)
end
