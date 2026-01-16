---@class UIN13MainControllerReview : UIController
_class("UIN13MainControllerReview", UIController)
UIN13MainControllerReview = UIN13MainControllerReview
-------------------initial-------------------
function UIN13MainControllerReview:Constructor()
    self._loginModule = self:GetModule(LoginModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._campaignModule = self:GetModule(CampaignModule)
end

function UIN13MainControllerReview:LoadDataOnEnter(TT, res, uiParams)
    -------------------拉取活动组件-------------------
    self._campaign = UIActivityCampaign:New()
    if self._campaign._type == -1 or self._campaign._id == -1 then
        self._campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_REVIEW_N13)
    else
        self.activityCampaign:ReLoadCampaignInfo_Force(TT, res)
    end
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    -------------------组件-------------------
    ---@type CCampaignN13
    self._process = self._campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_REVIEW_N13)
    ---@type LineMissionComponent 线性关卡组件（主线关）
    self._line_mission_cpt = self._campaign:GetComponent(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION)
    ---@type CampaignBuildComponent 重建组件（装扮赏樱园、野餐）
    self._build_cpt = self._campaign:GetComponent(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD)
    ---@type CampaignPower2itemComponent 体力转换组件（活动道具掉落）
    --self._physical_power_cpt = self._campaign:GetComponent(ECampaignN13ComponentID.ECAMPAIGN_N13_POWER2ITEM)
    -------------------Info-------------------
    ---@type LineMissionComponentInfo
    self._line_mission_info = self._campaign:GetComponentInfo(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION)
    ---@type BuildComponentInfo
    self._build_info = self._campaign:GetComponentInfo(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD)
    ---@type Power2ItemComponentInfo
    --self._physical_power_info = self._campaign:GetComponentInfo(ECampaignN13ComponentID.ECAMPAIGN_N13_POWER2ITEM)
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._battlePassCampaign._id, nil, nil)
        return
    end

    self._componentId = ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD
    ---@type CampaignBuildComponent
    self._component = self._campaign:GetComponent(self._componentId)

    ---@type UIBuildComponentManager
    self._buildManager = UIBuildComponentManager:New(self._component)

    self.playerID = GameGlobal.GameLogic():GetOpenId()
end

function UIN13MainControllerReview:OnShow(uiParams)
    self:_AttachEvent()
    self:_OnValue(uiParams)
    self:_GetComponent()
    self:_OnShow()
end

function UIN13MainControllerReview:OnHide()
    self._isOpen = false
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end

function UIN13MainControllerReview:_AttachEvent()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
end

function UIN13MainControllerReview:_OnValue(uiParams)
    self._rt = uiParams[1]
    self._componentState = {}
    self._btnImg = {}
    self._reds = {}
    self._news = {}
    self._objs = {}

    self._showSpine = false
    self._garden_lock_true = false
    self._isOpen = true
    --self:_CheckGuide()
end

function UIN13MainControllerReview:_GetComponent()
    self._animation = self.view.gameObject:GetComponent("Animation")
    --self._remainTime = self:GetUIComponent("UILocalizationText", "_remainTime")

    self._sakuragari_token_i = self:GetUIComponent("UILocalizationText", "_sakuragari_token_i")
    self._sakuragari_token_ii = self:GetUIComponent("UILocalizationText", "_sakuragari_token_ii")

    self._login_state = self:GetGameObject("_login_state")

    --- 线性关
    --- i mask; ii 锁定; iii 活动结束
    self._line_state_i = self:GetGameObject("_line_state_i")
    self._line_state_ii = self:GetGameObject("_line_state_ii")
    --self._line_state_iii = self:GetGameObject("_line_state_iii")

    --- 赏樱园
    --- i mask; ii 锁定; iii 开启（关闭）时间 iiii 活动结束
    self._sakuragari_state_i = self:GetGameObject("_sakuragari_state_i")
    self._sakuragari_state_ii = self:GetGameObject("_sakuragari_state_ii")
    --self._sakuragari_state_iii = self:GetGameObject("_sakuragari_state_iii")
    --self._sakuragari_state_iiii = self:GetGameObject("_sakuragari_state_iiii")

    self._garden_lock = self:GetGameObject("_garden_lock")

    self._btnImg[ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION] = self:GetUIComponent("Image", "_normal_level")
    --self._btnImg[ECampaignN13ComponentID.ECAMPAIGN_N13_POWER2ITEM] = self:GetUIComponent("Image", "_sakuragari")

    self._reds[ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION] = self:GetGameObject("_redPoint_level")
    self._redsBuild= self:GetGameObject("_redPoint_sakuragar")

    --self._news[ECampaignN13ComponentID.ECAMPAIGN_N13_POWER2ITEM] = self:GetGameObject("_newPoint_sakuragar")

    self._objs["0"] = self:GetGameObject("_need_hide_i")
    self._objs["1"] = self:GetGameObject("_need_hide_ii")
    self._objs["2"] = self:GetGameObject("_need_hide_iii")
    self._objs["3"] = self:GetGameObject("_need_hide_iiii")

    self._screenCut = self:GetUIComponent("RawImage", "ScreenCut")
