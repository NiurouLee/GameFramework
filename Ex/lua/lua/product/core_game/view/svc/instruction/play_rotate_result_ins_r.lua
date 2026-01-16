require("base_ins_r")

---@class PlayRotateResultInstruction: BaseInstruction
_class("PlayRotateResultInstruction", BaseInstruction)
PlayRotateResultInstruction = PlayRotateResultInstruction

function PlayRotateResultInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayRotateResultInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillRotateEffectResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Rotate)
    if resultArray == nil then
        Log.fatal("PlayRotateResultInstruction, result is nil.")
        return
    end

    local dirNew = resultArray[1]:GetDirNew()

    casterEntity:SetDirection(dirNew)
end
