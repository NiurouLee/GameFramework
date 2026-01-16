require("base_service")

_class("MonsterMoveServiceRender", BaseService)
---@class MonsterMoveServiceRender:BaseService
MonsterMoveServiceRender = MonsterMoveServiceRender

function MonsterMoveServiceRender:Constructor(world)
	self.world = world
end

function MonsterMoveServiceRender:_DoRenderTrapBeforeMonster(TT)
	---@type PlayAIService
	local playAISvc = self._world:GetService("PlayAI")
	if playAISvc == nil then
		return
	end


	playAISvc:DoCommonRountine(TT)
end

function MonsterMoveServiceRender:_DoRenderPlayMonsterAction(TT)
	---@type PlayAIService
	local playAISvc = self._world:GetService("PlayAI")
	if playAISvc == nil then
		return
	end

	---再播放移动和普攻行为
	playAISvc:DoMainAIRountine(TT)
end

function MonsterMoveServiceRender:_DoRenderTrapAfterMonster(TT)
	---@type PlayAIService
	local playAISvc = self._world:GetService("PlayAI")
	if playAISvc == nil then
		return
	end

	playAISvc:DoCommonRountine(TT)
end