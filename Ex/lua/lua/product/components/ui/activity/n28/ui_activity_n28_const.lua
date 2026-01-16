---@class UIActivityN28Const : Object
_class("UIActivityN28Const", Object)
UIActivityN28Const = UIActivityN28Const

function UIActivityN28Const:Constructor()
    self.dataAVG = nil
end

---@param res AsyncRequestRes
function UIActivityN28Const:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    self.dataAVG = campaignModule:GetN28AVGData()
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N28,
        ECampaignN28ComponentID.ECAMPAIGN_N28_CUMULATIVE_LOGIN, --累计登录（签到）
        ECampaignN28ComponentID.ECAMPAIGN_N28_FIRST_MEET, --线性关组件，光灵初见
        ECampaignN28ComponentID.ECAMPAIGN_N28_POWER2ITEM, --体力转换组件(掉落代币)
        ECampaignN28ComponentID.ECAMPAIGN_N28_LINE_MISSION, -- 普通关线性关
        ECampaignN28ComponentID.ECAMPAIGN_N28_DIFFICULT_MISSION, -- 困难关
        ECampaignN28ComponentID.ECAMPAIGN_N28_SHOP, --代币商店
        ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2 --AVG剧情小游戏二期
    )
    
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN28
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
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_CUMULATIVE_LOGIN)
    --线性关组件，光灵初见
    ---@type LineMissionComponent
    self._fixTeamComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_FIRST_MEET)
    ---@type LineMissionComponentInfo
    self._fixTeamCompInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_FIRST_MEET)
    --体力转换组件(掉落代币)
    ---@type CampaignPower2itemComponent
    self._power2itemComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_POWER2ITEM)
    ---@type Power2ItemComponentInfo
    self._power2itemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_POWER2ITEM)
    --普通线性关
    ---@type LineMissionComponent
    self._normalLineMissionComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._normalLineMissionompInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_LINE_MISSION)
    --困难线性关
    ---@type LineMissionComponent
    self._hardLineMissionComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_DIFFICULT_MISSION)
    ---@type LineMissionComponentInfo
    self._hardLineMissionompInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_DIFFICULT_MISSION)
    --商店探宝(抽奖)
    ---@type ExchangeItemComponent
    self._exchangeItemComponent = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_SHOP)
    ---@type ExchangeItemComponentInfo
    self._exchangeItemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_SHOP)
    --AVG二期
    ---@type NewYearDinnerMiniGameComponent
    self._N28AVGPHASE2Component = self._localProcess:GetComponent(ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2)
    ---@type NewYearDinnerComponentInfo
    self._N28AVGPHASE2CompInfo = self._localProcess:GetComponentInfo(ECampaignN28ComponentID.ECAMPAIGN_N28_AVG_PHASE_2) 
    
    
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

    local nowTime = self._timeModule:GetServerTime() / 1000
    --活动时间
    self._activeEndTime = sample.end_time

    if nowTime > sample.end_time then
        Log.error("Time error!")
        return
    end

    self.dataAVG:RequestCampaign(TT)
    self.dataAVG:Init()
    self.dataAVG:Update()
end

function UIActivityN28Const:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end


---@return CCampaignN28
function UIActivityN28Const:GetCampaign()
    return self._campaign
end

function UIActivityN28Const:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN28Const:GetName()
    return self._name
end

--副标题
function UIActivityN28Const:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityN28Const:GetActiveEndTime()
    return self._activeEndTime
end

--获取剧情id
function UIActivityN28Const:GetPlotId()
    return self._plotId
end

function UIActivityN28Const:CanPlayPlot()
    if self._plotId == nil then
        return false
    end
    if UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_ACTIVITY_FIRST_ENTER_PLOT") then
        return true
    end
    return false
end

function UIActivityN28Const:SetPlayPlotStatus()
    if self._plotId == nil then
        return
    end
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_ACTIVITY_FIRST_ENTER_PLOT", false)
end

--活动是否开启
function UIActivityN28Const:IsActivityEnd()
    if not self._activeEndTime then
       return true 
    end
    --local endTime = self:GetActiveEndTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

---=========================================== 获取组件 ===============================================

--获取累计登录组件
function UIActivityN28Const:GetLoginComponent()
    return self._cumulativeLoginComponent, self._cumulativeLoginComponentInfo
end

--获取光灵试用组件
function UIActivityN28Const:GetTryPetComponent()
    return self._fixTeamComponent, self._fixTeamCompInfo
end

--获取代币掉落组件
function UIActivityN28Const:GetPower2ItemComponent()
    return self._power2itemComponent, self._power2itemComponentInfo
end

--获取普通线性关组件
function UIActivityN28Const:GetNormalLineMissionComponent()
    return self._normalLineMissionComponent, self._normalLineMissionompInfo 
end

--获取困难线性关组件
function UIActivityN28Const:GetHardLineMissionComponent()
    return self._hardLineMissionComponent, self._hardLineMissionompInfo 
end

--获取商店组件
function UIActivityN28Const:GetShopComponent()
    return self._exchangeItemComponent, self._exchangeItemComponentInfo
end

--获取AVG组件
function UIActivityN28Const:GetAVGGameComponent()
    return   self._N28AVGPHASE2Component, self._N28AVGPHASE2CompInfo
end
---==========================================================================================

---====================================== 组件状态 ===========================================

