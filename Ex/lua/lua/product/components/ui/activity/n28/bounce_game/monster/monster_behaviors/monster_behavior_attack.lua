require "monster_behavior_base"

--怪物行为组件-攻击
---@class MonsterBeHaviorAttack : MonsterBeHaviorBase
_class("MonsterBeHaviorAttack", MonsterBeHaviorBase)
MonsterBeHaviorAttack = MonsterBeHaviorAttack

function MonsterBeHaviorAttack:Name()
    return "MonsterBeHaviorAttack"
end

function MonsterBeHaviorAttack:OnInit(param)
    self.attack = param.Attack
end

function MonsterBeHaviorAttack:Exec()
    --攻击后自动销毁
    local behaviorDestory = self:GetBehavior(MonsterBeHaviorDestroyAfterAttack:Name())
    if behaviorDestory then
        behaviorDestory:Exec()
    end
end

function MonsterBeHaviorAttack:OnShow()
end

function MonsterBeHaviorAttack:OnReset()
end

function MonsterBeHaviorAttack:OnRelease()
end
