---@class UIActivityN21CCConst
_class("UIActivityN21CCConst", Object)
UIActivityN21CCConst = UIActivityN21CCConst

function UIActivityN21CCConst:Constructor()
end

---@param res AsyncRequestRes
function UIActivityN21CCConst:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE,
        ECampaignN21ChallengeComponentID.CHALLENGE,
        ECampaignN21ChallengeComponentID.PROGRESS
    )

    -- 错误处理
    if res and not res:GetSucc() then
        -- campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN21Challenge
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --获取组件
    --挑战关卡组件
    ---@type ChallengeMissionComponent
    self._challengeComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.CHALLENGE)
    ---@type ChallengeMissionComponentInfo
    self._challengeCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.CHALLENGE)
    ---个人进度组件
    self._processComponents = {}
    self._processCompInfos = {}
    ---@type PersonProgressComponent
    local progressComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.PROGRESS)
    ---@type PersonProgressComponentInfo
    local progressCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.PROGRESS)
    if progressComponent and progressCompInfo then
        self._processComponents[#self._processComponents + 1] = progressComponent
        self._processCompInfos[#self._processCompInfos + 1] = progressCompInfo
    end
    ---@type PersonProgressComponent
    progressComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.PROGRESS2)
    ---@type PersonProgressComponentInfo
    progressCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.PROGRESS2)
    if progressComponent and progressCompInfo then
        self._processComponents[#self._processComponents + 1] = progressComponent
        self._processCompInfos[#self._processCompInfos + 1] = progressCompInfo
    end
    ---@type PersonProgressComponent
    progressComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.PROGRESS3)
    ---@type PersonProgressComponentInfo
    progressCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.PROGRESS3)
    if progressComponent and progressCompInfo then
        self._processComponents[#self._processComponents + 1] = progressComponent
        self._processCompInfos[#self._processCompInfos + 1] = progressCompInfo
    end
    ---@type PersonProgressComponent
    progressComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.PROGRESS4)
    ---@type PersonProgressComponentInfo
    progressCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.PROGRESS4)
    if progressComponent and progressCompInfo then
        self._processComponents[#self._processComponents + 1] = progressComponent
        self._processCompInfos[#self._processCompInfos + 1] = progressCompInfo
    end
    ---@type PersonProgressComponent
    progressComponent = self._localProcess:GetComponent(ECampaignN21ChallengeComponentID.PROGRESS5)
    ---@type PersonProgressComponentInfo
    progressCompInfo = self._localProcess:GetComponentInfo(ECampaignN21ChallengeComponentID.PROGRESS5)
    if progressComponent and progressCompInfo then
        self._processComponents[#self._processComponents + 1] = progressComponent
        self._processCompInfos[#self._processCompInfos + 1] = progressCompInfo
    end
    self._rewardDatas = {}
    for i = 1, #self._processCompInfos do
        local data = UIActivityN21CCShopBossData:New(self._processComponents[i], self._processCompInfos[i])
        self._rewardDatas[#self._rewardDatas + 1] = data
    end
    ---@type UIActivityN21CCLevelGroupsData
    self._levelGroupsData = UIActivityN21CCLevelGroupsData:New(self._challengeComponent:GetComponentCfgId(), self._challengeCompInfo)
    --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --标题数据
    self._name = StringTable.Get(cfg_campaign.CampaignName)
    self._subName = StringTable.Get(cfg_campaign.CampaignSubtitle)

    --活动结束时间
    local sample = self._campaign:GetSample()
    if not sample then
        return
    end
    self._activeEndTime = sample.end_time
    --活动时间
    local nowTime = self._timeModule:GetServerTime() / 1000
    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function UIActivityN21CCConst:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityN21CCConst:GetCampaign()
    return self._campaign
end

function UIActivityN21CCConst:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN21CCConst:GetName()
    return self._name
end

--副标题
function UIActivityN21CCConst:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityN21CCConst:GetActiveEndTime()
    return self._activeEndTime
end

--挑战关卡组件
function UIActivityN21CCConst:GetChallengeComponent()
    return self._challengeComponent, self._challengeCompInfo
end

---个人进度组件
function UIActivityN21CCConst:GetAllProcessComponents()
    return self._processComponents, self._processCompInfos
end

--活动是否开启
function UIActivityN21CCConst:IsActivityEnd()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

--挑战关卡组件是否开启
function UIActivityN21CCConst:IsChallengeEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._challengeComponent then
        return false
    end
    return self._challengeComponent:ComponentIsOpen()
end

--个人进度组件是否开启
function UIActivityN21CCConst:IsProgressEnable()
    if self:IsActivityEnd() then
        return false
    end

    for i = 1, #self._processComponents do
        if self._processComponents[i]:ComponentIsOpen() then
            return true
        end
    end
    return false
end

--获取任务数据
function UIActivityN21CCConst:GetShopDatas()
    return self._rewardDatas
end

-- ---=========================================== 红点和NEW相关接口 ====================================================

function UIActivityN21CCConst:IsShowEntryNew()
    if UIActivityN21CCConst.GetEnterNewStatus() then
        return true
    end

    if self._levelGroupsData == nil then
        Log.error("New异常情况")
        return false
    end

    local levelGroups = self._levelGroupsData:GetOpenLevelGroups()
    for i = 1, #levelGroups do
        ---@type UIActivityN21CCLevelGroupData
        local levelGroup = levelGroups[i]
        if levelGroup:IsShowNew() then
            return true
        end
    end
    return false
end

function UIActivityN21CCConst:IsShowEntryRed()
    if self._levelGroupsData == nil then
        Log.error("红点异常情况")
        return false
    end

    local levelGroups = self._levelGroupsData:GetOpenLevelGroups()
    for i = 1, #levelGroups do
        ---@type UIActivityN21CCLevelGroupData
        local levelGroup = levelGroups[i]
        if levelGroup:IsShowRed() then
            return true
        end
    end

    if self:IsShowEventnRed() then
        return true
    end
    return false
end

--是否显示预兆任务
function UIActivityN21CCConst:IsShowEventnRed()
    if not self:IsProgressEnable() then
        return false
    end
    for i = 1, #self._rewardDatas do
        if self._rewardDatas[i]:HasCanGetReward() then
            return true
        end
    end
    return false
end

function UIActivityN21CCConst.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N21CC_MODULE_NEW_FLAG" .. id
    return key
end

function UIActivityN21CCConst.GetNewFlagStatus(id)
    local key = UIActivityN21CCConst.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN21CCConst.SetNewFlagStatus(id, status)
    local key = UIActivityN21CCConst.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

function UIActivityN21CCConst.GetEnterNewStatus()
    return UIActivityN21CCConst.GetNewFlagStatus("ENTRY_NEW")
end

function UIActivityN21CCConst.ClearEnterNewStatus()
    UIActivityN21CCConst.SetNewFlagStatus("ENTRY_NEW", false)
end

-- ---======================================================================================================================

function UIActivityN21CCConst.GetTimeString(seconds)
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n20_crisis_contract_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n20_crisis_contract_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n20_crisis_contract_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n20_crisis_contract_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n20_crisis_contract_less_one_minus")
        end
    end
    return timeStr
end

function UIActivityN21CCConst.GetLevelRedStatus()
    if UIActivityN21CCConst.LEVEL_RED_STATUS == nil then
        UIActivityN21CCConst.LEVEL_RED_STATUS = {}
    end
    return UIActivityN21CCConst.LEVEL_RED_STATUS
end

function UIActivityN21CCConst.SaveTeamInfo(TT, id, name, pets)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE, ECampaignN21ChallengeComponentID.CHALLENGE)
    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, campaign._id, nil, nil)
        return false
    end
    ---@type CCampaignN21Challenge
    local localProcess = campaign:GetLocalProcess()
    if not localProcess then
        return false
    end
    ---@type ChallengeMissionComponent
    local challengeComponent = localProcess:GetComponent(ECampaignN21ChallengeComponentID.CHALLENGE)
    ---@type ChallengeFormationItem
    local teamInfo = ChallengeFormationItem:New()
    teamInfo.id = id
    teamInfo.name = name
    teamInfo.pet_list = pets
    challengeComponent:HandleChallengeChangeFormationReq(TT, res, teamInfo)
    if res:GetSucc() then
        return true
    end
    return false
end

function UIActivityN21CCConst.SaveHistoryScore(missionId)
    if UIActivityN21CCConst.HISTORY_SCORE_CACHE == nil then
        UIActivityN21CCConst.HISTORY_SCORE_CACHE = {}
    end
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type CCampaignN21Challenge
    local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE)
    local historyScore = 0
    ---@type ChallengeMissionComponent
    local challengeComponent = progress:GetComponent(ECampaignN21ChallengeComponentID.CHALLENGE)
    ---@type ChallengeMissionComponentInfo
    local challengeCompInfo = progress:GetComponentInfo(ECampaignN21ChallengeComponentID.CHALLENGE)
    local cfgs = Cfg.cfg_component_challenge_mission{ComponentID = challengeComponent:GetComponentCfgId(), CampaignMissionId = missionId}
    if cfgs == nil or #cfgs <= 0 then
        return
    end
    local cfg = cfgs[1]
    if challengeCompInfo.m_max_score and challengeCompInfo.m_max_score[cfg.LeveIndex] then
        historyScore = challengeCompInfo.m_max_score[cfg.LeveIndex]
    end
    UIActivityN21CCConst.HISTORY_SCORE_CACHE[cfg.LeveIndex] = historyScore
end

function UIActivityN21CCConst.GetHistoryScore(missionId)
    if UIActivityN21CCConst.HISTORY_SCORE_CACHE == nil then
        return 0
    end

    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type CCampaignN21Challenge
    local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE)
    ---@type ChallengeMissionComponent
    local challengeComponent = progress:GetComponent(ECampaignN21ChallengeComponentID.CHALLENGE)
    local cfgs = Cfg.cfg_component_challenge_mission{ComponentID = challengeComponent:GetComponentCfgId(), CampaignMissionId = missionId}
    if cfgs == nil or #cfgs <= 0 then
        return
    end
    local cfg = cfgs[1]

    if UIActivityN21CCConst.HISTORY_SCORE_CACHE[cfg.LeveIndex] == nil then
        return 0
    end

    return UIActivityN21CCConst.HISTORY_SCORE_CACHE[cfg.LeveIndex]
end

function UIActivityN21CCConst.GetAffixCategoryIcon(type)
    local icons = 
    {
        [UIActivityN21CCAffixGroupType.SelfGain] = "n21_wjyz_ct_icon02",
        [UIActivityN21CCAffixGroupType.EnemyGain] = "n21_wjyz_ct_icon01"
    }
    return icons[type]
end

function UIActivityN21CCConst.ShowRewards(rewards, callback)
    local petIdList = {}
    local mPet = GameGlobal.GetModule(PetModule)
    for _, reward in pairs(rewards) do
        if mPet:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                GameGlobal.UIStateManager():ShowDialog(
                    "UIGetItemController",
                    rewards,
                    function()
                        if callback then
                            callback()
                        end
                    end
                )
            end
        )
        return
    end
    GameGlobal.UIStateManager():ShowDialog(
        "UIGetItemController",
        rewards,
        function()
            if callback then
                callback()
            end
        end
    )
