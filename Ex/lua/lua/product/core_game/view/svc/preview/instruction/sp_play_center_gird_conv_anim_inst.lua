require("sp_base_inst")
---技能中心点播放转色预览
_class("SkillPreviewPlayScopeCenterGridConvertAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayScopeCenterGridConvertAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayScopeCenterGridConvertAnimInstruction = SkillPreviewPlayScopeCenterGridConvertAnimInstruction

function SkillPreviewPlayScopeCenterGridConvertAnimInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayScopeCenterGridConvertAnimInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type Vector2[]
    local scopeCenterPosList = previewContext:GetScopeCenterPosList()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
    local effectList = previewContext:GetEffect(SkillEffectType.ConvertGridElement)
    local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.ConvertGridElement,effectList)
    local result = previewEffectCalcService:CalcConvertGridElement(casterEntity,scopeCenterPosList,effectParam)
    previewActiveSkillService:DoConvertElement(TT,result:GetTargetGridArray(),result:GetTargetElementType(),casterEntity, result:GetBlockGridArray())
end