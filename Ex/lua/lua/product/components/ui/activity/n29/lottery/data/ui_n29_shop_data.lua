---@class UIN29ShopData:CampaignDataBase
_class("UIN29ShopData", CampaignDataBase)
UIN29ShopData = UIN29ShopData

function UIN29ShopData:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.componentIdLottery = ECampaignN29ComponentID.ECAMPAIGN_N29_LOTTERY
    self:Init()
end

function UIN29ShopData:Init()
end

---@param res AsyncRequestRes
function UIN29ShopData.CheckCode(res)
    local result = res:GetResult()
    if result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS then
        return true
    end
    local msg = StringTable.Get("str_activity_error_" .. result)
    ToastManager.ShowToast(msg)
    if
        result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED or
            result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
     then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain) --活动结束，切到主界面
    end
    return false
end

--region 红点 new
function UIN29ShopData:CheckRedShop()
    local state = self:GetStateShop()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local redFixTeam = self.mCampaign:CheckComponentRed(lp, self.componentIdLottery)
        return redFixTeam
    end
    return false
end
--endregion

--region Component ComponentInfo
---@return LotteryComponent 商店（抽奖）
function UIN29ShopData:GetComponentShop()
    local c = self.activityCampaign:GetComponent(self.componentIdLottery)
    return c
end
---@return LotteryComponentInfo 商店（抽奖）
function UIN29ShopData:GetComponentInfoShop()
    local cInfo = self.activityCampaign:GetComponentInfo(self.componentIdLottery)
    return cInfo
end
--endregion

--region 显隐New
---@return UISummerOneEnterBtnState
function UIN29ShopData:GetState(cInfo)
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
function UIN29ShopData:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(self.componentIdLottery)
    if c then
        return self:GetState(c)
    end
end
--endregion

---@return AwardInfo[][] 获取奖池列表
function UIN29ShopData:GetPools()
    local cInfoLottery = self:GetComponentInfoShop()
    return cInfoLottery.m_jackpots
end
---@return AwardInfo[] 根据奖池索引获取奖励列表
function UIN29ShopData:GetPoolAwards(index)
    local pools = self:GetPools()
    local awards = pools[index]
    return awards
end
---@return boolean 第index个奖池是否解锁
function UIN29ShopData:IsPoolUnlock(index)
    local cLottery = self:GetComponentShop()
    if cLottery then
        return cLottery:IsLotteryJackpotUnlock(index)
    end
    return false
end
---@return boolean 奖池是否抽空
function UIN29ShopData:IsPoolEmpty(index)
    local cLottery = self:GetComponentShop()
    if cLottery then
        return cLottery:IsLotteryJeckpotEmpty(index)
    end
    return false
end
---@return number, boolean 获取奖池剩余抽奖次数，奖池是否抽空
function UIN29ShopData:GetPoolLeftDrawCount(index)
    local canDrawCardCount = 0
    local awards = self:GetPoolAwards(index)
    for index, award in ipairs(awards) do
        if award.m_lottery_count and award.m_lottery_count > 0 then
            canDrawCardCount = canDrawCardCount + award.m_lottery_count
        end
    end
    return canDrawCardCount, canDrawCardCount <= 0
end
---@return number 获取剩余抽奖资源数
function UIN29ShopData:GetCostCount()
    local cInfoLottery = self:GetComponentInfoShop()
    local totalNum = ClientCampaignDrawShop.GetMoney(cInfoLottery.m_cost_item_id)
    return totalNum
end
---@param drawCount number 抽奖次数
---@return boolean 当前抽奖足够
function UIN29ShopData:IsCostEnough(drawCount)
    local totalNum = self:GetCostCount()
    local cInfoLottery = self:GetComponentInfoShop()
    local isEnough = totalNum >= cInfoLottery.m_cost_count * drawCount
    return isEnough
end
---@return boolean 是否获取都有大奖
function UIN29ShopData:GotAllBigAward()
    local pools = self:GetPools()
    for key, pool in pairs(pools) do
        for key, award in pairs(pool) do
            if award.m_is_big_reward and award.m_lottery_count > 0 then --该奖池还有大奖
                return false
            end
        end
    end
    return true
end

--region PrefsKey
---@private
function UIN29ShopData.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function UIN29ShopData.GetPrefsKey(str)
    local playerPrefsKey = UIN29ShopData.GetPstId() .. str
    return playerPrefsKey
end
function UIN29ShopData.GetPrefsKeyMain()
    return UIN29ShopData.GetPrefsKey("UIN23DataPrefsKeyMain")
end
function UIN29ShopData.GetPrefsKeyShop()
    return UIN29ShopData.GetPrefsKey("UIN23DataPrefsKeyShop")
end
---------------------------------------------------------------------------------
function UIN29ShopData.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(UIN29ShopData.GetPrefsKeyMain())
end
function UIN29ShopData.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(UIN29ShopData.GetPrefsKeyMain(), 1)
end
function UIN29ShopData.HasPrefsShop()
    return UnityEngine.PlayerPrefs.HasKey(UIN29ShopData.GetPrefsKeyShop())
end
function UIN29ShopData.SetPrefsShop()
    UnityEngine.PlayerPrefs.SetInt(UIN29ShopData.GetPrefsKeyShop(), 1)
end
--endregion
