require("base_ins_r")
---@class StopCasterMaterialAnimInstruction: BaseInstruction
_class("StopCasterMaterialAnimInstruction", BaseInstruction)
StopCasterMaterialAnimInstruction = StopCasterMaterialAnimInstruction

function StopCasterMaterialAnimInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function StopCasterMaterialAnimInstruction:DoInstruction(TT, casterEntity, phaseContext)
    casterEntity:StopMaterialAnim(self._animName)
end
