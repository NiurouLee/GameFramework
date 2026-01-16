require "homeland_actor_state"

---@class HomelandActorStateSwim: HomelandActorState
_class( "HomelandActorStateSwim", HomelandActorState )
HomelandActorStateSwim = HomelandActorStateSwim

function HomelandActorStateSwim:Constructor()

end

function HomelandActorStateSwim:GetType()
    return HomelandActorStateType.Swim
end

function HomelandActorStateSwim:Enter()
end

function HomelandActorStateSwim:Exit()
end

---@param deltaTimeMS number
function HomelandActorStateSwim:Update(deltaTimeMS)
end