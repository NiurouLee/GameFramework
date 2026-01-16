--[[
    清除技能结果
]]
_class("BuffLogicCleanSkillRoutine", BuffLogicBase)
BuffLogicCleanSkillRoutine = BuffLogicCleanSkillRoutine

function BuffLogicCleanSkillRoutine:Constructor(buffInstance, logicParam)
    self._skillHolderName = logicParam.skillHolderName or "self"
end

function BuffLogicCleanSkillRoutine:DoLogic()
    local e = self._buffInstance:Entity()

    local skillHolder = nil

    local skillHolderName = self._skillHolderName .. e:GetID()
    local skillHolderID = e:GetSkillHolder(skillHolderName)
    if skillHolderID then
        skillHolder = self._world:GetEntityByID(skillHolderID)
    end

    if not skillHolder then
        return
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = skillHolder:SkillContext():GetResultContainer()
    skillEffectResultContainer:Clear()
end
