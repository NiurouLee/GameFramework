--
---@class UIN25NewYearItemTips : UICustomWidget
_class("UIN25NewYearItemTips", UICustomWidget)
UIN25NewYearItemTips = UIN25NewYearItemTips

function UIN25NewYearItemTips:Constructor()
    self._itemModule = GameGlobal.GetModule(ItemModule)
    self._roleModule = GameGlobal.GetModule(RoleModule)
end

--初始化
function UIN25NewYearItemTips:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIN25NewYearItemTips:_GetComponents()
    self._parentGo = self:GetGameObject("Parent")
    self._itemInfoGo = self:GetGameObject("ItemInfo")
    ---@type UILocalizationText
    self._name = self:GetUIComponent("UILocalizationText", "Name")
    ---@type UILocalizationText
    self._count = self:GetUIComponent("UILocalizationText", "Count")
    ---@type UILocalizationText
    self._content = self:GetUIComponent("UILocalizationText", "Content")
    ---@type UICustomWidgetPool
    self._uIItem = self:GetUIComponent("UISelectObjectPath", "UIItem")
    ---@type UIItemHomeland
    self._uiItemWidget = self._uIItem:SpawnObject("UIItemHomeland")
    self._parentGo:SetActive(false)
end

--设置数据
function UIN25NewYearItemTips:SetData(id, position)
    local cfg = Cfg.cfg_item[id]
    if not cfg then
        return
    end
    self._name:SetText(StringTable.Get(cfg.Name))
    local count = self._roleModule:GetAssetCount(id)
    local str = string.format("<color=#d57f48>%s</color>", self:_FormatItemCount(count))
    self._count:SetText(StringTable.Get("str_item_public_owned") .. str)
    self._content:SetText(StringTable.Get(cfg.Intro))
    ---@type RoleAsset
    local roleAsset = {}
    roleAsset.assetid = id
    --roleAsset.count = count
    self._uiItemWidget:Flush(roleAsset)
    self._itemInfoGo.transform.position = position
    self._itemInfoGo.transform.localPosition = Vector3(self._itemInfoGo.transform.localPosition.x + 380, self._itemInfoGo.transform.localPosition.y + 130, 0) 
    self._parentGo:SetActive(true)
end

--按钮点击
function UIN25NewYearItemTips:CloseBtnOnClick(go)
    self._parentGo:SetActive(false)
end

function UIN25NewYearItemTips:_FormatItemCount(itemCount)
    return HelperProxy:GetInstance():FormatItemCount(itemCount)
end