--获取累计登录组件状态
function UIActivityN28Const:GetLoginComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._cumulativeLoginComponent)
end

--获取光灵初见组件状态
function UIActivityN28Const:GetTryPetComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._fixTeamComponent)
end

--获取体力转换组件状态
function UIActivityN28Const:GetPower2ItemComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._power2itemComponent)
end

--获取普通线性关组件状态
function UIActivityN28Const:GetNormalLineMissionComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._normalLineMissionComponent)
end

--获取困难线性关组件状态
function UIActivityN28Const:GetHardLineMissionComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._hardLineMissionComponent)
end
--特殊：入口获取困难线性关组件状态，时间到了就返回open
function UIActivityN28Const:EnterGetHardLineMissionComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckHard(self._hardLineMissionComponent)
end

--获取商店组件状态
function UIActivityN28Const:GetShopComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._exchangeItemComponent)
end

--获取小游戏组件状态
function UIActivityN28Const:GetAVGGameComponentStatus()
    if self:IsActivityEnd() then
        return ActivityN28ComponentStatus.ActivityEnd, 0
    end

    return UIActivityN28Helper.CheckComponentStatus(self._N28AVGPHASE2Component)
end

---===========================================================================================

---=========================================== 红点和NEW相关接口 ====================================================

--入口红点
function UIActivityN28Const:IsShowEntryRed()
    if self:IsActivityEnd() then
        return false
    end

    if self:IsShowLoginRed() then
        return true
    end

    if self:IsShowBattlePassRed() then
        return true
    end

    if self:IsShowNormalLineRed() then
        return true
    end

    if self:IsShowHardLineRed() then
        return true
    end

    if self:IsShowShopRed() then
        return true
    end

    if self:IsShowAVGGameRed() then
        return true
    end

    return false
end

--登录奖励红点
function UIActivityN28Const:IsShowLoginRed()
    local status, time = self:GetLoginComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end
   
    return self._campaign:CheckComponentRed(ECampaignN28ComponentID.ECAMPAIGN_N28_CUMULATIVE_LOGIN)
end

--战斗通行证红点
function UIActivityN28Const:IsShowBattlePassRed()
    if self:IsActivityEnd() then
        return false
    end

    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

--线性关红点
function UIActivityN28Const:IsShowNormalLineRed()
    local status, time = self:GetNormalLineMissionComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    local red = false
    red = red or self._localProcess:LineMissionRedDot()
    red = red or self._localProcess:GetFixMissionRedDot()

    return red
end

--困难线性关红点
function UIActivityN28Const:IsShowHardLineRed()
    local status, time = self:GetHardLineMissionComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    return self._localProcess:HardLineMissionRedDot()
end

--商店红点
function UIActivityN28Const:IsShowShopRed()
    local status, time = self:GetShopComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    return self._campaign:CheckComponentRed(ECampaignN28ComponentID.ECAMPAIGN_N28_SHOP)
end

--AVG游戏红点
function UIActivityN28Const:IsShowAVGGameRed()
    local status, time = self:GetAVGGameComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    local avgRed = self.dataAVG:HasRed()
    return avgRed

end

--入口NEW
function UIActivityN28Const:IsShowEntryNew()
    local enterNew = UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_ACTIVITY_ENTER_NEW")
    if enterNew then
        return true 
    end
    
    if self:IsShowNormalLineNew() then
        return true
    end

    if self:IsShowHardLineNew() then
        return true
    end

    if self:IsShowShopNew() then
        return true
    end

    if self:IsShowAVGGameNew() then
        return true
    end

    return false
end

--清除入口NEW
function UIActivityN28Const:ClearEnterNew()
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_ACTIVITY_ENTER_NEW", false)
end

--是否显示线性关New
function UIActivityN28Const:IsShowNormalLineNew()
    local status, time = self:GetNormalLineMissionComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    return UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_ACTIVITY_NORMAL_LINE_NEW")
end

--清除线性关NEW
function UIActivityN28Const:ClearNormalLineNew()
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_ACTIVITY_NORMAL_LINE_NEW", false)
end

--是否显示困难关NEW
function UIActivityN28Const:IsShowHardLineNew()
    local status, time = self:GetHardLineMissionComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    return UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_ACTIVITY_HARD_LINE_NEW")
end

--清除困难关NEW
function UIActivityN28Const:ClearHardLineNew()
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_ACTIVITY_HARD_LINE_NEW", false)
end

--是否显示商店NEW
function UIActivityN28Const:IsShowShopNew()
    local status, time = self:GetShopComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    return UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_ACTIVITY_SHOP_NEW")
end

--清除商店NEW
function UIActivityN28Const:ClearShopNew()
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_ACTIVITY_SHOP_NEW", false)
end

--是否显示avg游戏NEW
function UIActivityN28Const:IsShowAVGGameNew()
    local status, time = self:GetAVGGameComponentStatus()
    if status ~= ActivityN28ComponentStatus.Open then
        return false
    end

    local newFlag = UIActivityN28Helper.GetNewFlagStatus("PLAY_N28_AVG_Game_NEW")
    local avgNew = self.dataAVG:HasNew()
    return newFlag or avgNew
end

--清除avg游戏NEW
function UIActivityN28Const:ClearAVGGameNew()
    UIActivityN28Helper.SetNewFlagStatus("PLAY_N28_AVG_Game_NEW", false)
end