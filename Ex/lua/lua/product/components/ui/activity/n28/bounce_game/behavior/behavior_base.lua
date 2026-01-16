--行为组件基类
---@class BeHaviorBase : Object
_class("BeHaviorBase", Object)
BeHaviorBase = BeHaviorBase

--组件名字，用于管理组件，子类需继承
---@type string
function BeHaviorBase:Name()
    return "BeHaviorBase"
end