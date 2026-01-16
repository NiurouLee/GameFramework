require("sp_base_inst")
---施法者MaterialAnim
_class("SkillPreviewPlayCasterMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterMaterialAnimInstruction = SkillPreviewPlayCasterMaterialAnimInstruction

function SkillPreviewPlayCasterMaterialAnimInstruction:Constructor(params)
    self._anim = params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterMaterialAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    if self._anim == "Flash" then
        casterEntity:NewEnableFlash()
    elseif self._anim == "Transparent" then
        casterEntity:NewEnableTransparent()
    elseif self._anim == "Ghost" then
        casterEntity:NewEnableGhost()
    else
        casterEntity:PlayMaterialAnim(self._anim)
    end
end
