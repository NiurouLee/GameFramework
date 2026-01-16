---@class UIActivityN24Const : Object
_class("UIActivityN24Const", Object)
UIActivityN24Const = UIActivityN24Const

function UIActivityN24Const:Constructor()
end

---@param res AsyncRequestRes
function UIActivityN24Const:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N24,
        ECampaignN24ComponentID.ECAMPAIGN_N24_CUMULATIVE_LOGIN,
        ECampaignN24ComponentID.ECAMPAIGN_N24_FIRST_MEET,
        ECampaignN24ComponentID.ECAMPAIGN_N24_POWER2ITEM,
        ECampaignN24ComponentID.ECAMPAIGN_N24_LOTTERY,
        ECampaignN24ComponentID.ECAMPAIGN_N24_PANGOLIN
    )

    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN24
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
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN24ComponentID.ECAMPAIGN_N24_CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._localProcess:GetComponentInfo(ECampaignN24ComponentID.ECAMPAIGN_N24_CUMULATIVE_LOGIN)
    --线性关组件，光灵初见
    ---@type LineMissionComponent
    self._fixTeamComponent = self._localProcess:GetComponent(ECampaignN24ComponentID.ECAMPAIGN_N24_FIRST_MEET)
    ---@type LineMissionComponentInfo
    self._fixTeamCompInfo = self._localProcess:GetComponentInfo(ECampaignN24ComponentID.ECAMPAIGN_N24_FIRST_MEET)
    --体力转换组件(掉落代币)
    ---@type CampaignPower2itemComponent
    self._power2itemComponent = self._localProcess:GetComponent(ECampaignN24ComponentID.ECAMPAIGN_N24_POWER2ITEM)
    ---@type Power2ItemComponentInfo
    self._power2itemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN24ComponentID.ECAMPAIGN_N24_POWER2ITEM)
    --商店探宝(抽奖)
    ---@type LotteryComponent
    self._lotteryComponent = self._localProcess:GetComponent(ECampaignN24ComponentID.ECAMPAIGN_N24_LOTTERY)
    ---@type LotteryComponentInfo
    self._lotteryCompInfo = self._localProcess:GetComponentInfo(ECampaignN24ComponentID.ECAMPAIGN_N24_LOTTERY)
    --家园任务(奇遇任务)
    ---@type HomelandTaskComponent
    self._pangolinComponent = self._localProcess:GetComponent(ECampaignN24ComponentID.ECAMPAIGN_N24_PANGOLIN)
    ---@type HomlandTaskComponentInfo
    self._pangolinCompInfo = self._localProcess:GetComponentInfo(ECampaignN24ComponentID.ECAMPAIGN_N24_PANGOLIN)
    
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
        self._endTime = self._lotteryCompInfo.m_close_time
    else --活动开启
        self._status = 1
        self._endTime = power2itemEndTime
    end
    
    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function UIActivityN24Const:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityN24Const:GetCampaign()
    return self._campaign
end

function UIActivityN24Const:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN24Const:GetName()
    return self._name
end

--副标题
function UIActivityN24Const:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityN24Const:GetActiveEndTime()
    return self._activeEndTime
end

-- 1：活动剩余时间，2：领奖
function UIActivityN24Const:GetStatus()
    return self._status
end

function UIActivityN24Const:SetStatus(status)
    self._status = status
end

--活动是否开启
function UIActivityN24Const:IsActivityEnd()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

--获取光灵试用组件
function UIActivityN24Const:GetTryPetComponent()
    return self._fixTeamComponent, self._fixTeamCompInfo
end

--获取商店组件
function UIActivityN24Const:GetShopComponent()
    return self._lotteryComponent, self._lotteryCompInfo
end

--累计登录组件是否开启
function UIActivityN24Const:IsLoginEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._cumulativeLoginComponent then
        return false
    end
    return self._cumulativeLoginComponent:ComponentIsOpen()
end

--光灵初见组件是否开启
function UIActivityN24Const:IsTryPetEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._fixTeamComponent then
        return false
    end
    return self._fixTeamComponent:ComponentIsOpen()
end

--体力转换组件是否开启
function UIActivityN24Const:IsPower2ItemEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._power2itemComponent then
        return false
    end
    return self._power2itemComponent:ComponentIsOpen()
end

--商店探宝组件是否开启
function UIActivityN24Const:IsShopEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._lotteryComponent then
        return false
    end
    return self._lotteryComponent:ComponentIsOpen()
end

