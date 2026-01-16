---@class StateN24ShopDrawCard : StateN24ShopBase
_class("StateN24ShopDrawCard", StateN24ShopBase)
StateN24ShopDrawCard = StateN24ShopDrawCard

function StateN24ShopDrawCard:OnEnter(TT, ...)
    self:Init()
    self._uiModule:LockAchievementFinishPanel(true)
    self.lockKey = "UIN24ShopDoDraw"
    GameGlobal.UIStateManager():Lock(self.lockKey)
    local lotteryType = table.unpack({...})
    self:DoDraw(TT, lotteryType)
end

function StateN24ShopDrawCard:OnExit(TT)
    GameGlobal.UIStateManager():UnLock(self.lockKey)
end

function StateN24ShopDrawCard:DoDraw(TT, lotteryType)
    local res = AsyncRequestRes:New()
    local getRewards, isOpenNew = self:_SendDrawReq(TT, res, self:CurPageIndex(), lotteryType) --【消息】抽奖；isOpenNew是否开启新奖池
    if N24Data.CheckCode(res) then --res:GetSucc()
        -- self.ui:_RecordRewardsInfo(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
        self.ui:_RecordRewardsInfo(getRewards, lotteryType, nil, isOpenNew, nil) --缓存获取奖励
        self:ChangeState(StateN24Shop.SpineAnim, lotteryType)
    else
        self:ChangeState(StateN24Shop.Init)
    end
end
function StateN24ShopDrawCard:_SendDrawReq(TT, res, boxIndex, lotteryType)
    local cLottery = self.data:GetComponentShop()
    if cLottery then
        return cLottery:HandleLottery(TT, res, boxIndex, lotteryType)
    end
    res:SetSucc(false)
    return nil
end
