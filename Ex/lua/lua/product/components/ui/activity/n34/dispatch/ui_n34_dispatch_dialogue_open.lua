---@class UIN34DispatchDialogueOpen:UIController
_class("UIN34DispatchDialogueOpen", UIController)
UIN34DispatchDialogueOpen = UIN34DispatchDialogueOpen

function UIN34DispatchDialogueOpen:Constructor()
end

function UIN34DispatchDialogueOpen:LoadDataOnEnter(TT, res, uiParams)
    self._archId = uiParams[1]
    self._fnOpen = uiParams[2]
end

function UIN34DispatchDialogueOpen:OnShow(uiParams)

end

function UIN34DispatchDialogueOpen:OnHide()
end

function UIN34DispatchDialogueOpen:BtnAnywhereOnClick(go)

end

function UIN34DispatchDialogueOpen:BtnOpenOnClick(go)
    if self._fnOpen ~= nil then
        self._fnOpen()
    end
end
