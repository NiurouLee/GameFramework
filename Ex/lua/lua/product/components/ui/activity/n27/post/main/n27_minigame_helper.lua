---@class N27MinigameHelper : Object
_class("N27MinigameHelper", Object)
N27MinigameHelper = N27MinigameHelper

function N27MinigameHelper:Constructor()
end

---@param res AsyncRequestRes
function N27MinigameHelper:LoadData(TT, res)
    ---@type SvrTimeModule
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    self._loginModule = GameGlobal.GetModule(LoginModule)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N27,
        ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON
    )
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN27
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --获取组件
    self._component = self._campaign:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON)
    self._componentInfo = self._campaign:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON)
    --活动配置信息
    local cmpID = self._component:GetComponentCfgId()
    self._cfg_stage = Cfg.cfg_component_post_station_game_mission{ComponentID = cmpID}

    --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --标题数据
    self._name = StringTable.Get(cfg_campaign.CampaignName)
    self._subName = StringTable.Get(cfg_campaign.CampaignSubtitle)
    local plotIdList = cfg_campaign.FirstEnterStoryID
    self._plotId = nil
    if plotIdList and #plotIdList > 0 then
        self._plotId = plotIdList[1]
    end
    
    --活动结束时间
    local sample = self._campaign:GetSample()
    if not sample then
        return
    end

    local nowTime = self._svrTimeModule:GetServerTime() / 1000
    --活动时间
    self._activeEndTime = sample.end_time

    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function N27MinigameHelper:ForceReLoad(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function N27MinigameHelper:GetCampaign()
    return self._campaign
end

function N27MinigameHelper:GetCampaignId()
    return self._campaign._id
end

--标题
function N27MinigameHelper:GetName()
    return self._name
end

--副标题
function N27MinigameHelper:GetSubName()
    return self._subName
end

--活动结束时间
function N27MinigameHelper:GetActiveEndTime()
    return self._activeEndTime
end

--获取剧情id
function N27MinigameHelper:GetPlotId()
    return self._plotId
end

--活动是否开启
function N27MinigameHelper:IsActivityEnd()
    if not self._activeEndTime then 
        return true
    end 
    local nowTime = self._svrTimeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

---=========================================== 获取组件 ===============================================
--获取小游戏组件
function N27MinigameHelper:GetMiniGameComponent()
    return self._component
end

function N27MinigameHelper:GetMiniGameComponentInfo()
    return self._componentInfo
end
---==========================================================================================

---====================================== 组件状态 ===========================================
--获取小游戏组件状态
function N27MinigameHelper:GetMiniGameComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return self:CheckComponentStatus(self._component)
end

function N27MinigameHelper:CheckComponentStatus(component)
    if not component then
        return ActivityComponentStatus.Close, 0
    end
    
    ---@type ICampaignComponentInfo
    local info = component:GetComponentInfo()
    if not info then
        return ActivityComponentStatus.Close, 0
    end

    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime >= info.m_close_time then
        return ActivityComponentStatus.Close, 0
    end

    local opentTime = info.m_open_time
    local unLockTime = info.m_unlock_time
    local time = opentTime
    if unLockTime > time then
        time = unLockTime
    end

    if curTime > time then
        if not info.m_b_unlock then
            return ActivityComponentStatus.MissionLock, 0
        end
        return ActivityComponentStatus.Open, info.m_close_time - curTime
    end

    return ActivityComponentStatus.TimeLock, curTime - time
end

---===========================================================================================

---=========================================== 红点和NEW相关接口 ====================================================

function N27MinigameHelper:GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. id
    return key
end
--入口红点
function N27MinigameHelper:IsShowEntryNewOrRed()
    local isNew ,isRed = false ,false 
    if self:IsActivityEnd() then
        return false
    end
    if self:IsShowMiniGameRed() then
        isRed = true
    end
    if self:IsShowMiniGameNew() then
        isRed = false
        isNew = true
    end
    return isNew,isRed
end

--小游戏红点
function N27MinigameHelper:IsShowMiniGameRed()
    if not self._componentInfo.mission_infos  then 
       return false 
    end 
    for key, value in pairs(self._componentInfo.mission_infos) do
        if #value.can_get_target_list > 0  then
            return true
        end 
    end
    return false
end

--NEW
function N27MinigameHelper:IsShowMiniGameNew()
    for index, value in pairs(self._cfg_stage) do
        local nowTime = self._svrTimeModule:GetServerTime() * 0.001
        local cfg = value
        local unlockTime = self._loginModule:GetTimeStampByTimeStr( cfg.UnlockTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
        if unlockTime <= nowTime then
            local key = self:GetNewFlagKey(index)
            local hasNew = LocalDB.GetInt("UIN27MiniGameWayPoint" ..key)
            if hasNew == 0 and self:CheckPreMission(index)  then
                return true
            end
        end 
    end 
   return false
end

function N27MinigameHelper:ClearMiniGameNewByIndex(key)
    LocalDB.SetInt("UIN27MiniGameWayPoint" .. key, 1)
end

function N27MinigameHelper:CheckPreMission(index) 
    if index == 1 then
        return true
    end
    return self._componentInfo.mission_infos[self._cfg_stage[index - 1].ID] and 
    self._componentInfo.mission_infos[self._cfg_stage[index - 1].ID] .suc > 0 
end 
