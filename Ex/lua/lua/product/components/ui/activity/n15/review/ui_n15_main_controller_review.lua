---@class UIN15MainControllerReview : UIController
_class("UIN15MainControllerReview", UIController)
UIN15MainControllerReview = UIN15MainControllerReview
-------------------initial-------------------
function UIN15MainControllerReview:Constructor()
    self._loginModule = self:GetModule(LoginModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._campaignModule = self:GetModule(CampaignModule)
end

function UIN15MainControllerReview:LoadDataOnEnter(TT, res, uiParams)
    -------------------拉取活动组件-------------------
    self._campaign = UIActivityCampaign:New()
    if self._campaign._type == -1 or self._campaign._id == -1 then
        self._campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_REVIEW_N15)
    end
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    -- self._campaign_chess = UIActivityCampaign:New()
    -- self._isOpenChess = self._campaignModule:GetComponentByComponentId(ECampaignType.CAMPAIGN_TYPE_CHESS)
    -- if self._campaign_chess._type == -1 or self._campaign_chess._id == -1 then
    --     self._campaign_chess:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_CHESS)
    -- end
    -------------------组件-------------------
    ---@type CCampaignN15
    self._process = self._campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_REVIEW_N15)
    ---@type LineMissionComponent 线性关卡组件（主线关）
    self._line_mission_cpt = self._campaign:GetComponent(ECampaignReviewN15ComponentID.ECAMPAIGN_REVIEW_ReviewN15_LINE_MISSION)
    ---@type LineMissionComponent 线性关卡组件（光灵初见）
    --self._pet_try_cpt = self._campaign:GetComponent(ECampaignN15ComponentID.ECAMPAIGN_N15_LEVEL_FIXTEAM)
    ---@type CumulativeLoginComponent 累计登录（签到）
    --self._login_cpt = self._campaign:GetComponent(ECampaignN15ComponentID.ECAMPAIGN_N15_CUMULATIVE_LOGIN)
    ---@type LotteryComponent 积分商店（抽奖）
    --self._raffle_cpt = self._campaign:GetComponent(ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY)
    ---@type CampaignPower2itemComponent 体力转换组件（活动道具掉落）
    --self._physical_power_cpt = self._campaign:GetComponent(ECampaignN15ComponentID.ECAMPAIGN_N15_POWER2ITEM)
    -----------------Info-------------------
    ---@type LineMissionComponentInfo
    self._line_mission_info = self._campaign:GetComponentInfo(ECampaignReviewN15ComponentID.ECAMPAIGN_REVIEW_ReviewN15_LINE_MISSION)
    ---@type LineMissionComponentInfo
    --self._pet_try_info = self._campaign:GetComponentInfo(ECampaignN15ComponentID.ECAMPAIGN_N15_LEVEL_FIXTEAM)
    ---@type CumulativeLoginComponentInfo
    --self._login_info = self._campaign:GetComponentInfo(ECampaignN15ComponentID.ECAMPAIGN_N15_CUMULATIVE_LOGIN)
    ---@type LotteryComponentInfo
    --self._raffle_info = self._campaign:GetComponentInfo(ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY)
    ---@type Power2ItemComponentInfo
    --self._physical_power_info = self._campaign:GetComponentInfo(ECampaignN15ComponentID.ECAMPAIGN_N15_POWER2ITEM)
    -------------------通行证-------------------
    -- self._battlePassCampaign = UIActivityCampaign:New()
    -- self._battlePassCampaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_BATTLEPASS)
    -- if res and not res:GetSucc() then
    --     self._campaignModule:CheckErrorCode(res.m_result, self._battlePassCampaign._id, nil, nil)
    --     return
    -- end
    -------------------战棋-------------------
    ---@type ChessComponent
    --self._chess_cpt = self._campaign_chess:GetComponent(ECampaignChessComponentID.ECAMPAIGN_CHESS_MISSION)
    ---@type ChessComponentInfo
    --self._chess_info = self._campaign_chess:GetComponentInfo(ECampaignChessComponentID.ECAMPAIGN_CHESS_MISSION)
end

function UIN15MainControllerReview:OnShow(uiParams)
    --self:_AttachEvent()
    self:_InitParams(uiParams)
    self:_InitWidget()
    self:_RefView()
    --self:_CheckGuide()
    self:_PlayAudio()
end

function UIN15MainControllerReview:OnHide()
    self._isOpen = false
    -- self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end

-- function UIN15MainControllerReview:_AttachEvent()
--     self:AttachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
-- end

function UIN15MainControllerReview:_InitParams(uiParams)
    --- variable
    self._componentState = {}
    self._reds = {}
    self._news = {}
    self._objs = {}
    self._showSpine = false
    self._isOpen = true
