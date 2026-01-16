_class("BuffViewTransferLayerShieldToTarget", BuffViewBase)
---@class BuffViewTransferLayerShieldToTarget:BuffViewBase
BuffViewTransferLayerShieldToTarget = BuffViewTransferLayerShieldToTarget

function BuffViewTransferLayerShieldToTarget:PlayView(TT)
	---@type BuffResultTransferCasterLayerShieldToTarget
	self._buffResult = self._buffResult
	local casterEntity = self._world:GetEntityByID(self._buffResult:GetCasterID())
	local targetEntity = self._world:GetEntityByID(self._buffResult:GetTargetID())
	local targetNewLayer = self._buffResult:GetTargetNewLayer()
	local layerName=self._viewInstance:ParseBuffLayerName(BuffEffectType.LayerShield)
	---施法者清零
	self._world:GetService("PlayBuff"):PlayBuffView(TT, NTNotifyLayerChange:New(layerName))
	casterEntity:BuffView():SetBuffValue(layerName, 0)
	self._entity:PlayMaterialAnim("common_shieldactive")
	self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
	---目标增加
	targetEntity:BuffView():SetBuffValue(layerName, targetNewLayer)
	self._entity:PlayMaterialAnim("common_shield")
	self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end