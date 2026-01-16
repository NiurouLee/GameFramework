---@class HomelandPetComponentPlayAnimation:HomelandPetComponentBase
_class("HomelandPetComponentPlayAnimation", HomelandPetComponentBase)
HomelandPetComponentPlayAnimation = HomelandPetComponentPlayAnimation

function HomelandPetComponentPlayAnimation:Constructor(componentType, pet, behavior)
    HomelandPetComponentPlayAnimation.super.Constructor(self, componentType, pet, behavior)
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
    ---@type HomelandPetAnimName
    self._animationName = nil
    self._fadeLength = 0.3
end

---光灵替换皮肤后，删除了旧模型，需要重新加载一下新模型上的动画组件
function HomelandPetComponentPlayAnimation:ReLoadPetComponent()
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
end

function HomelandPetComponentPlayAnimation:OnExcute()
    if self.state == HomelandPetComponentState.Resting then
        if not self._animationName then
            return
        end
        if not self._animation or self._animation == null then
            self._animation = self._pet:GetAnimation()
        end
        if self._animation then
            self._animation:CrossFade(self._animationName, self._fadeLength)
        end
        self.state = HomelandPetComponentState.Success
    end
end

---@param animationName HomelandPetAnimName
---@param position UnityEngine.Vector3
---@param rotation UnityEngine.Quaternion
function HomelandPetComponentPlayAnimation:Play(animationName)
    self._animationName = animationName
end

---播放待机动画
function HomelandPetComponentPlayAnimation:PlayStand()
    --如果动作类型是游泳
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self._animationName = HomelandPetAnimName.Float
    else
        self._animationName = HomelandPetAnimName.Stand
    end
end

function HomelandPetComponentPlayAnimation:Exit()
    HomelandPetComponentPlayAnimation.super.Exit(self)
    self._animationName = nil
end
