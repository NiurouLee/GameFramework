--
---@class UIHomeVisitGetGiftItem : UICustomWidget
_class("UIHomeVisitGetGiftItem", UICustomWidget)
UIHomeVisitGetGiftItem = UIHomeVisitGetGiftItem
--初始化
function UIHomeVisitGetGiftItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHomeVisitGetGiftItem:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UnityEngine.GameObject
    self.selector = self:GetGameObject("Selector")
    ---@type UnityEngine.GameObject
    self.empty = self:GetGameObject("empty")
    --generated end--
    self.itemGo = self:GetGameObject("item")
end
--设置数据
---@param data SpecItemAsset
function UIHomeVisitGetGiftItem:SetData(idx, data, onSelect)
    self._idx = idx
    self._onSelect = onSelect
    if data then
        self.itemGo:SetActive(true)
        self.empty:SetActive(false)
        ---@type UIItemHomeland
        local itemHome = self.item:SpawnObject("UIItemHomeland")
        local asset = RoleAsset:New()
        asset.assetid = data.assetid
        asset.count = data.count
        itemHome:Flush(asset)
    else
        self.itemGo:SetActive(false)
        self.empty:SetActive(true)
    end
    self:Select(false)
end
--按钮点击
function UIHomeVisitGetGiftItem:AreaOnClick(go)
    self._onSelect(self._idx)
end

function UIHomeVisitGetGiftItem:Select(select)
    self.selector:SetActive(select)
end
