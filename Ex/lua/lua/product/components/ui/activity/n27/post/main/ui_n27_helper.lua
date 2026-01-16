---@class UIActivityN27Helper : Object
_class("UIActivityN27Helper", Object)
UIActivityN27Helper = UIActivityN27Helper

---@param res AsyncRequestRes
function UIActivityN27Helper:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign =  UIActivityCampaign.New()
    
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N27,
        ECampaignN27ComponentID.ECAMPAIGN_N27_CUMULATIVE_LOGIN,
        ECampaignN27ComponentID.ECAMPAIGN_N27_FIRST_MEET,
        ECampaignN27ComponentID.ECAMPAIGN_N27_POWER2ITEM,
        ECampaignN27ComponentID.ECAMPAIGN_N27_LINE_MISSION,
        ECampaignN27ComponentID.ECAMPAIGN_N27_DIFFICULT_MISSION,
        ECampaignN27ComponentID.ECAMPAIGN_N27_SHOP,
        ECampaignN27ComponentID.ECAMPAIGN_N27_BLOODSUCKER,
        ECampaignN27ComponentID.ECAMPAIGN_N27_IDOL

    )

    -- 错误处理
    if res and not res:GetSucc() then
        return res
    end

    ---@type CCampaignN27
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --战斗通行证
    local bpRes = AsyncRequestRes:New()
    bpRes:SetSucc(true)
    ---@type UIActivityCampaign
    self._battlepassCampaign = UIActivityCampaign:New()
    self._battlepassCampaign:LoadCampaignInfo(TT, bpRes, ECampaignType.CAMPAIGN_TYPE_BATTLEPASS)
    if not bpRes:GetSucc() then
        Log.info("获取战斗通行证数据失败")
    end

    --获取组件
    --累计登录（签到）
    ---@type CumulativeLoginComponent
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_CUMULATIVE_LOGIN)
   
    --线性关组件，光灵初见
    ---@type LineMissionComponent
    self._fixTeamComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_FIRST_MEET)
    ---@type LineMissionComponentInfo
    self._fixTeamCompInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_FIRST_MEET)

    --线性关组件
    ---@type LineMissionComponent
    self._lineComp = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._lineCompInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_LINE_MISSION)

    --困难
    ---@type LineMissionComponent
    self._hardComp = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_DIFFICULT_MISSION)
    ---@type LineMissionComponentInfo
    self._hardCompInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_DIFFICULT_MISSION)

    --体力转换组件(掉落代币)
    ---@type CampaignPower2itemComponent
    self._power2itemComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_POWER2ITEM)
    ---@type Power2ItemComponentInfo
    self._power2itemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_POWER2ITEM)

    --商店兑换
    ---@type ExchangeItemComponent
    self._exchangeComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_SHOP)
    ---@type ExchangeItemComponentInfo
    self._exchangeComponentInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_SHOP)

    --偶像养成 
    ---@type IdolMiniGameComponent
    self._idolMiniGameComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_IDOL)
    ---@type IdolComponentInfo
    self._idolMiniGameCompInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_IDOL)

    --吸血鬼组件
    ---@type BloodsuckerComponent
    self._bloodsuckerComponet = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_BLOODSUCKER)
    ---@type BloodsuckerComponentInfo
    self._bloodsuckerComponentInfo = self._localProcess:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_BLOODSUCKER)

    
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

    local nowTime = self._timeModule:GetServerTime() / 1000
    --活动时间
    self._activeEndTime = sample.end_time

    local power2itemEndTime = self._power2itemComponentInfo.m_close_time
    -- 1：活动剩余时间，2：领奖
    if nowTime >= power2itemEndTime then
        self._status = 2
       -- self._endTime = self._lotteryCompInfo.m_close_time
    else --活动开启
        self._status = 1
        self._endTime = power2itemEndTime
    end
    
    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function UIActivityN27Helper:ForceRefresh(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityN27Helper:GetCampaign()
    return self._campaign
end

function UIActivityN27Helper:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN27Helper:GetName()
    return self._name
end

--副标题
function UIActivityN27Helper:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityN27Helper:GetActiveEndTime()
    return self._activeEndTime
end

-- 1：活动剩余时间，2：领奖
function UIActivityN27Helper:GetStatus()
    return self._status
end

function UIActivityN27Helper:SetStatus(status)
    self._status = status
end

--活动是否开启
function UIActivityN27Helper:IsActivityEnd()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

--获取光灵试用组件
function UIActivityN27Helper:GetTryPetComponent()
    return self._fixTeamComponent, self._fixTeamCompInfo
end

--获取商店组件
function UIActivityN27Helper:GetShopComponent()
    return self._exchangeComponent, self._exchangeComponentInfo
end

--获得线性关组件
function UIActivityN27Helper:GetLineComponent()
    return self._lineComp, self._lineCompInfo
end

--获得困难关组件
function UIActivityN27Helper:GetHardComponent()
    return self._hardComp, self._hardCompInfo
end

--获得Idol关组件
function UIActivityN27Helper:GetIdolComponent()
    return self._idolMiniGameComponent, self._idolMiniGameCompInfo
end

--获得吸血鬼组件
function UIActivityN27Helper:GetBloodSuckerComponent()
    return self._bloodsuckerComponet, self._bloodsuckerComponentInfo
end


--光灵初见组件是否开启
function UIActivityN27Helper:IsTryPetEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._fixTeamComponent then
        return false
    end
    return self._fixTeamComponent:ComponentIsOpen()
end

--体力转换组件是否开启
function UIActivityN27Helper:IsPower2ItemEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._power2itemComponent then
        return false
    end
    return self._power2itemComponent:ComponentIsOpen()
end

-- ---=========================================== 红点和NEW相关接口 ====================================================
--入口NEW
function UIActivityN27Helper:IsShowEntryNew()
    if self:IsActivityEnd() then
        return false
    end

    local isNew = UIActivityN27Helper.GetEnterNewStatus() or 
        self:CheckNewHard() or  --困难关
        self:CheckNewNormal() or --线性关
        --self:CheckNewShop() or  --商店
        self:CheckGameIdolNew() or   --小游戏1 偶像养成是否有New
        self:CheckGameBloodSuckerNew()     --小游戏2 类吸血鬼是否有New
    
    return isNew
end

--线性关
function UIActivityN27Helper:CheckNewNormal()
    -- if not N27Data.HasPrefs(N27Data.GetPrefsKeyLine()) and 
    --     self._lineCompInfo and 
    --     self:GetState(self._lineCompInfo) == UISummerOneEnterBtnState.Normal then
    --         return true
    -- end
    return false
end

--困难关
function UIActivityN27Helper:CheckNewHard()
    if not N27Data.HasPrefs(N27Data.GetPrefsKeyHard()) and 
        self._hardCompInfo and 
        self:GetState(self._hardCompInfo) == UISummerOneEnterBtnState.Normal then
            return true
    end
    return false
end


--小游戏1 偶像养成是否有New
function UIActivityN27Helper:CheckGameIdolNew()
    if not N27Data.HasPrefs(N27Data.GetPrefsKeyGameIdol()) and 
        self._idolMiniGameCompInfo and 
        self:GetState(self._idolMiniGameCompInfo) == UISummerOneEnterBtnState.Normal then
            return true
    end
    return false
end

--小游戏2 类吸血鬼是否有New
function UIActivityN27Helper:CheckGameBloodSuckerNew()
    if not N27Data.HasPrefs(N27Data.GetPrefsKeyGameBloodSucker()) and 
        self._bloodsuckerComponentInfo and 
        self:GetState(self._bloodsuckerComponentInfo) == UISummerOneEnterBtnState.Normal then
            return true
    end
    return false
end

--入口红点
function UIActivityN27Helper:IsShowEntryRed()
    
    --活动结束
    if self:IsActivityEnd() then
        return false
    end

    --光灵初现
    if self:CheckRedTryPet() then
        return true
    end

    --商店
    if self:CheckRedShop() then
        return true
    end

    --困难关
    if self:CheckRedHard() then
        return true
    end

    --登录奖励
    if self:CheckRedAward() then
        return true;
    end

    --偶像养成
    if self:CheckGameIdolRed() then
        return true;
    end

    --吸血鬼
    if self:CheckGameBloodSuckerRed() then
        return true;
    end

    return false
end

function UIActivityN27Helper:CheckRedAward() --累计奖励
    local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_CUMULATIVE_LOGIN)
    return red