end

function UIN15MainControllerReview:_InitWidget()
    -- self._remainTime = self:GetUIComponent("UILocalizationText", "_remainTime")

    --- 代币
    -- self._raffle_token_i = self:GetUIComponent("UILocalizationText", "_raffle_token_i")
    -- self._raffle_token_ii = self:GetUIComponent("UILocalizationText", "_raffle_token_ii")

    --- 每日奖励
    --- mask
    -- self._login_state = self:GetGameObject("_login_state")

    --- 线性关
    --- i mask; ii 锁定; iii 活动结束
    self._line_state_i = self:GetGameObject("_line_state_i")
    self._line_state_ii = self:GetGameObject("_line_state_ii")
    self._line_state_iii = self:GetGameObject("_line_state_iii")

    --- 抽奖活动
    --- i mask; ii 锁定; iii 开启（关闭）时间 iiii 活动结束
    -- self._raffle_state_i = self:GetGameObject("_raffle_state_i")
    -- self._raffle_state_ii = self:GetGameObject("_raffle_state_ii")
    -- self._raffle_state_iii = self:GetGameObject("_raffle_state_iii")
    -- self._raffle_state_iiii = self:GetGameObject("_raffle_state_iiii")
    -- self._raffle_remainTime = self:GetUIComponent("UILocalizationText", "_raffle_remainTime")

    --- 战棋关
    --- i mask; ii 锁定; iii 开启（关闭）时间
    -- self._chess_state_i = self:GetGameObject("_chess_state_i")
    -- self._chess_state_ii = self:GetGameObject("_chess_state_ii")
    -- self._chess_state_iii = self:GetGameObject("_chess_state_iii")
    -- self._chess_remain_time = self:GetUIComponent("UILocalizationText", "_chess_remainTime")

    --self._reds[ECampaignN15ComponentID.ECAMPAIGN_N15_CUMULATIVE_LOGIN] = self:GetGameObject("_redPoint_login")
    --self._reds[ECampaignN15ComponentID.ECAMPAIGN_N15_LEVEL_COMMON] = self:GetGameObject("_redPoint_level")
    --self._reds[ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY] = self:GetGameObject("_redPoint_raffle")
    --self._reds[ECampaignType.CAMPAIGN_TYPE_BATTLEPASS] = self:GetGameObject("_redPoint_battlePass")
    --self._reds[999] = self:GetGameObject("red")

    --self._news[ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY] = self:GetGameObject("_newPoint_raffle")
    --self._news[999] = self:GetGameObject("new")

    self._objs["0"] = self:GetGameObject("_need_hide_i")
    self._objs["1"] = self:GetGameObject("_need_hide_ii")
    self._objs["2"] = self:GetGameObject("_need_hide_iii")
    self._objs["3"] = self:GetGameObject("_need_hide_iiii")
    self._objs["4"] = self:GetGameObject("cover")
end

-------------------show-------------------
--- 有操作刷新
-- function UIN15MainControllerReview:_OnAfterUILayerChanged()
--     -- 活动组件状态
--     --self:_RefreshComponentState()
--     -- 刷新道具数量
--     --self:_RefreshMoney()
-- end

-- function UIN15MainControllerReview:_RefreshMoney()
--     -- 获取抽奖组件 获取道具数量 显示ui文字
--     local count = ClientCampaignDrawShop.GetMoney(self._raffle_info.m_cost_item_id)
--     self._raffle_token_i:SetText(string.format("%07d", count))
--     self._raffle_token_ii:SetText(count)
-- end

-- function UIN15MainControllerReview:_RefreshComponentState()
--     for key, value in pairs(ECampaignN15ComponentID) do
--         self._componentState[value] = self._campaign:CheckComponentOpen(value)
--     end
--     self._componentState[999] = self._campaign_chess:CheckComponentOpen(
--         ECampaignChessComponentID.ECAMPAIGN_CHESS_MISSION)
-- end

-- function UIN15MainControllerReview:_RefRemainTime()
--     local str = "str_n15_remain_time_activity"
--     local remainTime = 0
--     local raffleTime = 0
--     local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
--     local endtime = self._campaign:GetSample().end_time
--     remainTime = endtime - curtime
--     raffleTime = self._raffle_info.m_close_time - curtime
--     if raffleTime > 0 then
--         str = "str_n15_remain_time_contest"
--         self._remainTime:SetText(StringTable.Get(str, N15ToolFunctions.GetRemainTime(raffleTime, "fac720")))
--     else
--         self._remainTime:SetText(StringTable.Get(str, N15ToolFunctions.GetRemainTime(remainTime, "fac720")))
--     end
--     return remainTime
-- end

