---@class UICampainEnterLocalData:CampaignDataBase
_class("UICampainEnterLocalData", CampaignDataBase)
UICampainEnterLocalData = UICampainEnterLocalData

function UICampainEnterLocalData:Constructor()
    self._redDotModule = GameGlobal.GetModule(RedDotModule)
end

--region 显隐New
---@return 
function UICampainEnterLocalData:GetState(cInfo)
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

function UICampainEnterLocalData:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end

function UICampainEnterLocalData:GetStateHard()
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
function UICampainEnterLocalData.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function UICampainEnterLocalData.GetPrefsKey(str)
    local playerPrefsKey = UICampainEnterLocalData.GetPstId() .. str
    return playerPrefsKey
end
function UICampainEnterLocalData.GetPrefsKeyStr(keyword)
    return UICampainEnterLocalData.GetPrefsKey("UICampainEnterLocalData"..keyword)
end
--------------------------------------------------------------------------------

function UICampainEnterLocalData.HasPrefsKeyStr(keyword)
    return UnityEngine.PlayerPrefs.HasKey(UICampainEnterLocalData.GetPrefsKeyStr(keyword))
end
---------------------------------------------------------------------------------

function UICampainEnterLocalData.SetPrefsKeyStr(keyword)
    UnityEngine.PlayerPrefs.SetInt(UICampainEnterLocalData.GetPrefsKeyStr(keyword), 1)
end

function UICampainEnterLocalData.GetRedPoint()

    return 
end

function UICampainEnterLocalData.GetNewPoint()
    return  UICampainEnterLocalData.GetPrefsKeyStr("NewPoint")
end

function UICampainEnterLocalData.SetNewPoint()
    if not UICampainEnterLocalData.HasPrefsKeyStr("NewPoint") then 
        UICampainEnterLocalData.SetPrefsKeyStr("NewPoint")
    end 
end



--endregion
