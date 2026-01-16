require("base_ins_r")
---面向到国际象棋马的瞬移方向
---@class PlayTurnToChessKnightInstruction: BaseInstruction
_class("PlayTurnToChessKnightInstruction", BaseInstruction)
PlayTurnToChessKnightInstruction = PlayTurnToChessKnightInstruction

function PlayTurnToChessKnightInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToChessKnightInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end

    local newPos = teleportEffectResult:GetPosNew()
    local oldPos = teleportEffectResult:GetPosOld()

    if newPos == oldPos then
        return
    end
    local dir = newPos - oldPos

    if math.abs(dir.x) == 1 then
        dir.x = 0
    end
    if math.abs(dir.y) == 1 then
        dir.y = 0
    end

    casterEntity:SetDirection(dir)
end
