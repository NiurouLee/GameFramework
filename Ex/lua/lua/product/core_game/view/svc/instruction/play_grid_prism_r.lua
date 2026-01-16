require("base_ins_r")
---格子变暗表现
---@class PlayGridPrismInstruction: BaseInstruction
_class("PlayGridPrismInstruction", BaseInstruction)
PlayGridPrismInstruction = PlayGridPrismInstruction

function PlayGridPrismInstruction:Constructor(paramList)
    self._prism = tonumber(paramList["prism"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridPrismInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local gridPos = casterEntity:GetGridPosition()
    if self._prism == 1 then
        pieceSvc:SetPieceRenderEffect(gridPos, PieceEffectType.Prism)
    else
        pieceSvc:SetPieceRenderEffect(gridPos, PieceEffectType.Normal)
    end
end
