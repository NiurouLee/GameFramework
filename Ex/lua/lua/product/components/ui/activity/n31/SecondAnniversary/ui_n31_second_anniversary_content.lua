--
---@class UIN31SecondAnniversaryContent : UISideEnterCenterContentBase
_class("UIN31SecondAnniversaryContent", UISideEnterCenterContentBase)
UIN31SecondAnniversaryContent = UIN31SecondAnniversaryContent

-- 因為需要加載數據
function UIN31SecondAnniversaryContent.CheckCampaignRedPoint(campaign)
    return campaign:CheckCampaignRed()
end

function UIN31SecondAnniversaryContent:DoInit(params)
    self._loginModule = self:GetModule(LoginModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._campaignModule = self:GetModule(CampaignModule)
    self._loginModule = self:GetModule(LoginModule)

    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id

    ---@type UIActivityCampaign
    self._campaign = self._data
end

--初始化
function UIN31SecondAnniversaryContent:DoShow(uiParams)
    -- 清除 new
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)
    self._autoPop = uiParams[1]
    local cfg = Cfg.cfg_campaign[self._campaign._id]
    --self._storyID = cfg.FirstEnterStoryID[1]
    self._localProcess = self._campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N31_ANNIVERSARY)
    ---@type TimeRewardComponent
    self._timeRewardComponent = self._localProcess:GetComponent(ECampaignN31AnniversaryComponentID.TIME_REWARD)
    ---@type TimeRewardComponentInfo
    self._timeRewardComponentInfo = self._timeRewardComponent:GetComponentInfo()
    ---@type CumulativeLoginComponent
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN31AnniversaryComponentID.CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._cumulativeLoginComponent:GetComponentInfo()
    -- if not self:_CheckAutoPop() then
    --     return
    -- end
    self:_GetComponents()
    self:_OnValue()
    self:_ForceRefresh()
end

--获取ui组件
function UIN31SecondAnniversaryContent:_GetComponents()
    ---@type UILocalizedTMP
    self._remainTime = self:GetUIComponent("UILocalizationText", "RemainTime")
    self._bigAwardBtnGo = self:GetGameObject("BigAwardBtn")
    self._bigAwardGotGo = self:GetGameObject("BigAwardGot")
    self._bigAwardUnlockTimedGo = self:GetGameObject("BigAwardUnlockTime")
    self._unlockTime = self:GetUIComponent("UILocalizationText", "UnlockTime")
    ---@type UILocalizationText
    self._wishesText = self:GetUIComponent("UILocalizationText", "WishesText")
    ---@type UILocalizationText
    self._authorText = self:GetUIComponent("UILocalizationText", "AuthorText")
    ---@type UICustomWidgetPool
    self._awardItem = self:GetUIComponent("UISelectObjectPath", "AwardItem")
    ---@type UILocalizationText
    self._awardText = self:GetUIComponent("UILocalizationText", "AwardText")
    ---@type UILocalizationText
    self._remainSignTimes = self:GetUIComponent("UILocalizationText", "RemainSignTimes")
    --self._rePlayGo = self:GetGameObject("RePlay")
    ---@type UnityEngine.Animation
    --self._rePlayAnimation = self:GetUIComponent("Animation", "RePlay")
    self._itemTips = self:GetUIComponent("UISelectObjectPath", "ItemTips")
    self._tips = self._itemTips:SpawnObject("UIN31SecondAnniversaryItemTips")
    self._remainSignGo = self:GetGameObject("RemainSign")
    self._signBtnGo = self:GetGameObject("SignBtn")
    self._signCDGo = self:GetGameObject("SignCD")
    self._signCDText = self:GetUIComponent("UILocalizationText", "SignCDText")

    -- self._matReq = UIWidgetHelper.SetLocalizedTMPMaterial(self, "titleSDF", "ui_second_anniversary_sdf_mat.mat", self._matReq)
    -- self._matReq1 = UIWidgetHelper.SetLocalizedTMPMaterial(self, "title1SDF", "ui_second_anniversary_sdf_mat.mat", self._matReq1)
