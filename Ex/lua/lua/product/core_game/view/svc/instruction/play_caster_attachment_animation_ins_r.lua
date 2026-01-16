require("base_ins_r")
---@class PlayCasterAttachmentAnimationInstruction: BaseInstruction
_class("PlayCasterAttachmentAnimationInstruction", BaseInstruction)
PlayCasterAttachmentAnimationInstruction = PlayCasterAttachmentAnimationInstruction

function PlayCasterAttachmentAnimationInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
end

---@param casterEntity Entity
function PlayCasterAttachmentAnimationInstruction:DoInstruction(TT, casterEntity, phaseContext)
    casterEntity:SetAttachmentAnimationTrigger(self._animName)
end
