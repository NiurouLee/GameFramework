--
---@class UIN34DispatchAwardItem : UICustomWidget
_class("UIN34DispatchAwardItem", UICustomWidget)
UIN34DispatchAwardItem = UIN34DispatchAwardItem
--初始化
function UIN34DispatchAwardItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIN34DispatchAwardItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self._iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    ---@type UILocalizationText
    self.iconCount = self:GetUIComponent("UILocalizationText", "IconCount")
    ---@type UILocalizationText
    self.giveCount = self:GetUIComponent("UILocalizationText", "GiveCount")
    --generated end--
end

--设置数据
function UIN34DispatchAwardItem:SetData(AwardData)
    if not AwardData then
        return
    end
    local id = AwardData[1][1]
    local count = AwardData[1][2]

    local cfg = Cfg.cfg_item[id]
    local icon = cfg.Icon
    self._iconLoader:LoadImage(icon)

    self.iconCount:SetText(count)
end
