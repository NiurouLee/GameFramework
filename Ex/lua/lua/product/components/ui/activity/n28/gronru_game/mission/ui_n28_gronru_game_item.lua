---@class UIN28GronruItem:UICustomWidget
_class("UIN28GronruItem", UICustomWidget)
UIN28GronruItem = UIN28GronruItem

function UIN28GronruItem:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)

    self.colorTxtCount = Color.white --txtCount默认颜色
end

function UIN28GronruItem:OnShow()
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self.colorTxtCount = self.txtCount.color

    self.first = self:GetGameObject("first")
end
function UIN28GronruItem:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param roleAsset RoleAsset
function UIN28GronruItem:Flush(roleAsset, atlas)
    self.atlas = atlas
    self.roleAsset = roleAsset
    local icon = ""
    local color = 1
    local count = 0
    if roleAsset.exp then
        icon = ""
        color = 6
        count = roleAsset.count
    else
        local cfg = Cfg.cfg_item[roleAsset.assetid]
        icon = cfg.Icon
        color = cfg.Color
        count = roleAsset.count
    end
    self.imgIcon:LoadImage(icon)
    self.txtCount:SetText(self:FormatCount(count))
    self.first:SetActive(roleAsset.first ~= nil)
end
---@return string
function UIN28GronruItem:FormatCount(count)
    if not count or count == "" then
        return ""
    end
    if count > 999999 then -->6位数
        local c = math.floor(count * 0.0001)
        return StringTable.Get("str_homeland_backpack_n_w", c)
    elseif count > 99999 then -->5位数
        local c = math.floor(count * 0.001) * 0.1
        return StringTable.Get("str_homeland_backpack_n_w", c)
    end
    return tostring(count)
end

function UIN28GronruItem:TxtCountRedIfNotEnough(cost)
    local c = self.mRole:GetAssetCount(self.roleAsset.assetid) or 0
    if cost <= c then
        self.txtCount.color = self.colorTxtCount
    else
        self.txtCount.color = Color.red
    end
end

---设置_notShowTips
function UIN28GronruItem:SetNotShowTips(notShowTips)
    self._notShowTips = notShowTips
end

function UIN28GronruItem:BgOnClick(go)
    if self.funcClick then
        self.funcClick()
    end
    if not self._notShowTips then
        self:ShowDialog("UIItemTipsHomeland", self.roleAsset.assetid, go)
    end
end

function UIN28GronruItem:ClearTextCount()
    self.txtCount:SetText("")
end

