require("skill_damage_effect_param")

_class("SkillEffectSwitchBodyAreaByTargetPosParam", SkillEffectParamBase)
---@class SkillEffectSwitchBodyAreaByTargetPosParam: SkillEffectParamBase
SkillEffectSwitchBodyAreaByTargetPosParam = SkillEffectSwitchBodyAreaByTargetPosParam

function SkillEffectSwitchBodyAreaByTargetPosParam:Constructor(t)
    self._type = t.type
end

function SkillEffectSwitchBodyAreaByTargetPosParam:GetEffectType()
    return SkillEffectType.SwitchBodyAreaByTargetPos
end

function SkillEffectSwitchBodyAreaByTargetPosParam:GetType()
    return self._type
end

---@see lua/product/core_game/type_define/switch_body_area_dir_type.lua
--local SwitchBodyAreaDirType=
--{
--    None         = 0,  ---
--    Left         = 1,  ---头不动屁股向右，整体方向向左
--    Right        = 2,  ---头不动屁股向左，整体方向向右
--    Turn         = 3,  ---头不动屁股180°，方向掉转
--}
--
--_enum("SwitchBodyAreaDirType",SwitchBodyAreaDirType)
