--玩家行为组件基类
---@class BouncePlayerBeHaviorBase : BeHaviorBase
_class("BouncePlayerBeHaviorBase", BeHaviorBase)
BouncePlayerBeHaviorBase = BouncePlayerBeHaviorBase

function BouncePlayerBeHaviorBase:SetPlayer(player)
   ---@type BouncePlayer
   self.player = player
end


function BouncePlayerBeHaviorBase:GetBehavior(behaviorName)
   return self.player:GetBehavior(behaviorName)
end

function BouncePlayerBeHaviorBase:Release()
   self:OnRelease()
end

function BouncePlayerBeHaviorBase:OnRelease()
end
