require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewPlayAllMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayAllMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayAllMaterialAnimInstruction = SkillPreviewPlayAllMaterialAnimInstruction

function SkillPreviewPlayAllMaterialAnimInstruction:Constructor(params)
	self._anim= params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayAllMaterialAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
	local world = previewContext:GetWorld()
	local flashEnemyEntities = world:GetGroup(world.BW_WEMatchers.MonsterID):GetEntities()
	if world:MatchType() == MatchType.MT_BlackFist then
		if casterEntity:HasPet() then
			---@type Entity
			local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
			---@type Entity
			local enemyEntity = teamEntity:Team():GetEnemyTeamEntity()
			flashEnemyEntities={enemyEntity:GetTeamLeaderPetEntity()}
		end
	end
	for _, v in ipairs(flashEnemyEntities) do
		local entity = v
		if entity then
			if self._anim == "Flash" then
				entity:NewEnableFlash()
			elseif self._anim == "Transparent" then
				entity:NewEnableTransparent()
			elseif self._anim == "Ghost" then
				entity:NewEnableGhost()
			elseif self._anim == "FlashAlpha" then
				entity:NewEnableFlashAlpha()
			end
		end
	end
end