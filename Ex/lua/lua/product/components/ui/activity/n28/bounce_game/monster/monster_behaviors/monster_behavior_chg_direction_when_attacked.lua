require "monster_behavior_base"

--怪物行为组件-被攻击后改变移动方向
---@class MonsterBeHaviorChgDirectionWhenAttacked : MonsterBeHaviorBase
_class("MonsterBeHaviorChgDirectionWhenAttacked", MonsterBeHaviorBase)
MonsterBeHaviorChgDirectionWhenAttacked = MonsterBeHaviorChgDirectionWhenAttacked

function MonsterBeHaviorChgDirectionWhenAttacked:Name()
    return "MonsterBeHaviorChgDirectionWhenAttacked"
end

function MonsterBeHaviorChgDirectionWhenAttacked:Exec()
    local moveBehavior = self:GetBehavior(MonsterBeHaviorMove:Name())
    if moveBehavior then
        moveBehavior:ChgDirection()
    end
end


function MonsterBeHaviorChgDirectionWhenAttacked:OnInit(param)
end

function MonsterBeHaviorChgDirectionWhenAttacked:OnShow()
end

function MonsterBeHaviorChgDirectionWhenAttacked:OnReset()
end

function MonsterBeHaviorChgDirectionWhenAttacked:OnRelease()
end

