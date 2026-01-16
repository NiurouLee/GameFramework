require("sp_base_inst")
---取消范围内目标MaterialAnim
_class("SkillPreviewStopAllMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewStopAllMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewStopAllMaterialAnimInstruction = SkillPreviewStopAllMaterialAnimInstruction

function SkillPreviewStopAllMaterialAnimInstruction:Constructor(params)
	self._exceptCaster = params["ExceptCaster"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewStopAllMaterialAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	local world = previewContext:GetWorld()
	local flashEnemyEntities = world:GetGroup(world.BW_WEMatchers.MonsterID):GetEntities()
	if world:MatchType() == MatchType.MT_BlackFist then
		flashEnemyEntities= world:GetGroup(world.BW_WEMatchers.Pet):GetEntities()
	end
	for _, v in ipairs(flashEnemyEntities) do
		--if v:MaterialAnimationComponent():IsPlayingSelect() or v:MaterialAnimationComponent():IsPlayingAlpha() then
			if self._exceptCaster and self._exceptCaster == "true" then
				if v:GetID() ~= casterEntity:GetID() then
					v:StopMaterialAnimLayer(MaterialAnimLayer.SkillPreview)
				end
			else
				v:StopMaterialAnimLayer(MaterialAnimLayer.SkillPreview)
			end
		--end
	end
	local targetIDList = previewContext:GetTargetEntityIDList()
	targetIDList = table.unique(targetIDList)
	for _, id in pairs(targetIDList) do
		local entity = world:GetEntityByID(id)
		if entity then
			if entity:HasTeam() then
				entity = entity:GetTeamLeaderPetEntity()
			end
			entity:StopMaterialAnimLayer(MaterialAnimLayer.SkillPreview)
		end
	end
end