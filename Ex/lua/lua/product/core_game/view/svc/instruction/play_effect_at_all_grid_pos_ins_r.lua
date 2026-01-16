require("base_ins_r")
---在地板所有非镂空格子上播特效【N30Boss 玻璃体格子特效】
---@class PlayEffectAtAllGridPosInstruction: BaseInstruction
_class("PlayEffectAtAllGridPosInstruction", BaseInstruction)
PlayEffectAtAllGridPosInstruction = PlayEffectAtAllGridPosInstruction

function PlayEffectAtAllGridPosInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

function PlayEffectAtAllGridPosInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._effectID].ResPath, 99 })
    end
    return t
end

---@param casterEntity Entity
function PlayEffectAtAllGridPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()

    ---@type EffectService
    local effectSvc = world:GetService("Effect")

    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    local gridEntityData = utilData:GetReplicaGridEntityData()
    if gridEntityData then
        for pos, _ in pairs(gridEntityData) do
            ---若已设置过，则不再新建
            if not renderBoardCmpt:GetGridEffectEntityID(pos) then
                local effectEntity = effectSvc:CreateWorldPositionDirectionEffect(self._effectID, pos)
                renderBoardCmpt:SetGridEffectEntityID(pos, effectEntity:GetID())
            end
        end
    end
end
