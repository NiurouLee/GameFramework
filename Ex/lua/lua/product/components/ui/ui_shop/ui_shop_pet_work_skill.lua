---显示在左侧面板的技能条的prefab
---@class UIShopPetWorkSkill : UICustomWidget
_class("UIShopPetWorkSkill", UICustomWidget)
UIShopPetWorkSkill = UIShopPetWorkSkill
function UIShopPetWorkSkill:OnShow(uiParams)
    self._workIndexName = self:GetUIComponent("UILocalizationText", "workIndexName")
    self._workSkillDesc = self:GetUIComponent("UILocalizationText", "workSkillDesc")
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._workSkillText = self:GetUIComponent("UILocalizationText", "workSkillText")
end

---@param index number 下标
---@param skillCls table 技能
function UIShopPetWorkSkill:SetData(index, skillCls, roomType)
    local cfg_work_skill = Cfg.cfg_work_skill[skillCls.ID]
    if cfg_work_skill then
        self._icon:LoadImage(cfg_work_skill.Icon)
        self._workIndexName:SetText(StringTable.Get(cfg_work_skill.Name))
        self._workSkillDesc:SetText(StringTable.Get(cfg_work_skill.Desc))
        self._workSkillText.color = Color(1, 1, 1, 1)
        self._workSkillDesc.color = Color(1, 1, 1, 1)
    end
end
