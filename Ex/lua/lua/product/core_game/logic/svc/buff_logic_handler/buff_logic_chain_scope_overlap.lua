--[[
    本体连锁技能范围 和 虚影连锁技能范围 重叠的部分 伤害增加
]]
--设置
_class("BuffLogicChainScopeOverlap", BuffLogicBase)
BuffLogicChainScopeOverlap = BuffLogicChainScopeOverlap

function BuffLogicChainScopeOverlap:Constructor(buffInstance, logicParam)
    self._changeValue = logicParam.changeValue
end

function BuffLogicChainScopeOverlap:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("ChainScopeOverlapChangeDamage", self._changeValue)
end
