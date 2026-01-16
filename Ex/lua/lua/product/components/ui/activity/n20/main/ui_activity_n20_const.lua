---@class UIActivityN20Const : Object
---@field dataAVG N20AVGData
_class("UIActivityN20Const", Object)
UIActivityN20Const = UIActivityN20Const

function UIActivityN20Const:Constructor()
    self.dataAVG = nil
end

function UIActivityN20Const:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    self.dataAVG = campaignModule:GetN20AVGData()
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N20,
        ECampaignN20ComponentID.ECAMPAIGN_N20_CUMULATIVE_LOGIN,
        ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_COMMON,
        ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_HARD,
        ECampaignN20ComponentID.ECAMPAIGN_N20_POWER2ITEM,
        ECampaignN20ComponentID.ECAMPAIGN_N20_SHOP,
        ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM,
        ECampaignN20ComponentID.ECAMPAIGN_N20_MINI_GAME,
        ECampaignN20ComponentID.ECAMPAIGN_N20_AVG_MINI_GAME
    )

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN20
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
    --累计登录组件
    ---@type CumulativeLoginComponent
    self._cumulativeLoginComponent =
        self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo =
        self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_CUMULATIVE_LOGIN)
    --- 普通线性关卡组件
    ---@type LineMissionComponent
    self._normalLineMissionComponet =
        self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_COMMON)
    ---@type LineMissionComponentInfo
    self._normalLineMissionCompInfo =
        self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_COMMON)
    --- 困难线性关卡组件
    ---@type LineMissionComponent
    self._hardlLineMissionComponet = self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_HARD)
    ---@type LineMissionComponentInfo
    self._hardLineMissionCompInfo =
        self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_HARD)
    -- 固定队伍关卡(光灵初见)
    ---@type LineMissionComponent
    self._lineMissionFixteamComponet =
        self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM)
    ---@type LineMissionComponentInfo
    self._lineMissionFixteamCompInfo =
        self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_LEVEL_FIXTEAM)
    -- 小游戏组件
    ---@type CampaignMiniGameComponent
    self._miniGameComponet = self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_MINI_GAME)
    ---@type MiniGameComponentInfo
    self._miniGameCompInfo = self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_MINI_GAME)
    -- 商店组件
    ---@type ExchangeItemComponent
    self._shopComponet = self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_SHOP)
    ---@type ExchangeItemComponentInfo
    self._shopCompInfo = self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_SHOP)
    -- 体力转换组件(掉落代币)
    ---@type CampaignPower2itemComponent
    self._power2ItemComponet = self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_POWER2ITEM)
    ---@type Power2ItemComponentInfo
    self._power2ItemCompInfo = self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_POWER2ITEM)
    -- AVG组件
    ---@type AvgMinigameComponent
    self._avgMinigameComponent = self._localProcess:GetComponent(ECampaignN20ComponentID.ECAMPAIGN_N20_AVG_MINI_GAME)
    ---@type AVGStoryComponentClientInfo
    self._avgStoryComponentClientInfo =
        self._localProcess:GetComponentInfo(ECampaignN20ComponentID.ECAMPAIGN_N20_AVG_MINI_GAME)

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

    local missionEndTime = 0
    if self._normalLineMissionCompInfo then
        missionEndTime = self._normalLineMissionCompInfo.m_close_time
    end
    -- 1：作战，2：领奖
    if nowTime >= missionEndTime then
        self._status = 2
        self._endTime = self._activeEndTime
    else --活动开启
        self._status = 1
        self._endTime = missionEndTime
    end

    self.dataAVG:RequestCampaign(TT)
    self.dataAVG:Init()
    self.dataAVG:Update()
end

function UIActivityN20Const:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityN20Const:GetCampaign()
    return self._campaign
end

function UIActivityN20Const:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN20Const:GetName()
    return self._name
end

--副标题
function UIActivityN20Const:GetSubName()
    return self._subName
end

-- 1：作战，2：领奖
function UIActivityN20Const:GetStatus()
    return self._status
end

function UIActivityN20Const:SetStatus(status)
    self._status = status
