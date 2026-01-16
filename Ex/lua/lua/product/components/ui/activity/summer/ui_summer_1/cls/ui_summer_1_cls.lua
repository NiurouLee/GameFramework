---@class Summer1Data:Object
_class("Summer1Data", Object)
Summer1Data = Summer1Data

function Summer1Data:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self._campaign = nil --夏活1活动信息
end

--region 活动信息

function Summer1Data:RequestCampaign(TT) --请求活动（有缓存）
    local res = AsyncRequestRes:New()
    if not self._campaign then
        -- 获取活动 以及本窗口需要的组件
        ---@type UIActivityCampaign
        self._campaign = UIActivityCampaign:New()
        self._campaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_SUMMER_I)
        return
    end
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
    if res and res:GetSucc() then
    else
        Log.fatal("### [RequestCampaign]CampaignComProtoLoadInfo failed.")
    end
end
function Summer1Data:GetCampaign() --获取活动
    return self._campaign
end
function Summer1Data:GetCampaignId() --获取活动Id
    return self._campaign._id
end
function Summer1Data:GetCampaignLocalProgress()
    return self._campaign:GetLocalProcess()
end
--endregion

--region 红点
function Summer1Data:CheckRedAward() --累计奖励
    local lp = self:GetCampaignLocalProgress()
    local red = self.mCampaign:CheckComponentRed(lp, ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_CUMULATIVE_LOGIN)
    return red
end
function Summer1Data:CheckRedNormal() ---普通关红点：行动点已满 or 光灵初见有未通关的关卡
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetCampaignLocalProgress()
        local redActionPoint =
            self.mCampaign:CheckComponentRed(lp, ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_ACTION_POINT)
        local redFixTeam =
            self.mCampaign:CheckComponentRed(lp, ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_LEVEL_FIXTEAM)
        return redActionPoint or redFixTeam
    end
    return false
end
function Summer1Data:CheckRedGame() --小游戏奖励
    local state = self:GetStateGame()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetCampaignLocalProgress()
        local red = self.mCampaign:CheckComponentRed(lp, ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_SHAVING_ICE)
        return red
    end
    return false
end
--endregion

--region GetComponent
---@return CampaignSummerI
function Summer1Data:GetCampaignSummerI()
    local cSummerI = self.mCampaign:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_SUMMER_I)
    return cSummerI
end
---@return ICampaignComponentInfo
function Summer1Data:GetComponent(ecampaignSummerIComponentID)
    local cSummerI = self:GetCampaignSummerI()
    if not cSummerI then
        Log.fatal("### GetCampaignSummerI failed.")
        return
    end
    local cInfo = cSummerI:GetComponentInfo(ecampaignSummerIComponentID)
    return cInfo
end
---@return ICampaignComponentInfo
function Summer1Data:GetComponentNormal()
    local cInfo = self:GetComponent(ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_LEVEL_COMMON)
    return cInfo
end
---@return ICampaignComponentInfo
function Summer1Data:GetComponentHard()
    local cInfo = self:GetComponent(ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_LEVEL_HARD)
    return cInfo
end
---@return ShavingIceComponentInfo 继承自 ICampaignComponentInfo
function Summer1Data:GetComponentGame()
    local cInfo = self:GetComponent(ECampaignSummerIComponentID.ECAMPAIGN_SUMMER_I_SHAVING_ICE)
    return cInfo
end
--endregion

---region 显隐New
---@return UISummerOneEnterBtnState
function Summer1Data:GetState(cInfo)
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
function Summer1Data:GetStateNormal()
    local cInfo = self:GetComponentNormal()
    if not cInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function Summer1Data:GetStateHard()
    local cHardInfo = self:GetComponentHard()
    if not cHardInfo then
        Log.fatal("### GetComponentHard failed.")
        return
    end
    return self:GetState(cHardInfo)
end
---@return UISummerOneEnterBtnState
function Summer1Data:GetStateGame()
    local cCameInfo = self:GetComponentGame()
    if not cCameInfo then
        Log.fatal("### GetComponentGame failed.")
        return
    end
    return self:GetState(cCameInfo)
end
--检测小游戏是否有新开关卡
function Summer1Data:CheckMiniGameNewStage()
    local mLogin = GameGlobal.GetModule(LoginModule)
    local str = LocalDB.GetString("MiniGameNewStage" .. mLogin:GetRoleShowID())
    local ids = string.split(str, ",")
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local componentInfo = self:GetComponentGame()
    local list = componentInfo.mission_info_list
    local newStage = false
    for i = 1, #list do
        if list[i].unlock_time <= nowTimestamp then
            local record = false
            for j = 1, #ids do
                if ids[j] == tostring(i) then
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
--endregion

--region PrefsKey
---@private
function Summer1Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function Summer1Data.GetPrefsKey(str)
    local playerPrefsKey = Summer1Data.GetPstId() .. str
    return playerPrefsKey
end
function Summer1Data.GetPrefsKeyMain()
    return Summer1Data.GetPrefsKey("UISummer1PrefsKeyMain")
end
function Summer1Data.GetPrefsKeyHard()
    return Summer1Data.GetPrefsKey("UISummer1PrefsKeyHard")
end
function Summer1Data.GetPrefsKeyGame()
    return Summer1Data.GetPrefsKey("UISummer1PrefsKeyGame")
end
---------------------------------------------------------------------------------
function Summer1Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(Summer1Data.GetPrefsKeyMain())
end
function Summer1Data.HasPrefsHard()
    return UnityEngine.PlayerPrefs.HasKey(Summer1Data.GetPrefsKeyHard())
end
function Summer1Data.HasPrefsGame()
    return UnityEngine.PlayerPrefs.HasKey(Summer1Data.GetPrefsKeyGame())
end
---------------------------------------------------------------------------------
function Summer1Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(Summer1Data.GetPrefsKeyMain(), 1)
end
function Summer1Data.SetPrefsHard()
    UnityEngine.PlayerPrefs.SetInt(Summer1Data.GetPrefsKeyHard(), 1)
end
function Summer1Data.SetPrefsGame()
    UnityEngine.PlayerPrefs.SetInt(Summer1Data.GetPrefsKeyGame(), 1)
end
--endregion

--region UISummerOneEnterBtnState
---@class UISummerOneEnterBtnState
local UISummerOneEnterBtnState = {
    NotOpen = 1, --未开启
    Locked = 2, --未解锁（通关xxx等）
    Closed = 3, --已关闭
    Normal = 4 --正常
}
_enum("UISummerOneEnterBtnState", UISummerOneEnterBtnState)
--endregion
