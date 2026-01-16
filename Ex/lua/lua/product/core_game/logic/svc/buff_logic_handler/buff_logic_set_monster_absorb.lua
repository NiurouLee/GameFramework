--[[
    修改怪物的技能吸收系数
]]
_class("BuffLogicSetMonsterAbsorb", BuffLogicBase)
---@class BuffLogicSetMonsterAbsorb:BuffLogicBase
BuffLogicSetMonsterAbsorb = BuffLogicSetMonsterAbsorb

function BuffLogicSetMonsterAbsorb:Constructor(buffInstance, logicParam)
    self._changeValueList = logicParam.changeValueList or {}
    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList or {}
end

function BuffLogicSetMonsterAbsorb:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()

    for k, paramType in ipairs(self._buffInstance._effectList) do
        local newValue = self._changeValueList[k] or -1
        self._buffLogicService:ChangeMonsterSkillAbsorb(self._entity, self:GetBuffSeq(), paramType, newValue)
    end
end

_class("BuffLogicRemoveMonsterAbsorb", BuffLogicBase)
---@class BuffLogicRemoveMonsterAbsorb:BuffLogicBase
BuffLogicRemoveMonsterAbsorb = BuffLogicRemoveMonsterAbsorb

function BuffLogicRemoveMonsterAbsorb:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveMonsterAbsorb:DoLogic()
    local e = self._buffInstance:Entity()

    for k, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveMonsterSkillAbsorb(self._entity, self:GetBuffSeq(), paramType)
    end
end
