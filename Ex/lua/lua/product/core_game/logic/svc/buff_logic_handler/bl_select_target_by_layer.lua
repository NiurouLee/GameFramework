--[[
    吸收被攻击目标的攻击力上限是施法者的攻击力
]]
require('buff_logic_base')
_class("BuffLogicSelectTargetByLayer", BuffLogicBase)
---@class BuffLogicSelectTargetByLayer:BuffLogicBase
BuffLogicSelectTargetByLayer = BuffLogicSelectTargetByLayer

function BuffLogicSelectTargetByLayer:Constructor(buffInstance, logicParam)
	self._layerType = logicParam.layerType
	self._saveDataName = logicParam.saveDataName
end

---@param notify NotifyAttackBase
function BuffLogicSelectTargetByLayer:DoLogic(notify)
	local resultIDs={}
	if notify:GetScopeResult() ~= nil then
		---@type SkillScopeResult
		local scopeResult =notify:GetScopeResult()
		local tmp= scopeResult:GetTargetIDs()
		local targetIDs ={}
		for i = 1, #tmp do
			targetIDs[i]=tmp[i]
		end
		    
		--获取层数
		---@type BuffLogicService
		local svc = self._world:GetService("BuffLogic")
		local count = svc:GetBuffLayer(self._entity, self._layerType)

		---@type RandomServiceLogic
		local randomSvc = self._world:GetService("RandomLogic")
		while count >0 and targetIDs and #targetIDs>0 do
			local index = randomSvc:LogicRand(1,#targetIDs)
			local targetID = targetIDs[index]
			table.insert(resultIDs,targetID)
			table.remove(targetIDs,index)
			count =count -1
		end
	end
	self._buffComponent:SetBuffValue(self._saveDataName,resultIDs)
	return #resultIDs ~= 0
end

_class("BuffLogicRemoveSelectTargetByLayer", BuffLogicBase)
---@class BuffLogicRemoveSelectTargetByLayer:BuffLogicBase
BuffLogicRemoveSelectTargetByLayer = BuffLogicRemoveSelectTargetByLayer

function BuffLogicRemoveSelectTargetByLayer:Constructor(buffInstance, logicParam)
	self._saveDataName = logicParam.saveDataName
end

---@param notify NotifyAttackBase
function BuffLogicRemoveSelectTargetByLayer:DoLogic(notify)
	self._buffComponent:SetBuffValue(self._saveDataName,nil)
end