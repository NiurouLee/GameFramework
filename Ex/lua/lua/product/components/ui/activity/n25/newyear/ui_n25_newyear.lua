--
---@class UIN25NewYear : UIController
_class("UIN25NewYear", UIController)
UIN25NewYear = UIN25NewYear

function UIN25NewYear:Constructor()
    self._loginModule = self:GetModule(LoginModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._campaignModule = self:GetModule(CampaignModule)
    self._loginModule = self:GetModule(LoginModule)
end

---@param res AsyncRequestRes
function UIN25NewYear:LoadDataOnEnter(TT, res, uiParams)
    self._autoPop = uiParams[1]
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N25_NEW_YEAR,
        ECampaignN25NewYearComponentID.CUMULATIVE_LOGIN,
        ECampaignN25NewYearComponentID.TIME_REWARD
    )
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    local cfg = Cfg.cfg_campaign[self._campaign._id]
    self._storyID = cfg.FirstEnterStoryID[1]
    ---@type CCampaignN25NewYear
    self._localProcess = self._campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N25_NEW_YEAR)
    ---@type TimeRewardComponent
    self._timeRewardComponent = self._localProcess:GetComponent(ECampaignN25NewYearComponentID.TIME_REWARD)
    ---@type TimeRewardComponentInfo
    self._timeRewardComponentInfo = self._timeRewardComponent:GetComponentInfo()
    ---@type CumulativeLoginComponent
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN25NewYearComponentID.CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._cumulativeLoginComponent:GetComponentInfo()
    if not self:_CheckAutoPop() then
        res:SetResult(-1)
        return res
    end
end

--初始化
function UIN25NewYear:OnShow(uiParams)
    self:_GetComponents()
    self:_OnValue()
end

--获取ui组件
function UIN25NewYear:_GetComponents()
    ---@type UILocalizedTMP
    self._remainTime = self:GetUIComponent("UILocalizedTMP", "RemainTime")
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
    self._rePlayGo = self:GetGameObject("RePlay")
    ---@type UnityEngine.Animation
    self._rePlayAnimation = self:GetUIComponent("Animation", "RePlay")
    self._itemTips = self:GetUIComponent("UISelectObjectPath", "ItemTips")
    ---@type UIN25NewYearItemTips
    self._tips = self._itemTips:SpawnObject("UIN25NewYearItemTips")
    self._remainSignGo = self:GetGameObject("RemainSign")
    self._signBtnGo = self:GetGameObject("SignBtn")
    self._signCDGo = self:GetGameObject("SignCD")
    ---@type UILocalizedTMP
    self._signCDText = self:GetUIComponent("UILocalizedTMP", "SignCDText")
end

function UIN25NewYear:_OnValue()
    local curtime = self._svrTimeModule:GetServerTime() * 0.001
    local endTime = self._campaign:GetSample().end_time
    local remainTime = endTime - curtime
    self._remainTime:SetText(UIN25NewYearToolFunctions.GetRemainTime(remainTime))
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
            self._unlockTime:SetText(UIN25NewYearToolFunctions.GetRemainTime(remainTime))
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
    self._rePlayGo:SetActive(bigAwardGot)
    if bigAwardGot then
        self._rePlayAnimation:Play("uieff_UIN25NewYear01_in")
    end
    self:_SetWishesText()
    self:_SetSignInfo()
end

