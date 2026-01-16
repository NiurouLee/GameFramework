---@class StateBouncePause : StateBounceBase
_class("StateBouncePause", StateBounceBase)
StateBouncePause = StateBouncePause

function StateBouncePause:OnEnter(TT, ...)
    self:Init()
end

function StateBouncePause:OnExit(TT)
end