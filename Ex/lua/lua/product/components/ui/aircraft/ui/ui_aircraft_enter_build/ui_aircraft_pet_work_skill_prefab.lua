---显示在星灵Item下方的几个技能图标Prefab
---@class UIAircraftPetWorkSkillPrefab : UICustomWidget
_class("UIAircraftPetWorkSkillPrefab", UICustomWidget)
UIAircraftPetWorkSkillPrefab = UIAircraftPetWorkSkillPrefab
function UIAircraftPetWorkSkillPrefab:OnShow(uiParams)
    self._icon = self:GetUIComponent("RawImageLoader", "RawImage")
    self._mask = self:GetGameObject("mask")
    --self._lv = self:GetUIComponent("UILocalizationText", "lv")

    self._lock = self:GetGameObject("lock")
end

---@param index number 下标
---@param skillCls table 技能
function UIAircraftPetWorkSkillPrefab:SetData(index, skillCls, roomType)
    local cfg_work_skill = Cfg.cfg_work_skill[skillCls.ID]
    if cfg_work_skill then
        --self._lv:SetText(cfg_work_skill.Level)

        self._icon:LoadImage(cfg_work_skill.Icon)
        self._mask:SetActive(cfg_work_skill.RoomType ~= roomType)
        self._lock:SetActive(skillCls.isLock)
    --self._lv.gameObject:SetActive(not skillCls.isLock)
    end
end
