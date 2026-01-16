---@class UIN34DelegatePersonTips: UIController
_class("UIN34DelegatePersonTips", UIController)
UIN34DelegatePersonTips = UIN34DelegatePersonTips

function UIN34DelegatePersonTips:OnShow(uiParams)
    ---@type UIActivityN34DelegatePersonData
    self._currentDelegatePerson = uiParams[1]
    self._pastBtn = self:GetGameObject("PastBtn")
    self._closeBtn = self:GetGameObject("CloseBtn")
    self:StartTask(self.PlayAnimation, self)
    -- if uiParams and uiParams[1] ~= nil then
    --     self._pastBtn:SetActive(false)
    -- end 
end

function UIN34DelegatePersonTips:PlayAnimation(TT)
    self:Lock("UIN34DelegatePersonTips_PlayAnimation")
    self._pastBtn:SetActive(false)
    self._closeBtn:SetActive(false)
    -- YIELD(TT, 2000)
    self._pastBtn:SetActive(true)
    self._closeBtn:SetActive(true)
    self:UnLock("UIN34DelegatePersonTips_PlayAnimation")
end

function UIN34DelegatePersonTips:PastBtnOnClick()
    self:ShowDialog("UIActivityN34TaskInfomationMainController")
end

function UIN34DelegatePersonTips:CloseBtnOnClick()
    self:CloseDialog()
end
