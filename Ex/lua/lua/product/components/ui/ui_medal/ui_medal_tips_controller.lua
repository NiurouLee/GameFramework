--
---@class UIMedalTipsController : UIController
_class("UIMedalTipsController", UIController)
UIMedalTipsController = UIMedalTipsController

--初始化
function UIMedalTipsController:OnShow(uiParams)
    self.itemId = uiParams[1] --勋章id
    self._atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)
    self:InitWidget()
    self:Refresh()
end

--获取ui组件
function UIMedalTipsController:InitWidget()
    ---@type UnityEngine.UI.Image
    self.imgIcon = self:GetUIComponent("Image", "imgIcon")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtdesc = self:GetUIComponent("UILocalizationText", "txtdesc")
    ---@type UILocalizationText
    self.txtGetWay = self:GetUIComponent("UILocalizationText", "txtGetWay")
end

function UIMedalTipsController:Refresh()
    if not self.itemId then
        return
    end
    local cfgItem = Cfg.cfg_item[self.itemId]
    if cfgItem then
        
    self.txtName:SetText(StringTable.Get(cfgItem.Name))
    self.txtdesc:SetText(StringTable.Get(cfgItem.RpIntro))
    end
    local cfgMedal = Cfg.cfg_item_medal[self.itemId]
    if cfgMedal then
        self.txtGetWay:SetText(StringTable.Get(cfgMedal.GetPathDesc))
        self.imgIcon.sprite = self._atlas:GetSprite(cfgMedal.Icon)
        self.imgIcon:SetNativeSize()
    end
end


--按钮点击
function UIMedalTipsController:BgOnClick(go)
    self:CloseDialog()
end
