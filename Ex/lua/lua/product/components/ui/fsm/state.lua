---@class State : Object
_class("State", Object)
State = State

---@param enumValue number
---@param fsmId number
function State:Constructor(enumValue)
    self.EnumValue = enumValue
end

function State:OnEnter(TT, ...)
end

function State:OnExit(TT)
end

function State:OnUpdate(deltaTimeMS)
end

function State:Destroy()
    self.fsm = nil
end

---根据子类类名实例化子类实例
---@param className string
---@return State
function State.CreateInstance(className, enum)
    local cls = _G[className]
    if not cls then
        Log.error("### no class : ", className)
    end
    if not cls.New then
        Log.error("### no New in class : ", className)
    end
    local s = cls:New(enum)
    return s
end

---@param fsm StateMachine
function State:SetFsm(fsm)
    self.fsm = fsm
end
---@return StateMachine
function State:GetFsm()
    return self.fsm
end

---@param enumValue number
function State:ChangeState(enumValue, ...)
    self.fsm:ChangeState(enumValue, ...)
end
