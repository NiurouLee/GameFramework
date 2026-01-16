--[[
    （怪）受到的总伤害为总血量的N%的x倍，设置x层layer
]]
--设置技能伤害加成
_class("BuffLogicSetLayerByDamagedRecord", BuffLogicBase)
---@class BuffLogicSetLayerByDamagedRecord:BuffLogicBase
BuffLogicSetLayerByDamagedRecord = BuffLogicSetLayerByDamagedRecord

function BuffLogicSetLayerByDamagedRecord:Constructor(buffInstance, logicParam)
    self._hpPercentPerLayer = logicParam.hpPercentPerLayer or 1 --每总计损失血量为总血量的N%（hpPercentPerLayer,小数，例0.1 = 10%）加一次
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._entity = buffInstance._entity
end

function BuffLogicSetLayerByDamagedRecord:DoLogic()
    if self._entity:HasDamageStatisticsComponent() then
        local totalDamage = self._entity:DamageStatisticsComponent():GetTotalDamage()
        if totalDamage > 0 then
            ---@type AttributesComponent
            local attrCmpt = self._entity:Attributes()
            local max_hp = attrCmpt:CalcMaxHp()
            if max_hp > 0 then
                local totalRate = totalDamage/max_hp
                local layerCount = math.floor(totalRate/self._hpPercentPerLayer)
                ---@type BuffLogicService
                local svc = self._world:GetService("BuffLogic")
                svc:SetBuffLayer(self._entity, self._layerType, layerCount)
                local buffResult = BuffResultAddLayer:New(layerCount)
                return buffResult
            end
        end
    end
end
