require("cutscene_base_ins_r")
---@class CutsceneCameraEffectInstruction: CutsceneBaseInstruction
_class("CutsceneCameraEffectInstruction", CutsceneBaseInstruction)
CutsceneCameraEffectInstruction = CutsceneCameraEffectInstruction

function CutsceneCameraEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param phaseContext CutscenePhaseContext
function CutsceneCameraEffectInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()

    ---@type EffectService
    local effectService = world:GetService("Effect")
    effectService:CreateScreenEffPointEffect(self._effectID)
end

function CutsceneCameraEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
