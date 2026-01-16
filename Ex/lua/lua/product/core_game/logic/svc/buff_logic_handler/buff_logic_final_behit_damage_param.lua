--[[
    减少伤害
]]
_class("BuffLogicSetFinalBehitDamageParam", BuffLogicBase)
BuffLogicSetFinalBehitDamageParam = BuffLogicSetFinalBehitDamageParam

function BuffLogicSetFinalBehitDamageParam:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent
end

function BuffLogicSetFinalBehitDamageParam:DoLogic()
    local e = self._buffInstance:Entity()

    ---@type AttributesComponent
    local cpt = e:Attributes()
    --设置减伤属性
    cpt:Modify("FinalBehitDamageParam", -self._percent / 100)
end
