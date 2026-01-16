require("skill_damage_effect_param")

_class("SkillEffectDestroyMonsterParam", SkillEffectParamBase)
---@class SkillEffectDestroyMonsterParam: SkillEffectParamBase
SkillEffectDestroyMonsterParam = SkillEffectDestroyMonsterParam

function SkillEffectDestroyMonsterParam:Constructor(t)
    self._destroyType = t.destroyType or SkillEffectDestroyMonsterType.Self
    self._monsterClassIdDic = {}
    if type(t.monsterClassID) == "number" then
        self._monsterClassIdDic[t.monsterClassID] = true
    elseif type(t.monsterClassID) == "table" then
        for _, id in ipairs(t.monsterClassID) do
            self._monsterClassIdDic[id] = true
        end
    end
end

function SkillEffectDestroyMonsterParam:GetEffectType()
    return SkillEffectType.DestroyMonster
end

---@return SkillEffectDestroyMonsterType
function SkillEffectDestroyMonsterParam:GetDestroyType()
    return self._destroyType
end
function SkillEffectDestroyMonsterParam:GetMonsterClassIdDic()
    return self._monsterClassIdDic
end

---@class SkillEffectDestroyMonsterType
local SkillEffectDestroyMonsterType = {
    Self = 1, ---删除自己
    MySummonMonster = 2, --自己召唤的怪物
    InRangeSpecificClass = 3, --范围内指定的怪物
    TargetMonster = 4, --技能目标怪
}
_enum("SkillEffectDestroyMonsterType", SkillEffectDestroyMonsterType)
