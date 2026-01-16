_class("BuffLogicChangeTrueDamageFixParamByDefence", BuffLogicBase)
---@class BuffLogicChangeTrueDamageFixParamByDefence: BuffLogicBase
BuffLogicChangeTrueDamageFixParamByDefence = BuffLogicChangeTrueDamageFixParamByDefence

function BuffLogicChangeTrueDamageFixParamByDefence:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent or 0
end
---@param notify NotifyAttackBase
function BuffLogicChangeTrueDamageFixParamByDefence:DoLogic(notify)
    ----@type Entity
    local attackerEntity = notify:GetAttackerEntity()
    ---@type AttributesComponent
    local attackAttr = attackerEntity:Attributes()
    local attackerDefenderCount = attackAttr:GetDefence()
    ----@type Entity
    local defenderEntity = notify:GetDefenderEntity()
    ---@type AttributesComponent
    local defendAttr = defenderEntity:Attributes()
    local defenderDefenderCount = defendAttr:GetDefence()
    ---策划给的死公式  微笑
    local value = attackerDefenderCount / (attackerDefenderCount + defenderDefenderCount)
    ---简单处理下有效位的问题
    value = self._percent * value
    value = value * 10000
    value = math.floor(value)
    value = value / 10000

    self._buffLogicService:ChangeTrueDamageFixParam(self._entity, self:GetBuffSeq(), value)
    return true
end

_class("BuffLogicUndoChangeTrueDamageFixParamByDefence", BuffLogicBase)
---@class BuffLogicUndoChangeTrueDamageFixParamByDefence: BuffLogicBase
BuffLogicUndoChangeTrueDamageFixParamByDefence = BuffLogicUndoChangeTrueDamageFixParamByDefence

function BuffLogicUndoChangeTrueDamageFixParamByDefence:Constructor()
end

function BuffLogicUndoChangeTrueDamageFixParamByDefence:DoLogic()
    self._buffLogicService:RemoveTrueDamageFixParam(self._entity, self:GetBuffSeq())
    return true
end