end

--光灵试用红点
function UIActivityN27Helper:CheckRedTryPet()
    local state = self:GetStateTryPet()
    if state == UISummerOneEnterBtnState.Normal then
        local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_FIRST_MEET)
        return red
    end
    return false
end

function UIActivityN27Helper:CheckRedNormal() --普通线性关
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_LINE_MISSION)
        return red
    end
    return false
end

function UIActivityN27Helper:CheckRedHard() --困难关
    local state = self:GetStateHard()
    if state == UISummerOneEnterBtnState.Normal then
        local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_DIFFICULT_MISSION)
        return red
    end
    return false
end

function UIActivityN27Helper:CheckRedShop() --商店兑换
    local state = self:GetStateShop()
    if state == UISummerOneEnterBtnState.Normal then
        local red = self._campaign:CheckComponentRed(self._localProcess, self.componentIdShop)
        return red
    end
    return false
end

--战斗通行证红点
function UIActivityN27Helper:IsShowBattlePassRed()
    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

--小游戏1 偶像养成是否有红点
function UIActivityN27Helper:CheckGameIdolRed()
    local state = self:GetStateGameIdol()
    if state == UISummerOneEnterBtnState.Normal then
        local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_IDOL)
        return red
    end
    return false
end

--小游戏2 类吸血鬼是否有红点
function UIActivityN27Helper:CheckGameBloodSuckerRed()
    -- local state = self:GetStateGameBloodSucker()
    -- if state == UISummerOneEnterBtnState.Normal then
    --     local red = self._campaign:CheckComponentRed(self._localProcess, ECampaignN27ComponentID.ECAMPAIGN_N27_BLOODSUCKER)
    --     return red
    -- end
    return false
