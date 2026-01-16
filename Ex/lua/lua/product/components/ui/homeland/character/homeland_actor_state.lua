--[[
    HomelandActorState : 家园角色状态机状态base
]]

---@class HomelandActorState: Object
_class( "HomelandActorState", Object )
HomelandActorState = HomelandActorState

---@param fsm HomelandActorStateMachine
function HomelandActorState:Constructor(fsm)
    ---@type HomelandActorStateMachine
    self._fsm = fsm
    ---@type HomelandMainCharacterController
    self._mcc = fsm:GetMainCharacterController()
    ---@type table<number, function>
    self._handlerMap = {}

    self:RegisterEventHandler()
end

function HomelandActorState:RegisterEventHandler()
    self._handlerMap[HomelandActorStateEventType.Move] = self.HandleEventMove
    self._handlerMap[HomelandActorStateEventType.Dash] = self.HandleEventDash
end

function HomelandActorState:Dispose()
end

function HomelandActorState:GetType()
    return HomelandActorStateType.NotDefined
end

function HomelandActorState:Enter()
end

function HomelandActorState:Exit()
end

---@param deltaTimeMS number
function HomelandActorState:Update(deltaTimeMS)
end

---处于活动状态的state接收外部输入执行操作
---@param eventType number 事件类型
function HomelandActorState:HandleEvent(eventType, ...)
    local handler = self._handlerMap[eventType]
    if handler then
        handler(self, ...)
    else
        Log.fatal("[HomelandActorState] handler missing:"..tostring(eventType))
    end
end

function HomelandActorState:HandleEventDash(callback)
    if self._mcc:IsForbiddenMove() then
        return
    end
    
    self._fsm:SwitchState(HomelandActorStateType.Dash, callback)
end

---@return Vector3 移动后的位置
---@param movement Vector3 移动距离
---@param moveState HomelandCharMoveType 移动状态
---@param deltaTimeMS number delta时间
function HomelandActorState:HandleEventMove(movement, moveState, deltaTimeMS)
    if moveState == HomelandCharMoveType.Idle then
        self._fsm:SwitchState(HomelandActorStateType.Idle)
    else
        self._fsm:SwitchState(HomelandActorStateType.Run, movement, moveState, deltaTimeMS)
    end
end