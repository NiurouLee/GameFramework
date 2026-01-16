---@class UIActivityN34TaskInfomationPasteTips: UIController
_class("UIActivityN34TaskInfomationPasteTips", UIController)
UIActivityN34TaskInfomationPasteTips = UIActivityN34TaskInfomationPasteTips

function UIActivityN34TaskInfomationPasteTips:OnShow(uiParams)
    ---@type UIActivityN34DelegatePersonData
    self._pastBtn = self:GetGameObject("PastBtn")
    self._closeBtn = self:GetGameObject("CloseBtn")
    self:StartTask(self.PlayAnimation, self)
    if uiParams and uiParams[1]~= nil  then 
       self._callBack = uiParams[1]
    end 
end

function UIActivityN34TaskInfomationPasteTips:PlayAnimation(TT)
    self._pastBtn:SetActive(false)
    self._closeBtn:SetActive(false)
    self._pastBtn:SetActive(false)
    self._closeBtn:SetActive(true)
end

function UIActivityN34TaskInfomationPasteTips:PastBtnOnClick()

end

function UIActivityN34TaskInfomationPasteTips:CloseBtnOnClick()
    if self._callBack then
        self._callBack()
    end 
    self:CloseDialog()
end
