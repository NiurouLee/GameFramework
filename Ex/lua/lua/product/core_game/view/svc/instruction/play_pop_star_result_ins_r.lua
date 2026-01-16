require("base_ins_r")
---@class PlayPopStarResultInstruction : BaseInstruction
_class("PlayPopStarResultInstruction", BaseInstruction)
PlayPopStarResultInstruction = PlayPopStarResultInstruction

function PlayPopStarResultInstruction:Constructor(paramList)

end

---@param casterEntity Entity
function PlayPopStarResultInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectPopStarResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.PopStar)
    if not result then
        return
    end

    ---@type DataPopStarResult
    local popRes = result:GetDataPopStarResult()

    ---消除表现
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    for _, v in ipairs(popRes:GetDelSet()) do
        pieceService:SetPieceAnimMoveDone(v.pos)
    end

    ---@type PopStarServiceRender
    local popStarRSvc = world:GetService("PopStarRender")
    popStarRSvc:PlayPopStarResult(TT, popRes)
end
