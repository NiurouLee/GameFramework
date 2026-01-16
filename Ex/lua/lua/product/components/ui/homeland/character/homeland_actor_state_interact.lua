require "homeland_actor_state"

---@class HomelandActorStateInteract: HomelandActorState
_class( "HomelandActorStateInteract", HomelandActorState )
HomelandActorStateInteract = HomelandActorStateInteract

function HomelandActorStateInteract:Constructor()

end

function HomelandActorStateInteract:GetType()
    return HomelandActorStateType.Interact
end

function HomelandActorStateInteract:HandleEventDash()
    if self._mcc:IsInteracting() then
        self._mcc._interactContext.InterruptInteraction = true
    end
end

---@return Vector3 移动后的位置
---@param movement Vector3 移动距离
---@param deltaTimeMS number delta时间
function HomelandActorStateInteract:HandleEventMove()
    if self._mcc:IsInteracting() then
        self._mcc._interactContext.InterruptInteraction = true
    end 
end