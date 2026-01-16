---@class UIN14MainReview:UIController
_class("UIN14MainReview", UIController)
UIN14MainReview = UIN14MainReview

function UIN14MainReview:Constructor(ui_root_transform)
    self.strsLeftTime = {
        "str_n14_left_time_d_h",
        "str_n14_left_time_h_m",
        "str_n14_left_time_m"
    }
    self.strsTakeAwardLeftTime = {
        "str_n14_take_award_left_time_d_h",
        "str_n14_take_award_left_time_h_m",
        "str_n14_take_award_left_time_m"
    }
    self.strsWillOpen = {
        "str_n14_will_open_after_d_h",
        "str_n14_will_open_after_h_m",
        "str_n14_will_open_after_m"
    }

    self.lanActivityTip =
    {
        "str_activity_common_state_notstart",
        "str_activity_common_end",
    }
end

function UIN14MainReview:LoadDataOnEnter(TT, res, uiParams)
    -- if not self.data then
    --     self.data = N14Data:New()
    -- end

    -- self.mCampaign =  self.data:GetCampaignModule()
    -- self.data:RequestCampaign(TT, ECampaignType.CAMPAIGN_TYPE_REVIEW_N14, res)
   
    self.isShow = true

    self._loginModule = self:GetModule(LoginModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)

    -- if res and not res:GetSucc() then
    --     self.mCampaign:CheckErrorCode(res.m_result, self.mCampaign._id, nil, nil)
    --     return
    -- end
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_REVIEW_N14
    self._componentId_LineMission = ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION

    self._missionModule = self:GetModule(MissionModule)

    ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIActivityCampaign
    self.activityCampaign = UIActivityCampaign:New()
    self.activityCampaign:LoadCampaignInfo(
        TT,
        res,
        self._campaignType,
        self._componentId_LineMission
    )

    --强制请求
    --请求完了再获取就一定是最新的了
    self.activityCampaign:ReLoadCampaignInfo_Force(TT, res)
    if res and res:GetSucc() then
        ---@type LineMissionComponent
        self._line_component = self.activityCampaign:GetComponent(self._componentId_LineMission)
        --- @type LineMissionComponentInfo
        self._line_info = self._line_component:GetComponentInfo()
    end
    -- 错误处理
    if res and not res:GetSucc() then
        self._campModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end

    self:_SetProgressData(TT, res)
end

function UIN14MainReview:_SetProgressData(TT, res)
    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    ---@type UIReviewActivityN1
    self._reviewData = uiModule:GetReviewData():GetActivityByType(ECampaignType.CAMPAIGN_TYPE_REVIEW_N14)
    self._reviewData:ReqDetailInfo(TT, res)
end

function UIN14MainReview:OnShow(uiParams)
    N14Data.SetPrefsMain()
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIN14.spriteatlas", LoadType.SpriteAtlas)
    self.dictSprite = {
        [1] = {n = "n13_zjm_btn05", d = "n13_zjm_btn05"}, --特别事件簿
        [2] = {n = "n14_zjm_shop", d = "n14_zjm_shop"}, --无人超市
        [3] = {n = "n13_zjm_btn07", d = "n13_zjm_btn07"}, --每日签到
        [4] = {n = "n14_zjm_xxg", d = "n14_zjm_xxg"}, --线性关
        [5] = {n = "n14_zjm_hard", d = "n14_zjm_hard"}, --高难关
        [6] = {n = "n14_zjm_game", d = "n14_zjm_game"} --捞鱼小游戏
    }

    self._useColor = {Color(1,1,1,1),Color(93/255,93/255,93/255,216/255)}

    ---@type UICustomWidgetPool  backbtn
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    ---@type UICommonTopButton
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIActivityReview)
        end,
        nil,
        nil,
        false,
        function()
            if self.isShow then
                self.isShow = false
                self:ShowHideUI()
            end
        end
    )
    self.animTopBtns = self._backBtns:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
    ---@type UnityEngine.UI.Button
    self.btnStageNormal = self:GetUIComponent("Button", "btnStageNormal")
    self.redStageNormal = self:GetGameObject("redStageNormal")
    self._spineLoader = self:GetGameObject("spine")
    ---@type UnityEngine.UI.Image
    self.imgStageNormal = self:GetUIComponent("Image", "btnStageNormal")
    self.anim = self:GetUIComponent("Animation","ani")
    self._masktable = {self:GetGameObject("MaskStageNormal")}
    self._modRawImagetable = {self:GetUIComponent("RawImage", "Normal")}
    self._modImagetable = {self:GetUIComponent("Image", "btnStageNormal")}
    self._modTexttable = {self:GetUIComponent("UILocalizationText", "StageNormalText")}

    self:Flush()
    --self:_CheckGuide()
    ---@type UIReviewProgress
    local progress = UIReviewProgressConst.SpawnObject(self, "_progress", self._reviewData)
end

function UIN14MainReview:OnHide()
    self.data = nil
    self.btnStageNormal = nil

end

