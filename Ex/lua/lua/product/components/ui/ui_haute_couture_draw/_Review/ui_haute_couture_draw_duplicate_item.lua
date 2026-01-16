--
---@class UIHauteCoutureDuplicateItem : UICustomWidget
_class("UIHauteCoutureDuplicateItem", UICustomWidget)
UIHauteCoutureDuplicateItem = UIHauteCoutureDuplicateItem
--初始化
function UIHauteCoutureDuplicateItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHauteCoutureDuplicateItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.s1 = self:GetUIComponent("RawImageLoader", "s1")
    ---@type RawImageLoader
    self.s2 = self:GetUIComponent("RawImageLoader", "s2")
    ---@type RawImageLoader
    self.t1 = self:GetUIComponent("RawImageLoader", "t1")
    ---@type RawImageLoader
    self.t2 = self:GetUIComponent("RawImageLoader", "t2")
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    --generated end--

    self.source2 = self:GetGameObject("Source2")
    self.target2 = self:GetGameObject("Target2")
    ---@type UILocalizationText
    self.s1Count = self:GetUIComponent("UILocalizationText", "s1Count")
    ---@type UILocalizationText
    self.s2Count = self:GetUIComponent("UILocalizationText", "s2Count")
    ---@type UILocalizationText
    self.t1Count = self:GetUIComponent("UILocalizationText", "t1Count")
    ---@type UILocalizationText
    self.t2Count = self:GetUIComponent("UILocalizationText", "t2Count")
    ---@type RawImageLoader
    self.bg = self:GetUIComponent("RawImageLoader", "bg")
end
--设置数据
function UIHauteCoutureDuplicateItem:SetData(cfg, onClick)
    self:SetBg(cfg)
    local twoAwards = cfg.AppendGlow > 0 --原奖励光珀大于0，说明只有2个奖励
    self.source2:SetActive(twoAwards)
    self.target2:SetActive(twoAwards)
    if twoAwards then
        self.s1:LoadImage(Cfg.cfg_item[RoleAssetID.RoleAssetGlow].Icon)
        self.s1Count:SetText(cfg.AppendGlow)
        self.t1:LoadImage(Cfg.cfg_item[RoleAssetID.RoleAssetGlow].Icon)
        self.t1Count:SetText(cfg.AppendGlow)
        self.s2:LoadImage(Cfg.cfg_item[cfg.RewardID].Icon)
        self.s2Count:SetText(cfg.RewardCount)
        self.t2:LoadImage(Cfg.cfg_item[cfg.ReplaceRewardID].Icon)
        self.t2Count:SetText(cfg.ReplaceRewardCount)

        self._s1ID = RoleAssetID.RoleAssetGlow
        self._s1Count = cfg.AppendGlow
        self._s2ID = cfg.RewardID
        self._s2Count = cfg.RewardCount
        self._t1ID = RoleAssetID.RoleAssetGlow
        self._t1Count = cfg.AppendGlow
        self._t2ID = cfg.ReplaceRewardID
        self._t2Count = cfg.ReplaceRewardCount
    else
        self.s1:LoadImage(Cfg.cfg_item[cfg.RewardID].Icon)
        self.s1Count:SetText(cfg.RewardCount)
        self.t1:LoadImage(Cfg.cfg_item[cfg.ReplaceRewardID].Icon)
        self.t1Count:SetText(cfg.ReplaceRewardCount)

        self._s1ID = cfg.RewardID
        self._s1Count = cfg.RewardCount
        self._t1ID = cfg.ReplaceRewardID
        self._t1Count = cfg.ReplaceRewardCount
    end
    self.title:SetText(StringTable.Get("str_senior_skin_draw_gifttype" .. cfg.RewardSortOrder))

    self._onClick = onClick
end

--设置背景图,如果有修改背景图需求可以重写此方法
function UIHauteCoutureDuplicateItem:SetBg(cfg)
end

function UIHauteCoutureDuplicateItem:S1OnClick(go)
    self._onClick(self._s1ID, go.transform.position, self._s1Count)
end
function UIHauteCoutureDuplicateItem:S2OnClick(go)
    self._onClick(self._s2ID, go.transform.position, self._s2Count)
end
function UIHauteCoutureDuplicateItem:T1OnClick(go)
    self._onClick(self._t1ID, go.transform.position, self._t1Count)
end
function UIHauteCoutureDuplicateItem:T2OnClick(go)
    self._onClick(self._t2ID, go.transform.position, self._t2Count)
end
