--[[
    处理好友的拜访数据
]]
---@class UIHomeVisitInfo:Object
_class("UIHomeVisitInfo", Object)
UIHomeVisitInfo = UIHomeVisitInfo

function UIHomeVisitInfo:Constructor(data)
    ---@type FriendHomelandInfo 拜访好友简单数据
    self._data = data
end

function UIHomeVisitInfo:Data()
    return self._data
end

--是否有有效的可领取的礼品
function UIHomeVisitInfo:HasGift()
    ---@type table<number, SpecItemAsset>
    local gifts = self._data.item_list
    if next(gifts) then
        for key, gift in pairs(gifts) do
            if gift.count > 0 then
                return true
            end
        end
    end
    return false
end
