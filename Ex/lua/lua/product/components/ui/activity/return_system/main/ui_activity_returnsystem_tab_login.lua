---@class UIActivityReturnSystemTabLogin:UICustomWidget
_class("UIActivityReturnSystemTabLogin", UICustomWidget)
UIActivityReturnSystemTabLogin = UIActivityReturnSystemTabLogin

function UIActivityReturnSystemTabLogin:OnShow()
end

function UIActivityReturnSystemTabLogin:OnHide()
    self.remainingTimeCallback = nil
    self:CancelTimerEventNextTime()
end

function UIActivityReturnSystemTabLogin:SetData(campaign, remainingTimeCallback, tipsCallback)
    self._campaign = campaign

    --- @type PlayerBackComponent
    self._componentPlayerBack = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "welecome", 1)

    --- @type CumulativeLoginComponent
    self._componentLogin = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "login", 1)

    self:InitLoginAwards()
    self.remainingTimeCallback = remainingTimeCallback
    self._tipsCallback = tipsCallback
    self:Flush()
end

function UIActivityReturnSystemTabLogin:ReFlush()
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            self._campaign:ReLoadCampaignInfo_Force(TT, res)
            self:Flush()
        end,
        self
    )
end

function UIActivityReturnSystemTabLogin:Flush()
    if not self.remainingTimeCallback then
        return
    end
    local sampleInfo = self._campaign:GetSample()
    if sampleInfo then
        local RegisterTimeEvent = function(seconds)
            self:CancelTimerEventNextTime()
            self.te =
                GameGlobal.Timer():AddEvent(
                seconds * 1000,
                function()
                    self:ReFlush()
                end
            )
        end
        local sTimestamp, eTimestamp = self._componentPlayerBack:GetTimeStampStartEnd()
        local nowTimestamp = UICommonHelper.GetNowTimestamp()
        --下次刷新时间戳
        local nextRefreshTime = sampleInfo.m_extend_info_time[CampainExtendKey.E_CAMPAIGN_EXTEND_KEY_NEXT_REFRESH_TIME]

        -- if eTimestamp - nowTimestamp < 86400 then --如果距离组件关闭不足24小时/组件已关闭，隐藏充值文本
        if eTimestamp < nextRefreshTime then --是否显示倒计时取绝于下次可领取的时间是否超过了活动关闭时间 靳策修改
            self:CancelTimerEventNextTime()
            self.remainingTimeCallback(0, true)
        else
            RegisterTimeEvent(nextRefreshTime - nowTimestamp)
            self.remainingTimeCallback(nextRefreshTime)
        end
    end
    ---
    self:FlushItems()
end

function UIActivityReturnSystemTabLogin:CancelTimerEventNextTime()
    if self.te then
        GameGlobal.Timer():CancelEvent(self.te)
    end
end

function UIActivityReturnSystemTabLogin:FlushItems()
    local awards = self.loginAwards
    local len = table.count(awards)
    ---@type UIActivityReturnSystemTabLoginAwardCell[]
    local uiCells = UIWidgetHelper.SpawnObjects(self, "Content", "UIActivityReturnSystemTabLoginAwardCell", len)
    for i, uiCell in ipairs(uiCells) do
        uiCell:Flush(awards[i], function(loginAward) -- getRewardCallback
            self:GetAward(loginAward)
        end,
        self._tipsCallback
        )
    end
end

function UIActivityReturnSystemTabLogin:GetAward(loginAward)
    if loginAward.status ~= ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV then
        return
    end
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            local day = loginAward.day
            self._componentLogin:HandleReceiveCumulativeLoginReward(TT, res, day)
            if res:GetSucc() then
                self:SetLoginAwardRecieved(day)
                self:Flush()

                local awards = loginAward.awards
                self:ShowDialog(
                    "UIActivityReturnSystemGetItem",
                    awards,
                    loginAward.petIcon,
                    loginAward.petName,
                    loginAward.petGreeting
                )
            else
                Log.fatal("### HandleRecvBackReward failed.")
            end
        end,
        self
    )
end

function UIActivityReturnSystemTabLogin:ShowItemInfo(matid, pos)
    self.tips:SetData(matid, pos)
end

function UIActivityReturnSystemTabLogin:InitLoginAwards()
    self.loginAwards = {}

    --- @type CumulativeLoginComponent
    local component = UIActivityReturnSystemHelper.GetComponentByTabName(self._campaign, "login", 1)
    local cInfo = component:GetComponentInfo()

    ---@type CumulativeLoginRewardInfo[]
    local sAwards = cInfo.m_cumulative_info
    if sAwards and table.count(sAwards) then
        for k, v in pairs(sAwards) do
            ---@type ActivityReturnSystemLoginAward
            local award = ActivityReturnSystemLoginAward:New()
            local day = v.m_login_days
            award.day = day
            local cfgv = Cfg.cfg_return_system[day]
            if cfgv then
                award:InitPetInfo(cfgv.PetId)
            else
                Log.fatal("### no data in cfg_return_system. day=", day)
            end
            award:SetStatus(v.m_reward_status)
            award.awards = v.m_rewards
            self.loginAwards[day] = award
        end
    else
    end
end

function UIActivityReturnSystemTabLogin:SetLoginAwardRecieved(day)
    if self.loginAwards[day] then
        self.loginAwards[day]:SetStatus(ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED)
    end
end