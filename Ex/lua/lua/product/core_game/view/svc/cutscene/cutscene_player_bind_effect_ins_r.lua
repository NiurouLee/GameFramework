require("cutscene_base_ins_r")
---@class CutscenePlayerBindEffectInstruction: CutsceneBaseInstruction
_class("CutscenePlayerBindEffectInstruction", CutsceneBaseInstruction)
CutscenePlayerBindEffectInstruction = CutscenePlayerBindEffectInstruction

function CutscenePlayerBindEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param phaseContext CutscenePhaseContext
function CutscenePlayerBindEffectInstruction:DoInstruction(TT, phaseContext)
    local world = phaseContext:GetCutsceneWorld()
    local playerEntity = world:Player():GetLocalTeamEntity()

    ---@type EffectService
    local effectService = world:GetService("Effect")
    local effect = effectService:CreateEffect(self._effectID, playerEntity)
end

function CutscenePlayerBindEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
