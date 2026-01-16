--[[

]]
---@class SkillEffectCalcResetSingleColorGridElement: Object
_class("SkillEffectCalcResetSingleColorGridElement", Object)
SkillEffectCalcResetSingleColorGridElement = SkillEffectCalcResetSingleColorGridElement

function SkillEffectCalcResetSingleColorGridElement:Constructor(world)
	---@type MainWorld
	self._world = world
	---@type SkillEffectCalcService
	self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcResetSingleColorGridElement:DoSkillEffectCalculator(skillEffectCalcParam)
	---@type SkillEffectParamResetSingleColorGridElement
	local param = skillEffectCalcParam.skillEffectParam
	---@type PieceType[]
	local newColorList= param:GetTargetGridTypeList()
	local scopeList = skillEffectCalcParam.skillRange
	---@type BoardServiceLogic
	local boardService = self._world:GetService("BoardLogic")
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
	---@type SkillLogicService
	local skillLogicService = self._world:GetService("SkillLogic")
	---取出选择的颜色,新生成的格子不包含选择的颜色
	local excludeColor = boardService:GetPieceType(scopeList[1])
	for k, v in ipairs(newColorList) do
		if v == excludeColor then
			table.remove(newColorList,k)
			table.sort(newColorList)
			break
		end
	end
	---@type SkillEffectResult_ResetGridData[]
	local newGridList = {}
	for _, pos in ipairs(scopeList) do
		local index=  randomSvc:LogicRand(1,#newColorList)
		---@type PieceType
		local newColor = newColorList[index]
		local newGridData = SkillEffectResult_ResetGridData:New(pos.x,pos.y,newColor)
		table.insert(newGridList,newGridData)
	end
	local flushTrapList = self._skillEffectService:GetFlushTrap(scopeList,param:GetExcludeTrapIDList())
	local trapIDList = {}
	for _,v in ipairs(flushTrapList) do 
		trapIDList[#trapIDList + 1] = v:GetID()
	end

	return SkillEffectResultResetSingleColorGridElement:New(newGridList, trapIDList)
end
