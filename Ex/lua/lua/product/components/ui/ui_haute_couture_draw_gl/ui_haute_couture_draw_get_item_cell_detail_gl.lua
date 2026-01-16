--
---@class UIHauteCoutureDrawGetItemCellDetailGL : UICustomWidget
_class("UIHauteCoutureDrawGetItemCellDetailGL", UICustomWidget)
UIHauteCoutureDrawGetItemCellDetailGL = UIHauteCoutureDrawGetItemCellDetailGL
--初始化
function UIHauteCoutureDrawGetItemCellDetailGL:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHauteCoutureDrawGetItemCellDetailGL:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    local item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UIHauteCoutureDrawGetItemCellGL
    self.item = item:SpawnObject("UIHauteCoutureDrawGetItemCellGL")

    ---@type UILocalizationText
    self.txt_name = self:GetUIComponent("UILocalizationText", "txt_name")
    ---@type UILocalizationText
    self.txt_have = self:GetUIComponent("UILocalizationText", "txt_have")
    ---@type UILocalizationText
    self.txt_desc = self:GetUIComponent("UILocalizationText", "txt_desc")
    --generated end--

end

--设置数据
function UIHauteCoutureDrawGetItemCellDetailGL:SetData(itemInfo)
    self.item:SetData(itemInfo,false, nil)
    self.item:EnableInteract(false)
    self.txt_name:SetText(StringTable.Get(itemInfo.item_name))
    self.txt_desc:SetText(StringTable.Get(itemInfo.simple_desc))
    local roleModule = GameGlobal.GetModule(RoleModule)
    local c = roleModule:GetAssetCount(itemInfo.item_id) or 0
    self.txt_have:SetText(c)
end