end

function UIActivityN21CCConst.GetEnterBattleHardIndex()
    return UIActivityN21CCConst.ENTER_BATTLE_HARD_INDEX
end

function UIActivityN21CCConst.SetEnterBattleHardIndex(hardIndex)
    UIActivityN21CCConst.ENTER_BATTLE_HARD_INDEX = hardIndex
end

function UIActivityN21CCConst.GetEnterBattleLevelId()
    return UIActivityN21CCConst.ENTER_BATTLE_LEVEL_ID
end

function UIActivityN21CCConst.SetEnterBattleLeveId(hardIndex)
    UIActivityN21CCConst.ENTER_BATTLE_LEVEL_ID = hardIndex
end

function UIActivityN21CCConst.GetHistoryLevelHard(levelIndex)
    local key = UIActivityN21CCConst.GetHistoryLevelHardKey(levelIndex)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return -1
    end

    return UnityEngine.PlayerPrefs.GetInt(key)
end

function UIActivityN21CCConst.SetHistoryLevelHard(levelIndex, hard)
    local key = UIActivityN21CCConst.GetHistoryLevelHardKey(levelIndex)
    UnityEngine.PlayerPrefs.SetInt(key, hard)
end

function UIActivityN21CCConst.GetHistoryLevelHardKey(levelIndex)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N21CC_MODULE_LEVEL_HARD" .. levelIndex
    return key
end
