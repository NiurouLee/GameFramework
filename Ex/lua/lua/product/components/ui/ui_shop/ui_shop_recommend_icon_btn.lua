--[[
    商城推荐页签 广告小图toggle
]]
---@class UIShopRecommendIconBtn:UICustomWidget

_class("UIShopRecommendIconBtn", UICustomWidget)
UIShopRecommendIconBtn = UIShopRecommendIconBtn
function UIShopRecommendIconBtn:OnShow()
    ---@type RawImageLoader
    self.picImg = self:GetUIComponent("RawImageLoader", "pic")
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
end

function UIShopRecommendIconBtn:Init(index, shopRecommendTabData, tglGroup, onClickTabBtn, param)
    self.index = index
    ---@type DShopRecommend
    self.shopRecommendTabData = shopRecommendTabData
    self.onClickTabBtn = onClickTabBtn
    self.param = param
    local adGroup = self.shopRecommendTabData:GetAdGroup() --cfg_shop_recommend_ad
    self.nameTxt:SetText(self.shopRecommendTabData:GetName())
    if adGroup then
        self.picImg:LoadImage(adGroup.Icon)
    end
end

function UIShopRecommendIconBtn:Select(select)
end

function UIShopRecommendIconBtn:picOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    self.onClickTabBtn(self.param, self.index)
end
