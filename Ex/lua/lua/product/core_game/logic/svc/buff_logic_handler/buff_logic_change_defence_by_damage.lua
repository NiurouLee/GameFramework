--[[
    根据伤害造成HP改变百分比加防
]]
---@class BuffLogicChangeDefenceByDamage:BuffLogicBase
_class("BuffLogicChangeDefenceByDamage", BuffLogicBase)
BuffLogicChangeDefenceByDamage = BuffLogicChangeDefenceByDamage

function BuffLogicChangeDefenceByDamage:Constructor(buffInstance, logicParam)
    self._factor = logicParam.factor or 0 --增长系数，负数表示减防
end

---@param notify NotifyAttackBase
function BuffLogicChangeDefenceByDamage:DoLogic(notify)
    local damage = notify:GetDamageValue()
    local maxHP = self._entity:Attributes():CalcMaxHp()
    local rate = damage / maxHP
    local val = rate * self._factor
    self._buffLogicService:ChangeBaseDefence(
        self._entity,
        self:GetBuffSeq(),
        ModifyBaseDefenceType.DefencePercentage,
        val
    )

end

---@class BuffLogicChangeDefenceByDamageUndo:BuffLogicBase
_class("BuffLogicChangeDefenceByDamageUndo", BuffLogicBase)
BuffLogicChangeDefenceByDamageUndo = BuffLogicChangeDefenceByDamageUndo

function BuffLogicChangeDefenceByDamageUndo:Constructor(buffInstance, logicParam)
end

function BuffLogicChangeDefenceByDamageUndo:DoLogic()
    self._buffLogicService:RemoveBaseDefence(self._entity, self:GetBuffSeq(), ModifyBaseDefenceType.DefencePercentage)
end
