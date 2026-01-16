---@class UISummer1Review:UIController
_class("UISummer1Review", UIController)
UISummer1Review = UISummer1Review

function UISummer1Review:LoadDataOnEnter(TT, res, uiParams)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_REVIEW_N3,
        ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_LINE_MISSION,
        ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_STAGE2_LINE_MISSION,
        ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_POINT_PROGRESS
    )

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignReviewN3
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --获取组件
    --普通线性关组件
    ---@type LineMissionComponent
    self._lineMissionComponent = self._localProcess:GetComponent(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._lineMissionCompInfo = self._localProcess:GetComponentInfo(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_LINE_MISSION)
    --困难线性关
    ---@type LineMissionComponent
    self._hardLineMissionComponent = self._localProcess:GetComponent(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_STAGE2_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._hardLineMissionCompInfo = self._localProcess:GetComponentInfo(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_STAGE2_LINE_MISSION)
    --个人进度组件
    ---@type PointProgressComponent
    self._pointProgressComponent = self._localProcess:GetComponent(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_POINT_PROGRESS)
    ---@type PointProgressComponentInfo
    self._pointProgressCompInfo = self._localProcess:GetComponentInfo(ECampaignReviewN3ComponentID.ECAMPAIGN_REVIEW_ReviewN3_POINT_PROGRESS)

    self._isHardLevelOpen = false
    if self._hardLineMissionComponent and self._hardLineMissionComponent:ComponentIsOpen() then
        self._isHardLevelOpen = true
    end
end

function UISummer1Review:OnShow(uiParams)
    self._btns = self:GetGameObject("Btns")
    self._mask = self:GetGameObject("Mask")
    self._btns:SetActive(true)
    self._mask:SetActive(false)
    self._redStageNormal = self:GetGameObject("redStageNormal")
    self._newStageHard = self:GetGameObject("newStageHard")
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    ---@type UICommonTopButton
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:PlayAnimOut(
                function()
                    self:SwitchState(UIStateType.UIActivityReview)
                end
            )
        end,
        nil,
        nil,
        nil,
        function()
            self:HideBtnOnClick()
        end
    )
    ---@type UnityEngine.UI.Button
    self._btnStageHard = self:GetUIComponent("Button", "btnStageHard")
    self._imgStageHard = self:GetGameObject("imgStageHard")
    self._imgStageHardGray = self:GetGameObject("imgStageHardGray")
    local s = self:GetUIComponent("UISelectObjectPath", "ItemInfo")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")
    self._tips:SetType(3)
    local detailObj = self._tips:GetG3CustomPool()
    detailObj.dynamicInfoOfEngine:SetObjectName("UISummer1SelectInfoReview.prefab")
    ---@type UISummer1SelectInfoReview
    self._selectDetail = detailObj:SpawnObject("UISummer1SelectInfoReview")
    self._tips._selectInfo.sizeDelta = Vector2(550, 200)
    self._tips:GetOffset()
    local go = self._tips:GetGameObject("g3")
    local tran = go.transform:Find("bg3")
    tran.gameObject:SetActive(false)
    self:RefreshRedAndNew()
    self:RefreshBtnStatus()
    self:RefreshRewards()

    self._shot = self:GetUIComponent("RawImage","shot")
    self._anim = self:GetGameObject("anim")

    self._rt = uiParams[1]
    self._anim:SetActive(self._rt~=nil) 
    if self._rt then
        self._shot.texture = self._rt
    end   
end

function UISummer1Review:HideBtnOnClick()
    local anim = self:GetGameObject("anim")
    anim:SetActive(false)
    local btns = self:GetGameObject("Btns")
    btns:SetActive(false)
    local showBtn = self:GetGameObject("showBtn")
    showBtn:SetActive(true)
end

function UISummer1Review:ShowBtnOnClick()
    local anim = self:GetGameObject("anim")
    anim:SetActive(true)
    local btns = self:GetGameObject("Btns")
    btns:SetActive(true)
    local showBtn = self:GetGameObject("showBtn")
    showBtn:SetActive(false)
end

function UISummer1Review:OnHide()
end

function UISummer1Review:ShowItemInfo(roleAsset, pos)
    if self._tips then
        self._selectDetail:SetData(roleAsset)
        self._tips:OnlyShow(pos)
    end
end

function UISummer1Review:RefreshRewards()
    if not self._pointProgressCompInfo then
        return
    end

    local currentProgress = self._pointProgressCompInfo.m_current_progress
    local totalProgress = self._pointProgressCompInfo.m_total_progress
    local process = currentProgress / totalProgress

    local isProgressGet = function(p)
        for i = 1, #self._pointProgressCompInfo.m_received_progress do
            if self._pointProgressCompInfo.m_received_progress[i] == p then
                return true
            end
        end
        return false
    end

    local datas = {}
    local hasRewards = false
    for p, rewards in pairs(self._pointProgressCompInfo.m_progress_rewards) do
        local data = {}
        data.progress = p
        data.rewards = rewards
        data.status = 0 --1:已领取，2:最近的可领取，3:可领取或未完成
        if process * 100 >= p then
            if not isProgressGet(p) then
                hasRewards = true
                data.status = 2
            else
                data.status = 1
            end
        else
            data.status = 3
        end
        datas[#datas + 1] = data
    end

    table.sort(datas, function(a, b)
       return a.progress < b.progress 
    end)

    local isFirst = true
    self._currentRewardData = nil
    for i = 1, #datas do
        if datas[i].status == 2 then
            if isFirst then
                isFirst = false
                self._currentRewardData = datas[i]
            -- else
            --     datas[i].status = 3
            end
        end
    end

    if not self._currentRewardData then
        if currentProgress >= totalProgress then
            self._currentRewardData = datas[#datas]
        else
            for i = 1, #datas do
                if datas[i].status == 3 then
                    self._currentRewardData = datas[i]
                    break
                end
            end
        end
    end

    local canGetGo = self:GetGameObject("CanGet")
    local hasGetGo = self:GetGameObject("HasGet")
    local noGetGo = self:GetGameObject("NoGet")
    canGetGo:SetActive(false)
    hasGetGo:SetActive(false)
    noGetGo:SetActive(false)
    if hasRewards then
        canGetGo:SetActive(true)
    else
        if currentProgress >= totalProgress then
            hasGetGo:SetActive(true)
        else
            noGetGo:SetActive(true)
        end
    end
    
    local processStr = math.floor(100 * process)
    local percentLabel = self:GetUIComponent("UILocalizationText", "Percent")
    percentLabel:SetText(processStr .. "%")
    local progressBar = self:GetUIComponent("Slider", "Progress")
    progressBar.value = process

    local rewardLoader = self:GetUIComponent("UISelectObjectPath", "Rewards")
    rewardLoader:SpawnObjects("UIXH1Summer1ProcessItemReview", #datas)
    ---@type table<number,UIXH1Summer1ProcessItemReview>
    local items = rewardLoader:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetData(self, datas[i])
    end

    if self._currentRewardData then
        if self._currentRewardData.rewards ~= nil and #self._currentRewardData.rewards > 0 then
            ---@type RoleAsset
            local roleAsset = self._currentRewardData.rewards[1]
            local cfg = Cfg.cfg_item[roleAsset.assetid]
            ---@type RawImageLoader
            local iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
            iconLoader:LoadImage(cfg.Icon)
            local countLabel = self:GetUIComponent("UILocalizationText", "Count")
            countLabel:SetText(roleAsset.count)
        end
    end

    self._datas = datas
end

function UISummer1Review:GetReward(progress)
    self:StartTask(self.GetRewardCoro, self, progress)
end

function UISummer1Review:GetRewardCoro(TT, progress)
    self:Lock("UISummer1Review_GetRewardCoro")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    local rewards = self._pointProgressComponent:HandleReceiveReward(TT, res, progress)
    if rewards and #rewards > 0 then
        UIActivityHelper.ShowUIGetRewards(rewards)
        self:RefreshRewards()
    end
    self:UnLock("UISummer1Review_GetRewardCoro")
end

function UISummer1Review:RewardBtnOnClick()
    self:ShowDialog("UISummer1RewardDetailRewivw", self._datas,
        function(progress)
            self:GetReward(progress)
        end)
end

function UISummer1Review:RefreshRedAndNew()
    self._redStageNormal:SetActive(false)
    if self._isHardLevelOpen then
        self._newStageHard:SetActive(self:GetNewFlagStatus(1))
    else
        self._newStageHard:SetActive(false)
    end
end

function UISummer1Review:RefreshBtnStatus()
    self._btnStageHard.interactable = self._isHardLevelOpen
    self._imgStageHard:SetActive(self._isHardLevelOpen)
    self._imgStageHardGray:SetActive(not self._isHardLevelOpen)
end

function UISummer1Review:PlayAnimOut(callback)
    self:StartTask(
        function(TT)
            self:Lock("UISummer1PlayAnimOut")
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1SeaWave)
            self:UnLock("UISummer1PlayAnimOut")
            if callback then
                callback()
            end
        end,
        self
    )
end

function UISummer1Review:ShowHideUI()
    self:StartTask(
        function(TT)
            self:Lock("UISummer1ShowHideUI")
            self._btns:SetActive(false)
            self._mask:SetActive(true)
            self:UnLock("UISummer1ShowHideUI")
        end,
        self
    )
end

function UISummer1Review:MaskOnClick()
    self._btns:SetActive(true)
    self._mask:SetActive(false)
end

function UISummer1Review:btnStageHardOnClick()
    if not self._isHardLevelOpen then
        ToastManager.ShowToast(StringTable.Get("str_summer_review_hard_level_unopen"))
        return
    end
    self:SetNewFlagStatus(1, false)
    self._newStageHard:SetActive(false)
    self:SwitchState(UIStateType.UIXH1HardLevelReview)
end

function UISummer1Review:btnStageNormalOnClick()
    self:SwitchState(UIStateType.UIXH1SimpleLevelReview)
end

function UISummer1Review:IconOnClick()
    if not self._currentRewardData then
        return
    end
    local roleAsset = self._currentRewardData.rewards[1]
    local icon = self:GetGameObject("Icon")
    self:ShowItemInfo(roleAsset, icon.transform.position)
end

function UISummer1Review:CanGetOnClick()
    if not self._currentRewardData then
        return
    end
    self:GetReward(self._currentRewardData.progress)
end

function UISummer1Review:GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N3_REVIEW_NEW_FLAG" .. id
    return key
end

function UISummer1Review:GetNewFlagStatus(id)
    local key = self:GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UISummer1Review:SetNewFlagStatus(id, status)
    local key = self:GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

function UISummer1Review:BtnOnClick()
    self:ShowDialog("UISummer1RewardDetailRewivw", self._datas,
    function(progress)
        self:GetReward(progress)
    end)
end