end

function UIActivityN27Helper.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N27_MODULE_NEW_FLAG" .. id
    return key
end

function UIActivityN27Helper.GetNewFlagStatus(id)
    local key = UIActivityN27Helper.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN27Helper.SetNewFlagStatus(id, status)
    local key = UIActivityN27Helper.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

function UIActivityN27Helper.GetEnterNewStatus()
    return UIActivityN27Helper.GetNewFlagStatus("ENTRY_NEW")
end

function UIActivityN27Helper.ClearEnterNewStatus()
    UIActivityN27Helper.SetNewFlagStatus("ENTRY_NEW", false)
end

---@return UISummerOneEnterBtnState
function UIActivityN27Helper:GetStateShop()
    if self._exchangeComponentInfo then
        return self:GetState(self._exchangeComponentInfo)
    end
end

---@return UISummerOneEnterBtnState
function UIActivityN27Helper:GetStateNormal()
    if self._lineCompInfo then
        return self:GetState(self._lineCompInfo)
    end
end

---@return UISummerOneEnterBtnState
function UIActivityN27Helper:GetStateHard()
    if self._hardCompInfo then
        return self:GetState(self._hardCompInfo)
    end
end

function UIActivityN27Helper:GetStateTryPet()
    if self._fixTeamCompInfo  then
        return self:GetState(self._fixTeamCompInfo)
    end
end

function UIActivityN27Helper:GetStateGameIdol()
    if self._idolMiniGameCompInfo  then
        return self:GetState(self._idolMiniGameCompInfo)
    end
end

function UIActivityN27Helper:GetStateGameBloodSucker()
    if self._bloodsuckerComponentInfo  then
        return self:GetState(self._bloodsuckerComponentInfo)
    end
end

---@return UISummerOneEnterBtnState
function UIActivityN27Helper:GetState(cInfo)
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

function UIActivityN27Helper.GetTimeString(seconds)
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_N27_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_N27_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_N27_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_N27_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_N27_less_one_minus")
        end
    end
    return timeStr
end

function UIActivityN27Helper.GetItemCountStr(count, preColor, countColor)
    local dight = 0
    local tmpCount = count
    if tmpCount < 0 then
        tmpCount = -tmpCount
    end
    while tmpCount > 0 do
        tmpCount = math.floor(tmpCount / 10)
        dight = dight + 1
    end

    local pre = ""
    if count >= 0 then
        for i = 1, 7 - dight do
            pre = pre .. "0"
        end
    else
        for i = 1, 7 - dight - 1 do
            pre = pre .. "0"
        end
    end

    if count > 0 then
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    elseif count == 0 then
        return string.format("<color=" .. preColor .. ">%s</color>", pre)
    else
        return string.format("<color=" .. preColor .. ">%s</color><color=" .. countColor .. ">%s</color>", pre, count)
    end
end

function UIActivityN27Helper.ShowRewards(rewards, callback)
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

---@return string, number
function UIActivityN27Helper:GetSpineAndBgm()
    local cfg = Cfg.cfg_N27_const[1]
    if self._lineCompInfo and cfg then
        ---@type MissionModule
        local missionModule = GameGlobal.GetModule(MissionModule)
        ---@type cam_mission_info[]
        local passInfo = self._lineCompInfo.m_pass_mission_info
        for _, info in pairs(passInfo) do
            local storyId = missionModule:GetStoryByStageIdStoryType(info.mission_id, StoryTriggerType.Node)
            if storyId == cfg.StoryID then
                return cfg.Spine2, cfg.Bgm2
            end
        end
        return cfg.Spine1, cfg.Bgm1
    end
    return nil, nil
end

function UIActivityN27Helper:CheckBloodSuckerMissionPassed(missionId)
    if not self._bloodsuckerComponentInfo then
       return false 
    end 
    if self._bloodsuckerComponentInfo.mission_infos then
         for index, value in pairs(self._bloodsuckerComponentInfo.mission_infos) do
             if index == missionId then
                return value.is_pass == 1
             end 
         end
    end 
    return false  
 end

 function UIActivityN27Helper:CheckBloodSuckerMissionJoind(missionId)
    if not self._bloodsuckerComponentInfo then
       return false 
    end 
    if self._bloodsuckerComponentInfo.join_mission_list then
         for index, value in pairs(self._bloodsuckerComponentInfo.join_mission_list) do
            if value == missionId then
                return true
            end 
         end
    end 
    return false  
 end

 function UIActivityN27Helper:GetTaskRedPoint()
    self._questComponent = self._localProcess:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_QUEST)
    if not self._questComponent then
       return false 
    end 
    return self._questComponent:HaveRedPoint()
 end
 
 function UIActivityN27Helper:GetShowFirstTaskIndex()
    local firstShow = 1 
    if not self._bloodsuckerComponentInfo then
        return firstShow
    end 
     if self._bloodsuckerComponentInfo.mission_infos then
          for index, value in pairs(self._bloodsuckerComponentInfo.mission_infos) do
              if value.is_pass == 1 then
                  firstShow = firstShow + 1 
              end 
          end
     end 
     return firstShow
 end