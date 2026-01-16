require("base_ins_r")
---@class StopTargetMaterialAnimInstruction: BaseInstruction
_class("StopTargetMaterialAnimInstruction", BaseInstruction)
StopTargetMaterialAnimInstruction = StopTargetMaterialAnimInstruction

function StopTargetMaterialAnimInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function StopTargetMaterialAnimInstruction:DoInstruction(TT, casterEntity, phaseContext)
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

    targetEntity:StopMaterialAnim(self._animName)
end
