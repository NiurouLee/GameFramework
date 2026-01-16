--
---@class UIN1SpecialTaskAwardItem : UICustomWidget
_class("UIN1SpecialTaskAwardItem", UICustomWidget)
UIN1SpecialTaskAwardItem = UIN1SpecialTaskAwardItem

--初始化
function UIN1SpecialTaskAwardItem:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIN1SpecialTaskAwardItem:_GetComponents()
    ---@type UnityEngine.UI.Image
    self._bg = self:GetUIComponent("Image", "bg")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "ImgIcon")
    ---@type UILocalizationText
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
end

--设置数据
---@param roleAsset RoleAsset
function UIN1SpecialTaskAwardItem:SetData(roleAsset, callback, lock)
    self.roleAsset = roleAsset
    self._callback = callback
    self._lock = lock

    local cfg = Cfg.cfg_item[roleAsset[1]]
    --local cfg = Cfg.cfg_item[self.roleAsset.assetid]
    local icon = cfg.Icon
    local count = roleAsset[2]
    --local count = roleAsset.count
    self._imgIcon:LoadImage(icon)
    self._txtCount:SetText(self:FormatCount(count))
end

--按钮点击
function UIN1SpecialTaskAwardItem:ImgIconOnClick(go)
    if not self._lock and self._callback then
        self._callback(self.roleAsset[1], go.transform.position)
        --self._callback(self.roleAsset.assetid, go.transform.position)
    end
end

function UIN1SpecialTaskAwardItem:FormatCount(count)
    if count < 1000 then
        return count
    end
    return math.floor(count / 1000) .. "k"
end