end

--结束时间
function UIActivityN20Const:GetEndTime()
    return self._endTime
end

--活动结束时间
function UIActivityN20Const:GetActiveEndTime()
    return self._activeEndTime
end

--战斗通行证
function UIActivityN20Const:GetBattlePassCampaign()
    return self._battlepassCampaign
end

--累计登录组件
function UIActivityN20Const:GetLoginComponent()
    return self._cumulativeLoginComponent, self._cumulativeLoginComponentInfo
end

--- 普通线性关卡组件
function UIActivityN20Const:GetNormalLineComponent()
    return self._normalLineMissionComponet, self._normalLineMissionCompInfo
end

--- 困难线性关卡组件
function UIActivityN20Const:GetHardLineComponent()
    return self._hardlLineMissionComponet, self._hardLineMissionCompInfo
end

-- 固定队伍关卡(光灵初见)
function UIActivityN20Const:GetLineMissionFixteamComponet()
    return self._lineMissionFixteamComponet, self._lineMissionFixteamCompInfo
end

-- 小游戏组件
function UIActivityN20Const:GetMiniGameComponent()
    return self._miniGameComponet, self._miniGameCompInfo
end

-- 商店组件
function UIActivityN20Const:GetShopComponent()
    return self._shopComponet, self._shopCompInfo
end

-- 体力转换组件(掉落代币)
function UIActivityN20Const:GetPower2itemComponent()
    return self._power2ItemComponet, self._power2ItemCompInfo
end

-- AVG组件
function UIActivityN20Const:GetPower2itemComponent()
    return self._avgMinigameComponent, self._avgStoryComponentClientInfo
end

--活动是否开启
function UIActivityN20Const:IsActivityEnd()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

--累计登录是否开启
function UIActivityN20Const:IsLoginEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._cumulativeLoginComponentInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._cumulativeLoginComponentInfo.m_unlock_time and
        curTime <= self._cumulativeLoginComponentInfo.m_close_time
    return result and self._cumulativeLoginComponentInfo.m_b_unlock
end

--普通线性关卡是否开启
function UIActivityN20Const:IsNormalMissionEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._normalLineMissionCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._normalLineMissionCompInfo.m_unlock_time and
        curTime <= self._normalLineMissionCompInfo.m_close_time
    return result and self._normalLineMissionCompInfo.m_b_unlock
end

--获取普通线性关开启时间
function UIActivityN20Const:GetNormalMissionOpenTime()
    return self._normalLineMissionCompInfo.m_unlock_time
end

--普通线性关是否关闭
function UIActivityN20Const:IsNormalMissionClose()
    if self:IsActivityEnd() then
        return true
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    if curTime > self._normalLineMissionCompInfo.m_close_time then
        return true
    end
    return false
end

--困难线性关卡是否开启
function UIActivityN20Const:IsHardMissionEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._hardLineMissionCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._hardLineMissionCompInfo.m_unlock_time and curTime <= self._hardLineMissionCompInfo.m_close_time
    return result and self._hardLineMissionCompInfo.m_b_unlock
end

--困难关是否到时间解锁了
function UIActivityN20Const:IsHardMissionTimeOpen()
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local isOpen =
        curTime >= self._hardLineMissionCompInfo.m_unlock_time and curTime <= self._hardLineMissionCompInfo.m_close_time
    return isOpen
end

--困难关是否关闭
function UIActivityN20Const:IsHardMissionClose()
    if self:IsActivityEnd() then
        return true
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    if curTime > self._hardLineMissionCompInfo.m_close_time then
        return true
    end
    return false
end

--获取困难关开启时间
function UIActivityN20Const:GetHardMissionOpenTime()
    return self._hardLineMissionCompInfo.m_unlock_time
end

--AVG是否开启
function UIActivityN20Const:IsAVGEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._avgStoryComponentClientInfo then
        return false
    end

    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._avgStoryComponentClientInfo.m_unlock_time and
        curTime <= self._avgStoryComponentClientInfo.m_close_time
    return result and self._avgStoryComponentClientInfo.m_b_unlock
