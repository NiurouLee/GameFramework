require("base_ins_r")
---@class PlayCasterSubMaterialAnimInstruction: BaseInstruction
_class("PlayCasterSubMaterialAnimInstruction", BaseInstruction)
PlayCasterSubMaterialAnimInstruction = PlayCasterSubMaterialAnimInstruction

function PlayCasterSubMaterialAnimInstruction:Constructor(paramList)
    self._nodeName = paramList["nodeName"]
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function PlayCasterSubMaterialAnimInstruction:DoInstruction(TT, casterEntity, phaseContext)
    casterEntity:PlaySubMaterialAnim(self._nodeName,self._animName)
end
