--
---@class UIHomeVisitGiftItem : UICustomWidget
_class("UIHomeVisitGiftItem", UICustomWidget)
UIHomeVisitGiftItem = UIHomeVisitGiftItem
--初始化
function UIHomeVisitGiftItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHomeVisitGiftItem:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.item = self:GetUIComponent("UISelectObjectPath", "item")
    ---@type UnityEngine.GameObject
    self.add = self:GetGameObject("add")
    --generated end--
    self.itemGo = self:GetGameObject("item")
    self.delBtn = self:GetGameObject("Del")
    self.select = self:GetGameObject("Select")
end
--设置数据
---@param data SpecItemAsset
function UIHomeVisitGiftItem:SetData(idx, data, onRemove, onClick)
    self._idx = idx
    self._onRemove = onRemove
    self._onClick = onClick
    if data == nil then
        self.add:SetActive(true)
        self.itemGo:SetActive(false)
        self.delBtn:SetActive(false)
    else
        ---@type UIItemHomeland
        local itemHome = self.item:SpawnObject("UIItemHomeland")
        local asset = RoleAsset:New()
        asset.assetid = data.assetid
        asset.count = data.count
        itemHome:Flush(asset)
        self.add:SetActive(false)
        self.itemGo:SetActive(true)
        self.delBtn:SetActive(true)
    end
    self:Select(false)
end
--按钮点击
function UIHomeVisitGiftItem:DelOnClick(go)
    self._onRemove(self._idx)
end
--按钮点击
function UIHomeVisitGiftItem:AreaOnClick(go)
    self._onClick(self._idx, go)
end

function UIHomeVisitGiftItem:Select(select)
    self.select:SetActive(select)
end
