--[[------------------------------------------------------------------------------------------
    MonsterAttackRangeComponent : 怪物攻击移动范围预览格子组件 
    目前包括 箭头(移动范围) 半透mask(攻击范围) 两种 半透mask未来可以支持每种属性一种颜色
]] --------------------------------------------------------------------------------------------





_class("MonsterAttackRangeComponent", Object)
---@class MonsterAttackRangeComponent: Object
MonsterAttackRangeComponent=MonsterAttackRangeComponent


function MonsterAttackRangeComponent:Constructor(entityConfigID)
    self._entityConfigID = entityConfigID
    self._bUse = false
end

function MonsterAttackRangeComponent:GetEntityConfigID()
    return self._entityConfigID
end

function MonsterAttackRangeComponent:IsUse()
    return self._bUse
end

function MonsterAttackRangeComponent:SetUseState(state)
    self._bUse = state
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] function Entity:MonsterAttackRange()
    return self:GetComponent(self.WEComponentsEnum.MonsterAttackRange)
end

function Entity:HasMonsterAttackRange()
    return self:HasComponent(self.WEComponentsEnum.MonsterAttackRange)
end

function Entity:AddMonsterAttackRange(entityConfigID)
    local index = self.WEComponentsEnum.MonsterAttackRange
    local component = MonsterAttackRangeComponent:New(entityConfigID)
    self:AddComponent(index, component)
end

function Entity:RemoveMonsterAttackRange()
    if self:HasMonsterAttackRange() then
        self:RemoveComponent(self.WEComponentsEnum.MonsterAttackRange)
    end
end
