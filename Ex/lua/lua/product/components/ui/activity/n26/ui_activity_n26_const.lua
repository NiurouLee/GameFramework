---@class UIActivityN26Const : Object
_class("UIActivityN26Const", Object)
UIActivityN26Const = UIActivityN26Const

function UIActivityN26Const:Constructor()
end

---@param res AsyncRequestRes
function UIActivityN26Const:LoadData(TT, res)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N26,
        ECampaignN26ComponentID.ECAMPAIGN_N26_CUMULATIVE_LOGIN, --累计登录（签到）
        ECampaignN26ComponentID.ECAMPAIGN_N26_FIRST_MEET, --线性关组件，光灵初见
        ECampaignN26ComponentID.ECAMPAIGN_N26_POWER2ITEM, --体力转换组件(掉落代币)
        ECampaignN26ComponentID.ECAMPAIGN_N26_LINE_MISSION, -- 普通关线性关
        ECampaignN26ComponentID.ECAMPAIGN_N26_DIFFICULT_MISSION, -- 困难关
        ECampaignN26ComponentID.ECAMPAIGN_N26_SHOP, --代币商店
        ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER --年夜饭
    )
    
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    ---@type CCampaignN26
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
    self._cumulativeLoginComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_CUMULATIVE_LOGIN)
    ---@type CumulativeLoginComponentInfo
    self._cumulativeLoginComponentInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_CUMULATIVE_LOGIN)
    --线性关组件，光灵初见
    ---@type LineMissionComponent
    self._fixTeamComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_FIRST_MEET)
    ---@type LineMissionComponentInfo
    self._fixTeamCompInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_FIRST_MEET)
    --体力转换组件(掉落代币)
    ---@type CampaignPower2itemComponent
    self._power2itemComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_POWER2ITEM)
    ---@type Power2ItemComponentInfo
    self._power2itemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_POWER2ITEM)
    --普通线性关
    ---@type LineMissionComponent
    self._normalLineMissionComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_LINE_MISSION)
    ---@type LineMissionComponentInfo
    self._normalLineMissionompInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_LINE_MISSION)
    --困难线性关
    ---@type LineMissionComponent
    self._hardLineMissionComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_DIFFICULT_MISSION)
    ---@type LineMissionComponentInfo
    self._hardLineMissionompInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_DIFFICULT_MISSION)
    --商店探宝(抽奖)
    ---@type ExchangeItemComponent
    self._exchangeItemComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_SHOP)
    ---@type ExchangeItemComponentInfo
    self._exchangeItemComponentInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_SHOP)
    --年夜饭
    ---@type NewYearDinnerMiniGameComponent
    self._newyearDinnerComponent = self._localProcess:GetComponent(ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER)
    ---@type NewYearDinnerComponentInfo
    self._newyearDinnerCompInfo = self._localProcess:GetComponentInfo(ECampaignN26ComponentID.ECAMPAIGN_N26_NEWYEQR_DINNER) 
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

    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function UIActivityN26Const:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityN26Const:GetCampaign()
    return self._campaign
end

function UIActivityN26Const:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityN26Const:GetName()
    return self._name
end

--副标题
function UIActivityN26Const:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityN26Const:GetActiveEndTime()
    return self._activeEndTime
end

--获取剧情id
function UIActivityN26Const:GetPlotId()
    return self._plotId
end

function UIActivityN26Const:CanPlayPlot()
    if self._plotId == nil then
        return false
    end
    if UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_FIRST_ENTER_PLOT") then
        return true
    end
    return false
end

function UIActivityN26Const:SetPlayPlotStatus()
    if self._plotId == nil then
        return
    end
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_FIRST_ENTER_PLOT", false)
end

--活动是否开启
function UIActivityN26Const:IsActivityEnd()
    if not self._activeEndTime then
       return true 
    end
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

---=========================================== 获取组件 ===============================================

--获取累计登录组件
function UIActivityN26Const:GetLoginComponent()
    return self._cumulativeLoginComponent, self._cumulativeLoginComponentInfo
end

--获取光灵试用组件
function UIActivityN26Const:GetTryPetComponent()
    return self._fixTeamComponent, self._fixTeamCompInfo
end

--获取代币掉落组件
function UIActivityN26Const:GetPower2ItemComponent()
    return self._power2itemComponent, self._power2itemComponentInfo
end

--获取普通线性关组件
function UIActivityN26Const:GetNormalLineMissionComponent()
    return self._normalLineMissionComponent, self._normalLineMissionompInfo 
end

--获取困难线性关组件
function UIActivityN26Const:GetHardLineMissionComponent()
    return self._hardLineMissionComponent, self._hardLineMissionompInfo 
end

--获取商店组件
function UIActivityN26Const:GetShopComponent()
    return self._exchangeItemComponent, self._exchangeItemComponentInfo
end

--获取小游戏组件
function UIActivityN26Const:GetMiniGameComponent()
    return self._newyearDinnerComponent, self._newyearDinnerCompInfo
end

---==========================================================================================

---====================================== 组件状态 ===========================================

--获取累计登录组件状态
function UIActivityN26Const:GetLoginComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._cumulativeLoginComponent)
end

