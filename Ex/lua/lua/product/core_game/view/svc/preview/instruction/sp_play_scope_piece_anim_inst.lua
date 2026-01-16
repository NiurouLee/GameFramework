require("sp_base_inst")
---范围区域执行ScopeAnim,其余区域执行OtherAnim
_class("SkillPreviewPlayScopePieceAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayScopePieceAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayScopePieceAnimInstruction = SkillPreviewPlayScopePieceAnimInstruction

function SkillPreviewPlayScopePieceAnimInstruction:Constructor(params)
    self._scopeAnim = params["ScopeAnim"]
    self._otherAnim = params["OtherAnim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayScopePieceAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    if not scopeGridList then
        return
    end
    previewActiveSkillService:DoConvert(scopeGridList, self._scopeAnim, self._otherAnim)
end
