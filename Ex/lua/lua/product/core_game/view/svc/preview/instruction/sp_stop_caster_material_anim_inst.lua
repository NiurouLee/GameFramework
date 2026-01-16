require("sp_base_inst")
---取消范围内目标MaterialAnim
_class("SkillPreviewStopCasterMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewStopCasterMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewStopCasterMaterialAnimInstruction = SkillPreviewStopCasterMaterialAnimInstruction

function SkillPreviewStopCasterMaterialAnimInstruction:Constructor(params)
    self._anim = params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewStopCasterMaterialAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MaterialAnimationComponent
    local comp = casterEntity:MaterialAnimationComponent()
    if comp then
        comp:StopLayer(MaterialAnimLayer.SkillPreview)
        if self._anim then
            casterEntity:StopMaterialAnim(self._anim)
        end
    end
end
