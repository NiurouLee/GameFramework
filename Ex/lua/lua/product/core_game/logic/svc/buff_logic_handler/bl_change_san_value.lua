--[[
    修改San值
]]

---@class BuffChangeSanValueType
local BuffChangeSanValueType = {
	Value = 1,--数值
    MaxPercent = 2,--上限的比例
    CurPercent = 3, --当前值的比例
    LostPercent = 4 --已损失的比例
}
_enum("BuffChangeSanValueType", BuffChangeSanValueType)

_class("BuffLogicChangeSanValue", BuffLogicBase)
---@class BuffLogicChangeSanValue:BuffLogicBase
BuffLogicChangeSanValue = BuffLogicChangeSanValue

function BuffLogicChangeSanValue:Constructor(buffInstance, logicParam)
	self._modifyValue = logicParam.modifyValue or 0
	self._modifyType = logicParam.modifyType or 1
end
function BuffLogicChangeSanValue:DoLogic(notify)
	---@type FeatureServiceLogic
	local lsvcFeature = self._world:GetService("FeatureLogic")
	local modifyValue = self._modifyValue
	if self._modifyType == BuffChangeSanValueType.Value then
		modifyValue = self._modifyValue
	elseif self._modifyType == BuffChangeSanValueType.MaxPercent then
		local sanMax = lsvcFeature:GetSanMaxValue()
		local oriModifyVal = self._modifyValue * sanMax
		local absModifyVal = math.abs(oriModifyVal)
		modifyValue = math.ceil(absModifyVal)
		if oriModifyVal < 0 then
			modifyValue = modifyValue * -1
		end
	elseif self._modifyType == BuffChangeSanValueType.CurPercent then
		local curSan = lsvcFeature:GetSanValue()
		local oriModifyVal = self._modifyValue * curSan
		local absModifyVal = math.abs(oriModifyVal)
		modifyValue = math.ceil(absModifyVal)
		if oriModifyVal < 0 then
			modifyValue = modifyValue * -1
		end
	elseif self._modifyType == BuffChangeSanValueType.LostPercent then
		local sanMax = lsvcFeature:GetSanMaxValue()
		local curSan = lsvcFeature:GetSanValue()
		local lostSan = sanMax - curSan
		local oriModifyVal = self._modifyValue * lostSan
		local absModifyVal = math.abs(oriModifyVal)
		modifyValue = math.ceil(absModifyVal)
		if oriModifyVal < 0 then
			modifyValue = modifyValue * -1
		end
	end
	local curSan,oldSan,realModifyValue,debtVal,modifyTimes = lsvcFeature:ModifySanValue(modifyValue)
	local nt = NTSanValueChange:New(curSan, oldSan,debtVal,modifyTimes)
	self._world:GetService("Trigger"):Notify(nt)
	local result = BuffResultChangeSanValue:New(curSan,oldSan,realModifyValue,debtVal,modifyTimes)
	return result
end
