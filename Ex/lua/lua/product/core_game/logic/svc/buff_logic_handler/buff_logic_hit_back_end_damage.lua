--[[
    改变攻击技能
]]
_class("BuffLogicHitBackEndDamage", BuffLogicBase)
---@class BuffLogicHitBackEndDamage:BuffLogicBase
BuffLogicHitBackEndDamage = BuffLogicHitBackEndDamage

function BuffLogicHitBackEndDamage:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent
    self._addition = logicParam.addition or 0 --单位击退距离对伤害的加成
end

---@param notify NTHitBackEnd
function BuffLogicHitBackEndDamage:DoLogic(notify)
    local attacker = notify:GetNotifyEntity()
    local defenderId = notify:GetDefenderId()
    if defenderId == nil or defenderId <= 0 then
        return
    end
    local targetEntity = self._world:GetEntityByID(defenderId)
    local curHp = targetEntity:Attributes():GetCurrentHP()
    if curHp == nil then
        return
    end

    -- 获取击退距离对伤害加成
    local addPercent = self:GetTotalAdditionByHitBackDistance(notify)

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), attacker, targetEntity, {
        percent = self._percent,
        addPercent = addPercent,
        formulaID = 9
    })

    local buffResult = BuffResultHitBackEndDamage:New(defenderId,damageInfo)
    return buffResult
end

---根据击退距离更新targetDamage
---@param data NTHitBackEnd
---@param targetDamage number
function BuffLogicHitBackEndDamage:GetTotalAdditionByHitBackDistance(data)
    local posStart = data:GetPosStart()
    local posEnd = data:GetPosEnd()
    if posStart and posEnd then
        local dis = 0
        local v = posEnd - posStart
        if v.x == 0 then --纵向击退
            dis = v.y
        else --横向或斜45°击退
            dis = v.x
        end
        if dis < 0 then
            dis = -dis
        end
        return self._addition * dis
    end
    return 0
end
