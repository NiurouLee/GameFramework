require("base_ins_r")
---@class PlayTargetMaterialAnimInstruction: BaseInstruction
_class("PlayTargetMaterialAnimInstruction", BaseInstruction)
PlayTargetMaterialAnimInstruction = PlayTargetMaterialAnimInstruction

function PlayTargetMaterialAnimInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function PlayTargetMaterialAnimInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    if not targetEntityID then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        return
    end

    targetEntity:PlayMaterialAnim(self._animName)
end
