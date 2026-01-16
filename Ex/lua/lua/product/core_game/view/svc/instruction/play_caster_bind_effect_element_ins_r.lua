require("base_ins_r")
---@class PlayCasterBindEffectElementInstruction: BaseInstruction
_class("PlayCasterBindEffectElementInstruction", BaseInstruction)
PlayCasterBindEffectElementInstruction = PlayCasterBindEffectElementInstruction

function PlayCasterBindEffectElementInstruction:Constructor(paramList)
    local ids = string.split(paramList["effectIDs"], "|")
    self._effectIDs = {}
    for _, id in ipairs(ids) do
        local nid = tonumber(id)
        table.insert(self._effectIDs, nid)
    end
    self._scale = tonumber(paramList["scale"]) or 1
end

---@param casterEntity Entity
function PlayCasterBindEffectElementInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    local element = utilDataSvc:GetEntityElementPrimaryType(casterEntity)
    
    local effectID = self._effectIDs[element]
    local effect = world:GetService("Effect"):CreateEffect(effectID, casterEntity)

    if effect and self._scale ~= 1 then
        YIELD(TT)
        ---@type UnityEngine.Transform
        local trajectoryObject = effect:View():GetGameObject()
        local transWork = trajectoryObject.transform
        local scaleData = Vector3.New(self._scale, self._scale, self._scale)
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOScale(scaleData, 0)
    end
end

function PlayCasterBindEffectElementInstruction:GetCacheResource()
    local t = {}
    if self._effectIDs then
        for i, eff in ipairs(self._effectIDs) do
            table.insert(t, {Cfg.cfg_effect[eff].ResPath, 1})
        end
    end
    return t
end
