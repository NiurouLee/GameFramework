---@class UIWorldBossDanRewardItem : UICustomWidget
_class("UIWorldBossDanRewardItem", UICustomWidget)
UIWorldBossDanRewardItem = UIWorldBossDanRewardItem

function UIWorldBossDanRewardItem:Constructor()
end
function UIWorldBossDanRewardItem:OnShow(uiParams)
    self:InitWidget()
end
function UIWorldBossDanRewardItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self._icon = self:GetUIComponent("RawImageLoader", "_icon")
    ---@type UILocalizationText
    self._numTex = self:GetUIComponent("UILocalizationText", "_numTex")
    self._numTexGo = self:GetGameObject("_numTex")
    ---@type UnityEngine.UI.Image
    self._numTexBg = self:GetUIComponent("Image", "_numTexBg")

    self._badgeGo = self:GetGameObject("DanBadgeGen")
    self._badgeGen = self:GetUIComponent("UISelectObjectPath","DanBadgeGen")
    self._badgeGenRect = self:GetUIComponent("RectTransform","DanBadgeGen")
    self._itemGo = self:GetGameObject("InfoArea")
    self._awardMulti = self:GetUIComponent("UILocalizationText", "AwardMulti")
    --generated end--
end
---@param itemAsset RoleAsset
function UIWorldBossDanRewardItem:SetData(itemAsset,itemClickCallBack,badgeDan,badgeRankLevel)
    self._bBadge = false
    if badgeDan then
        self._bBadge = true
    end
    self._badgeGo:SetActive(self._bBadge)
    self._itemGo:SetActive(not self._bBadge)

    local worldBossModule = self:GetModule(WorldBossModule)
    local str = ""
    if worldBossModule:AwardMultiOpen() then
        str = "x"..worldBossModule:GetAwardMultiple()
    end
    self._awardMulti:SetText(str)
    self._itemClickCallBack = itemClickCallBack
    if self._bBadge then
        ---@type role_world_boss_info
        local roleInfo = role_world_boss_info:New()
        roleInfo.dan_head_switch = true
        roleInfo.dan = badgeDan
        roleInfo.grading = badgeRankLevel
        UIWorldBossHelper.InitOtherDanBadgeSimple(self._badgeGen,self._badgeGo,self._badgeGenRect,roleInfo)
    else
        if itemAsset then
            self._itemId = itemAsset.assetid
            self._itemCount = itemAsset.count
            local itemCfg = Cfg.cfg_item[self._itemId]
            if itemCfg then
                self._icon:DestoryLastImage()
                local res = itemCfg.Icon
                self._icon:LoadImage(res)
                self._numTex:SetText(self._itemCount)
            end
        end
    end
end
function UIWorldBossDanRewardItem:IconOnClick(go)
    if self._itemClickCallBack then
        local tr = go.transform
        local pos = tr.position
        self._itemClickCallBack(self._itemId, pos)
    end
end
