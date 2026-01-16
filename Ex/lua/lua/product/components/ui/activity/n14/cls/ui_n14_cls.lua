---@class N14Data:CampaignDataBase
_class("N14Data", CampaignDataBase)
N14Data = N14Data

function N14Data:Constructor()
    self._redDotModule = GameGlobal.GetModule(RedDotModule)
end

--region 红点 new
function N14Data:CheckRedAward() --每日签到
    --_RequestRedDotStatus4N14是私有函数，后面不要这么用了，直接用RequestRedDotStatus
    local red = self._redDotModule:_RequestRedDotStatus4N14(RedDotType.RDT_N14_LOGIN_AWARD)
    return red
end
function N14Data:CheckRedNormal() -- 行动点  光灵初现
    --_RequestRedDotStatus4N14是私有函数，后面不要这么用了，直接用RequestRedDotStatus
    local red = self._redDotModule:_RequestRedDotStatus4N14(RedDotType.RDT_N14_EASYLINEMISSION)
    return red
end

function N14Data:CheckRedMiniGame() -- 捞鱼游戏
    --_RequestRedDotStatus4N14是私有函数，后面不要这么用了，直接用RequestRedDotStatus
    local red = false 
    self._componentInfo = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_MINI_GAME)
    local missions = self._componentInfo.mission_info_list
    for key, value in pairs(missions) do
        local miss_info  = value.mission_info
        for key, value in pairs(ScoreType) do
            --有新关卡的时候也显示红点
            if miss_info.mission_grade >= value and miss_info.reward_mask & value == 0  then
                return true
            end
        end
    end
    return red
end

function N14Data:CheckNewMiniGame() -- 捞鱼游戏
    --_RequestRedDotStatus4N14是私有函数，后面不要这么用了，直接用RequestRedDotStatus
    local new = self._redDotModule:_RequestRedDotStatus4N14(RedDotType.RDT_N14_FISHING_NEW)
    return new
end

function N14Data:CheckNewHard() -- 困难关
    --_RequestRedDotStatus4N14是私有函数，后面不要这么用了，直接用RequestRedDotStatus
    local red = self._redDotModule:_RequestRedDotStatus4N14(RedDotType.RDT_N14_HARDLINEMISSION_NEW)
    return red
end

--endregion

--region Component ComponentInfo
---@return LineMissionComponent
function N14Data:GetComponentNormal() -- 普通关组件
    local c = self.activityCampaign:GetComponent(ECampaignN14ComponentID.ECAMPAIGN_N14_LEVEL_COMMON)
    return c
end
---@return LineMissionComponent
function N14Data:GetComponentHard() -- 困难关组件
    local c = self.activityCampaign:GetComponent(ECampaignN14ComponentID.ECAMPAIGN_N14_LEVEL_HARD)
    return c
end
---@return LineMissionComponentInfo
function N14Data:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_LEVEL_COMMON)
    return cInfo
end
---@return LineMissionComponentInfo
function N14Data:GetComponentInfoHard()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_LEVEL_HARD)
    return cInfo
end

function N14Data:GetComponentInfoMinigame()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_MINI_GAME)
    return cInfo
end
--endregion

---@return UISummerOneEnterBtnState
function N14Data:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_SHOP)
    if c then
        return self:GetState(c)
    end
end
---@return UISummerOneEnterBtnState
---
------@return LineMissionComponentInfo
function N14Data:GetStateMiniGame()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_MINI_GAME)
    if c then
        return self:GetState(c)
    end
end
function N14Data:GetStateAward()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN14ComponentID.ECAMPAIGN_N14_CUMULATIVE_LOGIN)
    if c then
        return self:GetState(c)
    end
end

--region 显隐New
---@return UISummerOneEnterBtnState
function N14Data:GetState(cInfo)
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
function N14Data:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N14Data:GetStateHard()
    local cHardInfo = self:GetComponentInfoHard()
    if not cHardInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cHardInfo)
end
--endregion

--region PrefsKey
---@private
function N14Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function N14Data.GetPrefsKey(str)
    local playerPrefsKey = N14Data.GetPstId() .. str
    return playerPrefsKey
end
function N14Data.GetPrefsKeyMain()
    return N14Data.GetPrefsKey("UIN14DataPrefsKeyMain")
end
function N14Data.GetPrefsKeyHard()
    return N14Data.GetPrefsKey("UIN14DataPrefsKeyHard")
end

function N14Data.GetPrefsKeyMiniGame()
    return N14Data.GetPrefsKey("UIN14DataPrefsKeyMiniGame")
end
---------------------------------------------------------------------------------
function N14Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(N14Data.GetPrefsKeyMain())
end
function N14Data.HasPrefsHard()
    return UnityEngine.PlayerPrefs.HasKey(N14Data.GetPrefsKeyHard())
end

function N14Data.HasPrefsMiniGame()
    return UnityEngine.PlayerPrefs.HasKey(N14Data.GetPrefsKeyMiniGame())
end
---------------------------------------------------------------------------------
function N14Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(N14Data.GetPrefsKeyMain(), 1)
end
function N14Data.SetPrefsHard()
    UnityEngine.PlayerPrefs.SetInt(N14Data.GetPrefsKeyHard(), 1)
end

function N14Data.SetPrefsMiniGame()
    UnityEngine.PlayerPrefs.SetInt(N14Data.GetPrefsKeyMiniGame(), 1)
end

--endregion
