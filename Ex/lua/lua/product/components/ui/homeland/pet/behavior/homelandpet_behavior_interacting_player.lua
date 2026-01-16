require "homelandpet_behavior_base"

---@class HomelandPetBehaviorInteractingPlayer:HomelandPetBehaviorBase
_class("HomelandPetBehaviorInteractingPlayer", HomelandPetBehaviorBase)
HomelandPetBehaviorInteractingPlayer = HomelandPetBehaviorInteractingPlayer

function HomelandPetBehaviorInteractingPlayer:Constructor(behaviorType, pet)
    ---@type HomelandPetComponentPlayAnimation
    self._animationComponent = self:GetComponent(HomelandPetComponentType.Animation)
    ---@type HomelandPetComponentBubble
    self._bubbleComponent = self:GetComponent(HomelandPetComponentType.Bubble)
end

function HomelandPetBehaviorInteractingPlayer:Enter()
    HomelandPetBehaviorInteractingPlayer.super.Enter(self)

    -- 如果动作类型是游泳，欢迎动作是漂浮
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self._animationComponent:Play(HomelandPetAnimName.Float)
    else
        self._animationComponent:Play(HomelandPetAnimName.Greet)
    end

    self._bubbleComponent:Show()
end
--
function HomelandPetBehaviorInteractingPlayer:ShowBubble(bubble)
    local time = self._bubbleComponent:ShowBubble(bubble)
    return time
end
