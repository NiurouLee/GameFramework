require("sp_base_inst")
---类似传送带的效果，只不过是纵向从点击点开始，按照点击方向，行/列移动到版边，点击点所在的的行/列显示新的颜色
_class("SkillPreviewTransportGridInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewTransportGridInstruction : SkillPreviewBaseInstruction
SkillPreviewTransportGridInstruction = SkillPreviewTransportGridInstruction

function SkillPreviewTransportGridInstruction:Constructor(params)
    self._movePickUpMonster = false
    if params["MovePickUpMonster"] and params["MovePickUpMonster"] == "true" then
        self._movePickUpMonster = true
    end
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewTransportGridInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    ---@type Vector2[]
    local pickUpPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
    if not pickUpPosList or #pickUpPosList~=2 then
        return
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local range =utilScopeSvc:CalcRangeByPickUpPosList(pickUpPosList)
    previewActiveSkillService:DoConvert(range,"Normal","Dark")

    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
    local effectList = previewContext:GetEffect(SkillEffectType.TransportByRange)
    local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.TransportByRange,effectList)
    ---@type SkillEffectResultTransportByRange
    local result = previewEffectCalcService:CalcTransportByRange(casterEntity,previewContext,effectParam,pickUpPosList)
    previewActiveSkillService:PlayTransportPreview(TT,casterEntity,result)
end