--家园任务是否结束
function UIActivityN24Const:IsHomelandTaskEnd()
    if self:IsActivityEnd() then
        return true
    end

    if not self._pangolinCompInfo then
        return true
    end
    
    local curTime = math.floor(self._timeModule :GetServerTime() * 0.001)

    if curTime >= self._pangolinCompInfo.m_close_time then
        return true
    end
    
    return false
end

--家园任务组件是否开启
function UIActivityN24Const:IsHomelandTaskEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._pangolinCompInfo then
        return false
    end

    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local isOpen = curTime >= self._pangolinCompInfo.m_unlock_time and curTime <= self._pangolinCompInfo.m_close_time
    return isOpen
end

--家园任务开启剩余秒数
function UIActivityN24Const:GetHomelandRemaindOpenSeconds()
    local curTime = math.floor(self._timeModule :GetServerTime() * 0.001)
    local seconds = math.floor(self._pangolinCompInfo.m_unlock_time - curTime)
    if seconds <= 0 then
        seconds = 0
    end
    return seconds
end

-- ---=========================================== 红点和NEW相关接口 ====================================================

--入口NEW
function UIActivityN24Const:IsShowEntryNew()
    local enterNew = UIActivityN24Const.GetEnterNewStatus()
    if enterNew then
        return true 
    end
    return self:IsShowHomelandTaskNew()
end

--奇异任务new
function UIActivityN24Const:IsShowHomelandTaskNew()
    if not self:IsHomelandTaskEnable() then
        return false
    end
    return UIActivityN24Const.GetHomelandTaskNewStatus()
end


--入口红点
function UIActivityN24Const:IsShowEntryRed()
    if self:IsActivityEnd() then
        return false
    end

    if self:IsShowLoginRed() then
        return true
    end

    if self:IsShowHomelandTaskRed() then
        return true
    end

    if self:IsShowTryPetRed() then
        return true
    end

    if self:IsShowShopRed() then
        return true
    end

    return false
end

--光灵试用红点
function UIActivityN24Const:IsShowTryPetRed()
    if not self:IsTryPetEnable() then
        return false
    end

    return self._campaign:CheckComponentRed(ECampaignN24ComponentID.ECAMPAIGN_N24_FIRST_MEET)
end

--登录奖励红点
function UIActivityN24Const:IsShowLoginRed()
    if not self:IsLoginEnable() then
        return false
    end
    
    return self._campaign:CheckComponentRed(ECampaignN24ComponentID.ECAMPAIGN_N24_CUMULATIVE_LOGIN)
end

--商店红点
function UIActivityN24Const:IsShowShopRed()
    if not self:IsShopEnable() then
        return false
    end

    return self._campaign:CheckComponentRed(ECampaignN24ComponentID.ECAMPAIGN_N24_LOTTERY)
end

--奇异任务红点
function UIActivityN24Const:IsShowHomelandTaskRed()
    if not self:IsHomelandTaskEnable() then
        return false
    end

    return self._campaign:CheckComponentRed(ECampaignN24ComponentID.ECAMPAIGN_N24_PANGOLIN)
end

--战斗通行证红点
function UIActivityN24Const:IsShowBattlePassRed()
    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

function UIActivityN24Const.GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N24_MODULE_NEW_FLAG" .. id
    return key
end

function UIActivityN24Const.GetNewFlagStatus(id)
    local key = UIActivityN24Const.GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN24Const.SetNewFlagStatus(id, status)
    local key = UIActivityN24Const.GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

function UIActivityN24Const.GetEnterNewStatus()
    return UIActivityN24Const.GetNewFlagStatus("ENTRY_NEW")
end

function UIActivityN24Const.ClearEnterNewStatus()
    UIActivityN24Const.SetNewFlagStatus("ENTRY_NEW", false)
end

function UIActivityN24Const.GetHomelandTaskNewStatus()
    return UIActivityN24Const.GetNewFlagStatus("HOMELAND_TASK_NEW")
end

function UIActivityN24Const.ClearHomelandTaskNewStatus()
    UIActivityN24Const.SetNewFlagStatus("HOMELAND_TASK_NEW", false)
end

-- ---======================================================================================================================

function UIActivityN24Const.GetTimeString(seconds)
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n24_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n24_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n24_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n24_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n24_less_one_minus")
        end
    end
    return timeStr
end

function UIActivityN24Const.GetItemCountStr(count, preColor, countColor)
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

function UIActivityN24Const.ShowRewards(rewards, callback)
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
