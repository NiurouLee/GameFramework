--
---@class UIN26CookPoint : UICustomWidget
_class("UIN26CookPoint", UICustomWidget)
UIN26CookPoint = UIN26CookPoint

--初始化
function UIN26CookPoint:OnShow(uiParams)
    self:InitWidget()
end


function UIN26CookPoint:InitWidget()
    self.pointSel = self:GetGameObject("pointSel")
end


function UIN26CookPoint:SetSelect(bSelect)
    self.pointSel:SetActive(bSelect)
end