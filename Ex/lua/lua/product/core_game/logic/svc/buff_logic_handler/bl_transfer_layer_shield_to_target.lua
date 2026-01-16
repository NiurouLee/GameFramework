--[[
    转移施法者身上的护盾到目标身上
]]

_class("BuffLogicTransferLayerShieldToTarget", BuffLogicBase)
BuffLogicTransferLayerShieldToTarget = BuffLogicTransferLayerShieldToTarget

function BuffLogicTransferLayerShieldToTarget:Constructor(buffInstance, logicParam)

end

function BuffLogicTransferLayerShieldToTarget:DoLogic(notify)
	if not notify.GetDefenderEntity then
		return
	end
	local targetEntity =notify:GetDefenderEntity()
	local e = self._buffInstance:Entity()
	---@type BuffLogicService
	local buffLogic = self._world:GetService("BuffLogic")
	local myLayerCount = buffLogic:GetBuffLayer(e,BuffEffectType.LayerShield)
	buffLogic:AddBuffLayer(targetEntity,BuffEffectType.LayerShield,myLayerCount)
	local newLayer = buffLogic:GetBuffLayer(targetEntity,BuffEffectType.LayerShield)

	----@type BuffResultTransferCasterLayerShieldToTarget
	local buffResult =BuffResultTransferCasterLayerShieldToTarget:New(e:GetID(),targetEntity:GetID(),newLayer)


	return buffResult
end