end

-------------------show-------------------
--- 有操作刷新
function UIN13MainControllerReview:_OnAfterUILayerChanged()
    -- 活动组件状态
    self:_RefreshComponentState()
    -- 刷新道具数量
    self:_RefreshMoney()
end

function UIN13MainControllerReview:_RefreshMoney()
    -- 获取赏花组件 获取道具数量 显示ui文字
    local type = EnumN13Review.B
    local count = UIActivityN13Helper.GetCoinItemCount(type) -- self._physical_power_cpt:GetCampaignCount()
    self._sakuragari_token_i:SetText(string.format("%07d", count))
    self._sakuragari_token_ii:SetText(count)
end

function UIN13MainControllerReview:_RefreshComponentState()
    for key, value in pairs(ECampaignReviewN13ComponentID) do
        self._componentState[value] = self:_GetComponentState(value)
        if self._btnImg[value] then
            if self._componentState[value] then
            else
            end
        end
    end
end

function UIN13MainControllerReview:_RefRemainTime()
    local str = "str_n13_active_remaining_time"
    local remainTime = 0
    local sakuragariTime = 0
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    local endtime = self._campaign:GetSample().end_time
    remainTime = endtime - curtime
    sakuragariTime = self._build_info.m_close_time - curtime
    -- if sakuragariTime > 0 then
    --     str = "str_n13_garden_remaining_time"
    --     self._remainTime:SetText(StringTable.Get(str, N13ToolFunctions.GetRemainTime(sakuragariTime)))
    -- else
    --     self._remainTime:SetText(StringTable.Get(str, N13ToolFunctions.GetRemainTime(remainTime)))
    -- end
    return remainTime
end

function UIN13MainControllerReview:_OnShow()
    if self._rt then
        self._screenCut.texture = self._rt
        self._animation:Play("uieff_n13_main_in")
        self:StartTask(
            function(TT)
                local lockName = "UIN13MainControllerReview:_OnShow"
                self:Lock(lockName)
                YIELD(TT, 600)
                self._screenCut.gameObject:SetActive(false)
                YIELD(TT, 600)
                self._objs["0"]:SetActive(true)
                self:UnLock(lockName)
            end
        )
    else
        self._screenCut.gameObject:SetActive(false)
        self._objs["0"]:SetActive(true)
    end

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
            self:_ShowBgSpine(true, "uieff_n13_main_hide")
        end
    )
    self:_SetTimer()
    self:_ClearNewFlag()
end

function UIN13MainControllerReview:_GetComponentState(componentid)
    return self._campaign:CheckComponentOpen(componentid)
end

function UIN13MainControllerReview:_ShowBgSpine(showSpine, animationName)
    self._showSpine = showSpine
    if animationName then -- 有动效
        self._animation:Play(animationName)
    else -- 无动效
        for _, need_hide in pairs(self._objs) do
            need_hide:SetActive(not showSpine)
        end
    end
end
-------------------计时器-------------------
function UIN13MainControllerReview:_SetTimer()
    self._timeEvent = UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function()
            return self:_SetRemainingTimer() -- 返回 stopSign 在首次回调时停止继续创建计时器
        end
    )
end

function UIN13MainControllerReview:_SetRemainingTimer()
    if not self._isOpen then
        return
    end
    --- 显示逻辑
    local remaintime = self:_RefRemainTime()
    self:_RefAllState(remaintime)
    if remaintime <= 0 then
        self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
        return true -- 返回 stopSign 在首次回调时停止继续创建计时器
    end
end
-------------------state-------------------
function UIN13MainControllerReview:_RefAllState(remain_time)

    self:_RefSakuragariState(remain_time)
    self:_RefLineState(remain_time)
    self:_RefRedState(remain_time)
end


