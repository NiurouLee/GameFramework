--深渊出场技专用，加载深渊特效
require("base_ins_r")

---@class AbyssEffectInstruction: BaseInstruction
_class("AbyssEffectInstruction", BaseInstruction)
AbyssEffectInstruction = AbyssEffectInstruction

function AbyssEffectInstruction:Constructor(paramList)
    self._effectMask = tonumber(paramList["effectMask"])
    self._effectBottom = tonumber(paramList["effectBottom"])
    self._effectSide = tonumber(paramList["effectSide"])
end

---@param casterEntity Entity
function AbyssEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type Entity
    self._casterEntity = casterEntity
    if not casterEntity:HasTrapID() then
        return
    end
    local cEffectHolder = casterEntity:EffectHolder()
    if not cEffectHolder then
        casterEntity:AddEffectHolder()
    end
    cEffectHolder = casterEntity:EffectHolder()
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local bodyArea = casterEntity:BodyArea():GetArea()
    local cGridLocation = casterEntity:GridLocation()
    local pos, dir = cGridLocation.Position, cGridLocation.Direction
    local len = table.count(bodyArea)
    local keyMask = "AbssyMask"
    local keyBottom = "AbssyBottom"
    -- local keySide = "AbssySide"
    local dir = Vector2(0, 1)
    local truePosList = {}
    for i = 1, len do
        local truePos = bodyArea[i] + pos
        local ePiece = pieceSvc:FindPieceEntity(truePos)
	    ---ePiece:SetViewVisible(false)
	    ePiece:View():GetGameObject():SetActive(false)--隐藏格子
        ---Mask
        local effEntityMask = sEffect:CreateWorldPositionEffect(self._effectMask, truePos)
        local effEntityIdMask = effEntityMask:GetID()
        cEffectHolder:AttachEffect(keyMask, effEntityIdMask)
        ---Bottom
        local effEntityBottom = sEffect:CreateWorldPositionEffect(self._effectBottom, truePos)
        effEntityBottom:SetLocationHeight(effEntityBottom:Location():Height() + BattleConst.AbyssBottomDepth)
        local effEntityIdBottom = effEntityBottom:GetID()
        cEffectHolder:AttachEffect(keyBottom, effEntityIdBottom)
        ---Side
        table.insert(truePosList, truePos)
    end

    ---@type RenderEntityService
    local ersvc = self._world:GetService("RenderEntity")
    ersvc:CreateSideEffects(truePosList, self._effectSide, Vector3(1, BattleConst.GridSideYScale, 1))
end

function AbyssEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectMask and self._effectMask > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectMask].ResPath, 1})
    end
    if self._effectBottom and self._effectBottom > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectBottom].ResPath, 1})
    end
    if self._effectSide and self._effectSide > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectSide].ResPath, 1})
    end
    return t
end
