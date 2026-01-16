_class("BuffLogicSetChainSkillUseChainScope", BuffLogicBase)
---@class BuffLogicSetChainSkillUseChainScope : BuffLogicBase
BuffLogicSetChainSkillUseChainScope = BuffLogicSetChainSkillUseChainScope

function BuffLogicSetChainSkillUseChainScope:Constructor(buffInstance, logicParam)
end

function BuffLogicSetChainSkillUseChainScope:DoLogic(notify)
    self._entity:BuffComponent():SetBuffValue("ChainSkillUseChainScope",1)
end
