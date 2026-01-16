--[[
    斯莫奇专用逻辑：限制斯莫奇被动效果的伤害衰减底线
]]

require("buff_logic_base")

---@class BuffLogicSetSmokeyParamLimit : BuffLogicBase
_class("BuffLogicSetSmokeyParamLimit", BuffLogicBase)
BuffLogicSetSmokeyParamLimit = BuffLogicSetSmokeyParamLimit

function BuffLogicSetSmokeyParamLimit:Constructor(buffInstance, logicParam)
    self._limit = logicParam.limit
end

---@param notify NotifyAttackBase
function BuffLogicSetSmokeyParamLimit:DoLogic(notify)
    ---@type BuffComponent
    local cBuff = self._entity:BuffComponent()
    cBuff:SetBuffValue("SmokeyParamLimit", self._limit)

    --这个逻辑没有专门的表现
end

---@class BuffLogicRevertSmokeyParamLimit : BuffLogicBase
_class("BuffLogicRevertSmokeyParamLimit", BuffLogicBase)
BuffLogicRevertSmokeyParamLimit = BuffLogicRevertSmokeyParamLimit

function BuffLogicRevertSmokeyParamLimit:Constructor(buffInstance, logicParam)
end

---@param notify NotifyAttackBase
function BuffLogicRevertSmokeyParamLimit:DoLogic(notify)
    ---@type BuffComponent
    local cBuff = self._entity:BuffComponent()
    cBuff:SetBuffValue("SmokeyParamLimit", nil)

    --这个逻辑没有专门的表现
end
