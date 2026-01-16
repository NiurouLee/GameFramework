require("base_ins_r")

---@class PlayCameraEffectInstruction: BaseInstruction
_class("PlayCameraEffectInstruction", BaseInstruction)
PlayCameraEffectInstruction = PlayCameraEffectInstruction

function PlayCameraEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param casterEntity Entity
function PlayCameraEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self._effectID and self._effectID > 0 then
        ---@type MainWorld
        local world = casterEntity:GetOwnerWorld()
        ---@type EffectService
        local serEffect = world:GetService("Effect")
        serEffect:CreateScreenEffPointEffect(self._effectID)
    end
end

function PlayCameraEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
