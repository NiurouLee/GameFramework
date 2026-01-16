--[[
    设置过载状态
]]

_class("BuffLogicSetOverloadState", BuffLogicBase)
---@class BuffLogicSetOverloadState:BuffLogicBase
BuffLogicSetOverloadState = BuffLogicSetOverloadState
---
function BuffLogicSetOverloadState:Constructor(buffInstance, logicParam)
end
---
function BuffLogicSetOverloadState:DoLogic(notify)

    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffOverloadState", 1)
    return true
end


--[[
    取消设置过载状态
]]

_class("BuffLogicResetOverloadState", BuffLogicBase)
---@class BuffLogicResetOverloadState:BuffLogicBase
BuffLogicResetOverloadState = BuffLogicResetOverloadState
---
function BuffLogicResetOverloadState:Constructor(buffInstance, logicParam)
end
---
function BuffLogicResetOverloadState:DoLogic(notify)

    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffOverloadState", 0)
    return true
end