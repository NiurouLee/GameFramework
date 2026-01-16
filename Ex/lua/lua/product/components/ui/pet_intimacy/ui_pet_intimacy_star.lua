---@class UIPetIntimacyStar:UICustomWidget
_class("UIPetIntimacyStar", UICustomWidget)
UIPetIntimacyStar = UIPetIntimacyStar

function UIPetIntimacyStar:OnShow(uiParams)
    self._starOnyGo = self:GetGameObject("UIPetIntimacyStarOn")
end

function UIPetIntimacyStar:Refresh(isOn)
    self._starOnyGo:SetActive(isOn)
end
