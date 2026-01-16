--[[
    单位灰色生命池状态维护

    EnableGreyHP 表示启用灰色生命池积累
    SuspendGreyHP 表示停止灰色生命池的积累，但保留当前值
    DisableGreyHP 表示停止灰色生命池的积累，且清除之前累积的数值
]]
require("buff_logic_base")

_class("BuffLogicEnableGreyHPCharge", BuffLogicBase)
---@class BuffLogicEnableGreyHPCharge : BuffLogicBase
BuffLogicEnableGreyHPCharge = BuffLogicEnableGreyHPCharge

---
function BuffLogicEnableGreyHPCharge:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    cBuff:SetGreyHPEnable(true)
end

_class("BuffLogicDisableGreyHPCharge", BuffLogicBase)
---@class BuffLogicDisableGreyHPCharge : BuffLogicBase
BuffLogicDisableGreyHPCharge = BuffLogicDisableGreyHPCharge

---
function BuffLogicDisableGreyHPCharge:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    cBuff:SetGreyHPEnable(false)
    cBuff:ClearGreyHPValue()

    self._buffInstance.__ChargeGreyHPRunCount = nil
    return {}
end

_class("BuffLogicSuspendGreyHPCharge", BuffLogicBase)
---@class BuffLogicSuspendGreyHPCharge : BuffLogicBase
BuffLogicSuspendGreyHPCharge = BuffLogicSuspendGreyHPCharge

---
function BuffLogicSuspendGreyHPCharge:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    cBuff:SetGreyHPEnable(false)
end

_class("BuffLogicChargeGreyHP", BuffLogicBase)
---@class BuffLogicChargeGreyHP : BuffLogicBase
BuffLogicChargeGreyHP = BuffLogicChargeGreyHP

function BuffLogicChargeGreyHP:Constructor(_, logicParam)
    self._chargePercent = logicParam.percent

    assert(type(self._chargePercent) == "number")
end

local buffLogicChargeGreyHPTag = "BuffLogicChargeGreyHP: "
---
---@param notify NotifyAttackBase | NTMonsterHPCChange
function BuffLogicChargeGreyHP:DoLogic(notify)
    local damageVal = 0
    if notify:GetNotifyType() == NotifyType.MonsterHPCChange then
        damageVal = notify:GetChangeHP() * (-1) --[[受到伤害时这里是负数]]
    end

    if damageVal <= 0 then
        Log.debug(buffLogicChargeGreyHPTag, "notify has no damageVal: ", tostring(notify:GetNotifyType()))
        damageVal = 0
    end

    local val = damageVal * self._chargePercent

    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    local currentVal = self._buffLogicService:ChangeGreyHP(e, val)

    local result = BuffResultChargeGreyHP:New(e:GetID(), currentVal, notify:GetNotifyType(), notify:GetNotifyIndex(), val, notify:GetChangeHP())

    return result
end
