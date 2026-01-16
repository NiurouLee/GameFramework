---@class UIHomelandShopTabSellItem:UICustomWidget
_class("UIHomelandShopTabSellItem", UICustomWidget)
UIHomelandShopTabSellItem = UIHomelandShopTabSellItem

--
function UIHomelandShopTabSellItem:OnShow(uiParams)
end

--
function UIHomelandShopTabSellItem:OnHide(stamp)
end

--
---@param roleAsset RoleAsset
function UIHomelandShopTabSellItem:SetData(roleAsset, funcClick, notShowTips, showNew, newState)
    ---@type UIItemHomeland
    local obj = UIWidgetHelper.SpawnObject(self, "_item", "UIItemHomeland")
    obj:Flush(roleAsset, funcClick, notShowTips, showNew, newState)
end

function UIHomelandShopTabSellItem:SetSelected(isOn)
    self:GetGameObject("_selectBg"):SetActive(isOn)
end
