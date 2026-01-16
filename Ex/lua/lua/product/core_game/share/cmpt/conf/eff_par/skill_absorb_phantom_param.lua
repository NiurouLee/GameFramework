--[[
    吸收幻象技能参数
]]
---@class SkillAbsorbPhantomParam:SkillEffectParamBase
_class("SkillAbsorbPhantomParam", SkillEffectParamBase)
SkillAbsorbPhantomParam = SkillAbsorbPhantomParam

function SkillAbsorbPhantomParam:Constructor(t)
    self._hpRecover = t.hpRecover
end

function SkillAbsorbPhantomParam:GetEffectType()
    return SkillEffectType.AbsorbPhantom
end

function SkillAbsorbPhantomParam:GetHpRecoverPercent()
    return self._hpRecover
end
