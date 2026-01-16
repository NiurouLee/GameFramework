require("base_ins_r")
---面向到瞬移结果的旧坐标
---@class PlayTurnToTeleportOldPosInstruction: BaseInstruction
_class("PlayTurnToTeleportOldPosInstruction", BaseInstruction)
PlayTurnToTeleportOldPosInstruction = PlayTurnToTeleportOldPosInstruction

function PlayTurnToTeleportOldPosInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToTeleportOldPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end

    local oldPos = teleportEffectResult:GetPosOld()

    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local casterPos = boardServiceRender:GetRealEntityGridPos(casterEntity)
    local dir = oldPos - casterPos
    casterEntity:SetDirection(dir)
end