function UIN15MainControllerReview:_RefView()
    local back_btn = self:GetUIComponent("UISelectObjectPath", "_backBtn")
    self._commonTopBtn = back_btn:SpawnObject("UICommonTopButton")
    self._commonTopBtn:SetData(
        function()
            self:SwitchState(UIStateType.UIActivityReview)
        end,
        nil,
        nil,
        false,
        function()
            self:_ShowBgSpine(true)
        end
    )

    --self:_SetTimer()

    self:_ClearNewFlag()
end

function UIN15MainControllerReview:_ShowBgSpine(showSpine, animationName)
    self._showSpine = showSpine
    if animationName then -- 有动效
        self._animation:Play(animationName)
    else -- 无动效
        for _, need_hide in pairs(self._objs) do
            need_hide:SetActive(not showSpine)
        end
    end
end

-------------------state-------------------
function UIN15MainControllerReview:_RefAllState(remain_time)
    -- self:_RefLoginState(remain_time)
    self:_RefRaffleState(remain_time)
    self:_RefLineState(remain_time)
    self:_RefRedState(remain_time)
    --self:_RefChessState()
end

---@private
---刷新登录状态(前置关闭)
-- function UIN15MainControllerReview:_RefLoginState()
--     local remainTime = 0
--     local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
--     remainTime = self._login_info.m_close_time - curtime
--     self._login_state:SetActive(not (remainTime > 0))
-- end

---@private
---刷新战棋状态(后置开启)
-- function UIN15MainControllerReview:_RefChessState(remain_time)
--     local remainTime = 0
--     local startTime = 0
--     local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
--     startTime = self._chess_info.m_unlock_time - curtime
--     remainTime = self._chess_info.m_close_time - curtime
--     if remainTime < 0 then
--         self._chess_state_i:SetActive(true)
--         self._chess_state_ii:SetActive(false)
--         self._chess_state_iii:SetActive(false)
--         return
--     end
--     local start = self._chess_info.m_b_unlock or startTime < 0
--     self._chess_state_i:SetActive(not start)
--     self._chess_state_ii:SetActive(not start)
--     self._chess_state_iii:SetActive(not start)
--     if self._chess_info and not start then
--         local cfgv = Cfg.cfg_campaign_mission[self._chess_info.m_need_mission_id]
--         if cfgv then
--             self._chess_remain_time:SetText(StringTable.Get("str_n15_pass_level_unlock", cfgv.Name))
--         else
--             self._chess_remain_time:SetText(
--                 StringTable.Get("str_n15_raffle_remaining_open_time", N15ToolFunctions.GetRemainTime(startTime))
--             )
--         end
--     else
--         self._chess_remain_time:SetText(
--             StringTable.Get("str_n15_remain_time_contest", N15ToolFunctions.GetRemainTime(remainTime))
--         )
--     end
-- end

---@private
---刷新抽奖状态(无状态)
function UIN15MainControllerReview:_RefRaffleState(remain_time)
    -- local remainTime = 0
    -- local startTime = 0
    -- local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    -- startTime = self._raffle_info.m_unlock_time - curtime
    -- remainTime = self._raffle_info.m_close_time - curtime -- 抽奖玩法剩余时间
    -- if remain_time < 0 then
    --     self._raffle_state_i:SetActive(true)
    --     self._raffle_state_ii:SetActive(false)
    --     self._raffle_state_iii:SetActive(false)
    --     self._raffle_state_iiii:SetActive(true)
    --     return
    -- end
    -- local start = self._raffle_info.m_b_unlock
    -- self._raffle_state_i:SetActive(not start)
    -- self._raffle_state_ii:SetActive(not start)
    -- self._raffle_state_iii:SetActive(not start)
    -- self._raffle_state_iiii:SetActive(false)
    -- if self._raffle_info and not start then
    --     local cfgv = Cfg.cfg_campaign_mission[self._raffle_info.m_need_mission_id]
    --     if cfgv then
    --         self._raffle_remainTime:SetText(StringTable.Get("str_n15_pass_level_unlock", cfgv.Name))
    --     else
    --         self._raffle_remainTime:SetText(
    --             StringTable.Get("str_n15_raffle_remaining_open_time", N15ToolFunctions.GetRemainTime(startTime))
    --         )
    --     end
    -- else
    --     self._raffle_remainTime:SetText(
    --         StringTable.Get("str_n15_remain_time_contest", N15ToolFunctions.GetRemainTime(remainTime))
    --     )
    -- end
end

---@private
---刷新线性关状态(前置关闭)
function UIN15MainControllerReview:_RefLineState(remain_time)
    local remainTime = 0
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    remainTime = self._line_mission_info.m_close_time - curtime
    local lock = remainTime > 0
    self._line_state_i:SetActive(not lock)
    self._line_state_ii:SetActive(not lock)
    self._line_state_iii:SetActive(not lock)
