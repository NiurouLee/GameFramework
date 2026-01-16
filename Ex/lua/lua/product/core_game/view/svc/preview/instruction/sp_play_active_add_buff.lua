require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewPlayActiveSkillAddBuffInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayActiveSkillAddBuffInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayActiveSkillAddBuffInstruction = SkillPreviewPlayActiveSkillAddBuffInstruction

function SkillPreviewPlayActiveSkillAddBuffInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayActiveSkillAddBuffInstruction:DoInstruction(TT, casterEntity, previewContext)
	local world = previewContext:GetWorld()
	local targetIDList = previewContext:GetTargetEntityIDList()
	targetIDList = table.unique(targetIDList)
	local eids= {}
	for _, id in pairs(targetIDList) do
		local e = world:GetEntityByID(id)
		---@type PetPstIDComponent
		local cPstId = e:PetPstID()
		local pstId = cPstId:GetPstID()
		table.insert(eids, pstId)
	end
	--触发UI表现
	GameGlobal.EventDispatcher():Dispatch(GameEventType.PetShowPreviewArrow, eids)
end
