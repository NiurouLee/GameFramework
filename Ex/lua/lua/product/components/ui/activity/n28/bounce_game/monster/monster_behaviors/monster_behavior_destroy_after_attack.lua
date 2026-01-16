require "monster_behavior_base"

--怪物行为组件-攻击后销毁对象
---@class MonsterBeHaviorDestroyAfterAttack : MonsterBeHaviorBase
_class("MonsterBeHaviorDestroyAfterAttack", MonsterBeHaviorBase)
MonsterBeHaviorDestroyAfterAttack = MonsterBeHaviorDestroyAfterAttack

function MonsterBeHaviorDestroyAfterAttack:Name()
    return "MonsterBeHaviorDestroyAfterAttack"
end

function MonsterBeHaviorDestroyAfterAttack:Exec()
    self.monster:SetDeadWithDuration(0) --即刻销毁
end

function MonsterBeHaviorDestroyAfterAttack:OnInit(param)
end

function MonsterBeHaviorDestroyAfterAttack:OnShow()
end

function MonsterBeHaviorDestroyAfterAttack:OnReset()
end

function MonsterBeHaviorDestroyAfterAttack:OnRelease()
end
