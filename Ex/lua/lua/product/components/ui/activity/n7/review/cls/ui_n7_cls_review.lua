---@class N7DataReview:CampaignDataBase
---@field progresses N7DataReviewProgress[]
---@field papers BlackFightPaperData[] 小报列表
_class("N7DataReview", CampaignDataBase)
N7DataReview = N7DataReview

function N7DataReview:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.mMission = GameGlobal.GetModule(MissionModule)

    self.componentIdLine = ECampaignReviewN7ComponentID.ECAMPAIGN_REVIEW_ReviewN7_LINE_MISSION
    self.componentIdProgress = ECampaignReviewN7ComponentID.ECAMPAIGN_REVIEW_ReviewN7_POINT_PROGRESS
end

function N7DataReview:Init()
    self:InitProgress()
    self:InitPapers()
end
function N7DataReview:InitProgress()
    local cInfo = self:GetComponentInfoProgress()
    local m_progress_rewards = cInfo.m_progress_rewards
    self.progresses = {}
    for p, rewards in pairs(m_progress_rewards) do
        local progress = N7DataReviewProgress:New()
        progress.progress = p
        progress.awards = rewards
        table.insert(self.progresses, progress)
    end
    table.sort(
        self.progresses,
        function(a, b)
            return a.progress < b.progress
        end
    )
end
function N7DataReview:InitPapers()
    self.papers = {}
    local cfgPaper = Cfg.cfg_n7_black_fight_paper_review()
    for k, cfgv in pairs(cfgPaper) do
        local paper = BlackFightPaperData:New()
        ---@param paper BlackFightPaperData
        ---@field missionId number
        paper.Init = function(paper, idx)
            paper.idx = idx
            paper.unlockReputation = nil
            paper.missionId = cfgv.Condition
            paper.elementsL, paper.elementsR = paper:GetElements(cfgv, "PartsDetails")
            return cfgv
        end
        paper.IsUnlock = function(paper)
            if paper.missionId == 0 then
                return true
            end
            local info = self:GetComponentInfoNormal()
            if info and info.m_pass_mission_info and info.m_pass_mission_info[paper.missionId] then --是否通关
                return true
            end
            return false
        end
        paper.GetPrefsKeyPaperUnlock = function(idx)
            return Summer1Data.GetPrefsKey("BlackFightPaperUnlockRview") .. idx
        end
        paper:Init(k)
        table.insert(self.papers, paper)
    end
end

---@param res AsyncRequestRes
function N7DataReview.CheckCode(res)
    local result = res:GetResult()
    if result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS then
        return true
    end
    ToastManager.ShowToast(StringTable.Get("str_activity_error_" .. result))
    if
        result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED or
            result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
     then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain) --活动结束，切到主界面
    end
    return false
end

--region 红点 new
function N7DataReview:CheckRedNormal()
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local red = self.mCampaign:CheckComponentRed(lp, self.componentIdLine)
        return red
    end
    return false
end
function N7DataReview:CheckRedProgress()
    local state = self:GetStateProgress()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local red = self.mCampaign:CheckComponentRed(lp, self.componentIdProgress)
        return red
    end
    return false
end
--endregion

--region Component ComponentInfo
---@return LineMissionComponent 线性关
function N7DataReview:GetComponentNormal()
    local c = self.activityCampaign:GetComponent(self.componentIdLine)
    return c
end
---@return LineMissionComponentInfo 线性关
function N7DataReview:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(self.componentIdLine)
    return cInfo
end

---@return PointProgressComponent 进度
function N7DataReview:GetComponentProgress()
    local c = self.activityCampaign:GetComponent(self.componentIdProgress)
    return c
end
---@return PointProgressComponentInfo 进度
function N7DataReview:GetComponentInfoProgress()
    local cInfo = self.activityCampaign:GetComponentInfo(self.componentIdProgress)
    return cInfo
end
--endregion

--region 显隐New
---@return UISummerOneEnterBtnState
function N7DataReview:GetState(cInfo)
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
---@return UISummerOneEnterBtnState
function N7DataReview:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N7DataReview:GetStateProgress()
    local c = self.activityCampaign:GetComponentInfo(self.componentIdProgress)
    if c then
        return self:GetState(c)
    end
