require("base_ins_r")
---@class PlayCasterAnimationCleanTriggerInstruction: BaseInstruction
_class("PlayCasterAnimationCleanTriggerInstruction", BaseInstruction)
PlayCasterAnimationCleanTriggerInstruction = PlayCasterAnimationCleanTriggerInstruction

function PlayCasterAnimationCleanTriggerInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function PlayCasterAnimationCleanTriggerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end

    local csgo = casterEntity:View().ViewWrapper.GameObject
    local csTransformRoot = csgo.transform:Find("Root")
    if not csTransformRoot then
        return
    end
    ---@type UnityEngine.Animator
    local csAnimator = csTransformRoot:GetComponent("Animator")
    if csAnimator then
        csAnimator:ResetTrigger(self._animName)
    end
end
