---@class N11Data:CampaignDataBase
_class("N11Data", CampaignDataBase)
N11Data = N11Data

function N11Data:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
end

--region 红点 new
function N11Data:CheckRedAward() --累计奖励
    local lp = self:GetLocalProcess()
    local red = self.mCampaign:CheckComponentRed(lp, ECampaignN11ComponentID.ECAMPAIGN_N11_CUMULATIVE_LOGIN)
    return red
end
function N11Data:CheckRedNormal()
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local redActionPoint = self.mCampaign:CheckComponentRed(lp, ECampaignN11ComponentID.ECAMPAIGN_N11_ACTION_POINT)
        local redFixTeam = self.mCampaign:CheckComponentRed(lp, ECampaignN11ComponentID.ECAMPAIGN_N11_LEVEL_FIXTEAM)
        return redActionPoint or redFixTeam
    end
    return false
end
function N11Data:CheckNewHard()
    if not N11Data.HasPrefsHard() and self:GetStateHard() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
--endregion

--region Component ComponentInfo
---@return LineMissionComponent
function N11Data:GetComponentNormal()
    local c = self.activityCampaign:GetComponent(ECampaignN11ComponentID.ECAMPAIGN_N11_LEVEL_COMMON)
    return c
end
---@return LineMissionComponent
function N11Data:GetComponentHard()
    local c = self.activityCampaign:GetComponent(ECampaignN11ComponentID.ECAMPAIGN_N11_LEVEL_HARD)
    return c
end
---@return LineMissionComponentInfo
function N11Data:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN11ComponentID.ECAMPAIGN_N11_LEVEL_COMMON)
    return cInfo
end
---@return LineMissionComponentInfo
function N11Data:GetComponentInfoHard()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN11ComponentID.ECAMPAIGN_N11_LEVEL_HARD)
    return cInfo
end
--endregion

---@return UISummerOneEnterBtnState
function N11Data:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN11ComponentID.ECAMPAIGN_N11_SHOP)
    if c then
        return self:GetState(c)
    end
end
---@return UISummerOneEnterBtnState
function N11Data:GetStateAward()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN11ComponentID.ECAMPAIGN_N11_CUMULATIVE_LOGIN)
    if c then
        return self:GetState(c)
    end
end

--region 显隐New
---@return UISummerOneEnterBtnState
function N11Data:GetState(cInfo)
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
function N11Data:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N11Data:GetStateHard()
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
function N11Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function N11Data.GetPrefsKey(str)
    local playerPrefsKey = N11Data.GetPstId() .. str
    return playerPrefsKey
end
function N11Data.GetPrefsKeyMain()
    return N11Data.GetPrefsKey("UIN11DataPrefsKeyMain")
end
function N11Data.GetPrefsKeyHard()
    return N11Data.GetPrefsKey("UIN11DataPrefsKeyHard")
end
---------------------------------------------------------------------------------
function N11Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(N11Data.GetPrefsKeyMain())
end
function N11Data.HasPrefsHard()
    return UnityEngine.PlayerPrefs.HasKey(N11Data.GetPrefsKeyHard())
end
---------------------------------------------------------------------------------
function N11Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(N11Data.GetPrefsKeyMain(), 1)
end
function N11Data.SetPrefsHard()
    UnityEngine.PlayerPrefs.SetInt(N11Data.GetPrefsKeyHard(), 1)
end
--endregion
