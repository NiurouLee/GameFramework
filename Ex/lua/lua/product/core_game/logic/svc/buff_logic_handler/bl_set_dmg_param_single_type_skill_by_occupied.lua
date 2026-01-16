--[[
    根据怪物体型，修改其收到单体技能攻击的伤害系数 (20221108 改为累加的形式)
]]
require "buff_logic_base"
_class("BuffLogicSetDmgParamSingleTypeSkillByOccupied", BuffLogicBase)
---@class BuffLogicSetDmgParamSingleTypeSkillByOccupied:BuffLogicBase
BuffLogicSetDmgParamSingleTypeSkillByOccupied = BuffLogicSetDmgParamSingleTypeSkillByOccupied

function BuffLogicSetDmgParamSingleTypeSkillByOccupied:Constructor(buffInstance, logicParam)
	self._gridNumToParamDic = logicParam.gridNumToParamDic --例：{[1]=1,[4]=1.3}
	self._defaultParam = logicParam.defaultParam --gridNumToParamDic不配或没有对应值，就用这个值
end

function BuffLogicSetDmgParamSingleTypeSkillByOccupied:DoLogic()
	local dmgParam = self._defaultParam
	if self._gridNumToParamDic then
		local holdEntity = self:GetEntity()
		local gridNum = holdEntity:BodyArea():GetAreaCount()
		if self._gridNumToParamDic[gridNum] then
			dmgParam = self._gridNumToParamDic[gridNum]
		end
	end
	if dmgParam then
		self._buffLogicService:ChangeDmgParamSingleTypeSkill(
			self:GetEntity(),
			self:GetBuffSeq(),
			dmgParam
		)
	end
end

function BuffLogicSetDmgParamSingleTypeSkillByOccupied:DoOverlap(logicParam)
	return self:DoLogic()
end

_class("BuffLogicResetDmgParamSingleTypeSkill", BuffLogicBase)
---@class BuffLogicResetDmgParamSingleTypeSkill:BuffLogicBase
BuffLogicResetDmgParamSingleTypeSkill = BuffLogicResetDmgParamSingleTypeSkill

function BuffLogicResetDmgParamSingleTypeSkill:Constructor(buffInstance, logicParam)

end

function BuffLogicResetDmgParamSingleTypeSkill:DoLogic()
	self._buffLogicService:RemoveDmgParamSingleTypeSkill(
		self:GetEntity(),
		self:GetBuffSeq()
	)
end