require("base_ins_r")
---@class PlayCostCasterHPInstruction: BaseInstruction
_class("PlayCostCasterHPInstruction", BaseInstruction)
PlayCostCasterHPInstruction = PlayCostCasterHPInstruction

function PlayCostCasterHPInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCostCasterHPInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local skillID = skillEffectResultContainer:GetSkillID()
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()

    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.CostCasterHP)

    ---@type SkillEffectCostCasterHPResult
    local damageResult = damageResultArray[curDamageIndex]
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo()
    if not damageInfo then
        Log.fatal("### damageInfo is nil. curDamageIndex, ", curDamageIndex)
        return
    end
    --local damageGridPos = casterEntity:GetRenderGridPosition()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(casterEntity, damageInfo)
end