end

function UIN31SecondAnniversaryContent:_OnValue()
    if not self._campaign:CheckCampaignOpen() then
        local result = self._campaign:CheckComponentOpenClientError(ECampaignN31AnniversaryComponentID.TIME_REWARD) 
        self._campaign:CheckErrorCode(result)
        return
    end
    
    local curtime = self._svrTimeModule:GetServerTime() * 0.001
    local endTime = self._campaign:GetSample().end_time
    local remainTime = endTime - curtime
    self._remainTime:SetText(UIN31SecondAnniversaryToolFunctions.GetRemainTime(remainTime))
    ---@type TimeRewardInfo
    local bigTimeRewardInfo = nil
    self._bigAwardID = nil
    if self._timeRewardComponentInfo.m_reward_info then
        for id, timeRewardInfo in pairs(self._timeRewardComponentInfo.m_reward_info) do
            if not bigTimeRewardInfo then
                bigTimeRewardInfo = timeRewardInfo
            end
            if not self._bigAwardID then
                self._bigAwardID = id
            end
            break
        end
    end
    self._bigAwardLock = false
    local bigAwardGot = false
    if bigTimeRewardInfo then
        if bigTimeRewardInfo.rec_reward_status == ETimeRewardRewardStatus.E_TIME_REWARD_LOCK then
            remainTime = bigTimeRewardInfo.unlock_time - curtime
            self._bigAwardLock = true
            self._unlockTime:SetText(UIN31SecondAnniversaryToolFunctions.GetRemainTime(remainTime))
            self._bigAwardBtnGo:SetActive(false)
            self._bigAwardGotGo:SetActive(false)
        elseif bigTimeRewardInfo.rec_reward_status == ETimeRewardRewardStatus.E_TIME_REWARD_CAN_RECV then
            self._bigAwardBtnGo:SetActive(true)
            self._bigAwardGotGo:SetActive(false)
        elseif bigTimeRewardInfo.rec_reward_status == ETimeRewardRewardStatus.E_TIME_REWARD_RECVED then
            self._bigAwardBtnGo:SetActive(false)
            self._bigAwardGotGo:SetActive(true)
            bigAwardGot = true
        end
    end
    self._bigAwardUnlockTimedGo:SetActive(self._bigAwardLock)
    --self._rePlayGo:SetActive(bigAwardGot)
    -- if bigAwardGot then
    --     self._rePlayAnimation:Play("uieff_UIN25NewYear01_in")
    -- end
    self:_SetWishesText()
    self:_SetSignInfo()
end

function UIN31SecondAnniversaryContent:GetBigAwardStatus()
    local bigTimeRewardInfo = nil
    if self._timeRewardComponentInfo.m_reward_info then
        for id, timeRewardInfo in pairs(self._timeRewardComponentInfo.m_reward_info) do
            if not bigTimeRewardInfo then
                bigTimeRewardInfo = timeRewardInfo
            end
            break
        end
    end
    if bigTimeRewardInfo then
        return bigTimeRewardInfo.rec_reward_status
    end
    return nil
end

function UIN31SecondAnniversaryContent:_ForceRefresh()
    if self._refreshTaskID ~= nil then
        return
    end
    self._refreshTaskID = self:StartTask(function(TT)
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self._campaign:ReLoadCampaignInfo_Force(TT, res)
            if res and res:GetSucc() then
                self:_OnValue()
            end
            self._refreshTaskID = nil
        end,
        self
    )
end