end

--AVG是否关闭
function UIActivityN20Const:IsAVGClose()
    if self:IsActivityEnd() then
        return true
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    if curTime > self._avgStoryComponentClientInfo.m_close_time then
        return true
    end
    return false
end

--获取AVG开启时间
function UIActivityN20Const:GetAVGOpenTime()
    return self._avgStoryComponentClientInfo.m_unlock_time
end

--AVG是否到时间解锁了
function UIActivityN20Const:IsAVGTimeOpen()
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local isOpen =
        curTime >= self._avgStoryComponentClientInfo.m_unlock_time and
        curTime <= self._avgStoryComponentClientInfo.m_close_time
    return isOpen
end

--光灵初见是否开启
function UIActivityN20Const:IsPetEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._lineMissionFixteamCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._lineMissionFixteamCompInfo.m_unlock_time and
        curTime <= self._lineMissionFixteamCompInfo.m_close_time
    return result and self._lineMissionFixteamCompInfo.m_b_unlock
end

--小游戏是否开启
function UIActivityN20Const:IsMiniGameEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._miniGameCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result = curTime >= self._miniGameCompInfo.m_unlock_time and curTime <= self._miniGameCompInfo.m_close_time
    return result
end

--小游戏是否关闭
function UIActivityN20Const:IsMiniGameClose()
    if self:IsActivityEnd() then
        return true
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    if curTime > self._miniGameCompInfo.m_close_time then
        return true
    end
    return false
end

--获取小游戏开启时间
function UIActivityN20Const:GetMiniGameOpenTime()
    return self._miniGameCompInfo.m_unlock_time
end

--商店是否开启
function UIActivityN20Const:IsShopEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._shopCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result = curTime >= self._shopCompInfo.m_unlock_time and curTime <= self._shopCompInfo.m_close_time
    return result and self._shopCompInfo.m_b_unlock
end

function UIActivityN20Const:GetShopCloseTime()
    return self._shopCompInfo.m_close_time
end

--体力转换组件(掉落代币)是否开启
function UIActivityN20Const:IsPower2ItemEnable()
    if self:IsActivityEnd() then
        return false
    end

    if not self._power2ItemCompInfo then
        return false
    end
    local curTime = math.floor(self._timeModule:GetServerTime() * 0.001)
    local result =
        curTime >= self._power2ItemCompInfo.m_unlock_time and curTime <= self._power2ItemCompInfo.m_close_time
    return result and self._power2ItemCompInfo.m_b_unlock
end

---=========================================== 红点和NEW相关接口 ====================================================

--是否显示登录奖励红点
function UIActivityN20Const:IsShowLoginRed()
    if not self:IsLoginEnable() then
        return false
    end
    return self._campaign:CheckComponentRed(ECampaignN20ComponentID.ECAMPAIGN_N20_CUMULATIVE_LOGIN)
end

--是否显示战斗通行证红点
function UIActivityN20Const:IsShowEventRed()
    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

--是否显示普通线性关红点
function UIActivityN20Const:IsShowNormalMissionRed()
    if not self:IsNormalMissionEnable() then
        return false
    end
    return self._localProcess:GetEasyMissionRedDot()
end

--是否显示困难线性关红点
function UIActivityN20Const:IsShowHardMissionRed()
    if not self:IsHardMissionEnable() then
        return false
    end
    return self._localProcess:GetHardMissionRedDot()
end

--是否显示AVG红点
function UIActivityN20Const:IsShowAVGRed()
    if not self:IsAVGEnable() then
        return false
    end
    local avgRed = self.dataAVG:HasRed()
    return avgRed
end

--是否显示小游戏红点
function UIActivityN20Const:IsShowMiniGameRed()
    if not self:IsMiniGameEnable() then
        return false
    end
    return self._campaign:CheckComponentRed(ECampaignN20ComponentID.ECAMPAIGN_N20_MINI_GAME)
end

--是否显示商店NEW标记
function UIActivityN20Const:IsShowShopNew()
    if not self:IsShopEnable() then
        return false
    end

    return self:GetNewFlagStatus(5)
