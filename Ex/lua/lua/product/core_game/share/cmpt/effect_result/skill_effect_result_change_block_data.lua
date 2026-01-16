--[[------------------------------------------------------------------------------------------
    SkillEffectResultChangeBlockData : 技能结果：修改阻挡信息
]] --------------------------------------------------------------------------------------------

---@class SkillEffectResultChangeBlockData: SkillEffectResultBase
_class("SkillEffectResultChangeBlockData", SkillEffectResultBase)
SkillEffectResultChangeBlockData = SkillEffectResultChangeBlockData

function SkillEffectResultChangeBlockData:Constructor(onAbyss,change)
    self._onAbyss = onAbyss --是否在深渊上
    self._change = change --修改方式push/pop
end

function SkillEffectResultChangeBlockData:GetEffectType()
    return SkillEffectType.ChangeBlockData
end

function SkillEffectResultChangeBlockData:GetOnAbyss()
    return self._onAbyss
end

function SkillEffectResultChangeBlockData:GetChangeType()
    return self._change
end

