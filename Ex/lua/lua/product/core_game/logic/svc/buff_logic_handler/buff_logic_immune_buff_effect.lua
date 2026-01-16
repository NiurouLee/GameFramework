--[[
    免疫某些buff效果
]]
---@class BuffLogicImmuneBuffEffect:BuffLogicBase
_class("BuffLogicImmuneBuffEffect", BuffLogicBase)
BuffLogicImmuneBuffEffect = BuffLogicImmuneBuffEffect

function BuffLogicImmuneBuffEffect:Constructor(buffInstance, logicParam)
    self._effectList = logicParam.effectList

    self._keyImmuneBuffEffect = "ImmuneBuffEffect"
end

function BuffLogicImmuneBuffEffect:DoLogic(notify)
    if not self._effectList then
        return
    end
    local e = self._buffInstance:Entity()
    local cBuff = e:BuffComponent()
    local arr = cBuff:GetBuffValue(self._keyImmuneBuffEffect) or {}
    for i, v in ipairs(self._effectList) do
        if not table.icontains(arr, v) then
            table.insert(arr, v)
        end
    end
    cBuff:SetBuffValue(self._keyImmuneBuffEffect, arr)
end

--[[
    移除免疫buff效果
]]
---@class BuffLogicRemoveImmuneBuffEffect:BuffLogicBase
_class("BuffLogicRemoveImmuneBuffEffect", BuffLogicBase)
BuffLogicRemoveImmuneBuffEffect = BuffLogicRemoveImmuneBuffEffect

function BuffLogicRemoveImmuneBuffEffect:Constructor(buffInstance, logicParam)
    self._effectList = logicParam.effectList or {}

    self._keyImmuneBuffEffect = "ImmuneBuffEffect"
end

function BuffLogicRemoveImmuneBuffEffect:DoLogic(notify)
    local e = self._buffInstance:Entity()
    local cBuff = e:BuffComponent()
    local arr = cBuff:GetBuffValue(self._keyImmuneBuffEffect)
    if not arr then
        return
    end
    local arrNew = {}
    for i, v in ipairs(arr) do
        if not table.icontains(self._effectList, v) then
            table.insert(arrNew, v)
        end
    end
    cBuff:SetBuffValue(self._keyImmuneBuffEffect, arrNew)
end
