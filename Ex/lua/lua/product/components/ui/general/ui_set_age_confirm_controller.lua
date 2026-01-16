---@class UISetAgeConfirmController:UIController
_class("UISetAgeConfirmController", UIController)
UISetAgeConfirmController = UISetAgeConfirmController

function UISetAgeConfirmController:LoadDataOnEnter(TT, res, uiParams)
    ---@type PayModule
    self._payModule = GameGlobal.GetModule(PayModule)
    local res, replyEvent = self._payModule:GetAgeId(TT)
    if res:GetSucc() then
        self._currentSelectId = replyEvent.cfg_id
    end
end

function UISetAgeConfirmController:OnShow(uiParams)
    self._ageDes1 = self:GetUIComponent("UILocalizationText", "AgeDes1")
    self._limitDes1 = self:GetUIComponent("UILocalizationText", "LimitDes1")
    self._selected1 = self:GetGameObject("Selected1")
    self._ageDes2 = self:GetUIComponent("UILocalizationText", "AgeDes2")
    self._limitDes2 = self:GetUIComponent("UILocalizationText", "LimitDes2")
    self._selected2 = self:GetGameObject("Selected2")
    self._ageDes3 = self:GetUIComponent("UILocalizationText", "AgeDes3")
    self._limitDes3 = self:GetUIComponent("UILocalizationText", "LimitDes3")
    self._selected3 = self:GetGameObject("Selected3")
    self._cancelClick = self:GetGameObject("CancelClick")
    self._confirmClick = self:GetGameObject("ConfirmClick")
    self._cancelBtn = self:GetGameObject("CancelBtn")
    self._confirmBtn = self:GetGameObject("ConfirmBtn")
    self._callback = uiParams[1]
    for i = 1, 3 do
        local cfg = Cfg.cfg_pay_limit[i]
        self["_selected" .. i]:SetActive(i == self._currentSelectId)
        self["_ageDes" .. i]:SetText(StringTable.Get(cfg.AgeDes))
        self["_limitDes" .. i]:SetText(StringTable.Get(cfg.LimitDes))
    end
    local cancelBtn = UIEventTriggerListener.Get(self._cancelBtn)
    cancelBtn.onDown = function(go)
        self._cancelClick:SetActive(true)
    end
    cancelBtn.onUp = function(go)
        self._cancelClick:SetActive(false)
        self:CloseDialog()
    end
    local confirmBtn = UIEventTriggerListener.Get(self._confirmBtn)
    confirmBtn.onDown = function(go)
        self._confirmClick:SetActive(true)
    end
    confirmBtn.onUp = function(go)
        self._confirmClick:SetActive(false)
        self:Lock("UISetAgeConfirmController_SetAgeId")
        GameGlobal.TaskManager():StartTask(self.SetAgeId, self)
    end
end

function UISetAgeConfirmController:CancelBtnOnClick()
end

function UISetAgeConfirmController:ConfirmBtnOnClick()
end

function UISetAgeConfirmController:SetAgeId(TT)
    self._payModule:SetAgeId(TT, self._currentSelectId)
    self:CloseDialog()
    if self._callback then
        self._callback()
    end
    self:UnLock("UISetAgeConfirmController_SetAgeId")
end

function UISetAgeConfirmController:Age1OnClick()
    self:SetCurrentSelectedId(1)
end

function UISetAgeConfirmController:Age2OnClick()
    self:SetCurrentSelectedId(2)
end

function UISetAgeConfirmController:Age3OnClick()
    self:SetCurrentSelectedId(3)
end

function UISetAgeConfirmController:SetCurrentSelectedId(id)
    if self._currentSelectId and self._currentSelectId > 0 then
        self["_selected" .. self._currentSelectId]:SetActive(false)
    end
    self._currentSelectId = id
    if self._currentSelectId and self._currentSelectId > 0 then
        self["_selected" .. self._currentSelectId]:SetActive(true)
    end
end
