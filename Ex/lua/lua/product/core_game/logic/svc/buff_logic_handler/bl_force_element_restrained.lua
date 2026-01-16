--[[
    强制属性克制
]]
---@class BuffLogicSetForceElementRestrained:BuffLogicBase
_class("BuffLogicSetForceElementRestrained", BuffLogicBase)
BuffLogicSetForceElementRestrained = BuffLogicSetForceElementRestrained

function BuffLogicSetForceElementRestrained:Constructor(buffInstance, logicParam)
end

function BuffLogicSetForceElementRestrained:DoLogic(notify)
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:SetSimpleAttribute("BuffForceElementRestrained", 1)
    return true
end

-------------------------------------------------------------------------------------------

--[[
    移除格子技能免疫
]]
---@class BuffLogicRemoveForceElementRestrained:BuffLogicBase
_class("BuffLogicRemoveForceElementRestrained", BuffLogicBase)
BuffLogicRemoveForceElementRestrained = BuffLogicRemoveForceElementRestrained

function BuffLogicRemoveForceElementRestrained:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveForceElementRestrained:DoLogic(notify)
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveSimpleAttribute("BuffForceElementRestrained")
    return true
end
