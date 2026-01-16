require("base_ins_r")
---@class PlayTargetBuffEffectInstruction: BaseInstruction
_class("PlayTargetBuffEffectInstruction", BaseInstruction)
PlayTargetBuffEffectInstruction = PlayTargetBuffEffectInstruction

function PlayTargetBuffEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

function PlayTargetBuffEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetBuffEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")

    local targetEntityID = phaseContext:GetCurTargetEntityID()
    if targetEntityID and targetEntityID > 0 then
        local targetEntity = world:GetEntityByID(targetEntityID)
        local effect = world:GetService("Effect"):CreateEffect(self._effectID, targetEntity)
    end
end
