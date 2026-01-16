---@class StateMachine : Object
---@field Id number 状态机Id
---@field dictState State[] 状态字典 k-v 状态枚举值-State
---@field curState State 当前状态
---@field coId number 协程Id
---@field update boolean 是否执行OnUpdate()
---@field stateEnumName string 状态枚举名
_class("StateMachine", Object)
StateMachine = StateMachine

function StateMachine:Constructor(stateEnumName)
    self.Id = 0
    self.dictState = {}
    self.curState = nil
    self.coId = 0
    self.stateEnumName = stateEnumName
end

---@param fsmId number
function StateMachine.CreateInstance(fsmId, stateEnumName)
    local sm = StateMachine:New(stateEnumName)
    sm.Id = fsmId
    return sm
end

---@param stateEnum number
function StateMachine:Init(stateEnum, ...)
    if not self.dictState[stateEnum] then
        Log.fatal("### StateMachine does not contain state:", stateEnum)
        return
    end
    local curState = self.dictState[stateEnum]
    if curState == nil then
        Log.fatal("### No state:", GetEnumKey(self.stateEnumName, stateEnum))
        return
    end
    self.curState = curState
    local args = {...}
    self.coId =
        GameGlobal.TaskManager():StartTask(
        function(TT)
            self:EnterState(TT, self.curState, table.unpack(args))
        end,
        self
    )
end

---@param stateEnum number
function StateMachine:ChangeState(stateEnum, ...)
    if not self.dictState then
        Log.fatal("### StateMachine dictState nil")
        return
    end
    if not self.dictState[stateEnum] then
        Log.fatal("### StateMachine does not contain state:", stateEnum)
        return
    end
    local curState = self.curState
    local nextState = self.dictState[stateEnum]
    if nextState == nil then
        Log.fatal("No next state:", stateEnum)
        return
    end
    if curState == nextState then
        Log.fatal("Already in state:", self:GetEnumKey(curState))
        return
    end
    self.curState = nextState
    local args = {...}
    local coId = self.coId
    self.coId =
        GameGlobal.TaskManager():StartTask(
        function(TT)
            while TaskHelper:GetInstance():IsAllTaskFinished({coId}) == false do
                YIELD(TT)
            end
            self:ExitState(TT, curState)
            self:EnterState(TT, self.curState, table.unpack(args))
        end,
        self
    )
end

function StateMachine:Destroy()
    if self.coId then
        GameGlobal.TaskManager():KillTask(self.coId)
        self.coId = nil
    end
    if self.dictState then
        for k, state in pairs(self.dictState) do
            state:Destroy()
            state = nil
        end
        self.dictState = nil
    end
    self.curState = nil
end

---@return State
function StateMachine:GetState(stateEnum)
    if self.dictState and self.dictState[stateEnum] then
        return self.dictState[stateEnum]
    end
    return nil
end

---@return boolean
---@param pState State
function StateMachine:AddState(pState)
    if pState == nil then
        return false
    end
    local stateEnum = pState.EnumValue
    local state = self:GetState(stateEnum)
    if state then
        Log.fatal("State already exist.", stateEnum)
        return false
    end
    self.dictState[stateEnum] = pState
    return true
end

---@return State
---获取当前状态
function StateMachine:GetCurState()
    return self.curState
end

--region Data 状态中使用的数据
function StateMachine:SetData(data)
    self._data = data
end
function StateMachine:GetData()
    return self._data
end
--endregion

---@param update boolean 是否执行OnUpdate，nil表示获取
function StateMachine:Update(update)
    if update == nil then
        return self.update
    else
        self.update = update
    end
end

function StateMachine:OnUpdate(deltaTimeMS)
    if self.curState and self:Update() then
        self.curState:OnUpdate(deltaTimeMS)
    end
end

function StateMachine:EnterState(TT, state, ...)
    if IsUnityEditor() then
        Log.warn("###[FSM] OnEnter", self:GetEnumKey(state))
    end
    state:OnEnter(TT, ...)
    self:Update(true)
end
function StateMachine:ExitState(TT, state)
    if IsUnityEditor() then
        Log.warn("###[FSM] OnExit", self:GetEnumKey(state))
    end
    self:Update(false)
    state:OnExit(TT)
end
---@param state State
function StateMachine:GetEnumKey(state)
    local key = GetEnumKey(self.stateEnumName, state.EnumValue)
    return key
end
