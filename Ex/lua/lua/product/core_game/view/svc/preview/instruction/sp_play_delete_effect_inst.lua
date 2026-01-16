require("sp_base_inst")
_class("SkillPreviewPlayDeleteEffectInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeleteEffectInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeleteEffectInstruction = SkillPreviewPlayDeleteEffectInstruction

function SkillPreviewPlayDeleteEffectInstruction:Constructor(params)
	self._effectID = tonumber(params["EffectID"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeleteEffectInstruction:DoInstruction(TT,casterEntity,previewContext)
	local world =previewContext:GetWorld()
	---@type EffectHolderComponent
	local holderCmp = casterEntity:EffectHolder()
	if not holderCmp then
		return
	end
	local effectID = self._effectID
	local idDic = holderCmp:GetEffectIDEntityDic()
	local entityList = idDic[effectID]
	if entityList then
		for _, entityID in pairs(entityList) do
			if entityID then
				local entity = world:GetEntityByID(entityID)
				if entity then
					world:DestroyEntity(entity)
				end
			end

		end
		idDic[effectID]= nil
	end
end

