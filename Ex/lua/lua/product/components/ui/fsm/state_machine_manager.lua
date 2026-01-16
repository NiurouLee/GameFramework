---@class StateMachineManager : Singleton
---@field stateEnumName string 状态
_class("StateMachineManager", Singleton)
StateMachineManager = StateMachineManager

---@type number
local idSeedStateMachine = 1

function StateMachineManager:Constructor()
    ---@type StateMachine[] k-v:number-StateMachine
    self._stateMachineDict = {}
end

---创建状态机
---@return StateMachine
---@param enumName string 状态枚举名
---@param tStateEnum Object 状态枚举表
function StateMachineManager:CreateStateMachine(enumName, tStateEnum)
    local id = idSeedStateMachine
    idSeedStateMachine = idSeedStateMachine + 1
    local sm = StateMachine.CreateInstance(id, enumName)
    for key, enum in pairs(tStateEnum) do
        local name = enumName .. key
        local state = State.CreateInstance(name, enum)
        if state then
            state:SetFsm(sm)
            sm:AddState(state)
        else
            Log.fatal("### no class named :", name)
        end
    end
    self._stateMachineDict[id] = sm
    return sm
end

function StateMachineManager:DestroyStateMachine(fsmId)
    ---@type StateMachine
    local sm = nil
    if self._stateMachineDict and self._stateMachineDict[fsmId] then
        sm = self._stateMachineDict[fsmId]
        self._stateMachineDict[fsmId] = nil
    end
    if sm then
        sm:Destroy()
        sm = nil
    end
end

function StateMachineManager:AddState(fsmId, state)
    local sm = self:GetStateMachine(fsmId)
    if sm then
        sm:AddState(state)
    end
end

---@return StateMachine
function StateMachineManager:GetStateMachine(fsmId)
    if self._stateMachineDict and self._stateMachineDict[fsmId] then
        local sm = self._stateMachineDict[fsmId]
        return sm
    end
    return nil
end

--- 初始化状态机
---@param fsmId number 状态机Id
---@param stateId number 状态枚举
function StateMachineManager:Init(fsmId, stateId)
    local sm = self:GetStateMachine(fsmId)
    if sm then
        sm:Init(stateId)
    end
end

--- 更改状态
---@param fsmId number 状态机Id
---@param stateId number 状态枚举
function StateMachineManager:ChangeState(fsmId, stateId)
    local sm = self:GetStateMachine(fsmId)
    if sm then
        sm:ChangeState(stateId)
    end
end
