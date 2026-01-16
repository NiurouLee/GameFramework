---@class UIActivityValentineMainReward:UICustomWidget
_class("UIActivityValentineMainReward", UICustomWidget)
UIActivityValentineMainReward = UIActivityValentineMainReward

function UIActivityValentineMainReward:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)

    self.colorTxtCount = Color.white --txtCount默认颜色
end

function UIActivityValentineMainReward:OnShow()
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self.colorTxtCount = self.txtCount.color
    self._anim = self:GetUIComponent("Animation","anim")

    self.first = self:GetGameObject("first")

    self._isGetObj = self:GetGameObject("isGet")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIHomelandBuildInfo.spriteatlas", LoadType.SpriteAtlas)
end
function UIActivityValentineMainReward:OnHide()
    self.imgIcon:DestoryLastImage()
end

---@param roleAsset RoleAsset
function UIActivityValentineMainReward:Flush(roleAsset, funcClick, notShowTips, showNew, newState)
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
    self.funcClick = funcClick
    self._notShowTips = notShowTips
end
---@return string
function UIActivityValentineMainReward:FormatCount(count)
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

function UIActivityValentineMainReward:TxtCountRedIfNotEnough(cost)
    local c = self.mRole:GetAssetCount(self.roleAsset.assetid) or 0
    if cost <= c then
        self.txtCount.color = self.colorTxtCount
    else
        self.txtCount.color = Color.red
    end
end

---设置_notShowTips
function UIActivityValentineMainReward:SetNotShowTips(notShowTips)
    self._notShowTips = notShowTips
end

function UIActivityValentineMainReward:BtnOnClick(go)
    if self.funcClick then
        self.funcClick(self.roleAsset.assetid, go.transform.position)
    end
end

function UIActivityValentineMainReward:ClearTextCount()
    self.txtCount:SetText("")
end

function UIActivityValentineMainReward:SetIsGet(isGet)
    self._isGetObj:SetActive(isGet)
end

--播放获得动画
function UIActivityValentineMainReward:PlayGetAnim()
    self._isGetObj:SetActive(true)
    self._anim:Play("uieff_UIActivityValentineMainReward_mask")
end

