---@class UISeasonBuffProgressCell:UICustomWidget
_class("UISeasonBuffProgressCell", UICustomWidget)
UISeasonBuffProgressCell = UISeasonBuffProgressCell

function UISeasonBuffProgressCell:OnShow(uiParams)
    self.bgGo = self:GetGameObject("Bg")
    self.frontGo = self:GetGameObject("Front")
end
--设置数据
function UISeasonBuffProgressCell:SetData(index,isOn)
    self._index = index
    self.frontGo:SetActive(isOn)
end