function UIN14MainReview:CancelTimerEvent(nState)
    if nState == ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION then 
        if self.teNormal then
            GameGlobal.Timer():CancelEvent(self.teNormal)
            self.teNormal = nil 
        end
    end 
   
end

function UIN14MainReview:Flush()
    self:FlushNormalStage()
end

--region 按钮状态
function UIN14MainReview:SetModeState(mode,isOpen)
    if self._masktable[mode] then 
        self._masktable[mode]:SetActive(not isOpen)
    end 
    if self._modRawImagetable[mode] then 
        self._modRawImagetable[mode].color = isOpen and  self._useColor[1] or  self._useColor[2]  
    end 
    if self._modImagetable[mode] then  
        self._modImagetable[mode].color = isOpen and  self._useColor[1] or  self._useColor[2]  
    end 
    
end

function UIN14MainReview:GetSpriteN(idx)
    local n = self.atlas:GetSprite(self.dictSprite[idx].n)
    return n
end

function UIN14MainReview:GetSpriteD(idx)
    local d = self.atlas:GetSprite(self.dictSprite[idx].d)
    return d
end
--endregion

--region 普通关
function UIN14MainReview:FlushNormalStage()
    self.btnStageNormal.interactable = false
    self.imgStageNormal.sprite = self:GetSpriteD(4)
    local cNormalInfo = self._line_info
    if not cNormalInfo then
        Log.fatal("### cNormalInfo nil.")
        return
    end
    
    local state = self:GetState(self._line_info)
    self:SetModeState(1,state == UISummerOneEnterBtnState.Normal)
    if state == UISummerOneEnterBtnState.NotOpen then --未开启
        local leftSeconds = UICommonHelper.CalcLeftSeconds(cNormalInfo.m_unlock_time)
        --self:RegisterTimeEvent(leftSeconds, ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION)
        self._modTexttable[1]:SetText(StringTable.Get(self.lanActivityTip[1]))
    elseif state == UISummerOneEnterBtnState.Closed then --已关闭
        self._modTexttable[1]:SetText(StringTable.Get(self.lanActivityTip[2]))
        --self:CancelTimerEvent(ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION)
    elseif state == UISummerOneEnterBtnState.Normal then --进行中
        self.btnStageNormal.interactable = true
        self.imgStageNormal.sprite = self:GetSpriteN(4)
        local leftSeconds = UICommonHelper.CalcLeftSeconds(cNormalInfo.m_close_time)
        --self:RegisterTimeEvent(leftSeconds, ECampaignReviewN14ComponentID.ECAMPAIGN_REVIEW_ReviewN14_LINE_MISSION)
    else
        Log.fatal("### state=", state)
    end
    --self:FlushRedPointStageNormal()
end

function UIN14MainReview:GetState(cInfo)
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < cInfo.m_unlock_time then --未开启
        return UISummerOneEnterBtnState.NotOpen
    elseif nowTimestamp > cInfo.m_close_time then --已关闭
        return UISummerOneEnterBtnState.Closed
    else --进行中
        if cInfo.m_b_unlock then --是否已解锁，可能有关卡条件
            return UISummerOneEnterBtnState.Normal
        else
            local cfgv = Cfg.cfg_campaign_mission[cInfo.m_need_mission_id]
            if cfgv then
                return UISummerOneEnterBtnState.Locked
            else
                return UISummerOneEnterBtnState.Normal
            end
        end
    end
end

--endregion
---@param uiText UILocalizationText
---@param time number 时间戳
function UIN14MainReview:FlushCDText(uiText, time, strs)
    local leftSeconds = UICommonHelper.CalcLeftSeconds(time)
    local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
    if d >= 1 then
        uiText:RefreshText(StringTable.Get(strs[1], math.floor(d), math.floor(h)))
    else
        if h >= 1 then
            uiText:RefreshText(StringTable.Get(strs[2], math.floor(h), math.floor(m)))
        else
            if m >= 1 then
                uiText:RefreshText(StringTable.Get(strs[3], math.floor(m)))
            else
                uiText:RefreshText(StringTable.Get(strs[3], "<1"))
            end
        end
    end
end
--region OnClick
function UIN14MainReview:BgOnClick(go)
    if not self.isShow then
        self.isShow = true
        self:ShowHideUI()
    end
end

function UIN14MainReview:BtnStageNormalOnClick(go)
    -- local state = self.data:GetStateNormal()
    -- if state == UISummerOneEnterBtnState.Normal then
        self:SwitchState(UIStateType.UIActivityN14LineMissionControllerReview)
    -- else
    --     self:_ShowBtnErrorMsg(state)
    -- end
end

--endregion 
-- kv
function UIN14MainReview:ShowHideUI()
    local goSafeArea = self:GetGameObject("SafeArea")
    if self.isShow then
        self.anim:Play("uieff_UIN14Main_show")
        self._backBtns:GetGameObject():SetActive(true)
        -- goSafeArea:SetActive(true)
    else
        self.anim:Play("uieff_UIN14Main_hide")
        self._backBtns:GetGameObject():SetActive(false)
        -- goSafeArea:SetActive(false)
    end
    self._spineLoader:SetActive(true)
end