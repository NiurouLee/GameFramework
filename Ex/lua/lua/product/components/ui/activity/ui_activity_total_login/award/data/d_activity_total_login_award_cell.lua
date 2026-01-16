--[[
    活动 累计登录 格子 UI数据结构
]]
---@class DActivityTotalLoginAwardCell
_class("DActivityTotalLoginAwardCell", Object)
---@class DActivityTotalLoginAwardCell:Object
function DActivityTotalLoginAwardCell:Constructor()
end
function DActivityTotalLoginAwardCell:Refresh(data)
    self._dayNum = 0
    self._items = {}
    ---@type RoleAsset

    self._state = 1
    self._isSpecial = false
end
---@public 
---商品唯一id
function DActivityTotalLoginAwardCell:GetGoodsId()
    return self.goodsId
end
function DActivityTotalLoginAwardCell:CanReceive()
    return (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV)
end
function DActivityTotalLoginAwardCell:Unlocked()--可领取或已领取
    if (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV) or
        (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED) then
        return true
    end
    return false
end