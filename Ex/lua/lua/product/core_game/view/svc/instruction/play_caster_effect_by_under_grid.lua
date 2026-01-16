require("base_ins_r")
---@class PlayCasterEffectByUnderGridInstruction: BaseInstruction
_class("PlayCasterEffectByUnderGridInstruction", BaseInstruction)
PlayCasterEffectByUnderGridInstruction = PlayCasterEffectByUnderGridInstruction

function PlayCasterEffectByUnderGridInstruction:Constructor(paramList)
    self._redEffectID = paramList["redEffectID"]
    self._yellowEffectID = paramList["yellowEffectID"]
    self._blueEffectID = paramList["blueEffectID"]
    self._greenEffectID = paramList["greenEffectID"]
end

---@param casterEntity Entity
function PlayCasterEffectByUnderGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end
    ---@type Vector2
    local gridPos = e:GetRenderGridPosition()
    self._world = e:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pieceType =utilDataSvc:GetPieceType(gridPos)
    local effectID
    if pieceType== PieceType.Blue then
        effectID  = self._blueEffectID
    elseif pieceType== PieceType.Red then
        effectID  = self._redEffectID
    elseif pieceType== PieceType.Green then
        effectID  = self._greenEffectID
    elseif pieceType== PieceType.Yellow then
        effectID  = self._yellowEffectID
    end

    ---@type Entity
    local effect = self._world:GetService("Effect"):CreateEffect(self.effectID, e)
end

function PlayCasterEffectByUnderGridInstruction:GetCacheResource()
    local t = {}
    if self._redEffectID and self._redEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._redEffectID].ResPath, 1})
    end
    if self._blueEffectID and self._blueEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._blueEffectID].ResPath, 1})
    end
    if self._yellowEffectID and self._yellowEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._yellowEffectID].ResPath, 1})
    end
    if self._greenEffectID and self._greenEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._greenEffectID].ResPath, 1})
    end
    return t
end
