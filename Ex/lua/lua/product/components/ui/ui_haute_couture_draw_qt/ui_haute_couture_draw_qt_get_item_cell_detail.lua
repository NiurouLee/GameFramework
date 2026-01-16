--
---@class UIHauteCoutureDraw_QT_GetItemCellDetail : UICustomWidget
_class("UIHauteCoutureDraw_QT_GetItemCellDetail", UICustomWidget)
UIHauteCoutureDraw_QT_GetItemCellDetail = UIHauteCoutureDraw_QT_GetItemCellDetail
--初始化
function UIHauteCoutureDraw_QT_GetItemCellDetail:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHauteCoutureDraw_QT_GetItemCellDetail:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    local item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UIHauteCoutureDraw_QT_GetItemCell
    self.item = item:SpawnObject("UIHauteCoutureDraw_QT_GetItemCell")

    ---@type UILocalizationText
    self.txt_name = self:GetUIComponent("UILocalizationText", "txt_name")
    ---@type UILocalizationText
    self.txt_have = self:GetUIComponent("UILocalizationText", "txt_have")
    ---@type UILocalizationText
    self.txt_desc = self:GetUIComponent("UILocalizationText", "txt_desc")
    --generated end--
end

--设置数据
function UIHauteCoutureDraw_QT_GetItemCellDetail:SetData(itemInfo)
    self.item:SetData(itemInfo, false, nil)
    self.item:EnableInteract(false)
    self.txt_name:SetText(StringTable.Get(itemInfo.item_name))
    self.txt_desc:SetText(StringTable.Get(itemInfo.simple_desc))
    local roleModule = GameGlobal.GetModule(RoleModule)
    local c = roleModule:GetAssetCount(itemInfo.item_id) or 0
    c = StringTable.Get("str_senior_skin_draw_num_qt") .. c
    self.txt_have:SetText(c)
end
