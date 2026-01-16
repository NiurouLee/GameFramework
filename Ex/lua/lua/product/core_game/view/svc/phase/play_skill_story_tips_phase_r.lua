require "play_skill_phase_base_r"
--@class PlaySkillStoryTipsPhase: Object
_class("PlaySkillStoryTipsPhase", PlaySkillPhaseBase)
PlaySkillStoryTipsPhase = PlaySkillStoryTipsPhase

function PlaySkillStoryTipsPhase:PlayFlight(TT, casterEntity, phaseParam)
	---@type SkillPhaseStoryTipsParam
	local param = phaseParam
	local prob = param:GetProb()
	local tipsList = param:GetTipsList()
	local rand = Mathf.Random(1,100)
	if rand<= prob then
		local index = Mathf.Random(1,#tipsList)
		local monsterTemplateID = casterEntity:MonsterID():GetMonsterID()
		---@type InnerStoryService
		local innerStoryService = self._world:GetService("InnerStory")
		innerStoryService:DoMonsterStoryTips(monsterTemplateID,casterEntity:GetID(), tonumber(tipsList[index]))
	end
end
