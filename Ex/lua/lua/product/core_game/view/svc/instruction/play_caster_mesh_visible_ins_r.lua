require("base_ins_r")
---@class PlayCasterMeshVisibleInstruction: BaseInstruction
_class("PlayCasterMeshVisibleInstruction", BaseInstruction)
PlayCasterMeshVisibleInstruction = PlayCasterMeshVisibleInstruction

function PlayCasterMeshVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
    self._objs = string.split(paramList["objs"], "|")
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterMeshVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    for i, objName in ipairs(self._objs) do
        ---@type UnityEngine.Transform
        local tf = GameObjectHelper.FindChild(casterEntity:View().ViewWrapper.GameObject.transform, objName)
        if tf then
            tf.gameObject:SetActive(self._visible == 1)
        end
    end
end
