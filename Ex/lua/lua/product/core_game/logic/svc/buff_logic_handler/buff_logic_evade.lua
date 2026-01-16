--[[
    闪避buff逻辑
]]
---@class BuffLogicAddEvade:BuffLogicBase
_class("BuffLogicAddEvade", BuffLogicBase)
BuffLogicAddEvade = BuffLogicAddEvade

function BuffLogicAddEvade:Constructor(buffInstance, logicParam)
    self._evadeRate = logicParam["evadeRate"]
end

function BuffLogicAddEvade:DoLogic(notify)
    if self._evadeRate <= 0 then
        return
    end

    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:Modify("Evade", self._evadeRate, self:GetBuffSeq())
end

-------------------------------------------------------------------------------------------

--[[
    移除闪避
]]
_class("BuffLogicRemoveEvade", BuffLogicBase)
BuffLogicRemoveEvade = BuffLogicRemoveEvade

function BuffLogicRemoveEvade:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveEvade:DoLogic(notify)
    ---@type AttributesComponent
    local cpt = self._buffInstance:Entity():Attributes()
    cpt:RemoveModify("Evade", self:GetBuffSeq())
end
