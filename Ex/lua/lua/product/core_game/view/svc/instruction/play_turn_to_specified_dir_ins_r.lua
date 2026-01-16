require("base_ins_r")
---面向指定方向
---@class PlayTurnToSpecifiedDirInstruction: BaseInstruction
_class("PlayTurnToSpecifiedDirInstruction", BaseInstruction)
PlayTurnToSpecifiedDirInstruction = PlayTurnToSpecifiedDirInstruction

function PlayTurnToSpecifiedDirInstruction:Constructor(paramList)
    self._dirX = tonumber(paramList["dirX"]) or 0
    self._dirY = tonumber(paramList["dirY"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToSpecifiedDirInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local dir = Vector2(self._dirX, self._dirY)
    casterEntity:SetDirection(dir)
end
