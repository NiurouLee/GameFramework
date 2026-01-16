---@class UIN18LineMissionMapLine:UICustomWidget
_class("UIN18LineMissionMapLine", UICustomWidget)
UIN18LineMissionMapLine = UIN18LineMissionMapLine

function UIN18LineMissionMapLine:OnShow()
    ---@type UnityEngine.RectTransform
    self._rect = self:GetUIComponent("RectTransform", "shape")
     ---@type UnityEngine.UI.Image
    self._image = self:GetUIComponent("Image", "line")
end

function UIN18LineMissionMapLine:OnHide()
end

function UIN18LineMissionMapLine:Flush(from, to, condition)
    local dis = Vector2.Distance(from, to)
    self._rect.sizeDelta = Vector2(dis, self._rect.sizeDelta.y)
    self._rect.anchoredPosition = from
    local v = to - from
    self._rect.localRotation = Quaternion.FromToRotation(Vector3.right, Vector3(v.x, v.y, 0))
end
