require("base_ins_r")

---@class PlayChangeBodyAreaInstruction: BaseInstruction
_class("PlayChangeBodyAreaInstruction", BaseInstruction)
PlayChangeBodyAreaInstruction = PlayChangeBodyAreaInstruction

function PlayChangeBodyAreaInstruction:Constructor(paramList)
    self._notRefreshPieceAnimAndOutLine = tonumber(paramList["notRefreshPieceAnimAndOutLine"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayChangeBodyAreaInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultChangeBodyArea[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ChangeBodyArea)
    if resultArray == nil then
        Log.fatal("PlayChangeBodyAreaInstruction, result is nil.")
        return
    end

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")

    --设置怪物脚底暗色  刷新红线
    if self._notRefreshPieceAnimAndOutLine == 0 then
        pieceService:RefreshPieceAnim()
        pieceService:RefreshMonsterAreaOutLine(TT)
    end
end
