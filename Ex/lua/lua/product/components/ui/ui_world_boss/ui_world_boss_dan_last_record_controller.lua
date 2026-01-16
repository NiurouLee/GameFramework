---@class UIWorldBossDanLastRecordController : UIController
_class("UIWorldBossDanLastRecordController", UIController)
UIWorldBossDanLastRecordController = UIWorldBossDanLastRecordController
function UIWorldBossDanLastRecordController:OnShow(uiParams)
    self:InitWidget()
end
function UIWorldBossDanLastRecordController:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self._uianim = self:GetGameObject("uianim")
    ---@type UICustomWidgetPool
    self._danBadgeGen = self:GetUIComponent("UISelectObjectPath", "DanBadgeGen")
    ---@type RawImageLoader
    self._bg = self:GetUIComponent("RawImageLoader", "Bg")
    ---@type UILocalizationText
    self._danText = self:GetUIComponent("UILocalizationText", "DanText")
    --generated end--
end
function UIWorldBossDanLastRecordController:ConfirmBtnOnClick(go)
    self:CloseDialog()
end
