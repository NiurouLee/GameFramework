--[[
    修改光灵副属性参数
]]

_class("BuffLogicChangeSecondaryParam", BuffLogicBase)
---@class BuffLogicChangeSecondaryParam:BuffLogicBase
BuffLogicChangeSecondaryParam = BuffLogicChangeSecondaryParam

function BuffLogicChangeSecondaryParam:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
end

function BuffLogicChangeSecondaryParam:DoLogic()
    local e = self._buffInstance:Entity()
    self._buffLogicService:ChangeSecondaryAttackParam(e, self._buffInstance:BuffSeq(), self._addValue)
end

--取消光灵副属性系数修改
_class("BuffLogicRemoveSecondaryParam", BuffLogicBase)
---@class BuffLogicRemoveSecondaryParam:BuffLogicBase
BuffLogicRemoveSecondaryParam = BuffLogicRemoveSecondaryParam

function BuffLogicRemoveSecondaryParam:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSecondaryParam:DoLogic()
    local e = self._buffInstance:Entity()
    self._buffLogicService:RemoveSecondaryAttackParam(e, self._buffInstance:BuffSeq())
end
