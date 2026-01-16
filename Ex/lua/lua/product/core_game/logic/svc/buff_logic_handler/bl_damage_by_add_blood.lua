--[[
    根据通知中的加血量对Buff持有者造成真实伤害
    buff执行条件为：8|386,1
    buff通知：PlayerHPChange = 8, --队伍或星灵的血量变化
    buff触发条件：BloodChange =386, ---判断血量变化 1：血量增加 2：血量减少
]]

---@class BuffLogicDamageByAddBlood:BuffLogicBase
_class("BuffLogicDamageByAddBlood", BuffLogicBase)
BuffLogicDamageByAddBlood = BuffLogicDamageByAddBlood

function BuffLogicDamageByAddBlood:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent or 1
    self._formulaID = logicParam.formulaID or 155
    self._useHPSpilled = logicParam.useHPSpilled or false
end

function BuffLogicDamageByAddBlood:DoLogic(notify)
    if not NTPlayerHPChange:IsInstanceOfType(notify) then
        return
    end

    ---@type Entity
    local attacker = notify:GetNotifyEntity()
    --如果是星灵，则查找队伍
    if attacker:HasPetPstID() then
        attacker = attacker:Pet():GetOwnerTeamEntity()
    end

    ---@type Entity
    local defender = self._buffInstance:Entity()

    local changeHP = notify:GetChangeHP()
    if not changeHP or changeHP <= 0 then
        return
    end

    ---使用实际加血量
    if not self._useHPSpilled then
        changeHP = changeHP - notify:GetHPSpilled()
    end

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    local damageParam = { percent = self._percent, formulaID = self._formulaID, changeHP = changeHP }
    local damageInfo = buffSvc:DoBuffDamage(self._buffInstance:BuffID(), attacker, defender, damageParam)

    local buffResult = BuffResultDamage:New(damageInfo)

    return buffResult
end
