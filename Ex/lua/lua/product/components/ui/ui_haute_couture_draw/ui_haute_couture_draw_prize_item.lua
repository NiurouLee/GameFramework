---@class UIHauteCoutureDrawPrizeItem:UICustomWidget
_class("UIHauteCoutureDrawPrizeItem", UICustomWidget)
UIHauteCoutureDrawPrizeItem = UIHauteCoutureDrawPrizeItem

function UIHauteCoutureDrawPrizeItem:Constructor()
    self._guangPoNum = 0
    self._itemId = 0
    self._assetList = {}
end

function UIHauteCoutureDrawPrizeItem:OnShow()
    self:_GetComponents()
end

function UIHauteCoutureDrawPrizeItem:_GetComponents()
    self._atlas = self:GetAsset("UIHauteCotureDraw.spriteatlas", LoadType.SpriteAtlas)
    self._icon = self:GetUIComponent("RawImageLoader", "Image")
    self._guangPoObj = self:GetGameObject("Guangpo")
    self._receiveImg = self:GetGameObject("receiveImg")
    self._bg = self:GetUIComponent("Image", "bg")
    self._addImgObj = self:GetGameObject("add")
    self._gray = self:GetGameObject("gray")
end

function UIHauteCoutureDrawPrizeItem:SetData(prizeSortOrder, componentId, specail, replace)
    self._data = Cfg.cfg_component_senior_skin_weight {ComponentID = componentId, RewardSortOrder = prizeSortOrder}[1]
    self._itemId = self._data.RewardID
    if replace then
        self._itemId = self._data.ReplaceRewardID
    end
    self._guangPoNum = self._data.AppendGlow
    self._specail = specail
    if self._specail then
        local cfg = Cfg.cfg_senior_skin_draw {ComponentId = componentId}[1] --只有一个
        if replace then
            self._specialIcon = cfg.ReplaceSpecailIcon
        else
            self._specialIcon = cfg.SpecailIcon
        end
    end

    self._replace = replace
    self:_OnValue()
end

function UIHauteCoutureDrawPrizeItem:HideAddImg()
    self._addImgObj:SetActive(false)
end
function UIHauteCoutureDrawPrizeItem:Flush(state)
    self._receiveImg:SetActive(state)
    if self._specail then
    else
        if state then
            self._bg.sprite = self._atlas:GetSprite("senior_pray_di05")
        else
            self._bg.sprite = self._atlas:GetSprite("senior_pray_di06")
        end
    end
end

function UIHauteCoutureDrawPrizeItem:GetPrizeId()
    return self._itemId
end

function UIHauteCoutureDrawPrizeItem:GetCfgID()
    return self._data.ID
end

--是否为特殊奖励（时装）
function UIHauteCoutureDrawPrizeItem:IsSpecailAward()
    return self._specail
end

function UIHauteCoutureDrawPrizeItem:SetGray(gray)
    if gray then
        self._gray:SetActive(true)
    else
        self._gray:SetActive(false)
    end
end

function UIHauteCoutureDrawPrizeItem:_OnValue()
    self._receiveImg:SetActive(false)
    if self._specail then
        self._guangPoObj:SetActive(false)
        self:HideAddImg()
    else
        if self._guangPoNum > 0 then
            self._guangPoObj:SetActive(true)
        else
            self._guangPoObj:SetActive(false)
        end
    end
    local cfg = Cfg.cfg_item[self._itemId]
    if cfg == nil then
        Log.fatal("cfg_item is nil." .. self._itemId)
    else
        local icon = cfg.Icon
        local quality = cfg.Color
        local text1 = self._itemCount
        if self._specialIcon then
            self._icon:LoadImage(self._specialIcon)
        else
            self._icon:LoadImage(icon)
        end
        self:InsertReward()
    end
    self:SetGray(false)
end

function UIHauteCoutureDrawPrizeItem:ImageOnClick(go)
    if
        self._specail and self._itemId > RoleAssetID.RoleAssetPetSkinBegin and
            self._itemId < RoleAssetID.RoleAssetPetSkinEnd
     then
        self:ShowDialog("UIPetSkinsMainController", PetSkinUiOpenType.PSUOT_TIPS, self._itemId - 4000000)
    else
        self:ShowDialog("UIHauteCoutureGetItemController", self._assetList, StringTable.Get(self._data.DesName), true)
    end
end

function UIHauteCoutureDrawPrizeItem:InsertReward()
    local reward = RoleAsset:New()
    reward.assetid = self._data.RewardID
    reward.count = self._data.RewardCount
    if self._replace then
        reward.assetid = self._data.ReplaceRewardID
        reward.count = self._data.ReplaceRewardCount
    end
    table.insert(self._assetList, reward)
    if self._data.AppendGlow and self._data.AppendGlow > 0 then
        local rewardCoin = RoleAsset:New()
        rewardCoin.assetid = RoleAssetID.RoleAssetGlow
        rewardCoin.count = self._data.AppendGlow
        table.insert(self._assetList, rewardCoin)
    end
end
