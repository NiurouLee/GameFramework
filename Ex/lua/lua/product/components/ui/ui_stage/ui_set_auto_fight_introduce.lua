---@class UISetAutoFightIntroduce:UIController
_class("UISetAutoFightIntroduce", UIController)
UISetAutoFightIntroduce = UISetAutoFightIntroduce

function UISetAutoFightIntroduce:OnShow(uiParams)
end

function UISetAutoFightIntroduce:MaskOnClick()
    self:CloseDialog()
end
