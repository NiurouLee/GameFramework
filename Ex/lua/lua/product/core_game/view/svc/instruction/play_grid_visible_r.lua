require("base_ins_r")
---@class PlayGridVisibleInstruction: BaseInstruction
_class("PlayGridVisibleInstruction", BaseInstruction)
PlayGridVisibleInstruction = PlayGridVisibleInstruction

function PlayGridVisibleInstruction:Constructor(paramList)
    local param = tonumber(paramList["visible"])
    if param == 1 then
        self._visible = true
    else
        self._visible = false
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local pos = casterEntity:GetGridPosition()
    local ePiece = pieceSvc:FindPieceEntity(pos)
    ePiece:View():GetGameObject():SetActive(self._visible)
end