--获取光灵初见组件状态
function UIActivityN26Const:GetTryPetComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._fixTeamComponent)
end

--获取体力转换组件状态
function UIActivityN26Const:GetPower2ItemComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._power2itemComponent)
end

--获取普通线性关组件状态
function UIActivityN26Const:GetNormalLineMissionComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._normalLineMissionComponent)
end

--获取困难线性关组件状态
function UIActivityN26Const:GetHardLineMissionComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._hardLineMissionComponent)
end

--获取商店组件状态
function UIActivityN26Const:GetShopComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._exchangeItemComponent)
end

--获取开拍吧组件状态
function UIActivityN26Const:GetMovieComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)

    return ActivityComponentStatus.Open, seconds
end

--获取小游戏组件状态
function UIActivityN26Const:GetMiniGameComponentStatus()
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end

    return UIActivityN26Helper.CheckComponentStatus(self._newyearDinnerComponent)
end

---===========================================================================================

---=========================================== 红点和NEW相关接口 ====================================================

--入口红点
function UIActivityN26Const:IsShowEntryRed()
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

    if self:IsShowMovieRed() then
        return true
    end

    if self:IsShowMiniGameRed() then
        return true
    end

    return false
end

--登录奖励红点
function UIActivityN26Const:IsShowLoginRed()
    local status, time = self:GetLoginComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end
   
    return self._campaign:CheckComponentRed(ECampaignN26ComponentID.ECAMPAIGN_N26_CUMULATIVE_LOGIN)
end

--战斗通行证红点
function UIActivityN26Const:IsShowBattlePassRed()
    if self:IsActivityEnd() then
        return false
    end

    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

--线性关红点
function UIActivityN26Const:IsShowNormalLineRed()
    local status, time = self:GetNormalLineMissionComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    local red = false
    red = red or self._localProcess:LineMissionRedDot()
    red = red or self._localProcess:GetFixMissionRedDot()

    return red
end

--困难线性关红点
function UIActivityN26Const:IsShowHardLineRed()
    local status, time = self:GetHardLineMissionComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return self._localProcess:HardLineMissionRedDot()
end

--商店红点
function UIActivityN26Const:IsShowShopRed()
    local status, time = self:GetShopComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return self._campaign:CheckComponentRed(ECampaignN26ComponentID.ECAMPAIGN_N26_SHOP)
end

--开拍吧红点
function UIActivityN26Const:IsShowMovieRed()

    local status, time = self:GetMovieComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end
    return UIActivityN26Helper.ShowOrNot()
end

--小游戏红点
function UIActivityN26Const:IsShowMiniGameRed()
    local status, time = self:GetMiniGameComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIN26CookData.CheckRed_MatRequire(self._newyearDinnerCompInfo) or 
        UIN26CookData.CheckRed_Collect(self._newyearDinnerCompInfo) or
        UIN26CookData.CheckRed_CookBook(self._newyearDinnerCompInfo)
end

--入口NEW
function UIActivityN26Const:IsShowEntryNew()
    local enterNew = UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_ENTER_NEW")
    if enterNew then
        return true 
    end
    
    if self:IsShowNormalLineNew() then
        return true
    end

    if self:IsShowHardLineNew() then
        return true
    end

    if self:IsShowMovieNew() then
        return true
    end

    if self:IsShowShopNew() then
        return true
    end

    if self:IsShowMiniGameNew() then
        return true
    end

    return false
end

--清除入口NEW
function UIActivityN26Const:ClearEnterNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_ENTER_NEW", false)
end


--是否显示线性关New
function UIActivityN26Const:IsShowNormalLineNew()
    local status, time = self:GetNormalLineMissionComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_NORMAL_LINE_NEW")
end

--清除线性关NEW
function UIActivityN26Const:ClearNormalLineNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_NORMAL_LINE_NEW", false)
end

--是否显示困难关NEW
function UIActivityN26Const:IsShowHardLineNew()
    local status, time = self:GetHardLineMissionComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_HARD_LINE_NEW")
end

--清除困难关NEW
function UIActivityN26Const:ClearHardLineNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_HARD_LINE_NEW", false)
end

--是否显示商店NEW
function UIActivityN26Const:IsShowShopNew()
    local status, time = self:GetShopComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_SHOP_NEW")
end

--清除商店NEW
function UIActivityN26Const:ClearShopNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_SHOP_NEW", false)
end

--是否显示开拍吧NEW
function UIActivityN26Const:IsShowMovieNew()
    local status, time = self:GetMovieComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_MOVIE_NEW")
end

--清除开拍吧NEW
function UIActivityN26Const:ClearMovieNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_MOVIE_NEW", false)
end

--是否显示开拍吧NEW
function UIActivityN26Const:IsShowMiniGameNew()
    local status, time = self:GetMiniGameComponentStatus()
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityN26Helper.GetNewFlagStatus("PLAY_N26_ACTIVITY_MINGAME_NEW") or
        UIN26CookData.CheckNew_CookBook(self._newyearDinnerCompInfo)
end

--清除开拍吧NEW
function UIActivityN26Const:ClearMiniGameNew()
    UIActivityN26Helper.SetNewFlagStatus("PLAY_N26_ACTIVITY_MINGAME_NEW", false)
end
