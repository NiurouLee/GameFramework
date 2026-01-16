require "homelandpet_component_base"
---@class HomelandPetComponentMove:HomelandPetComponentBase
_class("HomelandPetComponentMove", HomelandPetComponentBase)
HomelandPetComponentMove = HomelandPetComponentMove
---@param pet HomelandPet
function HomelandPetComponentMove:Constructor(componentType, pet, behavior)
    HomelandPetComponentMove.super.Constructor(self, componentType, pet, behavior)
    ---@type UnityEngine.AI.NavMeshAgent
    self._navMeshAgent = self._pet:GetNavMeshAgent()
    ---@type UnityEngine.AI.NavMeshObstacle
    self._obstacle = self._pet:GetNavMeshObstacle()
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
    self._destination = nil
    self._stuckTime = 0
end

---光灵替换皮肤后，删除了旧模型，需要重新加载一下新模型上的动画组件
function HomelandPetComponentMove:ReLoadPetComponent()
    ---@type UnityEngine.AI.NavMeshAgent
    self._navMeshAgent = self._pet:GetNavMeshAgent()
    ---@type UnityEngine.AI.NavMeshObstacle
    self._obstacle = self._pet:GetNavMeshObstacle()
    ---@type UnityEngine.Animation
    self._animation = self._pet:GetAnimation()
end

function HomelandPetComponentMove:OnExcute()
    if self.state == HomelandPetComponentState.Resting then
        if not self._destination then
            return
        end
        self._naviMeshTask =
            GameGlobal.TaskManager():StartTask(
            function(TT)
                self._obstacle.enabled = false
                YIELD(TT)
                if self._pet:IsAlive() then
                    self._stuckTime = 0
                    self._navMeshAgent.enabled = true
                    self._navMeshAgent.destination = self._destination
                    if not self._animation then
                        self._animation = self._pet:GetAnimation()
                    end
                    if self._animation then
                        if self._pet:GetSpeed() >= self._pet.runSpeed then
                            self:PlayRun()
                        else
                            self:PlayWalk()
                        end
                    end
                end
            end
        )
        self.state = HomelandPetComponentState.Running
    end
end

function HomelandPetComponentMove:Update(dms)
    HomelandPetComponentMove.super.Update(self, dms)
    if self.state == HomelandPetComponentState.Running then
        if self._navMeshAgent.enabled then
            ---检查游泳模型下的动作
            self:CheckPetMotionType()
            local remainingDistance = Vector3.Distance(self._navMeshAgent.destination, self._pet:GetPosition())
            if remainingDistance <= self._navMeshAgent.stoppingDistance then
                self:Stop()
                if self._animation then
                    self:PlayStand()
                end
                self.state = HomelandPetComponentState.Success
            else
                self:_CheckStuck(self._pet:GetPosition(), dms)
            end
        end
    end
end
---@param destination Vector3
function HomelandPetComponentMove:SetTarget(destination)
    self._destination = destination
end
function HomelandPetComponentMove:Exit()
    HomelandPetComponentMove.super.Exit(self)
    self._navMeshAgent.enabled = false
    self._destination = nil
    if self._naviMeshTask then
        GameGlobal.TaskManager():KillTask(self._naviMeshTask)
        self._naviMeshTask = nil
    end
    self._obstacle.enabled = true
end
function HomelandPetComponentMove:Stop()
    self._navMeshAgent.enabled = false
    if self._naviMeshTask then
        GameGlobal.TaskManager():KillTask(self._naviMeshTask)
        self._naviMeshTask = nil
    end
    self._obstacle.enabled = true
end

--Stuck Check
function HomelandPetComponentMove:_CheckStuck(position, ms)
    if self._stuckTime == 0 then
        self._recordPosition = position
    end
    self._stuckTime = self._stuckTime + ms
    if self._stuckTime >= 1000 and self._recordPosition then
        local distance = Vector3.Distance(self._recordPosition, self._pet:GetPosition())
        if distance <= 0.1 then
            self:Stop()
            if self._animation then
                self:PlayStand()
            end
            self.state = HomelandPetComponentState.Failure
            --Log.error("Homeland Pet Stuck.", self._pet:TemplateID())
        end
        self._stuckTime = 0
    end
end

function HomelandPetComponentMove:Dispose()
    HomelandPetComponentMove.super.Dispose()
    if self._naviMeshTask then
        GameGlobal.TaskManager():KillTask(self._naviMeshTask)
        self._naviMeshTask = nil
    end
end

function HomelandPetComponentMove:PlayStand()
    --如果动作类型是游泳
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self._animation:CrossFade(HomelandPetAnimName.Float)
        self:ShowStandOrMoveInWaterEffect(true)
    else
        self._animation:CrossFade(HomelandPetAnimName.Stand)
    end
end

function HomelandPetComponentMove:PlayRun()
    --如果动作类型是游泳
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self._animation:CrossFade(HomelandPetAnimName.FastSwim)
        self:ShowStandOrMoveInWaterEffect(false)
    else
        self._animation:CrossFade(HomelandPetAnimName.Run)
    end
end

function HomelandPetComponentMove:PlayWalk()
    --如果动作类型是游泳
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self._animation:CrossFade(HomelandPetAnimName.Swim)
        self:ShowStandOrMoveInWaterEffect(false)
    else
        self._animation:CrossFade(HomelandPetAnimName.Walk)
    end
end

function HomelandPetComponentMove:CheckPetMotionType()
    --游泳层是2
    if self._navMeshAgent.areaMask ~= 4 and self._navMeshAgent.areaMask ~= 5 then
        return
    end

    self:OnGetBehaviorSwimmingPool()

    --没有游泳行为的光灵
    if not self._behaviorSwimmingPool then
        return
    end

    --没有泳池
    ---@type HomelandSwimmingPool
    local homelandSwimmingPool = self._behaviorSwimmingPool._building
    if not homelandSwimmingPool then
        return
    end

    --在泳池的外面不检测
    local roleSwimAreaCollider = homelandSwimmingPool:GetRoleSwimAreaCollider()
    if not roleSwimAreaCollider then
        return
    end
    local petPos = self._pet:GetPosition()
    local closestPoint = roleSwimAreaCollider:ClosestPoint(petPos)
    local dir = Vector3.Distance(closestPoint, petPos)
    if dir > 0 then
        return
    end

    self._behaviorSwimmingPool:CheckPetMotionType()
end

function HomelandPetComponentMove:OnGetBehaviorSwimmingPool()
    if self._behaviorSwimmingPool then
        return
    end

    ---@type HomelandPetBehavior
    local behavior = self._pet:GetPetBehavior()
    ---@type HomelandPetBehaviorSwimmingPool
    self._behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
end

function HomelandPetComponentMove:ShowStandOrMoveInWaterEffect(floatEffectVisible)
    self:OnGetBehaviorSwimmingPool()
    self._behaviorSwimmingPool:ShowFloatEffect(floatEffectVisible)
    self._behaviorSwimmingPool:ShowSwimEffect(not floatEffectVisible)
end
