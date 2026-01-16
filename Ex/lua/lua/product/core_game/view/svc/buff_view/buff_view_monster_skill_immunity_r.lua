--[[
    魔免表现——挂特效
]]
---@class BuffViewMonsterSkillImmunity:BuffViewBase
_class("BuffViewMonsterSkillImmunity", BuffViewBase)
BuffViewMonsterSkillImmunity = BuffViewMonsterSkillImmunity

function BuffViewMonsterSkillImmunity:PlayView(TT)
    if not self:ViewParams() then
        return
    end

    local effectID = self:ViewParams().LoadEffectID
    if not effectID then
        return
    end
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    local e = self:Entity()
    local cEffectHolder = e:EffectHolder()
    local eEffect = sEffect:CreateEffect(effectID, e)
    local effEntityId = eEffect:GetID()
    cEffectHolder:AttachEffect("MonsterSkillImmunity", effEntityId)
end

--[[
    魔免表现——移除特效
]]
---@class BuffViewRemoveMonsterSkillImmunity:BuffViewBase
_class("BuffViewRemoveMonsterSkillImmunity", BuffViewBase)
BuffViewRemoveMonsterSkillImmunity = BuffViewRemoveMonsterSkillImmunity

function BuffViewRemoveMonsterSkillImmunity:PlayView(TT)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    local e = self:Entity()
    local cEffectHolder = e:EffectHolder()
    local effects = cEffectHolder:GetEffectList("MonsterSkillImmunity")
    if effects and table.count(effects) > 0 then
        for _, effId in ipairs(effects) do
            sEffect:DestroyEffectByID(effId)
        end
    end
end
