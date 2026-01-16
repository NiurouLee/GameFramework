require("base_ins_r")
---瞬移表现
---@class PlayStageTeleportInstruction: BaseInstruction
_class("PlayStageTeleportInstruction", BaseInstruction)
PlayStageTeleportInstruction = PlayStageTeleportInstruction

function PlayStageTeleportInstruction:Constructor(paramList)
    self._type = tonumber(paramList["type"])
    self._onlySelf = tonumber(paramList["onlySelf"])
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
end

---@param casterEntity Entity
function PlayStageTeleportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult or table.count(teleportEffectResult) == 0 then
        return
    end
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    playSkillInstructionService:Teleport(TT, casterEntity, self._type, self._onlySelf, teleportEffectResult[1])
end
