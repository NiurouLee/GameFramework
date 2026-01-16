--
---@class UIHomelandTaskGuideRewardItem : UICustomWidget
_class("UIHomelandTaskGuideRewardItem", UICustomWidget)
UIHomelandTaskGuideRewardItem = UIHomelandTaskGuideRewardItem
--初始化
function UIHomelandTaskGuideRewardItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHomelandTaskGuideRewardItem:InitWidget()
    ---@type UICustomWidgetPool
    self.item = self:GetUIComponent("UISelectObjectPath", "Item")
    ---@type UnityEngine.UI.Image
    self.done = self:GetGameObject("Done")
end
--设置数据
function UIHomelandTaskGuideRewardItem:SetData(roleAsset, done)
    ---@type UIItemHomeland
    self.itemWidget = self.item:SpawnObject("UIItemHomeland")
    self.itemWidget:Flush(roleAsset)
    self.done:SetActive(done)
end

function UIHomelandTaskGuideRewardItem:ClearTextCount()
    self.itemWidget:ClearTextCount()
end

