---@class N22Data:CampaignDataBase
_class("N22Data", CampaignDataBase)
N22Data = N22Data

function N22Data:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
end

--region 红点 new
function N22Data:CheckRedAward() --累计奖励
    local lp = self:GetLocalProcess()
    local red = self.mCampaign:CheckComponentRed(lp, ECampaignN22ComponentID.ECAMPAIGN_N22_CUMULATIVE_LOGIN)
    return red
end
function N22Data:CheckRedNormal()
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local redActionPoint = self.mCampaign:CheckComponentRed(lp, ECampaignN22ComponentID.ECAMPAIGN_N22_POWER2ITEM)
        local redFixTeam = self.mCampaign:CheckComponentRed(lp, ECampaignN22ComponentID.ECAMPAIGN_N22_FIRST_MEET)
        return redActionPoint or redFixTeam
    end
    return false
end
function N22Data:CheckNewHard()
    if not N22Data.HasPrefsHard() and self:GetStateHard() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
--endregion

--region Component ComponentInfo
---@return LineMissionComponent
function N22Data:GetComponentNormal()
    local c = self.activityCampaign:GetComponent(ECampaignN22ComponentID.ECAMPAIGN_N22_LINE_MISSION)
    return c
end
---@return LineMissionComponent
function N22Data:GetComponentHard()
    local c = self.activityCampaign:GetComponent(ECampaignN22ComponentID.ECAMPAIGN_N22_DIFFICULT_MISSION)
    return c
end
function N22Data:GetComponentEntrust()
    local c = self.activityCampaign:GetComponent(ECampaignN22ComponentID.ECAMPAIGN_N22_ENTRUST)
    return c
end
---@return LineMissionComponentInfo
function N22Data:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN22ComponentID.ECAMPAIGN_N22_LINE_MISSION)
    return cInfo
end
---@return LineMissionComponentInfo
function N22Data:GetComponentInfoHard()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN22ComponentID.ECAMPAIGN_N22_DIFFICULT_MISSION)
    return cInfo
end
---@return LineMissionComponentInfo
function N22Data:GetComponentInfoEntrust()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN22ComponentID.ECAMPAIGN_N22_ENTRUST)
    return cInfo
end
--endregion

---@return UISummerOneEnterBtnState
function N22Data:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN22ComponentID.ECAMPAIGN_N22_SHOP)
    if c then
        return self:GetState(c)
    end
end
---@return UISummerOneEnterBtnState
function N22Data:GetStateAward()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN22ComponentID.ECAMPAIGN_N22_CUMULATIVE_LOGIN)
    if c then
        return self:GetState(c)
    end
end

--region 显隐New
---@return UISummerOneEnterBtnState
function N22Data:GetState(cInfo)
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
function N22Data:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N22Data:GetStateHard()
    local cHardInfo = self:GetComponentInfoHard()
    if not cHardInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cHardInfo)
end

function N22Data:GetStateEntrust()
    local cEntrustInfo = self:GetComponentInfoEntrust()
    if not cEntrustInfo then
        Log.fatal("### GetComponentEntrust failed.")
        return
    end
    return self:GetState(cEntrustInfo)
end
--endregion

--region PrefsKey
---@private
function N22Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function N22Data.GetPrefsKey(str)
    local playerPrefsKey = N22Data.GetPstId() .. str
    return playerPrefsKey
end
function N22Data.GetPrefsKeyMain()
    return N22Data.GetPrefsKey("UIN22DataPrefsKeyMain")
end
function N22Data.GetPrefsKeyHard()
    return N22Data.GetPrefsKey("UIN22DataPrefsKeyHard")
end

function N22Data.GetPrefsKeyMission()
    return N22Data.GetPrefsKey("UIActivityN22lineMission")
end

function N22Data.GetPrefsKeyEntrust()
    return N22Data.GetPrefsKey("UIActivityN22lineEntrust")
end
---------------------------------------------------------------------------------
function N22Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(N22Data.GetPrefsKeyMain())
end
function N22Data.HasPrefsHard()
    return UnityEngine.PlayerPrefs.HasKey(N22Data.GetPrefsKeyHard())
end
function N22Data.HasPrefsMission()
    return UnityEngine.PlayerPrefs.HasKey(N22Data.GetPrefsKeyMission())
end

function N22Data.HasPrefsEntrust()
    return UnityEngine.PlayerPrefs.HasKey(N22Data.GetPrefsKeyEntrust())
end
---------------------------------------------------------------------------------
function N22Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(N22Data.GetPrefsKeyMain(), 1)
end
function N22Data.SetPrefsHard()
    UnityEngine.PlayerPrefs.SetInt(N22Data.GetPrefsKeyHard(), 1)
end

function N22Data.SetPrefsMission()
    UnityEngine.PlayerPrefs.SetInt(N22Data.GetPrefsKeyMission(), 1)
end

function N22Data.SetPrefsEntrust()
    UnityEngine.PlayerPrefs.SetInt(N22Data.GetPrefsKeyEntrust(), 1)
end
--endregion
