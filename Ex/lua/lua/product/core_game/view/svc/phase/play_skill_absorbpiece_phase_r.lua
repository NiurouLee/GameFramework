require "play_skill_phase_base_r"
_class("PlaySkillAbsorbPiecePhase", PlaySkillPhaseBase)
PlaySkillAbsorbPiecePhase = PlaySkillAbsorbPiecePhase

function PlaySkillAbsorbPiecePhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseAbsorbPieceParam
    local absorbPieceParam = phaseParam
    ---@type number
    local changeDelay = absorbPieceParam:GetChangeDelay()
    ---@type number
    local displayDelay = absorbPieceParam:GetDisPlayDelay()
    ---@type number
    local gridEffectID = absorbPieceParam:GetGridEffectID()
    ---@type number
    local scopeDelay = absorbPieceParam:GetScopeDelay()
    local gridPlayType = absorbPieceParam:GetGridPlayType()

    ---@type Vector2
    local castPos = casterEntity:GridLocation().Position

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillAbsorbPieceEffectResult
    local absorbResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AbsorbPiece)
    local absorbPieceList = absorbResult:GetAbsorbPieceList()
    if not absorbPieceList or #absorbPieceList == 0 then
        return
    end
    local newPieceList = absorbResult:GetNewPieceList()
    local targetGirdList, _, maxGridCount = InnerGameSortGridHelperRender:SortGrid(absorbPieceList, castPos)

    for i = 1, maxGridCount do
        local needWait = false
        for dir = 1, 8 do
            local t = targetGirdList[dir]
            if #(t.gridList) >= i then
                local gridPos = t.gridList[i]
                if gridPos then
                    needWait = true
                    GameGlobal.TaskManager():CoreGameStartTask(
                        self._DoEffect,
                        self,
                        gridPos,
                        self:_GetPieceType(newPieceList, gridPos),
                        gridEffectID,
                        changeDelay,
                        displayDelay
                    )
                end
            end
        end
        if i ~= maxGridCount and needWait then
            YIELD(TT, scopeDelay)
        end
    end
end

---@param gridPos Vector2
function PlaySkillAbsorbPiecePhase:_GetPieceType(newPieceList, gridPos)
    for _, grid in pairs(newPieceList) do
        if grid.x == gridPos.x and grid.y == gridPos.y then
            return grid.color
        end
    end
    return nil
end

function PlaySkillAbsorbPiecePhase:_DoEffect(TT, gridPos, newPieceType, effectID, changeDelay, displayDelay)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    self._world:GetService("Effect"):CreateWorldPositionEffect(effectID, gridPos)

    if changeDelay and changeDelay ~= 0 then
        YIELD(TT, changeDelay)
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local pieceEntity = pieceSvc:FindPieceEntity(gridPos)
    pieceEntity:View():GetGameObject():SetActive(false)
    local entity = boardServiceRender:CreateEmptyGridEffectEntity(gridPos)
    if displayDelay and displayDelay ~= 0 then
        YIELD(TT, displayDelay)
    else
        YIELD(TT)
    end
    self._world:DestroyEntity(entity)
    boardServiceRender:ReCreateGridEntity(newPieceType, gridPos, false, false, true)
end
