--[[------------------------------------------------------------------------------------------
    ModifyAntiAttackParam = 172, --修改反制技能参数当前数值的效果
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamModifyAntiAttackParam", SkillEffectParamBase)
---@class SkillEffectParamModifyAntiAttackParam: SkillEffectParamBase
SkillEffectParamModifyAntiAttackParam = SkillEffectParamModifyAntiAttackParam

function SkillEffectParamModifyAntiAttackParam:Constructor(t)
    self._modifyType = t.modifyType
    self._modifyParam = t.modifyParam
end

function SkillEffectParamModifyAntiAttackParam:GetEffectType()
    return SkillEffectType.ModifyAntiAttackParam
end

function SkillEffectParamModifyAntiAttackParam:GetModifyType()
    return self._modifyType
end

function SkillEffectParamModifyAntiAttackParam:GetModifyParam()
    return self._modifyParam
end

--- @class ModifyAntiAttackParamType
local ModifyAntiAttackParamType = {
    WaitActiveSkillCount = 1, --修改等待光灵技能施放次数，这个参数会叠加到现在的数值上，如果配-1，就是减。这个参数最小是0。
    AntiSkillCountCurRound = 2, --修改当前回合反制AI已经触发的次数，这个参数会叠加到现在的数值上。
    AntiSkillEnabled = 3, --反制是否激活，默认1激活
    MAX = 999 --
}
_enum("ModifyAntiAttackParamType", ModifyAntiAttackParamType)
