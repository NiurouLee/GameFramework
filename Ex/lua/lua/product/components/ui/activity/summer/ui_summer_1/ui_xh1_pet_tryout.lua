---@class UIXH1PetTryoutController : UIController
_class("UIXH1PetTryoutController", UIController)
UIXH1PetTryoutController = UIXH1PetTryoutController
function UIXH1PetTryoutController:OnShow(uiParams)
    self:InitWidget()
end
function UIXH1PetTryoutController:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.pets = self:GetUIComponent("UISelectObjectPath", "pets")
    --generated end--
end
function UIXH1PetTryoutController:maskOnClick(go)
end
