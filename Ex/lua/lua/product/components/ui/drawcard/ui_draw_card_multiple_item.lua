---@class UIDrawCardMultipleItem:UICustomWidget
_class("UIDrawCardMultipleItem", UICustomWidget)
UIDrawCardMultipleItem = UIDrawCardMultipleItem

function UIDrawCardMultipleItem:OnShow()
    self.starPool = self:GetUIComponent("UISelectObjectPath", "stars")
    ---@type UnityEngine.Transform
    self.starParent = self:GetUIComponent("Transform", "stars")
end

function UIDrawCardMultipleItem:SetData()
    Log.warn("set multiple item data")

    local count = 5
    self.starPool:SpawnObjects(nil, count)
end

function UIDrawCardMultipleItem:OnHide()
end
