require("sp_base_inst")
--清理预览阶段临时创建的特效 菲雅
_class("SkillPreviewPlayDeletePreviewEffectInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeletePreviewEffectInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeletePreviewEffectInstruction = SkillPreviewPlayDeletePreviewEffectInstruction

function SkillPreviewPlayDeletePreviewEffectInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeletePreviewEffectInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type PreviewStageEffectRecord
    local previewStrageEffectRecordComponent = casterEntity:PreviewStageEffectRecord()
    if previewStrageEffectRecordComponent then
        local entityIDs = previewStrageEffectRecordComponent:GetPreviewStageEffectEntityIDList()
        local world = casterEntity:GetOwnerWorld()
        for _, id in ipairs(entityIDs) do
            local e = world:GetEntityByID(id)
            if e then
                world:DestroyEntity(e)
            end
        end
        previewStrageEffectRecordComponent:ClearPreviewStageEffectEntityIDList()
    end
end