function UIN13MainControllerReview:_RefSakuragariState(remain_time)
    local remainTime = 0
    local startTime = 0
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    startTime = self._build_info.m_unlock_time - curtime
    remainTime = self._build_info.m_close_time - curtime -- 赏樱园剩余时间
    if remainTime < 0 then
        self._sakuragari_state_i:SetActive(true)
        self._sakuragari_state_ii:SetActive(false)
        --self._sakuragari_state_iii:SetActive(false)
        return
    end
    local start = self._build_info.m_b_unlock
    self._sakuragari_state_i:SetActive(not start)
    self._sakuragari_state_ii:SetActive(not start)
    --self._sakuragari_state_iii:SetActive(not start)
    -- if self._build_info and not start then
    --     local cfgv = Cfg.cfg_campaign_mission[self._build_info.m_need_mission_id]
    --     if cfgv then
    --         self._garden_remainTime:SetText(StringTable.Get("str_n13_pass_level_unlock", cfgv.Name))
    --     else
    --         self._garden_remainTime:SetText(
    --             StringTable.Get("str_n13_garden_remaining_open_time", N13ToolFunctions.GetRemainTime(startTime))
    --         )
    --     end
    -- else
    --     self._garden_remainTime:SetText(
    --         StringTable.Get("str_n13_garden_remaining_time", N13ToolFunctions.GetRemainTime(remainTime))
    --     )
    -- end
end



function UIN13MainControllerReview:_RefLineState(remain_time)
    local remainTime = 0
    local curtime = math.floor(self._svrTimeModule:GetServerTime() * 0.001)
    remainTime = self._line_mission_info.m_close_time - curtime
    local lock = remainTime > 0
    if remainTime < 0 and not lock then
        self._line_state_i:SetActive(true)
        self._line_state_ii:SetActive(false)
        --self._line_state_iii:SetActive(true)
        return
    end
    local start = self._line_mission_info.m_b_unlock
    self._line_state_i:SetActive(not start)
    self._line_state_ii:SetActive(not start)
    --self._line_state_iii:SetActive(false)
end

function UIN13MainControllerReview:_RefRedState(remain_time)
    local red_level = self._campaign:CheckComponentRed(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION)
    --local red_fix = self._process:GetFixMissionRedDot()or red_fix
    self._reds[ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION]:SetActive(red_level )

    local unlock, all = self._buildManager:CalcBuildUnlockProgress()
    local value = LocalDB.GetInt(self.playerID.."UIN13BuildPlotControllerReviewExtOnClickTrue")
    local red_sakuragari = self._campaign:CheckComponentRed(ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD)
    if red_sakuragari or (unlock == all and value ~= 1) then
        self._redsBuild:SetActive(true)
    else
        self._redsBuild:SetActive(false)
    end

    --self._redsBuild:SetActive(red_sakuragari)
    --local red_sakuragari = self._process:GetSakuragariRedDot()
    --local new_sakuragari = self._process:GetSakuragariNew()
    -- self._news[ECampaignN13ComponentID.ECAMPAIGN_N13_POWER2ITEM]:SetActive(new_sakuragari)and not new_sakuragari

end

function UIN13MainControllerReview:_ClearNewFlag()
    if not self._campaign:GetSample():GetStepStatus(ECampaignStep.CAMPAIGN_STEP_NEW) then
        return
    end
    self:StartTask(
        function(TT)
            local res = AsyncRequestRes:New()
            GameGlobal.GetModule(CampaignModule):CampaignClearNewFlag(TT, res, self._campaign._id)
            if res:GetSucc() then
                --self:_CheckGuide()
            end
        end,
        self
    )
end

-------------------btn-------------------
function UIN13MainControllerReview:BgBtnOnClick()
    if self._showSpine then
        self:_ShowBgSpine(false, "uieff_n13_main_show")
    end
end

-- --- 活动说明
-- function UIN13MainControllerReview:ActivityIntroBtnOnClick(go)
--     self:ShowDialog("UIN13IntroController", "UIN13MainControllerReview", 1)
-- end

--- 线性关
function UIN13MainControllerReview:NormalLevelBtnOnClick(go)
    if not self._componentState[ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_LINE_MISSION] then
        ToastManager.ShowToast(StringTable.Get("str_n13_activity_over"))
        return
    end
    self._campaignModule:CampaignSwitchState(
        true,
        UIStateType.UIN13LineMissionControllerReview,
        UIStateType.UIMain,
        nil,
        self._campaign._id
    )
end

--- 赏樱园
function UIN13MainControllerReview:SakuragariBtnOnClick(go)
    if not self._build_info.m_b_unlock then
        ToastManager.ShowToast(StringTable.Get("str_n13_activity_lock"))
        return
    end
    if not self._componentState[ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD] then
        ToastManager.ShowToast(StringTable.Get("str_n13_activity_over"))
        return
    end

    -- 首次剧情
    UIActivityHelper.PlayFirstPlot_Component(
        self._campaign,
        ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD,
        function()
            self:SwitchState(UIStateType.UIN13BuildControllerReview)
        end,
        false
    )
end

-- function UIN13MainControllerReview:_CheckGuide()
--     GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN13MainControllerReview)
-- end
