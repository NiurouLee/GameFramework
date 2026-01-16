require("sp_base_inst")
_class("SkillPreviewPlayCasterEffectInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterEffectInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterEffectInstruction = SkillPreviewPlayCasterEffectInstruction

function SkillPreviewPlayCasterEffectInstruction:Constructor(params)
    self._effectID = tonumber(params["EffectID"])
end

function SkillPreviewPlayCasterEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterEffectInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type EffectService
    local effectService = previewContext:GetWorld():GetService("Effect")
    effectService:CreateEffect(tonumber(self._effectID), casterEntity)
end
