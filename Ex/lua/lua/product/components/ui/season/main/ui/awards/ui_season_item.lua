---@class UISeasonItem:UICustomWidget
_class("UISeasonItem", UICustomWidget)
UISeasonItem = UISeasonItem

function UISeasonItem:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)

    self.colorTxtCount = Color.white --txtCount默认颜色
end

function UISeasonItem:OnShow()
    self._trans = self:GetGameObject()
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    self.bgGo = self:GetGameObject("bg")
    self.quality = self:GetUIComponent("Image", "quality")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self.colorTxtCount = self.txtCount.color

    self.first = self:GetGameObject("first")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIS1Main.spriteatlas", LoadType.SpriteAtlas)
end
function UISeasonItem:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param roleAsset RoleAsset
function UISeasonItem:Flush(roleAsset, funcClick, notShowTips, showNew, newState)
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
    self.quality.sprite = self.atlas:GetSprite("exp_s1_map_se" .. color)
    self.txtCount:SetText(self:FormatCount(count))
    self.first:SetActive(roleAsset.first ~= nil)
    self.funcClick = funcClick
    self._notShowTips = notShowTips
end
---@return string
function UISeasonItem:FormatCount(count)
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

function UISeasonItem:TxtCountRedIfNotEnough(cost)
    local c = self.mRole:GetAssetCount(self.roleAsset.assetid) or 0
    if cost <= c then
        self.txtCount.color = self.colorTxtCount
    else
        self.txtCount.color = Color.red
    end
end

---设置_notShowTips
function UISeasonItem:SetNotShowTips(notShowTips)
    self._notShowTips = notShowTips
end

function UISeasonItem:BgOnClick(go)
    if self.funcClick then
        self.funcClick()
    end
    if not self._notShowTips then
        --self:ShowDialog("UISeasonItemTips", self.roleAsset.assetid, go)
        --self:ShowDialog("UIItemTips", self.roleAsset, go, "UISeasonItem")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowItemTips, self.roleAsset.assetid, self._trans.transform.position)
    end
end
function UISeasonItem:GetBtn()
    return self.bgGo
end