require("sp_base_inst")
---点选一格是选择列聚拢，再次点选是选择行聚拢
_class("SkillPreviewPlayPickUpGridTogetherInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayPickUpGridTogetherInstruction : SkillPreviewBaseInstruction
SkillPreviewPlayPickUpGridTogetherInstruction = SkillPreviewPlayPickUpGridTogetherInstruction

function SkillPreviewPlayPickUpGridTogetherInstruction:Constructor(params)

end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayPickUpGridTogetherInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    ---@type Vector2[]
    local pickUpPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    previewActiveSkillService:DoConvert(scopeGridList,"Normal","Dark")
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
    local effectList = previewContext:GetEffect(SkillEffectType.PickUpGridTogether)
    local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.PickUpGridTogether,effectList)
    ---@type SkillEffectResult_PickUpGridTogether
    local result = previewEffectCalcService:CalcPickUpGridTogether(casterEntity,previewContext,effectParam,pickUpPosList)
    previewActiveSkillService:PlayPickUpGridTogether(TT,result:GetNewGridDataList(),casterEntity,nil)
end


