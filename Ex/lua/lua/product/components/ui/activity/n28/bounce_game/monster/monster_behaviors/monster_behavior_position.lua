require "monster_behavior_base"

--怪物行为组件-位置
---@class MonsterBeHaviorPosition : MonsterBeHaviorBase
_class("MonsterBeHaviorPosition", MonsterBeHaviorBase)
MonsterBeHaviorPosition = MonsterBeHaviorPosition

function MonsterBeHaviorPosition:Name()
    return "MonsterBeHaviorPosition"
end

---@param initPosition number[] 
function MonsterBeHaviorPosition:SetData(initPosition)
    self._initPosition =  Vector2:New()
    self._initPosition.x = initPosition[1]
    self._initPosition.y = initPosition[2]
    self:SetPosition(self._initPosition)
end

---@return Vector2
function MonsterBeHaviorPosition:GetPosition()
    return self._curPostion
end

--返回新的位置
---@param poistion Vector2
function MonsterBeHaviorPosition:SetPosition(poistion)
    self._curPostion = poistion
    self:GetBehavior(MonsterBeHaviorView:Name()):SetPosition(poistion)
end


function MonsterBeHaviorPosition:ResetPosition()
    self:SetPosition(self._curPostion)
end

function MonsterBeHaviorPosition:OnInit(param)
end

function MonsterBeHaviorPosition:OnShow()
end

function MonsterBeHaviorPosition:OnReset()
end

function MonsterBeHaviorPosition:OnRelease()
end
