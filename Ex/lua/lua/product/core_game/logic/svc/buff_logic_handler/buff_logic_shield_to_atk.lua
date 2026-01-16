require("buff_type")
require("buff_logic_base")
_class("BuffLogicShieldToAtk", BuffLogicBase)
---@class BuffLogicShieldToAtk:BuffLogicBase
BuffLogicShieldToAtk = BuffLogicShieldToAtk

function BuffLogicShieldToAtk:Constructor(buffInstance, logicParam)
    self._atkMul = logicParam.atkMul or 0
end

--buff伤害结算
function BuffLogicShieldToAtk:DoLogic()
    local e = self._entity

    local recoverEntity = e
    if e:PetPstID() then
        recoverEntity = e:Pet():GetOwnerTeamEntity()
    end

    ---@type BuffComponent
    local buffCmpt = recoverEntity:BuffComponent()
    if buffCmpt == nil then
        return
    end

    local curShieldValue = buffCmpt:GetBuffValue("HPShield") or 0

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    local buffSeqID = self:GetBuffSeq()

    local atkAdded = self._atkMul * curShieldValue

    buffLogicService:RemoveBaseAttack(self._entity, buffSeqID, ModifyBaseAttackType.AttackPercentage)
    buffLogicService:ChangeBaseAttack(e, buffSeqID, ModifyBaseAttackType.AttackPercentage, atkAdded)

    local result = BuffResultShieldToAtk:New(atkAdded)
    return result
end

_class("BuffLogicUndoShieldToAtk", BuffLogicBase)
---@class BuffLogicUndoShieldToAtk:BuffLogicBase
BuffLogicUndoShieldToAtk = BuffLogicUndoShieldToAtk

function BuffLogicUndoShieldToAtk:DoLogic()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local buffSeqID = self:GetBuffSeq()

    buffLogicService:RemoveBaseAttack(self._entity, buffSeqID, ModifyBaseAttackType.AttackPercentage)
end