---新年寄语
function UIN25NewYear:_SetWishesText()
    local index = 1
    local strTable = {}
    while true do
        local key = "str_n25_newyear_wishes_"..index
        local str = StringTable.Has(key)
        if str then
            strTable[index] = {}
            strTable[index].text = HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(key))
            strTable[index].author = StringTable.Get("str_n25_newyear_author_"..index)
            index = index + 1
        else
            break
        end
    end
    if #strTable < 1 then
        Log.fatal("N25 New Year message is not configured.")
        return
    end
    local wishesStrTable = strTable[1]
    if self._autoPop then
        local index = math.random(1, #strTable)
        wishesStrTable = strTable[index]
        UIN25NewYearToolFunctions.SetLocalDBInt("UIN25NewYearWishIndex", index)
    else
        local index = UIN25NewYearToolFunctions.GetLocalDBInt("UIN25NewYearWishIndex", 1)
        wishesStrTable = strTable[index]
        if not wishesStrTable then
            wishesStrTable = strTable[1]
        end
    end
    self._wishesText:SetText(wishesStrTable.text)
    self._authorText:SetText("-- "..wishesStrTable.author)
end

function UIN25NewYear:_SetSignInfo()
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
            self._signCDText:SetText(StringTable.Get("str_n25_newyear_sign_done"))
        else --距离下次签到剩余时间
            local curTime = self._svrTimeModule:GetServerTime() * 0.001
            local unlockTime = self._cumulativeLoginComponentInfo.m_unlock_time
            local nextRefreshTime = self._loginModule:GetCampaignRefreshTime()
            if curTime >= unlockTime then --签到组件解锁
                if nextLockAward then
                    local awardUnlockTime = nextLockAward.m_login_unlock_time
                    self._signCDText:SetText(UIN25NewYearToolFunctions.GetRemainTime(awardUnlockTime - curTime)) --签到组件解锁了但是下一个待签到的奖励未解锁
                else
                    self._signCDText:SetText(UIN25NewYearToolFunctions.GetRemainTime(nextRefreshTime - curTime))
                end
            else
                self._signCDText:SetText(UIN25NewYearToolFunctions.GetRemainTime(unlockTime - curTime)) --签到组件未解锁显示签到组件的解锁时间
            end
        end
        self._canSign = false
        self._signBtnGo:SetActive(false)
        self._signCDGo:SetActive(true)
    end
    if remainSignCount > 0 then
        local str = string.format("<color=#FDE06C>%s</color>", remainSignCount)
        self._remainSignTimes:SetText(StringTable.Get("str_n25_newyear_remain_sign", str))
    end
    self._remainSignGo:SetActive(remainSignCount > 0)
    if SignAward and SignAward[1] then
        ---@type RoleAsset
        local award = SignAward[1]
        ---@type UIN25NewYearAwardItem
        local awardItem = self._awardItem:SpawnObject("UIN25NewYearAwardItem")
        awardItem:SetData(
            award, 
            function (id, position)
                self:_ShowTips(id, position)
            end
        )
        self._awardText:SetText(StringTable.Get("str_n25_newyear_sign_award", award.count))
    end
end

--大奖预览
function UIN25NewYear:PreViewAwardBtnOnClick(go)
    self:ShowDialog("UIN25NewYearAwards", self._timeRewardComponentInfo.m_reward_info)
end

--领取大奖
function UIN25NewYear:BigAwardBtnOnClick(go)
    if not self._bigAwardLock then
        self._timeRewardComponent:Start_HandleTakeTimeRewardReward(
            self._bigAwardID,
            function (res, rewards)
                if res:GetSucc() then
                    if self._storyID then
                        self:ShowDialog("UIStoryController", 
                        self._storyID, 
                        function ()
                            self:ShowDialog("UIGetItemController", rewards)
                            self._autoPop = false
                            self:_OnValue()
                        end)
                    else
                        self:ShowDialog("UIGetItemController", rewards)
                        self._autoPop = false
                        self:_OnValue()
                    end
                end
            end
        )
    end
end

--签到
function UIN25NewYear:SignBtnOnClick(go)
    if self._canSign then
        self:StartTask(
            function(TT)
                local res = AsyncRequestRes:New()
                local rewards = self._cumulativeLoginComponent:HandleReceiveCumulativeLoginReward(TT, res, self._day)
                if res:GetSucc() then
                    self:ShowDialog("UIGetItemController", rewards)
                    self._autoPop = false
                    self:_OnValue()
                end
            end,
            self
        )
    end
end

--重播剧情
function UIN25NewYear:RePlayBtnOnClick(go)
    if self._storyID then
        self:ShowDialog("UIStoryController", self._storyID)
    end
end

--关闭
function UIN25NewYear:CloseBtnOnClick(go)
    self:CloseDialog()
end

function UIN25NewYear:_ShowTips(id, position)
    self._tips:SetData(id, position)
end

--如果奖励全部领取了，就不在自动弹窗了
function UIN25NewYear:_CheckAutoPop()
    local remainSignCount = 0
    ---@type CumulativeLoginRewardInfo[]
    local CumulativeLoginRewardInfos = self._cumulativeLoginComponentInfo.m_cumulative_info
    for _, info in pairs(CumulativeLoginRewardInfos) do
        if info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK or info.m_reward_status == ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV then
            remainSignCount = remainSignCount + 1
        end
    end
    local bigAwardGot = false
    ---@type TimeRewardInfo[]
    local timeRewardInfos = self._timeRewardComponentInfo.m_reward_info
    for _, timeRewardInfo in pairs(timeRewardInfos) do
        if timeRewardInfo then
            bigAwardGot = timeRewardInfo.rec_reward_status == ETimeRewardRewardStatus.E_TIME_REWARD_RECVED
        end
        break
    end
    if bigAwardGot and remainSignCount <= 0 and self._autoPop then
        return false
    end
    return true
end