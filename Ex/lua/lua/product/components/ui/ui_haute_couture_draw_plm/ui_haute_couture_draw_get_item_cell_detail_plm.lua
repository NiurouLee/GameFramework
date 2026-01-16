--
---@class UIHauteCoutureDrawGetItemCellDetailPLM : UICustomWidget
_class("UIHauteCoutureDrawGetItemCellDetailPLM", UICustomWidget)
UIHauteCoutureDrawGetItemCellDetailPLM = UIHauteCoutureDrawGetItemCellDetailPLM
--初始化
function UIHauteCoutureDrawGetItemCellDetailPLM:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHauteCoutureDrawGetItemCellDetailPLM:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    local item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UIHauteCoutureDrawGetItemCellGL
    self.item = item:SpawnObject("UIHauteCoutureDrawGetItemCellPLM")

    ---@type UILocalizationText
    self.txt_name = self:GetUIComponent("UILocalizationText", "txt_name")
    ---@type UILocalizationText
    self.txt_have = self:GetUIComponent("UILocalizationText", "txt_have")
    ---@type UILocalizationText
    self.txt_desc = self:GetUIComponent("UILocalizationText", "txt_desc")
    --generated end--

end

--设置数据
function UIHauteCoutureDrawGetItemCellDetailPLM:SetData(itemInfo)
    self.item:SetData(itemInfo,false, nil)
    self.item:EnableInteract(false)
    self.txt_name:SetText(StringTable.Get(itemInfo.item_name))
    self.txt_desc:SetText(StringTable.Get(itemInfo.simple_desc))
    local roleModule = GameGlobal.GetModule(RoleModule)
    local c = roleModule:GetAssetCount(itemInfo.item_id) or 0
    local front = StringTable.Get("str_senior_skin_draw_num_qt")
    self.txt_have:SetText(front..c)
end
