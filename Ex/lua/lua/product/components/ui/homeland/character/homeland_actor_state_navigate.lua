require "homeland_actor_state"

---@class HomelandActorStateNavigate: HomelandActorState
_class( "HomelandActorStateNavigate", HomelandActorState )
HomelandActorStateNavigate = HomelandActorStateNavigate

function HomelandActorStateNavigate:Constructor()
    ---@type number 自动寻路停止半径
    self._destinationRadius = 0.02

    ---@type boolean 是否是按下移动按键同时进入的导航状态，是的话，需要取消移动后再次移动，才可以打断导航
    self._moveHold = false
    ---@type Vector3
    self._movement = nil
end

function HomelandActorStateNavigate:GetType()
    return HomelandActorStateType.Navigate
end

function HomelandActorStateNavigate:Enter(pos, holdMove)
    self._moveHold = holdMove

    local forward = pos - self._mcc:Position()
    local distance = forward:Magnitude()
    if distance <= self._destinationRadius then
        return
    end

    self._mcc:SetForward(forward)
    self._mcc._navMeshAgent:SetDestination(pos)
    self._mcc._navMeshAgent.isStopped = false

    self._mcc:SetAnimatorBool("Run", true)
end

function HomelandActorStateNavigate:Exit()
    self._mcc:SetAnimatorBool("Run", false)
end

---@param deltaTimeMS number
function HomelandActorStateNavigate:Update()
    self._mcc:UpdateFollowCamPos()
    if self._mcc._navMeshAgent.remainingDistance <= self._destinationRadius then
        self._mcc._navMeshAgent.isStopped = true
        self._fsm:SwitchState(HomelandActorStateType.Idle)
    end
    if not self._movement then
        self._moveHold = false
    end
    self._movement = nil
end

---@return Vector3 移动后的位置
---@param movement Vector3 移动距离
---@param deltaTimeMS number delta时间
function HomelandActorStateNavigate:HandleEventMove(movement, moveState, deltaTimeMS)
    self._movement = movement
    if not self._moveHold then
        HomelandActorStateNavigate.super.HandleEventMove(self, movement, moveState, deltaTimeMS)
    end
end