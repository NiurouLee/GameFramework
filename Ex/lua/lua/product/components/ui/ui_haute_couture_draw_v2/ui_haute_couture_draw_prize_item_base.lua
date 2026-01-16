--时装奖励item Base
---@class UIHauteCoutureDrawPrizeItemBase : UICustomWidget
_class("UIHauteCoutureDrawPrizeItemBase", UICustomWidget)
UIHauteCoutureDrawPrizeItemBase = UIHauteCoutureDrawPrizeItemBase

function UIHauteCoutureDrawPrizeItemBase:Constructor()
    self._coinNum = 0
    self._itemId = 0
    self._itemCount = 0
    self._assetList = {}
    self._data = nil
    self._specail = nil
end

--设置数据
---@param replaced boolean 奖励是否被替换,复刻的时候会用
function UIHauteCoutureDrawPrizeItemBase:SetData(prizeSortOrder, componentId, specail, ctx, replaced)
    self._data = Cfg.cfg_component_senior_skin_weight {ComponentID = componentId, RewardSortOrder = prizeSortOrder}[1]
    if replaced then
        self._itemId = self._data.ReplaceRewardID
        self._itemCount = self._data.ReplaceRewardCount
    else
        self._itemId = self._data.RewardID
        self._itemCount = self._data.RewardCount
    end
    self._coinNum = self._data.AppendGlow
    self._specail = specail
    self._replaced = replaced
    ---@type UIHauteCoutureDataBase
    self._ctx = ctx --从伯利恒高级时装开始，需要传此参数
    self._componentId = componentId
    -- if self._specail then
    --     local cfg = Cfg.cfg_senior_skin_draw {ComponentId = self._componentId}[1] --只有一个
    --     self._specialIcon = cfg.SpecailIcon
    -- end

    self:_OnValue()
    self:_InsertReward()
end

function UIHauteCoutureDrawPrizeItemBase:_OnValue()
end

function UIHauteCoutureDrawPrizeItemBase:GetPrizeId()
    return self._itemId
end

function UIHauteCoutureDrawPrizeItemBase:GetCfgID()
    return self._data.ID
end

function UIHauteCoutureDrawPrizeItemBase:_InsertReward()
    local reward = RoleAsset:New()
    if self._replaced then
        reward.assetid = self._data.ReplaceRewardID
        reward.count = self._data.ReplaceRewardCount
    else
        reward.assetid = self._data.RewardID
        reward.count = self._data.RewardCount
    end
    table.insert(self._assetList, reward)
    if self._data.AppendGlow and self._data.AppendGlow > 0 then
        local rewardCoin = RoleAsset:New()
        rewardCoin.assetid = RoleAssetID.RoleAssetGlow
        rewardCoin.count = self._data.AppendGlow
        table.insert(self._assetList, rewardCoin)
    end
end

---@return boolean 是否为特殊奖励
function UIHauteCoutureDrawPrizeItemBase:IsSpecailPrize()
    return self._specail
end

---@return boolean 奖励物品是否为高级时装
function UIHauteCoutureDrawPrizeItemBase:IsHauteCouture()
    return self._itemId > RoleAssetID.RoleAssetPetSkinBegin and self._itemId < RoleAssetID.RoleAssetPetSkinEnd
end
-- ---@param gray boolean
-- function UIHauteCoutureDrawPrizeItemGL:SetGray(gray)
--     self.gray:SetActive(gray)
-- end

-- --按钮点击
-- function UIHauteCoutureDrawPrizeItemGL:bgOnClick(go)
-- end
