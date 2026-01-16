require("sp_base_inst")
_class("SkillPreviewPlaySerialKillerInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlaySerialKillerInstruction: SkillPreviewBaseInstruction
SkillPreviewPlaySerialKillerInstruction = SkillPreviewPlaySerialKillerInstruction

function SkillPreviewPlaySerialKillerInstruction:Constructor(params)
    self._otherAnim = params["OtherAnim"]
    self._noOtherAnim = tonumber(params["NoOtherAnim"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlaySerialKillerInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    local targetIDList = previewContext:GetTargetEntityIDList()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService = self._world:GetService("PreviewCalcEffect")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    local effectList = previewContext:GetEffect(SkillEffectType.SerialKiller)
    local effectParam = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.SerialKiller, effectList)
    ---@type SkillSerialKillerResult
    local result = previewEffectCalcService:CalcSerialKiller(casterEntity:GetID(), targetIDList, effectParam)
    local posList = result:GetAddPiecePosList()

    if self._noOtherAnim == 1 then
        previewActiveSkillService:DoConvert(posList, "Add")
    else
        previewActiveSkillService:DoConvert(posList, "Add", "Dark")
    end
end
