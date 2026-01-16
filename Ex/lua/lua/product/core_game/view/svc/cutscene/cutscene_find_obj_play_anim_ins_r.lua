require("cutscene_base_ins_r")
---@class CutsceneFindObjPlayAnimationInstruction: CutsceneBaseInstruction
_class("CutsceneFindObjPlayAnimationInstruction", CutsceneBaseInstruction)
CutsceneFindObjPlayAnimationInstruction = CutsceneFindObjPlayAnimationInstruction

function CutsceneFindObjPlayAnimationInstruction:Constructor(paramList)
    self._gameObjectName = paramList["gameObjectName"]
    self._animName = paramList["anim"]
end

---@param phaseContext CutscenePhaseContext
function CutsceneFindObjPlayAnimationInstruction:DoInstruction(TT, phaseContext)
    ---@type UnityEngine.GameObject
    local targetGameObject = UnityEngine.GameObject.Find(self._gameObjectName)
    if targetGameObject then
        ---@type UnityEngine.Animation
        local anim = targetGameObject.gameObject:GetComponent("Animation")
        anim:Play(self._animName)
    end
end
