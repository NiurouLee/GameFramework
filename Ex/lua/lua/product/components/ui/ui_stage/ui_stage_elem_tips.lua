---@class UIStageElemTips:UIController
_class("UIStageElemTips", UIController)
UIStageElemTips = UIStageElemTips

function UIStageElemTips:OnShow(uiParams)
end

function UIStageElemTips:BgOnClick()
    self:CloseDialog()
end