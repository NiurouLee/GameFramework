--[[
    元素伤害减伤
]]
require "buff_logic_base"
_class("BuffLogicElementHarmReduce", BuffLogicBase)
---@class BuffLogicElementHarmReduce:BuffLogicBase
BuffLogicElementHarmReduce = BuffLogicElementHarmReduce

function BuffLogicElementHarmReduce:Constructor(buffInstance, logicParam)
    --减伤的元素列表
    self._element = logicParam.element
    self._rate = logicParam.rate
end

function BuffLogicElementHarmReduce:DoLogic(notify)
    if not self._entity:HasMonsterID() then
        return
    end
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    if self._rate==0 then --系数为0按元素伤害免疫处理
        cpt:SetSimpleAttribute("BuffElementImmunity",self._element)
        self._buffInstance._elementHarmReduceRate = self._rate
    else
        cpt:SetSimpleAttribute("BuffElementHarmReduce", {self._element,self._rate})
    end
end

-------------------------------------------------------------------------------------------

--[[
    移除元素伤害减伤
]]
_class("BuffLogicRemoveElementHarmReduce", BuffLogicBase)
BuffLogicRemoveElementHarmReduce = BuffLogicRemoveElementHarmReduce

function BuffLogicRemoveElementHarmReduce:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveElementHarmReduce:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    local rate = self._buffInstance._elementHarmReduceRate or 1
    if rate==0 then
        cpt:RemoveSimpleAttribute("BuffElementImmunity")
    else
        cpt:RemoveSimpleAttribute("BuffElementHarmReduce")
    end
end