end

function N7DataReview:CheckNewLine()
    if not N7DataReview.HasPrefsLine() and self:GetStateNormal() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
function N7DataReview:CheckNewProgress()
    if not N7DataReview.HasPrefsShop() and self:GetStateProgress() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
--endregion

---@return number 计算当前进度比例
function N7DataReview:GetCurProgressPercent()
    local cInfo = self:GetComponentInfoProgress()
    local currentProgress = cInfo.m_current_progress
    local totalProgress = cInfo.m_total_progress
    local process = currentProgress / totalProgress
    return process
end

---@return N7DataReviewProgress 获取第1个已完成但未领奖的进度
function N7DataReview:GetProgressCanGet()
    local cInfo = self:GetComponentInfoProgress()
    for index, progress in ipairs(self.progresses) do
        if progress:State() == CampaignPointProgressStatus.CPPS_Completed then
            return progress
        end
    end
end
---@return N7DataReviewProgress 获取第1个未达成的进度
function N7DataReview:GetProgressNext()
    local cInfo = self:GetComponentInfoProgress()
    for index, progress in ipairs(self.progresses) do
        if progress:State() == CampaignPointProgressStatus.CPPS_Accepted then
            return progress
        end
    end
end
---@return boolean 进度是否已满
function N7DataReview:IsProgressPercentFull()
    local percent = self:GetCurProgressPercent()
    local isFull = percent >= 1
    return isFull
end

--region Paper
---@return boolean, BlackFightPaperData
function N7DataReview:ExistNotReadPaper()
    if self.papers then
        for index, paper in ipairs(self.papers) do
            if not paper:HasRead() then
                return true, paper
            end
        end
    end
    return false, nil
end
function N7DataReview:ReadPaper(idx)
    if self.papers then
        for index, paper in ipairs(self.papers) do
            if paper.idx == idx then
                paper:Read()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.BlackFistUpdatePaperRed)
                return
            end
        end
    end
end

function N7DataReview:CheckGot(progress)
    local cInfo = self:GetComponentInfoProgress()
    if table.icontains(cInfo.m_received_progress, progress) then
        return true
    end
    return false
end

--endregion

--region N7DataReviewProgress
---@class N7DataReviewProgress:Object
---@field progress number 进度值
---@field awards RoleAsset[] 奖励列表
_class("N7DataReviewProgress", Object)
N7DataReviewProgress = N7DataReviewProgress

function N7DataReviewProgress:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN7DataReview()
end
---@return string
function N7DataReviewProgress:GetProgressPercentString()
    return self.progress .. "%"
end
---@return RoleAsset
function N7DataReviewProgress:Get1stAward()
    if self.awards then
        local ra = self.awards[1]
        if ra then
            return ra
        end
    end
    Log.fatal("### no award in this progress.", self.progress)
end
function N7DataReviewProgress:GetItemCfg(tplId)
    local cfgv = Cfg.cfg_item[tplId]
    if not cfgv then
        Log.fatal("### no data in cfg_item", tplId)
        return
    end
    return cfgv
end
function N7DataReviewProgress:IconNameDesc()
    local ra = self:Get1stAward()
    local cfg = self:GetItemCfg(ra.assetid)
    if cfg then
        return cfg.Icon, StringTable.Get(cfg.Name), StringTable.Get(cfg.Intro) --RpIntro
    end
end

---@return CampaignPointProgressStatus
function N7DataReviewProgress:State()
    local curProgressPercent = self.data:GetCurProgressPercent()
    if curProgressPercent * 100 >= self.progress then
        if self:HasGot() then
            return CampaignPointProgressStatus.CPPS_Taken --已领取
        else
            return CampaignPointProgressStatus.CPPS_Completed --已完成，未领取
        end
    else
        return CampaignPointProgressStatus.CPPS_Accepted --未领取
    end
end
---@return boolean 是否已领取
function N7DataReviewProgress:HasGot()
    local cInfo = self.data:GetComponentInfoProgress()
    if table.icontains(cInfo.m_received_progress, self.progress) then
        return true
    end
    return false
end
--endregion
