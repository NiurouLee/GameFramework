--[[
    修改层数能够提供的加成比例
    默认每层提高1
]]
_class("BuffLogicChangeLayerMul", BuffLogicBase)
---@class BuffLogicChangeLayerMul:BuffLogicBase
BuffLogicChangeLayerMul = BuffLogicChangeLayerMul

function BuffLogicChangeLayerMul:Constructor(buffInstance, logicParam)
	self._layerMul = logicParam.layerMul or 1
	self._buffInstance._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
end

function BuffLogicChangeLayerMul:DoLogic()
	---@type BuffLogicService
	local buffLogicSvc = self._world:GetService("BuffLogic")
	buffLogicSvc:SetBuffLayerMul(self._entity,self._buffInstance._layerType,self._layerMul)
end

_class("BuffLogicRemoveChangeLayerMul", BuffLogicBase)
---@class BuffLogicRemoveChangeLayerMul:BuffLogicBase
BuffLogicRemoveChangeLayerMul = BuffLogicRemoveChangeLayerMul

function BuffLogicRemoveChangeLayerMul:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveChangeLayerMul:DoLogic()
	---@type BuffLogicService
	local buffLogicSvc = self._world:GetService("BuffLogic")
	buffLogicSvc:SetBuffLayerMul(self._entity,self._buffInstance._layerType,1)
end
