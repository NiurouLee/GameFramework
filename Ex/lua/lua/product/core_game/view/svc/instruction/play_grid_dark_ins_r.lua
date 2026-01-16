require("base_ins_r")
---格子变暗表现
---@class PlayGridDarkInstruction: BaseInstruction
_class("PlayGridDarkInstruction", BaseInstruction)
PlayGridDarkInstruction = PlayGridDarkInstruction

function PlayGridDarkInstruction:Constructor(paramList)
    self._type = tonumber(paramList["darkType"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridDarkInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type SkillPhaseParam_GridDark_Type
    if PlayGridDarkType.Dark == self._type then
        pieceService:SetAllPieceDark()
    elseif PlayGridDarkType.Resume == self._type then
    end
end

---@class PlayGridDarkType
local PlayGridDarkType = {
    Dark = 0, --变暗
    Resume = 1 --恢复
}
_enum("PlayGridDarkType", PlayGridDarkType)
