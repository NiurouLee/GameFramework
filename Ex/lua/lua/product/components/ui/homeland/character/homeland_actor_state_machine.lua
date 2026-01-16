--[[
    HomelandActorStateMachine : 家园角色状态机
]]

---@class HomelandActorStateMachine: Object
_class( "HomelandActorStateMachine", Object )
HomelandActorStateMachine = HomelandActorStateMachine

function HomelandActorStateMachine:Constructor()
    ---@type HomelandActorState
    self._curState = nil
    ---@type HomelandMainCharacterController
    self._mcc = nil
    ---@type table<number, HomelandActorState>
    self._stateMap = {}

    ---@type boolean
    self._stateSwitchLock = false
    ---@type number
    self._nextStateType = nil
end

---@param mcc HomelandMainCharacterController
function HomelandActorStateMachine:Init(mcc)
    self._mcc = mcc

    self:AddState(HomelandActorStateIdle:New(self))
    self:AddState(HomelandActorStateSwim:New(self))
    self:AddState(HomelandActorStateRun:New(self))
    self:AddState(HomelandActorStateDash:New(self))
    self:AddState(HomelandActorStateInteract:New(self))
    self:AddState(HomelandActorStateAxe:New(self))
    self:AddState(HomelandActorStatePick:New(self))
    self:AddState(HomelandActorStateNavigate:New(self))
end

---@param state HomelandActorState
function HomelandActorStateMachine:AddState(state)
    local type = state:GetType()
    if self._stateMap[type] then
        --Log.fatal("[HomelandActorStateMachine] 已存在相同类型state:"..tostring(type))
        return
    end

    self._stateMap[type] = state
end

function HomelandActorStateMachine:Dispose()
    for _, state in pairs(self._stateMap) do
        state:Dispose()
    end

    self._stateMap = {}
end

function HomelandActorStateMachine:Update(deltaTimeMS)
    self._stateSwitchLock = true
    if self._curState then
        self._curState:Update(deltaTimeMS)
    end
    self._stateSwitchLock = false
    self:CheckSwitchState()
end

---@return HomelandActorStateType
function HomelandActorStateMachine:CurrenStateType()
    if self._curState then
        return self._curState:GetType()
    end
end

---@return HomelandMainCharacterController
function HomelandActorStateMachine:GetMainCharacterController()
    return self._mcc
end

---@param targetState number 目标状态
function HomelandActorStateMachine:SwitchState(targetState, ...)
    if self._curState and self._curState:GetType() == targetState then
        return
    end
    
    self._nextStateType = targetState
    self._nextStateParam = table.pack(...)
    if not self._stateSwitchLock then
        self:CheckSwitchState()
    end
end

---同步切换state，切换后可能会立刻再次切换，需注意避免死循环
function HomelandActorStateMachine:CheckSwitchState()
    self._stateSwitchLock = true
    while self._nextStateType do
        local nextState = self._stateMap[self._nextStateType]
        self._nextStateType = nil
        if not nextState then
            --Log.fatal("[HomelandActorStateMachine] 目标state type不存在:"..tostring(self._nextStateType))
            break
        end

        if self._curState then
            self._curState:Exit()
            --Log.fatal("[HomelandActorStateMachine] exit state:"..HomelandActorStateType.TypeToName(self._curState:GetType()))
        end

        self._curState = nextState
        self._curState:Enter(table.unpack(self._nextStateParam))
        --Log.fatal("[HomelandActorStateMachine] enter state:"..HomelandActorStateType.TypeToName(self._curState:GetType()))
    end
    self._stateSwitchLock = false
end

---@param eventType number 事件类型
function HomelandActorStateMachine:HandleEvent(eventType, ...)
    if self._curState then
        self._curState:HandleEvent(eventType, ...)
    end
end