---新年寄语
function UIN31SecondAnniversaryContent:_SetWishesText()
    local index = 1
    local strTable = {}
    while true do
        local key = "str_n31_second_anniversary_wishes_"..index
        local str = StringTable.Has(key)
        if str then
            strTable[index] = {}
            strTable[index].text = HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(key))
            strTable[index].author = StringTable.Get("str_n31_second_anniversary_author_"..index)
            index = index + 1
        else
            break
        end
    end
    if #strTable < 1 then
        Log.fatal("N31 second anniversary message is not configured.")
        return
    end
    local wishesStrTable = strTable[1]
    if self._autoPop then
        local index = math.random(1, #strTable)
        wishesStrTable = strTable[index]
        UIN31SecondAnniversaryToolFunctions.SetLocalDBInt("UIN31SecondAnniversaryWishIndex", index)
    else
        local index = UIN31SecondAnniversaryToolFunctions.GetLocalDBInt("UIN31SecondAnniversaryWishIndex", 1)
        wishesStrTable = strTable[index]
        if not wishesStrTable then
            wishesStrTable = strTable[1]
        end
    end
    self._wishesText:SetText(wishesStrTable.text)
    self._authorText:SetText("—— "..wishesStrTable.author)
end

function UIN31SecondAnniversaryContent:_SetSignInfo()
    ---@type CumulativeLoginRewardInfo[]
    local CumulativeLoginRewardInfos = self._cumulativeLoginComponentInfo.m_cumulative_info
    local remainSignCount = 0
    self._day = 0 --当前可以领取奖励的那一天
    local SignAward = nil --每次签到领取的奖励都是一样的
    local nextLockAward = nil --下一个准备领取但是却没有解锁的
    for _, info in pairs(CumulativeLoginRewardInfos) do
        if info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK or info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV then
            remainSignCount = remainSignCount + 1
        end
        if info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV then
            if self._day == 0 then
                self._day = info.m_login_days
            end
        end
        if not nextLockAward then
            if info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK then
                nextLockAward = info
            end
        end
        if not SignAward then
            SignAward = info.m_rewards
        end
    end
    if self._day > 0 then --可以签到
        self._canSign = true
        self._signBtnGo:SetActive(true)
        self._signCDGo:SetActive(false)
    else
        if remainSignCount <= 0 then --签到完成
            self._signCDText:SetText(StringTable.Get("str_n31_second_anniversary_sign_done"))
        else --距离下次签到剩余时间
            local curTime = self._svrTimeModule:GetServerTime() * 0.001
            local unlockTime = self._cumulativeLoginComponentInfo.m_unlock_time
            local nextRefreshTime = self._loginModule:GetCampaignRefreshTime()
            if curTime >= unlockTime then --签到组件解锁
                if nextLockAward then
                    local awardUnlockTime = nextLockAward.m_login_unlock_time
                    self._signCDText:SetText(UIN31SecondAnniversaryToolFunctions.GetSignRemainTime(awardUnlockTime - curTime)) --签到组件解锁了但是下一个待签到的奖励未解锁
                else
                    self._signCDText:SetText(UIN31SecondAnniversaryToolFunctions.GetSignRemainTime(nextRefreshTime - curTime))
                end
            else
                self._signCDText:SetText(UIN31SecondAnniversaryToolFunctions.GetSignRemainTime(unlockTime - curTime)) --签到组件未解锁显示签到组件的解锁时间
            end
        end
        self._canSign = false
        self._signBtnGo:SetActive(false)
        self._signCDGo:SetActive(true)
    end
    if remainSignCount > 0 then
        local str = string.format("<color=#FDE06C>%s</color>", remainSignCount)
        self._remainSignTimes:SetText(StringTable.Get("str_n31_second_anniversary_remain_sign", str))
    end
    self._remainSignGo:SetActive(remainSignCount > 0)
    if SignAward and SignAward[1] then
        ---@type RoleAsset
        local award = SignAward[1]
        local awardItem = self._awardItem:SpawnObject("UIN31SecondAnniversaryAwardItem")
        awardItem:SetData(
            award, 
            function (id, position)
                self:_ShowTips(id, position)
            end
        )
        self._awardText:SetText(StringTable.Get("str_n31_second_anniversary_sign_award", award.count))
    end
end

--大奖预览
function UIN31SecondAnniversaryContent:PreViewAwardBtnOnClick(go)
    local bigRewardStatus = self:GetBigAwardStatus()
    if bigRewardStatus == ETimeRewardRewardStatus.E_TIME_REWARD_LOCK then
        ToastManager.ShowToast(StringTable.Get("str_n31_second_anniversary_tips"))
    else
        self:ShowDialog("UIN31SecondAnniversaryAwards", self._timeRewardComponentInfo.m_reward_info) 
    end
end

--领取大奖
function UIN31SecondAnniversaryContent:BigAwardBtnOnClick(go)
    if not self._bigAwardLock then
        self._timeRewardComponent:Start_HandleTakeTimeRewardReward(
            self._bigAwardID,
            function (res, rewards)
                if res:GetSucc() then
                    self:ShowDialog("UIGetItemController", rewards)
                    self._autoPop = false
                    self:_OnValue()
                else
                    self._campaign:CheckErrorCode(res.m_result, nil, nil)
                end
            end
        )
    end
end

--签到
function UIN31SecondAnniversaryContent:SignBtnOnClick(go)
    if self._canSign then
        self:StartTask(
            function(TT)
                local res = AsyncRequestRes:New()
                local rewards = self._cumulativeLoginComponent:HandleReceiveCumulativeLoginReward(TT, res, self._day)
                if res:GetSucc() then
                    self:ShowDialog("UIGetItemController", rewards)
                    self._autoPop = false
                    --刷新信息
                    local res = AsyncRequestRes:New()
                    self._campaign:ReLoadCampaignInfo_Force(TT, res)
                    self:_OnValue()
                else
                    self._campaign:CheckErrorCode(res.m_result, nil, nil)
                end
            end,
            self
        )
    end
end

--重播剧情
-- function UIN31SecondAnniversaryContent:RePlayBtnOnClick(go)
--     if self._storyID then
--         self:ShowDialog("UIStoryController", self._storyID)
--     end
-- end

--关闭
function UIN31SecondAnniversaryContent:CloseBtnOnClick(go)
    self:CloseDialog()
end

function UIN31SecondAnniversaryContent:_ShowTips(id, position)
    self._tips:SetData(id, position)
end

--如果奖励全部领取了，就不在自动弹窗了
function UIN31SecondAnniversaryContent.CheckAutoPop(campaign)
    if not campaign:CheckCampaignOpen() then
        return false
    end
    local remainSignCount = 0
    local loginComponentInfo = campaign:GetComponentInfo(ECampaignN31AnniversaryComponentID.CUMULATIVE_LOGIN)
    if not loginComponentInfo then
        return false
    end
    ---@type CumulativeLoginRewardInfo[]
    local CumulativeLoginRewardInfos = loginComponentInfo.m_cumulative_info
    for _, info in pairs(CumulativeLoginRewardInfos) do
        if info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK or info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV then
            remainSignCount = remainSignCount + 1
        end
    end
    local bigAwardGot = false
    ---@type TimeRewardInfo[]
    local timeRewardInfos = campaign:GetComponentInfo(ECampaignN31AnniversaryComponentID.TIME_REWARD).m_reward_info
    for _, timeRewardInfo in pairs(timeRewardInfos) do
        if timeRewardInfo then
            bigAwardGot = timeRewardInfo.rec_reward_status == ETimeRewardRewardStatus.E_TIME_REWARD_RECVED
        end
        break
    end
    if bigAwardGot and remainSignCount <= 0 then
        return false
    end
    return true
end

function UIN31SecondAnniversaryContent:DoHide()
    self._tips:ForceHideObject()
end

function UIN31SecondAnniversaryContent:DoDestroy()
    -- self._matReq = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._matReq)
    -- self._matReq1 = UIWidgetHelper.DisposeLocalizedTMPMaterial(self._matReq1)
end