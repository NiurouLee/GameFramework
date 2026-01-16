require("base_ins_r")
---在当前目标位置播放特效
---@class PlayEffectAtTargetPosInstruction: BaseInstruction
_class("PlayEffectAtTargetPosInstruction", BaseInstruction)
PlayEffectAtTargetPosInstruction = PlayEffectAtTargetPosInstruction

function PlayEffectAtTargetPosInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEffectAtTargetPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        Log.fatal("#### PlayEffectAtTargetPosInstruction targetEntity nil. targetEntityID=", targetEntityID)
        return
    end

    local pos =  targetEntity:GetRenderGridPosition()
    ---@type EffectService
    local sEffect = world:GetService("Effect")
    sEffect:CreateWorldPositionEffect(self._effectID, pos)
end

function PlayEffectAtTargetPosInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