end

-- 刷新红点状态
function UIN15MainControllerReview:_RefRedState(remain_time)
    -- local red_level = self._campaign:CheckComponentRed(ECampaignN15ComponentID.ECAMPAIGN_N15_LEVEL_COMMON)
    -- local red_fix = self._process:GetFixMissionRedDot()
    -- self._reds[ECampaignReviewN15ComponentID.ECAMPAIGN_N15_LEVEL_COMMON]:SetActive(red_level or red_fix)

    -- local red_login = self._campaign:CheckComponentRed(ECampaignN15ComponentID.ECAMPAIGN_N15_CUMULATIVE_LOGIN)
    -- self._reds[ECampaignN15ComponentID.ECAMPAIGN_N15_CUMULATIVE_LOGIN]:SetActive(red_login)

    -- local red_raffle = self._process:GetLottleryRedDot()
    -- local new_raffle = self._process:GetLottleryNew()
    -- self._news[ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY]:SetActive(new_raffle)
    -- self._reds[ECampaignN15ComponentID.ECAMPAIGN_N15_LOTTERY]:SetActive(red_raffle and not new_raffle)

    -- local red_bp = UIActivityHelper.CheckCampaignSampleRedPoint(self._battlePassCampaign)
    -- self._reds[ECampaignType.CAMPAIGN_TYPE_BATTLEPASS]:SetActive(red_bp == true)

    -- local remainTime = 0
    -- local startTime = 0
    -- local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    -- startTime = self._chess_info.m_unlock_time - curtime
    -- remainTime = self._chess_info.m_close_time - curtime
    -- local red_chess = UIActivityHelper.CheckCampaignSampleRedPoint(self._campaign_chess)
    -- local new_chess = UIActivityHelper.CheckCampaignSampleNewPoint(self._campaign_chess)
    -- self._reds[999]:SetActive(red_chess == true and not new_chess and (startTime < 0))
    -- self._news[999]:SetActive(new_chess and (startTime < 0))
end

function UIN15MainControllerReview:_ClearNewFlag()
    if not self._campaign:GetSample():GetStepStatus(ECampaignStep.CAMPAIGN_STEP_NEW) then
        return
    end
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            GameGlobal.GetModule(CampaignModule):CampaignClearNewFlag(TT, res, self._campaign._id)
            if res:GetSucc() then
            end
        end,
        self
    )
end

-------------------计时器-------------------
-- function UIN15MainControllerReview:_SetTimer()
--     self._timeEvent = UIActivityHelper.StartTimerEvent(
--         self._timeEvent,
--         function()
--             return self:_SetRemainingTimer() -- 返回 stopSign 在首次回调时停止继续创建计时器
--         end
--     )
-- end

-- function UIN15MainControllerReview:_SetRemainingTimer()
--     if not self._isOpen then
--         return
--     end
--     --- 显示逻辑
--     local remaintime = self:_RefRemainTime()
--     self:_RefAllState(remaintime)
--     if remaintime <= 0 then
--         self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
--         return true -- 返回 stopSign 在首次回调时停止继续创建计时器
--     end
-- end

-------------------btn-------------------
function UIN15MainControllerReview:BgBtnOnClick()
    if self._showSpine then
        self:_ShowBgSpine(false)
    end
end

--- 线性关
function UIN15MainControllerReview:NormalLevelBtnOnClick(go)
    -- if not self._componentState[ECampaignReviewN15ComponentID.ECAMPAIGN_N15_LEVEL_COMMON] then
    --     if not self._componentState[ECampaignReviewN15ComponentID.ECAMPAIGN_N15_LOTTERY] then
    --         self:SwitchState(UIStateType.UIMain)
    --     end
    --     ToastManager.ShowToast(StringTable.Get("str_n15_over_activity"))
    --     return
    -- end
    self._campaignModule:CampaignSwitchState(
        true,
        UIStateType.UIN15LineMissionControllerReview,
        UIStateType.UIMain,
        nil,
        self._campaign._id
    )
end

--N15 引导
-- function UIN15MainControllerReview:_CheckGuide()
--     self:Lock("UIN15MainControllerReviewCheckGuide")
--     self:StartTask(
--         function (TT)
--             YIELD(TT, 1600)
--             GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN15MainControllerReview)
--             self:UnLock("UIN15MainControllerReviewCheckGuide")
--         end,
--         self
--     )
-- end

--N15 Audio
function UIN15MainControllerReview:_PlayAudio()
    self:StartTask(
        function (TT)
            YIELD(TT, 125)
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N15SwitchState)
        end,
        self
    )
end