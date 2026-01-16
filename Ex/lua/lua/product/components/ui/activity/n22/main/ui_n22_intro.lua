---@class UIN22Intro:UIController
_class("UIN22Intro", UIController)
UIN22Intro = UIN22Intro

function UIN22Intro:OnShow(uiParams)
    ---@type ATransitionComponent
    self.atc = self:GetGameObject():GetComponent(typeof(ATransitionComponent))
    self.atc.enabled = true
    self.atc:PlayEnterAnimation(true)
end

function UIN22Intro:OnHide()
end

--region OnClick
function UIN22Intro:BtnCloseOnClick(go)
    self:CloseDialog()
end
--endregion
