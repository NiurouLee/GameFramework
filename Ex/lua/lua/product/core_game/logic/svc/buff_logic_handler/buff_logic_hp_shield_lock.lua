--[[
    血量护盾buff的增强buff，血量护盾消耗完之后如果有此buff，则继续免疫一切伤害，依赖于血量护盾，单配无效，诺尔突破5阶被动技
]]
---@class BuffLogicAddHPShieldLock:BuffLogicBase
_class("BuffLogicAddHPShieldLock", BuffLogicBase)
BuffLogicAddHPShieldLock = BuffLogicAddHPShieldLock

function BuffLogicAddHPShieldLock:Constructor()
end

function BuffLogicAddHPShieldLock:DoLogic(notify)
    ---@type BuffComponent
    local buff = self._entity:BuffComponent()
    buff:SetBuffValue("HPShieldLockHP", true)
end

--------------------------------------------------------------

--[[
    移除
]]
---@class BuffLogicRemoveHPShieldLock:BuffLogicBase
_class("BuffLogicRemoveHPShieldLock", BuffLogicBase)
BuffLogicRemoveHPShieldLock = BuffLogicRemoveHPShieldLock

function BuffLogicRemoveHPShieldLock:Constructor()
end

function BuffLogicRemoveHPShieldLock:DoLogic(notify)
    ---@type BuffComponent
    local buff = self._entity:BuffComponent()
    buff:SetBuffValue("HPShieldLockHP", nil)
end
