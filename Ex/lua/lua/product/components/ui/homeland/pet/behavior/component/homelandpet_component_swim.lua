require "homelandpet_component_base"
---@class HomelandPetComponentSwim:HomelandPetComponentBase
_class("HomelandPetComponentSwim", HomelandPetComponentBase)
HomelandPetComponentSwim = HomelandPetComponentSwim

--- @class HomelandPetSwimBehaviorType
local HomelandPetSwimBehaviorType = {
    Float = 1, --漂浮
    Swim = 2, --游泳
    FastSwim = 3, --快速游泳
    MAX = 3 --MAX
}
_enum("HomelandPetSwimBehaviorType", HomelandPetSwimBehaviorType)

function HomelandPetComponentSwim:Constructor(componentType, pet, behavior)
    HomelandPetComponentSwim.super.Constructor(self, componentType, pet, behavior)
    ---@type HomeBuilding 当前交互的建筑
    self._building = nil
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
end

---光灵替换皮肤后，删除了旧模型，需要重新加载一下新模型上的动画组件
function HomelandPetComponentSwim:ReLoadPetComponent()
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
end

function HomelandPetComponentSwim:Init()
    ---@type HomelandPetComponentMove
    self._moveComponent = self._behavior:GetComponent(HomelandPetComponentType.Move)
end

---@param building HomelandSwimmingPool
function HomelandPetComponentSwim:Play(building)
    self._building = building
    self.state = HomelandPetComponentState.Running
    self._finishTime = GameGlobal:GetInstance():GetCurrentTime()
end

function HomelandPetComponentSwim:OnExcute()
    if self.state == HomelandPetComponentState.Resting then
        if not self._animation then
            self._animation = self._pet:GetAnimation()
        end
    end
end

function HomelandPetComponentSwim:Update(dms)
    HomelandPetComponentSwim.super.Update(self, dms)
    if self.state == HomelandPetComponentState.Running then
        if not self._building then
            self:Exit()
        end

        --需要判断不在交互中

        local swimFinish =
            (self._swimBehaviorType == HomelandPetSwimBehaviorType.Swim or
            self._swimBehaviorType == HomelandPetSwimBehaviorType.FastSwim) and
            self._moveComponent.state == HomelandPetComponentState.Success
        local timeFinish = GameGlobal:GetInstance():GetCurrentTime() >= self._finishTime

        --游到了终点 or 时间到了
        if swimFinish or timeFinish then
            self:NextBehavior()
        end
    end
end

function HomelandPetComponentSwim:NextBehavior()
    --站立 游泳 2选1
    self._swimBehaviorType = math.random(1, HomelandPetSwimBehaviorType.Swim)
    -- local time = math.random(7, 10) * 1000
    local time = 10 * 1000
    self._finishTime = GameGlobal:GetInstance():GetCurrentTime() + time

    self._moveComponent:Stop()
    self._moveComponent:Resting()
    if self._swimBehaviorType == HomelandPetSwimBehaviorType.Float then
        self:OnFloat()
    elseif self._swimBehaviorType == HomelandPetSwimBehaviorType.Swim then
        self:OnSwim()
    -- elseif self._swimBehaviorType == HomelandPetSwimBehaviorType.FastSwim then
    --     self:OnFastSwim()
    end
end

function HomelandPetComponentSwim:OnFloat()
    -- --需要这个move组件是完成状态，否则会break就跳过下一个游泳行为
    -- self._moveComponent:Finish()
end

function HomelandPetComponentSwim:OnSwim()
    local targetPos = self._building:GetSwimRandomPos()
    self._moveComponent:SetTarget(targetPos)
    self._pet:SetSpeed(self._pet.walkSpeed)
end
function HomelandPetComponentSwim:OnFastSwim()
    local targetPos = self._building:GetSwimRandomPos()
    self._moveComponent:SetTarget(targetPos)
    self._pet:SetSpeed(self._pet.runSpeed)
end

function HomelandPetComponentSwim:Exit()
    HomelandPetComponentSwim.super.Exit(self)
    self.state = HomelandPetComponentState.Success
    self._pet:SetSpeed(self._pet.walkSpeed)
    self._building = nil
end

function HomelandPetComponentSwim:Dispose()
    HomelandPetComponentSwim.super.Dispose()
    self._pet:SetSpeed(self._pet.walkSpeed)
    self._building = nil
end
