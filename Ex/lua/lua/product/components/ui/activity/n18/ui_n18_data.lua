---@class N18Data:CampaignDataBase
_class("N18Data", CampaignDataBase)
N18Data = N18Data

function N18Data:Constructor()
    self._redDotModule = GameGlobal.GetModule(RedDotModule)
end

--region 红点 new
function N18Data:CheckRedCumulativeLogin() --累登
    local red_level = self.activityCampaign:CheckComponentRed(ECampaignN18ComponentID.ECAMPAIGN_N18_CUMULATIVE_LOGIN)
    return red_level
end

function N18Data:CheckRedLevelFixteam() -- 光灵初见
    local red_level = self.activityCampaign:CheckComponentRed(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_FIXTEAM)
    return red_level
end

function N18Data:CheckRedNormal() -- 普通关
    local red_level = self.activityCampaign:CheckComponentRed(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_COMMON)
    return red_level
end

function N18Data:CheckRedHard() -- 困难关
    local red_level = self.activityCampaign:CheckComponentRed(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_HARD)
    return red_level
end

function N18Data:CheckRedMiniGame() -- 薇丝大冒险
    local primaryCount, seniorCount = HomelandFindTreasureConst.GetSingleCount()
    return seniorCount > 0
end
--endregion

--region Component ComponentInfo
---@return LineMissionComponent
function N18Data:GetComponentNormal() -- 普通关组件
    local c = self.activityCampaign:GetComponent(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_COMMON)
    return c
end
---@return LineMissionComponent
function N18Data:GetComponentHard() -- 困难关组件
    local c = self.activityCampaign:GetComponent(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_HARD)
    return c
end
---@return LineMissionComponentInfo
function N18Data:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_COMMON)
    return cInfo
end
---@return LineMissionComponentInfo
function N18Data:GetComponentInfoHard()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_LEVEL_HARD)
    return cInfo
end
---@return MiniGameComponentInfo
function N18Data:GetComponentInfoMinigame()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_MINI_GAME)
    return cInfo
end
--endregion

---@return UIN18BtnState
function N18Data:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_SHOP)
    if c then
        return self:GetState(c)
    end
end

function N18Data:CheckNewMiniGame() -- 薇丝大冒险
    return not self:HasPrefsMiniGame()
end

---@return UIN18BtnState
function N18Data:GetStateMiniGame()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_MINI_GAME)
    if c then
        return self:GetState(c)
    end
end

---@return UIN18BtnState
function N18Data:GetStateCumulativeLogin()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN18ComponentID.ECAMPAIGN_N18_CUMULATIVE_LOGIN)
    if c then
        return self:GetState(c)
    end
end

--region 显隐New
---@return UIN18BtnState
function N18Data:GetState(cInfo)
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < cInfo.m_unlock_time then --未开启
        return UIN18BtnState.NotOpen
    elseif nowTimestamp > cInfo.m_close_time then --已关闭
        return UIN18BtnState.Closed
    else --进行中
        if cInfo.m_b_unlock then --是否已解锁，可能有关卡条件
            return UIN18BtnState.Normal
        else
            local cfgv = Cfg.cfg_campaign_mission[cInfo.m_need_mission_id]
            if cfgv then
                return UIN18BtnState.Locked
            else
                return UIN18BtnState.Normal
            end
        end
    end
end
---@return UIN18BtnState
function N18Data:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end
---@return UIN18BtnState
function N18Data:GetStateHard()
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
function N18Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function N18Data.GetPrefsKey(str)
    local playerPrefsKey = N18Data.GetPstId() .. str
    return playerPrefsKey
end
function N18Data.GetPrefsKeyMain()
    return N18Data.GetPrefsKey("UIN18DataPrefsKeyMain")
end
function N18Data.GetPrefsKeyHard()
    return N18Data.GetPrefsKey("UIN18DataPrefsKeyHard")
end

function N18Data.GetPrefsKeyMiniGame()
    return N18Data.GetPrefsKey("UIN18DataPrefsKeyMiniGame")
end
---------------------------------------------------------------------------------
function N18Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(N18Data.GetPrefsKeyMain())
end
function N18Data.HasPrefsHard()
    return UnityEngine.PlayerPrefs.HasKey(N18Data.GetPrefsKeyHard())
end

function N18Data.HasPrefsMiniGame()
    return UnityEngine.PlayerPrefs.HasKey(N18Data.GetPrefsKeyMiniGame())
end
---------------------------------------------------------------------------------
function N18Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(N18Data.GetPrefsKeyMain(), 1)
end
function N18Data.SetPrefsHard()
    UnityEngine.PlayerPrefs.SetInt(N18Data.GetPrefsKeyHard(), 1)
end

function N18Data.SetPrefsMiniGame()
    UnityEngine.PlayerPrefs.SetInt(N18Data.GetPrefsKeyMiniGame(), 1)
end

--region UIN18BtnState
---@class UIN18BtnState
local UIN18BtnState = {
    NotOpen = 1, --未开启
    Locked = 2, --未解锁（通关xxx等）
    Closed = 3, --已关闭
    Normal = 4 --正常
}
_enum("UIN18BtnState", UIN18BtnState)


--endregion
