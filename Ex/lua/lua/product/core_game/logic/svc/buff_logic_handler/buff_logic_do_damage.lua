--[[
    触发后对目标造成伤害，走伤害公式
]]
_class("BuffLogicDoDamage", BuffLogicBase)
BuffLogicDoDamage = BuffLogicDoDamage

function BuffLogicDoDamage:Constructor(buffInstance, logicParam)
    self._damageParam = logicParam
end

function BuffLogicDoDamage:DoLogic(notify)
    local caster = self._entity
    local defender = self._entity

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), caster, defender, self._damageParam)

    local buffResult = BuffResultDamage:New(damageInfo)

    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        local walkPos = notify:GetWalkPos()
        buffResult:SetWalkPos(walkPos)
    end

    return buffResult
end
