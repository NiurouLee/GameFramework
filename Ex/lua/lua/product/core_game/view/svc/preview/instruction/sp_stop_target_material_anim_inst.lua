require("sp_base_inst")
---取消范围内目标MaterialAnim
_class("SkillPreviewStopTargetMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewStopTargetMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewStopTargetMaterialAnimInstruction = SkillPreviewStopTargetMaterialAnimInstruction

function SkillPreviewStopTargetMaterialAnimInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewStopTargetMaterialAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    local targetIDList = previewContext:GetTargetEntityIDList()
    targetIDList = table.unique(targetIDList)
    for _, id in pairs(targetIDList) do
        local entity = world:GetEntityByID(id)
        if entity then
            if entity:HasTeam() then
                entity = entity:GetTeamLeaderPetEntity()
            end
            ---@type MaterialAnimationComponent
            local comp = entity:MaterialAnimationComponent()
            if comp then
                comp:StopLayer(MaterialAnimLayer.SkillPreview)
            end
        end
    end
end
