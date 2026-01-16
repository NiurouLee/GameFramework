require("base_ins_r")
---面向指定坐标
---@class PlayTurnToSpecifiedPosInstruction: BaseInstruction
_class("PlayTurnToSpecifiedPosInstruction", BaseInstruction)
PlayTurnToSpecifiedPosInstruction = PlayTurnToSpecifiedPosInstruction

function PlayTurnToSpecifiedPosInstruction:Constructor(paramList)
    self._gridX = tonumber(paramList["gridX"]) or 0
    self._gridY = tonumber(paramList["gridY"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToSpecifiedPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local grid = Vector2(self._gridX, self._gridY)

    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local casterPos = boardServiceRender:GetRealEntityGridPos(casterEntity)

    local dir = grid - casterPos

    casterEntity:SetDirection(dir)
end
