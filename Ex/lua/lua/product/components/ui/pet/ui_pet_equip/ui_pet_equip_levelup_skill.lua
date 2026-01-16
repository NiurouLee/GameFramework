--
---@class UIPetEquipLevelupSkill : UICustomWidget
_class("UIPetEquipLevelupSkill", UICustomWidget)
UIPetEquipLevelupSkill = UIPetEquipLevelupSkill
--初始化
function UIPetEquipLevelupSkill:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIPetEquipLevelupSkill:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.skillName = self:GetUIComponent("UILocalizationText", "skillName")
    ---@type UILocalizedTMP
    self._skillDesc = self:GetUIComponent("UILocalizedTMP", "skillDesc")
    self._skillDesc.onHrefClick = function(hrefName)
        GameGlobal.UIStateManager():ShowDialog("UISkillHrefInfo", hrefName)
    end

    ---@type RawImageLoader
    self.skillIcon = self:GetUIComponent("RawImageLoader", "skillIcon")
    --generated end--
end

function UIPetEquipLevelupSkill:SetData(skillIcon, skillDesc)
    self.skillIcon:LoadImage(skillIcon)
    self._skillDesc:SetText(skillDesc)
end