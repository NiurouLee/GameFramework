_class("BuffLogicCostHPBySanChangeDebt", BuffLogicBase)
---@class BuffLogicCostHPBySanChangeDebt : BuffLogicBase
BuffLogicCostHPBySanChangeDebt = BuffLogicCostHPBySanChangeDebt

function BuffLogicCostHPBySanChangeDebt:Constructor(buffInstance, logicParam)
    self._damagePercent = logicParam.damagePercent
end

---@param notify NTSanValueChange
function BuffLogicCostHPBySanChangeDebt:DoLogic(notify)
    if not NTSanValueChange:IsInstanceOfType(notify) then
        return
    end
    if self._entity:HasDeadMark() or self._entity:HasPetDeadMark() then
        return
    end
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local maxHp = attrCmpt:CalcMaxHp()
    if maxHp <= 0 then
        return
    end
    local debtVal = notify:GetDebtValue()
    if debtVal <= 0 then
        return
    end
    local costPercent = self._damagePercent * debtVal
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), e, e, {
        percent = costPercent,
        formulaID = 10--最大生命值百分比伤害
    })

    return BuffResultCostHPBySanChangeDebt:New(damageInfo, notify)
end
