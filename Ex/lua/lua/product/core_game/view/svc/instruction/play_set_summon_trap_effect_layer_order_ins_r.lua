require("base_ins_r")
---@class PlaySetSummonTrapEffectLayerOrderInstruction: BaseInstruction
_class("PlaySetSummonTrapEffectLayerOrderInstruction", BaseInstruction)
PlaySetSummonTrapEffectLayerOrderInstruction = PlaySetSummonTrapEffectLayerOrderInstruction

function PlaySetSummonTrapEffectLayerOrderInstruction:Constructor(paramList)
    self._wait = tonumber(paramList["wait"])
    self._targetLayerName = paramList["targetLayerName"] or "SkillGeziEffect"
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySetSummonTrapEffectLayerOrderInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if not APPVER1210 then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local resultIndex = phaseContext:GetCurResultIndexByType(SkillEffectType.SummonScanTrap)
    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()
    local tResults = routineCmpt:GetEffectResultsAsArray(SkillEffectType.SummonScanTrap)
    if not tResults then
        return
    end
    ---@type SkillEffectResult_SummonScanTrap
    local result = tResults[resultIndex]

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type TrapServiceRender
    local rsvcTrap = world:GetService("TrapRender")

    local eidNewTrap = result:GetSummonTrapEntityID()
    local eNewTrap = world:GetEntityByID(eidNewTrap)
    if not eNewTrap then
        return
    end

    local go = eNewTrap:View():GetGameObject()

    --如果是棱镜
    ---@type TrapRenderComponent
    local trapRenderCmpt = eNewTrap:TrapRender()
    if trapRenderCmpt and trapRenderCmpt:GetIsPrismGrid() == 1 then
        local pos = eNewTrap:GetRenderGridPosition()
        ---@type PieceServiceRender
        local pieceSvc = world:GetService("Piece")
        local pieceEntity = pieceSvc:FindPieceEntity(pos)
        go = pieceEntity:View():GetGameObject()
      
    end

    ---@type TLayerOrderComponent
    local tLayerOrderComponent = go.gameObject:GetComponentInChildren(typeof(TLayerOrderComponent))
    if not tLayerOrderComponent then
        return
    end

    local curLayerName = tLayerOrderComponent:GetSortLayerName()
    tLayerOrderComponent:SetSortLayer(self._targetLayerName)
    tLayerOrderComponent:Sorted()

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT, self._wait)
            tLayerOrderComponent:SetSortLayer(curLayerName)
            tLayerOrderComponent:Sorted()
            tLayerOrderComponent:TLayerOrderManagerClearAll()
            tLayerOrderComponent:Sorted()
        end
    )
end
