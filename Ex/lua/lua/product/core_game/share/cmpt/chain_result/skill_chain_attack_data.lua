--[[------------------------------------------------------------------------------------------
    SkillChainAttackData : 宝宝的连锁技攻击数据
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_container")

_class("SkillChainAttackData", SkillEffectResultContainer)
---@class SkillChainAttackData: SkillEffectResultContainer
SkillChainAttackData = SkillChainAttackData

function SkillChainAttackData:Constructor(idx)
    --第几次连锁技
    self._chainIndex = idx
end

function SkillChainAttackData:GetChainSkillIndex()
    return self._chainIndex
end

function SkillChainAttackData:GetTotalDamage()
    local val = 0
    local ress = self:GetEffectResultsAsArray(SkillEffectType.Damage)
    if ress then
        for _, res in ipairs(ress) do
            if res:GetTotalDamage() > 0 then
                val = val + res:GetTotalDamage()
            end
        end
    end
    return val
end