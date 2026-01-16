--
---@class UUIShopHomelandPreviewItem : UICustomWidget
_class("UUIShopHomelandPreviewItem", UICustomWidget)
UUIShopHomelandPreviewItem = UUIShopHomelandPreviewItem

function UUIShopHomelandPreviewItem:Constructor()
end

--初始化
function UUIShopHomelandPreviewItem:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UUIShopHomelandPreviewItem:_GetComponents()
    ---@type RawImageLoader
    self._picture = self:GetUIComponent("RawImageLoader", "Picture")
    self._pictureObj = self:GetGameObject("Picture")
    ---@type UIDrag
    self._uiDrag = self:GetUIComponent("UIDrag", "Picture")
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._pictureObj),
        UIEvent.BeginDrag,
        function(pointData)
            self:OnBeginDrag(pointData)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._pictureObj),
        UIEvent.Drag,
        function(pointData)
            self:OnDragEvent(pointData)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._pictureObj),
        UIEvent.EndDrag,
        function(pointData)
            self:OnEndDrag(pointData)
        end
    )
    self._dragState = 0
end

--设置数据
function UUIShopHomelandPreviewItem:SetData(picture)
    self._picture:LoadImage(picture)
end

---@param pointData UnityEngine.EventSystems.PointerEventData
function UUIShopHomelandPreviewItem:OnBeginDrag(pointData)
    local delta = pointData.delta
    local d_x = delta.x
    local d_y = delta.y
    if math.abs(d_x) > math.abs(d_y) then
        self._dragState = 2
        self._uiDrag:OnBeginDrag(pointData)
    else
        self._dragState = 1
    end
end

---@param pointData UnityEngine.EventSystems.PointerEventData
function UUIShopHomelandPreviewItem:OnDragEvent(pointData)
    if self._dragState == 2 then
        if self._uiDrag then
            self._uiDrag:OnDrag(pointData)
        end
    end
end

function UUIShopHomelandPreviewItem:OnEndDrag(pointData)
    if self._dragState == 2 then
        if self._uiDrag then
            self._uiDrag:OnEndDrag(pointData)
        end
    end
    self._dragState = 0
end