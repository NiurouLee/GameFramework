require("base_ins_r")
---@class PlayAddHpTextInstruction: BaseInstruction
_class("PlayAddHpTextInstruction", BaseInstruction)
PlayAddHpTextInstruction = PlayAddHpTextInstruction

function PlayAddHpTextInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["damageStageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAddHpTextInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local addHpResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBlood, self._stageIndex)

    if not addHpResultArray then
        return
    end

    ---@type SkillEffectResult_AddBlood
    local addHpResult = addHpResultArray[1]
    local targetID = addHpResult:GetTargetID()
    local targetPos = addHpResult:GetGridPos()
    local addValue = addHpResult:GetAddValue()

    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntity = world:GetEntityByID(targetID)
    local damageShowType = playDamageService:SingleOrGrid(skillID)
    if targetEntity then
        local addHpDamageInfo = addHpResult:GetDamageInfo()
        addHpDamageInfo:SetShowType(damageShowType)
        addHpDamageInfo:SetRenderGridPos(targetPos)
        playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, addHpDamageInfo)
    else
        Log.error("[PlayInstruction_AddHpText] 没有找到目标， nSkillID = ", skillID, ", TargetID = ", targetID)
    end
end
