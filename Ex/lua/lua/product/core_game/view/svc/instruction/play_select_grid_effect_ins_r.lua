require("base_ins_r")
---@class PlaySelectGridEffectInstruction: BaseInstruction
_class("PlaySelectGridEffectInstruction", BaseInstruction)
PlaySelectGridEffectInstruction = PlaySelectGridEffectInstruction

function PlaySelectGridEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._intervalTime = tonumber(paramList["intervalTime"])
end

---@param casterEntity Entity
function PlaySelectGridEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    --获取攻击范围
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    if not scopeResult then
        return
    end
    --格子个数
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local pieceArray = {}
    local pieceCount = 0
    local array = scopeResult:GetAttackRange()
    if array then
        pieceCount = table.count(array)
        for _, v in pairs(array) do
            local gridEntity = pieceSvc:FindPieceEntity(v)
            table.insert(pieceArray, gridEntity)
        end
    end
    if pieceCount == 0 then
        return
    end
    --创建特效
    local effectService = world:GetService("Effect")
    for _, piece in pairs(pieceArray) do
        local renderPos = piece:Location().Position
        local effectEntity = effectService:CreatePositionEffect(self._effectID, renderPos)
        YIELD(TT, self._intervalTime)
    end
end

function PlaySelectGridEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
