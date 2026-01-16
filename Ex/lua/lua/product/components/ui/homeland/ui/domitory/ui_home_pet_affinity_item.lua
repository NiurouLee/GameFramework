---@class UIHomePetAffinityItem : UICustomWidget
_class("UIHomePetAffinityItem", UICustomWidget)
UIHomePetAffinityItem = UIHomePetAffinityItem
function UIHomePetAffinityItem:OnShow(uiParams)
    self:InitWidget()
end
function UIHomePetAffinityItem:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Slider
    self.slider = self:GetUIComponent("Slider", "Slider")
    ---@type UnityEngine.UI.Image
    self.percent = self:GetUIComponent("Image", "percent")
    ---@type UILocalizationText
    self.level = self:GetUIComponent("UILocalizationText", "level")
    --generated end--
end
---@param pet MatchPet
function UIHomePetAffinityItem:SetData(pet)
    self.level:SetText(pet:GetPetAffinityLevel())
    local percent = pet:GetPetAffinityLevelUpPercent()
    self.slider.value = percent
    self.percent.fillAmount = percent
end
