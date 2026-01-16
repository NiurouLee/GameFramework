---@class UIActiveTaskMissionReward:UICustomWidget
_class("UIActiveTaskMissionReward", UICustomWidget)
UIActiveTaskMissionReward = UIActiveTaskMissionReward

function UIActiveTaskMissionReward:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)

    self.colorTxtCount = Color.white --txtCount默认颜色
end

function UIActiveTaskMissionReward:OnShow()
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    self.colorTxtCount = self.txtCount.color

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIHomelandBuildInfo.spriteatlas", LoadType.SpriteAtlas)
end
function UIActiveTaskMissionReward:OnHide()

end

---@param roleAsset RoleAsset
function UIActiveTaskMissionReward:Flush(roleAsset, funcClick)
    self.roleAsset = roleAsset
    local icon = ""
    local count = 0
    if roleAsset.exp then
        icon = ""
        count = roleAsset.count
    else
        local cfg = Cfg.cfg_item[roleAsset.assetid]
        icon = cfg.Icon
        count = roleAsset.count
    end
    self.imgIcon:LoadImage(icon)
    self.txtCount:SetText(self:FormatCount(count))
    self.funcClick = funcClick
end
---@return string
function UIActiveTaskMissionReward:FormatCount(count)
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

function UIActiveTaskMissionReward:TxtCountRedIfNotEnough(cost)
    local c = self.mRole:GetAssetCount(self.roleAsset.assetid) or 0
    if cost <= c then
        self.txtCount.color = self.colorTxtCount
    else
        self.txtCount.color = Color.red
    end
end

function UIActiveTaskMissionReward:BtnOnClick(go)
    if self.funcClick then
        self.funcClick(self.roleAsset.assetid, go.transform.position)
    end
end

function UIActiveTaskMissionReward:ClearTextCount()
    self.txtCount:SetText("")
end
