--region 以下枚举都和策划配置对应，改之前和策划说下用法

---@class LotteryShopState
local LotteryShopState = 
{
    Lottery = 1, -- 抽奖
    Idle = 2,  -- 待机
}
_enum("LotteryShopState", LotteryShopState)
LotteryShopState = LotteryShopState

 -- ECampaignLotteryType 单抽还是十连枚举已有定义，但是从0开始，用的时候要加1

 ---@class N33LotterySpineState
local N33LotterySpineState = 
{
    ClawDown = 1, -- 钩爪下降
    ClawUp = 2, -- 钩爪上升
}
_enum("N33LotterySpineState", N33LotterySpineState)
N33LotterySpineState = N33LotterySpineState

---@class LotteryRewardState
local LotteryRewardState = 
{
    NotOpen = 1, -- 奖池未解锁
    HasBigReward = 2, -- 大奖还在
    NoBigReward = 3, -- 大奖没了，但是还有奖励
    NoReward = 4, -- 奖励都没了，抽空
}
_enum("LotteryRewardState", LotteryRewardState)
LotteryRewardState = LotteryRewardState

-- ---@class MaxRewardLevel
-- local _MaxRewardLevel = 
-- {
--     Small = 1, -- 无标记
--     Normal = 2, -- 小奖
--     Big = 3, -- 大奖
-- }
-- _enum("MaxRewardLevel", _MaxRewardLevel)
-- MaxRewardLevel = MaxRewardLevel

-- ECampaignLRType 有了，但是从0开始，需要+1

--endregion

---@class UIN33ShopTipsComponent : Object
_class("UIN33ShopTipsComponent", Object)
UIN33ShopTipsComponent = UIN33ShopTipsComponent

function UIN33ShopTipsComponent:Constructor(objTipsBg, textTips, rawImageLoader)
    self._objTipsBg = objTipsBg
    self._textTips = textTips
    self._rawImageLoader = rawImageLoader
end

---@public
---改变UI
function UIN33ShopTipsComponent:FillUi(lotteryShopState, hundreds, tens, ones)
    local id = self:_GetConfigID(lotteryShopState, hundreds, tens, ones)
    local config = Cfg.cfg_n33_shop_tips[id]
    if not config then
        return
    end
    local maxIndex = #config.TipsText
    local index = math.random(1, maxIndex)
    self._textTips:SetText(StringTable.Get(config.TipsText[index]))
    self._rawImageLoader:LoadImage(config.FacePic[index]) 
end

---@private
---改变UI
---@param lotteryShopState LotteryShopState 千位数，是抽奖还是待机
---@param hundreds number 百位数，抽奖时代表单抽还是十连抽，待机时表示奖池ID
---@param tens number 抽奖时，钩子下落0，上升无标记1，小奖2，大奖3，待机LotteryRewardState
---@param ones number 抽奖时，钩子下落0，钩子上升无标记1，小奖2，大奖3，待机时0
function UIN33ShopTipsComponent:_GetConfigID(lotteryShopState, hundreds, tens, ones)
    if lotteryShopState ~= LotteryShopState.Lottery and lotteryShopState ~= LotteryShopState.Idle then
        return -1
    end
    if lotteryShopState == LotteryShopState.Lottery then
        hundreds = hundreds + 1
        if tens == N33LotterySpineState.ClawUp then
            ones = ones + 1
        end
    end
    return lotteryShopState * 1000 + hundreds * 100 + tens * 10 + ones
end