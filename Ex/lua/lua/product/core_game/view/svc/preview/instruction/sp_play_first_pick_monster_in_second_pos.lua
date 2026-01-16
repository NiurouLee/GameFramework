require("sp_base_inst")
_class("SkillPreviewPlayFirstPickMonsterInSecondPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayFirstPickMonsterInSecondPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayFirstPickMonsterInSecondPosInstruction = SkillPreviewPlayFirstPickMonsterInSecondPosInstruction

function SkillPreviewPlayFirstPickMonsterInSecondPosInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayFirstPickMonsterInSecondPosInstruction:DoInstruction(TT, casterEntity, previewContext)
	local world = casterEntity:GetOwnerWorld()
	---@type RenderEntityService
	local entitySvc = world:GetService("RenderEntity")
	----@type PreviewPickUpComponent
	local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
	local firstPickUpPos =previewPickUpComponent:GetFirstValidPickUpGridPos()
	local lastPickUpPos = previewPickUpComponent:GetLastPickUpGridPos()
	----@type UtilDataServiceShare
	local utilDataServiceShare = world:GetService("UtilData")
	if firstPickUpPos and lastPickUpPos and not (firstPickUpPos.x == lastPickUpPos.x and firstPickUpPos.y == lastPickUpPos.y) then
		local monsterEntity = utilDataServiceShare:GetMonsterAtPos(firstPickUpPos)
		if monsterEntity then
			entitySvc:CreateGhost(previewContext:GetPickUpPos(), monsterEntity,"AtkUltPreview")
		end
	end
end
