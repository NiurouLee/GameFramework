require("base_ins_r")
---使用瞬移结果的目标播放
---@class PlayTeleportTargetAndSelectIndexInstruction: BaseInstruction
_class("PlayTeleportTargetAndSelectIndexInstruction", BaseInstruction)
PlayTeleportTargetAndSelectIndexInstruction = PlayTeleportTargetAndSelectIndexInstruction

function PlayTeleportTargetAndSelectIndexInstruction:Constructor(paramList)
    self._type = tonumber(paramList["type"])
    self._onlySelf = tonumber(paramList["onlySelf"])
    self._index = tonumber(paramList["index"]) or 1
end

---@param casterEntity Entity
function PlayTeleportTargetAndSelectIndexInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport[]
    local teleportEffectResultAll = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Teleport)
    if not teleportEffectResultAll then
        return
    end

    ---@type SkillEffectResult_Teleport
    local teleportEffectResult = teleportEffectResultAll[self._index]
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
