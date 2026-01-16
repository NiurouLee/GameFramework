require("sp_base_inst")
_class("SkillPreviewPlayDeletePickUpEffectInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeletePickUpEffectInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeletePickUpEffectInstruction = SkillPreviewPlayDeletePickUpEffectInstruction

function SkillPreviewPlayDeletePickUpEffectInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeletePickUpEffectInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = previewContext:GetWorld():GetService("PreviewActiveSkill")
    local world = casterEntity:GetOwnerWorld()
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    if not previewPickUpComponent then
        return
    end

    local entityIDs = previewPickUpComponent:GetPickUpEffectEntityIDArray()
    local world = casterEntity:GetOwnerWorld()
    for _, id in ipairs(entityIDs) do
        local e = world:GetEntityByID(id)
        if e then
            world:DestroyEntity(e)
        end
    end
end
