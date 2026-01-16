require("base_ins_r")
---在当前目标所在格子上播放特效，仅支持单格
---@class PlayEffectAtTargetGridInstruction: BaseInstruction
_class("PlayEffectAtTargetGridInstruction", BaseInstruction)
PlayEffectAtTargetGridInstruction = PlayEffectAtTargetGridInstruction

function PlayEffectAtTargetGridInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEffectAtTargetGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        Log.fatal("PlayEffectAtTargetGridInstruction targetEntity nil. targetEntityID=", targetEntityID)
        return
    end

    local pos = targetEntity:GetGridPosition()
    ---@type EffectService
    local sEffect = world:GetService("Effect")
    sEffect:CreateWorldPositionEffect(self._effectID, pos)
end

function PlayEffectAtTargetGridInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
