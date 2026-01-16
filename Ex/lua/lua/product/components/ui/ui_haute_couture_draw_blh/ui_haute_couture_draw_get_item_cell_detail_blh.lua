--
---@class UIHauteCoutureDrawGetItemCellDetailBLH : UICustomWidget
_class("UIHauteCoutureDrawGetItemCellDetailBLH", UICustomWidget)
UIHauteCoutureDrawGetItemCellDetailBLH = UIHauteCoutureDrawGetItemCellDetailBLH
--初始化
function UIHauteCoutureDrawGetItemCellDetailBLH:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHauteCoutureDrawGetItemCellDetailBLH:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    local item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UIHauteCoutureDrawGetItemCellBLH
    self.item = item:SpawnObject("UIHauteCoutureDrawGetItemCellBLH")

    ---@type UILocalizationText
    self.txt_name = self:GetUIComponent("UILocalizationText", "txt_name")
    ---@type UILocalizationText
    self.txt_have = self:GetUIComponent("UILocalizationText", "txt_have")
    ---@type UILocalizationText
    self.txt_desc = self:GetUIComponent("UILocalizationText", "txt_desc")
    --generated end--
end

--设置数据
function UIHauteCoutureDrawGetItemCellDetailBLH:SetData(itemInfo)
    self.item:SetData(itemInfo, false, nil)
    self.item:EnableInteract(false)
    self.txt_name:SetText(StringTable.Get(itemInfo.item_name))
    self.txt_desc:SetText(StringTable.Get(itemInfo.simple_desc))
    local roleModule = GameGlobal.GetModule(RoleModule)
    local c = roleModule:GetAssetCount(itemInfo.item_id) or 0
    self.txt_have:SetText(c)
end
