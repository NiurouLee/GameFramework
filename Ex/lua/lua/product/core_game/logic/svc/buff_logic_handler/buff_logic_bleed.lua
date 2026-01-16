--[[
    流血buff，已损失血量
]]
_class("BuffLogicAddBleed", BuffLogicBase)
BuffLogicAddBleed = BuffLogicAddBleed

function BuffLogicAddBleed:Constructor(buffInstance, logicParam)
    self._damagePercent = logicParam.damagePercent
end

function BuffLogicAddBleed:DoLogic()
    local e = self._buffInstance:Entity()
    if not e:Attributes() then
        return
    end

    --每回合只有一个buff逻辑会执行
    local turn = e:BuffComponent():GetBuffValue("BleedTurn")
    local round = self._world:BattleStat():GetLevelTotalRoundCount()
    if turn == round then
        return
    end

    e:BuffComponent():SetBuffValue("BleedTurn", round)

    local layer = self._buffInstance:GetLayerCount()
    local maxHP = e:Attributes():CalcMaxHp()
    local curHp = e:Attributes():GetCurrentHP()

    --MSG62022 层数为0时应认为DOT无效，而不是造成1点伤害
    if layer == 0 then
        return
    end

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), e, e, {
        percent = self._damagePercent,
        layer = layer,
        formulaID = 13
    })
    
    if damageInfo:GetDamageType() == DamageType.Real then
        damageInfo:SetDamageType(DamageType.Bleed)
    end

    local buffResult = BuffResultDamage:New(damageInfo)
    
    return buffResult
end
