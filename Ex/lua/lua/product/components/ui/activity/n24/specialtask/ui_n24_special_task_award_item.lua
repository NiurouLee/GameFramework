--
---@class UIN24SpecialTaskAwardItem : UICustomWidget
_class("UIN24SpecialTaskAwardItem", UICustomWidget)
UIN24SpecialTaskAwardItem = UIN24SpecialTaskAwardItem

--初始化
function UIN24SpecialTaskAwardItem:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIN24SpecialTaskAwardItem:_GetComponents()
    ---@type UnityEngine.UI.Image
    self._bg = self:GetUIComponent("Image", "bg")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "ImgIcon")
    ---@type UILocalizationText
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
end

--设置数据
---@param roleAsset RoleAsset
function UIN24SpecialTaskAwardItem:SetData(roleAsset, callback, lock)
    self.roleAsset = roleAsset
    self._callback = callback
    self._lock = lock
    local cfg = Cfg.cfg_item[self.roleAsset.assetid]
    local icon = cfg.Icon
    local count = roleAsset.count
    self._imgIcon:LoadImage(icon)
    self._txtCount:SetText(self:FormatCount(count))
end

--按钮点击
function UIN24SpecialTaskAwardItem:ImgIconOnClick(go)
    if not self._lock then
        self._callback(self.roleAsset.assetid, go.transform.position)
    end
end

function UIN24SpecialTaskAwardItem:FormatCount(count)
    if count < 1000 then
        return count
    end
    return math.floor(count / 1000) .. "k"
end