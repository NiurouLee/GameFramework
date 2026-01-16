---@class StateN29ShopDrawCard : StateN29ShopBase
_class("StateN29ShopDrawCard", StateN29ShopBase)
StateN29ShopDrawCard = StateN29ShopDrawCard

function StateN29ShopDrawCard:OnEnter(TT, ...)
    self:Init()
    self._uiModule:LockAchievementFinishPanel(true)
    self.lockKey = "UIN29ShopDoDraw"
    GameGlobal.UIStateManager():Lock(self.lockKey)
    local lotteryType = table.unpack({...})
    self:DoDraw(TT, lotteryType)
end

function StateN29ShopDrawCard:OnExit(TT)
    GameGlobal.UIStateManager():UnLock(self.lockKey)
end

function StateN29ShopDrawCard:DoDraw(TT, lotteryType)
    local res = AsyncRequestRes:New()
    local getRewards, isOpenNew = self:_SendDrawReq(TT, res, self:CurPageIndex(), lotteryType) --【消息】抽奖；isOpenNew是否开启新奖池
    if UIN29ShopData.CheckCode(res) then --res:GetSucc()
        -- self.ui:_RecordRewardsInfo(getRewards, lotteryType, curBoxHasRest, isOpenNew, canDrawOnceMore)
        self.ui:_RecordRewardsInfo(getRewards, lotteryType, nil, isOpenNew, nil) --缓存获取奖励
        self:ChangeState(StateN29Shop.SpineAnim, lotteryType)
    else
        self:ChangeState(StateN29Shop.Init)
    end
end
function StateN29ShopDrawCard:_SendDrawReq(TT, res, boxIndex, lotteryType)
    local cLottery = self.data:GetComponentShop()
    if cLottery then
        return cLottery:HandleLottery(TT, res, boxIndex, lotteryType)
    end
    res:SetSucc(false)
    return nil
end
