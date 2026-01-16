--[[
    根据目标身上的buff的Layer 增加挂载者技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillFinalByTargetBuffLayer", BuffLogicBase)
---@class BuffLogicChangeSkillFinalByTargetBuffLayer:BuffLogicBase
BuffLogicChangeSkillFinalByTargetBuffLayer = BuffLogicChangeSkillFinalByTargetBuffLayer

function BuffLogicChangeSkillFinalByTargetBuffLayer:Constructor(buffInstance, logicParam)
	self._buffInstance._effectList = logicParam.effectList
	self._buffID = logicParam.buffID
	self._minValue = logicParam.minValue or 0
	self._oneLayerValue = logicParam.oneLayerValue or 0
end

function BuffLogicChangeSkillFinalByTargetBuffLayer:DoLogic(notify)
	--挂载者 增伤的目标
	local casterEntity = self._buffInstance:Entity()
	--攻击目标 检测的目标
	local defenderEntity = notify:GetDefenderEntity()
	if not defenderEntity then
		return
	end

	---@type BuffComponent
	local buffComponent = defenderEntity:BuffComponent()
	if not buffComponent then
		return
	end

	---@type BuffInstance
	local buffInstance = buffComponent:GetBuffById(self._buffID)
	if not buffInstance then
		return
	end

	local layer = buffInstance:GetLayerCount()
	local changeValue = 0
	changeValue = self._minValue + self._oneLayerValue * layer
	for _, paramType in ipairs(self._buffInstance._effectList) do
		self._buffLogicService:ChangeSkillFinalParam(casterEntity, self:GetBuffSeq(), paramType, changeValue)
	end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillFinalByTargetBuffLayer", BuffLogicBase)
---@class BuffLogicRemoveSkillFinalByTargetBuffLayer:BuffLogicBase
BuffLogicRemoveSkillFinalByTargetBuffLayer = BuffLogicRemoveSkillFinalByTargetBuffLayer

function BuffLogicRemoveSkillFinalByTargetBuffLayer:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillFinalByTargetBuffLayer:DoLogic()
	--挂载者 增伤的目标
	local casterEntity = self._buffInstance:Entity()
	if not casterEntity then
		return
	end
	for _, paramType in pairs(self._buffInstance._effectList) do
		self._buffLogicService:RemoveSkillFinalParam(casterEntity, self:GetBuffSeq(), paramType)
	end
	return true
end
