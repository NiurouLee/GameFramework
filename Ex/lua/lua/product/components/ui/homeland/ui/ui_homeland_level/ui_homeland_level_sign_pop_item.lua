---@class UIHomelandLevelSignPopItem:UICustomWidget
_class("UIHomelandLevelSignPopItem", UICustomWidget)
UIHomelandLevelSignPopItem = UIHomelandLevelSignPopItem

function UIHomelandLevelSignPopItem:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetHomelandLevelData()
end

function UIHomelandLevelSignPopItem:OnShow()
    ---@type UILocalizationText
    self.level = self:GetUIComponent("UILocalizationText", "level")
    ---@type UILocalizationText
    self.txtSignAward = self:GetUIComponent("UILocalizationText", "txtSignAward")
    ---@type UILocalizationText
    self.txtNewAward = self:GetUIComponent("UILocalizationText", "txtNewAward")
    ---@type UILocalizationText
    self.liveable = self:GetUIComponent("UILocalizationText", "liveable")
end
function UIHomelandLevelSignPopItem:OnHide()
end

---@param level HomelandLevelItemData
function UIHomelandLevelSignPopItem:Flush(level)
    self.level:SetText(level.level)
    self.txtSignAward:SetText(level.signReward)
    self.txtNewAward:SetText(level.furnitureReward)
    self.liveable:SetText(level.livableValueMax)
end
