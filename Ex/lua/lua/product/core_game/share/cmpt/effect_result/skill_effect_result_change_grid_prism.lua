--[[------------------------------------------------------------------------------------------
    SkillEffectResultChangeGridPrism : 技能结果：修改棱镜信息
]] --------------------------------------------------------------------------------------------

---@class SkillEffectResultChangeGridPrism: SkillEffectResultBase
_class("SkillEffectResultChangeGridPrism", SkillEffectResultBase)
SkillEffectResultChangeGridPrism = SkillEffectResultChangeGridPrism

function SkillEffectResultChangeGridPrism:Constructor()

end

function SkillEffectResultChangeGridPrism:GetEffectType()
    return SkillEffectType.ChangeGridPrism
end
