--[[
    大航海 进度奖励 格子 UI数据结构
]]
---@class DSailingProgressRewardsCell:Object
_class("DSailingProgressRewardsCell", Object)
DSailingProgressRewardsCell = DSailingProgressRewardsCell
function DSailingProgressRewardsCell:Constructor()
end
function DSailingProgressRewardsCell:Refresh(data)
    self._progressNum = 0--对应累计通关数
    self._cfgID = 0--奖励配置id
    self._items = {}
    ---@type RoleAsset

    self._state = 1
    self._isSpecial = false
end
function DSailingProgressRewardsCell:CanReceive()
    return (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV)
end
function DSailingProgressRewardsCell:Unlocked()--可领取或已领取
    if (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV) or
        (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED) then
        return true
    end
    return false
end
function DSailingProgressRewardsCell:IsReceived()
    return (self._state ==  ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED)
end