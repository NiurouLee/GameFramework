---@class TaskToken:Object
_class("TaskToken", Object)
TaskToken = TaskToken

---@private
function TaskToken:Constructor()
end

---@class StoppableTaskToken:TaskToken
_class("StoppableTaskToken", TaskToken)
StoppableTaskToken = StoppableTaskToken

---@private
function StoppableTaskToken:Constructor()
end