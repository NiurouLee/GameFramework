require("base_ins_r")

---@class PlayPlayerRotateToPickupInstruction: BaseInstruction
_class("PlayPlayerRotateToPickupInstruction", BaseInstruction)
PlayPlayerRotateToPickupInstruction = PlayPlayerRotateToPickupInstruction

function PlayPlayerRotateToPickupInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList.stageIndex) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPlayerRotateToPickupInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultRotateToPickup
    local rotateResult = routineComponent:GetEffectResultByArray(SkillEffectType.RotateToPickup, self._stageIndex)

    local dir = rotateResult:GetNewDir()
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    local pets = teamEntity:Team():GetTeamPetEntities()
    ---@param petEntity Entity
    for i, petEntity in ipairs(pets) do
        petEntity:SetDirection(dir)
    end
    teamEntity:SetDirection(dir)
end
