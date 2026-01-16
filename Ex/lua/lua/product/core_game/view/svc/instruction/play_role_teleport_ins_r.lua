require("base_ins_r")
---瞬移表现的指令外包装： 2020-06-19 韩玉信
---@class PlayRoleTeleportInstruction: BaseInstruction
_class("PlayRoleTeleportInstruction", BaseInstruction)
PlayRoleTeleportInstruction = PlayRoleTeleportInstruction

function PlayRoleTeleportInstruction:Constructor(paramList)
    self._type = tonumber(paramList["type"])
    self._onlySelf = tonumber(paramList["onlySelf"])
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1

end

---@param casterEntity Entity
function PlayRoleTeleportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    playSkillInstructionService:Teleport(TT, casterEntity, self._type, self._onlySelf, teleportEffectResult)
end
