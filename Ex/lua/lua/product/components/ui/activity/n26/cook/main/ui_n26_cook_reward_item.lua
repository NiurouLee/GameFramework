--
---@class UIN26CookRewardItem : UICustomWidget
_class("UIN26CookRewardItem", UICustomWidget)
UIN26CookRewardItem = UIN26CookRewardItem

--初始化
function UIN26CookRewardItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN26Cook.spriteatlas", LoadType.SpriteAtlas)
    self:InitWidget()
end

function UIN26CookRewardItem:InitWidget()
    ---@type UILocalizationText
    self.num = self:GetUIComponent("UILocalizationText", "num")

    self.icon = self:GetUIComponent("RawImageLoader", "icon")
end

function UIN26CookRewardItem:SetData(tplId, num, clickCall)
    self.num:SetText(num)
    local cfg = Cfg.cfg_item[tplId]
    if cfg then
        self.icon:LoadImage(cfg.Icon)
    end
    self.tplId = tplId
    self.clickCall = clickCall
end

function UIN26CookRewardItem:RootOnClick(go)
    if self.clickCall then
        local pos = go.transform.position
        self.clickCall(self.tplId, pos)
    end
end