--[[
    @商城神秘页签二级按钮
]]
---@class UIShopSecretTabBtn:UICustomWidget

_class("UIShopSecretTabBtn", UICustomWidget)
UIShopSecretTabBtn = UIShopSecretTabBtn
function UIShopSecretTabBtn:OnShow()
    -- self.tgl = self:GetUIComponent("Toggle", "pic")
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.atlas = self:GetAsset("UIResInstance.spriteatlas", LoadType.SpriteAtlas)
    -- self.animator = self:GetGameObject().transform:GetComponent("Animator")
    self.choose = self:GetGameObject("choose")
end

function UIShopSecretTabBtn:OnHide()
    -- self.animator:SetTrigger("out")
end
function UIShopSecretTabBtn:Init(subTabType, name, tglGroup, onClickTabBtn, param)
    self.subTabType = subTabType
    -- self.tgl.group = tglGroup
    -- self.tgl.isOn = false
    self.choose:SetActive(false)
    self.onClickTabBtn = onClickTabBtn
    self.param = param
    self.nameTxt:SetText(name or "")
    -- self.animator:SetTrigger("in")
end
function UIShopSecretTabBtn:Select(select)
    -- self.tgl.isOn = select
    self.choose:SetActive(select)
end
function UIShopSecretTabBtn:picOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    self.onClickTabBtn(self.param, self.subTabType)
end

function UIShopSecretTabBtn:GetSubType()
    return self.subTabType
end
