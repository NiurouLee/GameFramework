require("sp_base_inst")
---范围区域执行ScopeAnim
_class("SkillPreviewPlayCalcScopePieceAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCalcScopePieceAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCalcScopePieceAnimInstruction = SkillPreviewPlayCalcScopePieceAnimInstruction

function SkillPreviewPlayCalcScopePieceAnimInstruction:Constructor(params)
    self._scopeAnim = params["ScopeAnim"]
    self._skillID = tonumber(params["skillID"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCalcScopePieceAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    if not self._skillID then
        return
    end

    ---@type MainWorld
    local world = previewContext:GetWorld()

    local casterPos = casterEntity:GetGridPosition()
    local bodyArea = casterEntity:BodyArea():GetArea()
    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(self._skillID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, casterEntity)
    if not scopeResult then
        return
    end

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    previewActiveSkillService:DoConvert(scopeResult:GetAttackRange(), self._scopeAnim)
end
