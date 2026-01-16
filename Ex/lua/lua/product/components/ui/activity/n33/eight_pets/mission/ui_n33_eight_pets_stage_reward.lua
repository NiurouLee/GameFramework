--
---@class UIN33EightPetsStageReward : UICustomWidget
_class("UIN33EightPetsStageReward", UICustomWidget)
UIN33EightPetsStageReward = UIN33EightPetsStageReward

--初始化
function UIN33EightPetsStageReward:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN33EightPetsStageReward:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    ---@type UILocalizationText
    self.awardText = self:GetUIComponent("UILocalizationText", "awardText")
    
    ---@type UnityEngine.GameObject
    self.uiFirst = self:GetGameObject("uiFirst")
    ---@type UnityEngine.GameObject
    self.uiNormal = self:GetGameObject( "uiNormal")
    ---@type UnityEngine.GameObject
    self.ui3Star = self:GetGameObject( "ui3Star")
    
    ---@type UnityEngine.GameObject
    self.uiLimit = self:GetGameObject( "uiLimit")
    self.uiLimit:SetActive(false)
    ---@type UnityEngine.GameObject
    self.animation = self:GetGameObject("animation")
    --generated end--
end

--设置数据
---@param rewardType number AwardType.First 首通 AwardType.ThreeStar 三星 
function UIN33EightPetsStageReward:SetData(award, rewardType, clickCb)
    self.clickCb = clickCb
    self.uiNormal:SetActive(false)
    self.uiFirst:SetActive(rewardType == AwardType.ThreeStar)
    self.ui3Star:SetActive(rewardType == AwardType.First)
    if rewardType == AwardType.ThreeStar then
        self.awardText:SetText(StringTable.Get("str_n33_level_3star_award"))
    elseif rewardType == AwardType.First then
        self.awardText:SetText(StringTable.Get("str_n33_level_firstpass_ward"))
    end
    self.rewardItemId = award.ItemID
    local cfg = Cfg.cfg_item[award.ItemID]
    if cfg then
        self.icon:LoadImage(cfg.Icon)
    end
    self.count:SetText(award.Count)
end

--按钮点击
function UIN33EightPetsStageReward:BtnOnClick(go)
    if self.clickCb then
        self.clickCb(self.rewardItemId, go)
    end
end
