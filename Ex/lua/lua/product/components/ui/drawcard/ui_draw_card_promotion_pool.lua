---@class UIDrawCardPromotionPool:UICustomWidget
_class("UIDrawCardPromotionPool", UICustomWidget)
UIDrawCardPromotionPool = UIDrawCardPromotionPool

function UIDrawCardPromotionPool:OnShow()
end

function UIDrawCardPromotionPool:OnHide()
    if self.timer then
        GameGlobal.Timer():CancelEvent(self.timer)
        self.timer = nil
    end
end

function UIDrawCardPromotionPool:SetData(data)
    ---@type PrizePoolInfo
    self.poolData = data

    if self.poolData.close_type ~= PrizePoolType.PROMOTION_POOL then
        Log.fatal("[DrawCard] pool type is not promotion: ", self.poolData.close_type)
        return
    end

    ---@type SvrTimeModule
    local timeModule = self:GetModule(SvrTimeModule)
    local now = math.floor(timeModule:GetServerTime())
    local deltaTime = self.poolData.extend_data * 1000 - now
    if deltaTime > 0 and deltaTime < 86400000 then
        --不超过一天
        self.timer =
            GameGlobal.Timer():AddEvent(
            deltaTime,
            function()
                self.timer = nil
                self:StartTask(self.UpdatePoolData, self)
            end
        )
    end
end

function UIDrawCardPromotionPool:UpdatePoolData(TT)
    ---@type GambleModule
    local module = GameGlobal.GetModule(GambleModule)
    local ack = module:ApplyAllPoolInfo(TT)
    if ack:GetSucc() then
        Log.notice("[DrawCard] promotion time up, refresh pools")
        self:SwitchState(UIStateType.UIDrawCard)
    else
        Log.notice("[DrawCard] promotion time up, refresh pools failed")
        ToastManager.ShowToast(module:GetReasonByErrorCode(ack:GetResult()))
    end
end
