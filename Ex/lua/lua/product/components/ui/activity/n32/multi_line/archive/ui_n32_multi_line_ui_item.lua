---@class UIN32MultiLineUIItem:UICustomWidget
_class("UIN32MultiLineUIItem", UICustomWidget)
UIN32MultiLineUIItem = UIN32MultiLineUIItem

function UIN32MultiLineUIItem:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)

    self.colorTxtCount = Color.white --txtCount默认颜色
end

function UIN32MultiLineUIItem:OnShow()
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self.colorTxtCount = self.txtCount.color

    self.first = self:GetGameObject("first")

end
function UIN32MultiLineUIItem:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param roleAsset RoleAsset
function UIN32MultiLineUIItem:Flush(roleAsset, funcClick, notShowTips, showNew, newState)
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
    --self.bg.sprite = self.atlas:GetSprite("N17_produce_bg_item_" .. color)
    self.txtCount:SetText("x"..self:FormatCount(count))
    self.first:SetActive(roleAsset.first ~= nil)
    self.funcClick = funcClick
    self._notShowTips = notShowTips
end
---@return string
function UIN32MultiLineUIItem:FormatCount(count)
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

function UIN32MultiLineUIItem:TxtCountRedIfNotEnough(cost)
    local c = self.mRole:GetAssetCount(self.roleAsset.assetid) or 0
    if cost <= c then
        self.txtCount.color = self.colorTxtCount
    else
        self.txtCount.color = Color.red
    end
end

---设置_notShowTips
function UIN32MultiLineUIItem:SetNotShowTips(notShowTips)
    self._notShowTips = notShowTips
end

function UIN32MultiLineUIItem:BgOnClick(go)
    if self.funcClick then
        self.funcClick()
    end
end

function UIN32MultiLineUIItem:ClearTextCount()
    self.txtCount:SetText("")
end

