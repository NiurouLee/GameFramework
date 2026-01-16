
require("sp_base_inst")
_class("SkillPreviewPlayCasterCancelPreviewAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterCancelPreviewAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterCancelPreviewAnimInstruction = SkillPreviewPlayCasterCancelPreviewAnimInstruction

function SkillPreviewPlayCasterCancelPreviewAnimInstruction:Constructor(params)
    self._anim = params["Anim"] or "AtkUltPreviewCancel"
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterCancelPreviewAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillSvc = world:GetService("PreviewActiveSkill")
    previewActiveSkillSvc:PlayCasterPreviewAnim(casterEntity,false,self._anim)
end

