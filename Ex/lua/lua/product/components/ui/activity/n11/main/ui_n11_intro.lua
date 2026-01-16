---@class UIN11Intro:UIController
_class("UIN11Intro", UIController)
UIN11Intro = UIN11Intro

function UIN11Intro:OnShow(uiParams)
    ---@type ATransitionComponent
    self.atc = self:GetGameObject():GetComponent(typeof(ATransitionComponent))
    self.atc.enabled = true
    self.atc:PlayEnterAnimation(true)
end

function UIN11Intro:OnHide()
end

--region OnClick
function UIN11Intro:btnCloseOnClick(go)
    self:CloseDialog()
end
--endregion