end

--清除商店NEW标记
function UIActivityN20Const:ClearShopNew()
    self:SetNewFlagStatus(5, false)
end

--是否显示普通线性关NEW标记
function UIActivityN20Const:IsShowNormalMissionNew()
    if not self:IsNormalMissionEnable() then
        return false
    end

    return self:GetNewFlagStatus(1)
end

--清除普通线性关NEW标记
function UIActivityN20Const:ClearNormalMissionNew()
    self:SetNewFlagStatus(1, false)
end

--是否显示困难线性关NEW标记
function UIActivityN20Const:IsShowHardMissionNew()
    if not self:IsHardMissionEnable() then
        return false
    end

    return self:GetNewFlagStatus(2)
end

--清除困难线性关NEW标记
function UIActivityN20Const:ClearHardMissionNew()
    self:SetNewFlagStatus(2, false)
end

--是否显示AVG玩法NEW标记
function UIActivityN20Const:IsShowAVGNew()
    if not self:IsAVGEnable() then
        return false
    end
    local newFlag = self:GetNewFlagStatus(3)
    local avgNew = self.dataAVG:HasNew()
    return newFlag or avgNew
end

--清除AVG玩法NEW标记
function UIActivityN20Const:ClearAVGNew()
    self:SetNewFlagStatus(3, false)
end

--是否显示小游戏NEW标记
function UIActivityN20Const:IsShowMiniGameNew()
    if not self:IsMiniGameEnable() then
        return false
    end
    if not self._miniGameCompInfo then
        return false
    end
    local mLogin = GameGlobal.GetModule(LoginModule)
    local str = LocalDB.GetString("N20MiniGameNewStage" .. mLogin:GetRoleShowID())
    local ids = string.split(str, ",")
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local newStage = false
    for key, value in pairs(self._miniGameCompInfo.mission_info_list) do
        if value.unlock_time <= nowTimestamp then
            local record = false
            for j = 1, #ids do
                if ids[j] == tostring(key) then
                    record = true
                    break
                end
            end
            if not record then
                newStage = true
                break
            end
        end
    end
    return newStage
end

--清除显示小游戏NEW标记
function UIActivityN20Const:ClearMiniGameNew()
    self:SetNewFlagStatus(4, false)
end

--是否显示主界面NEW标记
function UIActivityN20Const:IsShowMainEntryNew()
    return self:GetNewFlagStatus(6) or self:IsShowHardMissionNew() or self:IsShowMiniGameNew() or self:IsShowAVGNew() or
        self:IsShowNormalMissionNew()
end

--清除AVG玩法NEW标记
function UIActivityN20Const:ClearMainEntryNew()
    self:SetNewFlagStatus(6, false)
end

--是否显示主界面红点
function UIActivityN20Const:IsShowMainEntryRed()
    return self:IsShowAVGRed() or self:IsShowMiniGameRed() or self:IsShowHardMissionRed() or self:IsShowLoginRed() or
        self:IsShowNormalMissionRed() or
        self:IsShowShopNew()
end

function UIActivityN20Const:GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "ACTIVITY_N20_MODULE_NEW_FLAG" .. id
    return key
end

function UIActivityN20Const:GetNewFlagStatus(id)
    local key = self:GetNewFlagKey(id)
    if not UnityEngine.PlayerPrefs.HasKey(key) then
        return true
    end
    local value = UnityEngine.PlayerPrefs.GetInt(key)
    return value == 0
end

function UIActivityN20Const:SetNewFlagStatus(id, status)
    local key = self:GetNewFlagKey(id)
    if status then
        UnityEngine.PlayerPrefs.SetInt(key, 0)
    else
        UnityEngine.PlayerPrefs.SetInt(key, 1)
    end
end

---======================================================================================================================

function UIActivityN20Const:GetTimeString(seconds)
    -- 遵循通用倒计时显示逻辑：”1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟”
    local timeStr = ""
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_n20_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_n20_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_n20_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_n20_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_n20_less_one_minus")
        end
    end
    return timeStr
end
