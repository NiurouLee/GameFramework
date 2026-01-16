require("base_ins_r")
---使用瞬移结果的目标播放
---@class PlayTeleportResultTargetInstruction: BaseInstruction
_class("PlayTeleportResultTargetInstruction", BaseInstruction)
PlayTeleportResultTargetInstruction = PlayTeleportResultTargetInstruction

function PlayTeleportResultTargetInstruction:Constructor(paramList)
    self._type = tonumber(paramList["type"])
    self._onlySelf = tonumber(paramList["onlySelf"])
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
end

---@param casterEntity Entity
function PlayTeleportResultTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end

    local world = casterEntity:GetOwnerWorld()

    --使用瞬移结果中的技能目标 替换施法者
    local targetEntityID = teleportEffectResult:GetTargetID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    casterEntity = targetEntity

    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    playSkillInstructionService:Teleport(TT, casterEntity, self._type, self._onlySelf, teleportEffectResult)
end
