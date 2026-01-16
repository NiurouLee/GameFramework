--[[
    存储技能的伤害结果
]]
require "buff_logic_base"
_class("BuffLogicSaveSkillDamage", BuffLogicBase)
---@class BuffLogicSaveSkillDamage:BuffLogicBase
BuffLogicSaveSkillDamage = BuffLogicSaveSkillDamage

function BuffLogicSaveSkillDamage:Constructor(buffInstance, logicParam)
end

function BuffLogicSaveSkillDamage:DoOverlap(logicParam, context)
    self:DoLogic()
end

---@param notify NotifyAttackBase
function BuffLogicSaveSkillDamage:DoLogic(notify)
    --取技能添加buff的上下文
    local context = self._buffInstance:Context()
    if not context then
        return
    end

    local e = self._buffInstance:Entity()
    if e:HasDeadMark() then
        return
    end

    local casterEntity = context.casterEntity

    -- local casterEntity = notify:GetAttackerEntity()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return
    end

    local curSaveSkillDamage = e:BuffComponent():GetBuffValue("SaveSkillDamage") or 0

    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果

        if targetEntityID == e:GetID() then
            ---@type DamageInfo
            local damageInfo = damageResult:GetDamageInfo(1)
            curSaveSkillDamage = curSaveSkillDamage + damageInfo:GetDamageValue()
        end
    end

    e:BuffComponent():SetBuffValue("SaveSkillDamage", curSaveSkillDamage)

    return true
end

_class("BuffLogicCleanSaveSkillDamage", BuffLogicBase)
---@class BuffLogicCleanSaveSkillDamage:BuffLogicBase
BuffLogicCleanSaveSkillDamage = BuffLogicCleanSaveSkillDamage

function BuffLogicCleanSaveSkillDamage:Constructor(buffInstance, logicParam)
end

function BuffLogicCleanSaveSkillDamage:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("SaveSkillDamage", 0)
end
