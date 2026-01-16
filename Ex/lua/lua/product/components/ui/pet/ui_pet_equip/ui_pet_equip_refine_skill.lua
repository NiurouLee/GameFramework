--
---@class UIPetEquipRefineSkill : UICustomWidget
_class("UIPetEquipRefineSkill", UICustomWidget)
UIPetEquipRefineSkill = UIPetEquipRefineSkill
--初始化
function UIPetEquipRefineSkill:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIPetEquipRefineSkill:InitWidget()
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

function UIPetEquipRefineSkill:SetData(petTemplateId, petLv)
    local cfg = UIPetEquipHelper.GetRefineCfg(petTemplateId, petLv)
    if not cfg then
        return
    end
    local skillType = cfg.SkillType
    local skillTypeStrKey = nil

    if skillType == PetSkillType.SkillType_ChainSkill then
        skillTypeStrKey = "str_pet_equip_skilltype_refine_2"
    elseif skillType == PetSkillType.SkillType_Active then
        skillTypeStrKey = "str_pet_equip_skilltype_refine_3"
    elseif skillType == PetSkillType.SkillType_Passive then
        skillTypeStrKey = "str_pet_equip_skilltype_refine_4"
    end

    self.skillIcon:LoadImage(cfg.SkillIcon)
    self._skillDesc:SetText(StringTable.Get(cfg.Desc))

    if skillTypeStrKey then
        local str = StringTable.Get(skillTypeStrKey, StringTable.Get(cfg.SkillName))
        self.skillName:SetText(str)
    else
        self.skillName:SetText(StringTable.Get(cfg.SkillName))
    end
end