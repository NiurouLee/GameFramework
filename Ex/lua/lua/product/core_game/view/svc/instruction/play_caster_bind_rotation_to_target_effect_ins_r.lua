require("base_ins_r")
---@class PlayCasterBindRotationToTargetEffectInstruction: BaseInstruction
_class("PlayCasterBindRotationToTargetEffectInstruction", BaseInstruction)
PlayCasterBindRotationToTargetEffectInstruction = PlayCasterBindRotationToTargetEffectInstruction

function PlayCasterBindRotationToTargetEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._offsetX = tonumber(paramList["offsetx"])
    self._offsetY = tonumber(paramList["offsety"])
    self._offsetZ = tonumber(paramList["offsetz"])
end

---@param casterEntity Entity
function PlayCasterBindRotationToTargetEffectInstruction:DoInstruction(TT,casterEntity,phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    --创建特效
    local tran = casterEntity:View():GetGameObject().transform
    local renderPos = tran:TransformPoint(Vector3(self._offsetX, self._offsetY, self._offsetZ))
    local effectEntity = world:GetService("Effect"):CreatePositionEffect(self._effectID, renderPos)
    --计算特效的方向
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local go = targetEntity:View():GetGameObject()
    local targetPos = go.transform.position
    local dir = targetPos - renderPos
    --设置特效方向
    effectEntity:SetDirection(dir)
end

function PlayCasterBindRotationToTargetEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end