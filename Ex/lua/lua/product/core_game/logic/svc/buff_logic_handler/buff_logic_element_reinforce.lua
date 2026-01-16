--[[
    属性强化buff——挂了这个buff的实体，仅受到来源为克制属性的伤害，来源为被克属性的伤害会转为恢复HP
]]
---@class BuffLogicElementReinforce:BuffLogicBase
_class("BuffLogicElementReinforce", BuffLogicBase)
BuffLogicElementReinforce = BuffLogicElementReinforce

function BuffLogicElementReinforce:DoLogic()
    local e = self._buffInstance:Entity()
    if not e:HasMonsterID() then --只有怪才会挂该buff
        return
    end
    local logicParam = self:GetLogicParam()
    local a = logicParam.a or 1
    local b = logicParam.b or 0
    local c = logicParam.c or 1
    local cBuff = e:BuffComponent()
    if cBuff then
        cBuff:SetBuffValue("ElementReinforceFactorA", a)
        cBuff:SetBuffValue("ElementReinforceFactorB", b)
        cBuff:SetBuffValue("ElementReinforceFactorC", c)
    end
    if e:HasAttributes() then
        e:Attributes():SetSimpleAttribute("ElementReinforce", true)
    end
    return true
end

---------------------------------------------------------------------------

---@class BuffLogicRemoveElementReinforce:BuffLogicBase
_class("BuffLogicRemoveElementReinforce", BuffLogicBase)
BuffLogicRemoveElementReinforce = BuffLogicRemoveElementReinforce

function BuffLogicRemoveElementReinforce:DoLogic()
    local e = self._buffInstance:Entity()
    if not e:HasMonsterID() then --只有怪才会挂该buff
        return
    end
    local cBuff = e:BuffComponent()
    if cBuff then
        cBuff:SetBuffValue("ElementReinforceFactorA", nil)
        cBuff:SetBuffValue("ElementReinforceFactorB", nil)
        cBuff:SetBuffValue("ElementReinforceFactorC", nil)
    end
    if e:HasAttributes() then
        e:Attributes():SetSimpleAttribute("ElementReinforce", false)
    end
    return true
end
