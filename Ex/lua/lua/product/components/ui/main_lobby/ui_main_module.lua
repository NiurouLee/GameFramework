---主界面打开功能
---@class UIMainModule:UIModule
_class("UIMainModule", UIModule)
UIMainModule = UIMainModule

function UIMainModule:Dispose()
    self._openIdx = nil
    self._openList = nil
end

function UIMainModule:Constructor()
    --打开列表
    ---@type UIMainOpenData[]
    self._openList = {}
    self._openIdx = 1

    self:RegisterAllOpenList()
end

function UIMainModule:GetOpenIdx()
    return self._openIdx
end

function UIMainModule:SetOpenIdx(idx)
    self._openIdx = idx
end

---@return UIMainOpenData[] 返回一个openList的拷贝，防止误操作openList
function UIMainModule:GetOpenList()
    local retList = {}
    if self._openList and table.count(self._openList) > 0 then
        for i = 1, #self._openList do
            local _data = self._openList[i]
            table.insert(retList, _data)
        end
    end
    return retList
end

--注册一个打开界面
---@param data UIMainOpenData
function UIMainModule:RegisertOpenData(data)
    if not self._openList then
        self._openList = {}
    end
    if table.count(self._openList) > 0 then
        for i = 1, #self._openList do
            local _data = self._openList[i]
            if _data.ID == data.ID then
                Log.error("###[UIMainModule] RegisertOpenData -- regisert a same data ! id --> ", data.ID)
                return
            end
        end
    end
    local _data = data
    table.insert(self._openList, _data)
    Log.debug("###[UIMainModule] register one data ! id --> ", data.ID)
end

--移除一个注册
---@param data UIMainOpenData
function UIMainModule:RemoveOpenData(data)
    if self._openList and table.count(self._openList) > 0 then
        for i = 1, #self._openList do
            local _data = self._openList[i]
            if _data.ID == data.ID then
                table.remove(self._openList, i)
                break
            end
        end
    end
end

--注册
function UIMainModule:RegisterAllOpenList()
    self:RegisterSignInOpen()

    if not NoNoticeOut then
        self:RegisterNoticeOpen()
    end

    local regCampaignCfgList = Cfg.cfg_main_open_list {NormalAndActivity = 1, Reg = true}
    if regCampaignCfgList and #regCampaignCfgList > 0 then
        for i = 1, #regCampaignCfgList do
            local cfg = regCampaignCfgList[i]
            self:RegisterActivityTotalLoginOpen(cfg.UIType)
        end
    end
end

--注册签到打开
function UIMainModule:RegisterSignInOpen()
    ---@type UIMainOpenData
    local uIMainOpenData =
        UIMainOpenData:New(
        UIMainOpenType.SignIn,
        function()
            --检查通关1-3 4001030--cfg_global
            local isPassMissionID = Cfg.cfg_global["signInPassMissionID"].IntValue
            local missionModule = GameGlobal.GetModule(MissionModule)
            local isPass = missionModule:IsPassMissionID(isPassMissionID)
            if not isPass then
                return false
            end

            --module获取当前有没有签到
            local signInModule = GameGlobal.GetModule(SignInModule)
            local todaySignIn = signInModule:IsSignInToday()
            if not todaySignIn then
                GameGlobal.UIStateManager():ShowDialog("UISignInController")
                return true
            end
            return false
        end,
        UIMainOpenState.DayOnce
    )

    self:RegisertOpenData(uIMainOpenData)
end

--注册星灵打开
function UIMainModule:RegisterPetOpen()
    local uiMainOpenData =
        UIMainOpenData:New(
        UIMainOpenType.Pet,
        function()
            GameGlobal.UIStateManager():ShowDialog("UIHeartSpiritController")
            return true
        end,
        UIMainOpenState.DayOnce
    )
    self:RegisertOpenData(uiMainOpenData)
end

--注册公告打开
function UIMainModule:RegisterNoticeOpen()
    ---@type UIMainOpenData
    local uIMainOpenData =
        UIMainOpenData:New(
        UIMainOpenType.Notice,
        function()
            local noticeData = GameGlobal.GetModule(LoginModule):GetNoticeData()
            if noticeData == nil then
                Log.debug("###[UIMainModule] noticeData == nil!")
                return false
            end
            local systemState = noticeData:GetNoticeNewStateWithGroup(NoticeType.System)
            local activeState = noticeData:GetNoticeNewStateWithGroup(NoticeType.Active)
            local systemCount = noticeData:GetNoticeCountStateWithGroup(NoticeType.System)
            local activeCount = noticeData:GetNoticeCountStateWithGroup(NoticeType.Active)
            local systemState = noticeData:GetNoticeNewStateWithGroup(NoticeType.System)
            local ret = false
            local noticeOpen = GameGlobal.GetModule(RoleModule):CheckModuleUnlock(GameModuleID.MD_Notify)
            if noticeOpen then
                if systemState then
                    if not noticeData._firstLogin then
                        --离线登陆
                        if not NoPopNotice then
                            GameGlobal.UIStateManager():ShowDialog("UINoticeController", NoticeType.System)
                            ret = true
                        end
                    end
                else
                    if activeState then
                        if not noticeData._firstLogin then
                            --离线登陆
                            if not NoPopNotice then
                                GameGlobal.UIStateManager():ShowDialog("UINoticeController", NoticeType.Active)
                                ret = true
                            end
                        end
                    end
                end
            end
            if not noticeData._firstLogin then
                noticeData:ChangeFirstLogin()
            end

            if not ret then
                Log.debug("###[UIMainModule] notice no pop !")
            end

            return ret
        end,
        UIMainOpenState.Once
    )

    self:RegisertOpenData(uIMainOpenData)
end

--注册签到打开

function UIMainModule:RegisterActivityTotalLoginOpen(openType)
    local componentType = 0
    local open_cfg = Cfg.cfg_main_open_list {UIType = openType}
    if open_cfg and #open_cfg > 0 then
        componentType = open_cfg[1].RegParam
        if not componentType then
            return
        end
    else
        return
    end
    local campaignType = openType --活动id与功能id相同
    ---@type UIMainOpenData
    local uIMainOpenData =
        UIMainOpenData:New(
        openType,
        function()
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            if not campaignModule then
                return false
            end
            local isCmptOpened = false
            local sampleInfo = campaignModule.m_campaign_manager:GetSampleByType(campaignType)
            if not sampleInfo then
                return false
            end
            if sampleInfo.is_open then
                isCmptOpened = true
            end
            if not isCmptOpened then
                return false
            end
            local complateFlag =
                sampleInfo.m_extend_info[CampainExtendKey.E_CAMPAIGN_EXTEND_KEY_CUMULATIVE_LOGIN_COMPLATE]
            if complateFlag and complateFlag == 1 then
                return false --全部领完
            end
            if openType == ECampaignType.CAMPAIGN_TYPE_N10 then --n20 小林家
                GameGlobal.UIStateManager():ShowDialog(
                    "UIN10TotalLoginAwardController",
                    true,
                    campaignType,
                    componentType
                )
            elseif openType == ECampaignType.CAMPAIGN_TYPE_N19_P5 then --n19p5
                GameGlobal.UIStateManager():ShowDialog("UIN19P5SignInController",true)
            elseif openType == ECampaignType.CAMPAIGN_TYPE_N25_NEW_YEAR then --n25 new year 
                GameGlobal.UIStateManager():ShowDialog("UIN25NewYear", true)
            elseif openType == ECampaignType.CAMPAIGN_TYPE_N31_ANNIVERSARY then
                local campaign = UIActivityCampaign:New()
                campaign:LoadCampaignInfo_Local(ECampaignType.CAMPAIGN_TYPE_N31_ANNIVERSARY)
                local show = UIN31SecondAnniversaryContent.CheckAutoPop(campaign)
                if show then
                    GameGlobal.UIStateManager():ShowDialog("UISideEnterCenterController", { campaign_type = 10045, params = { true }, single_mode = true })
                else
                    return false
                end
            else
                GameGlobal.UIStateManager():ShowDialog(
                    "UIActivityTotalLoginAwardController",
                    true,
                    campaignType,
                    componentType
                )
            end
            return true
        end,
        UIMainOpenState.DayOnce
    )

    self:RegisertOpenData(uIMainOpenData)
end

--终端解锁BGM的提示在这里处理
function UIMainModule:GetUnLockBGMs()
    return self._unlockBgms
end

function UIMainModule:RemoveBGM1()
    if self._unlockBgms and next(self._unlockBgms) then
        table.remove(self._unlockBgms, 1)
    end
end

--id对应role_music表的ID
function UIMainModule:AddBGM(id)
    if not self._unlockBgms then
        self._unlockBgms = {}
    end
    if not table.icontains(self._unlockBgms, id) then
        table.insert(self._unlockBgms, id)
    end
end

---检查事件是否开启
---@param eventType number
function UIMainModule:CheckEventOpen(eventType)
    local cfgs = Cfg.cfg_common_event{Type = eventType}
    if #cfgs == 0 then
        return false
    end

    local cfg = cfgs[1]
    
    local startTime = HelperProxy:GetInstance():FormatGMTDateTime(cfg.DateTimeBegin)
    local endTime = HelperProxy:GetInstance():FormatGMTDateTime(cfg.DateTimeEnd)
    
    local svrTime = self:GetModule(SvrTimeModule):GetServerTime() / 1000
    return svrTime >= startTime and svrTime <= endTime
end

---@class UIMainOpenData:Object
_class("UIMainOpenData", Object)
UIMainOpenData = UIMainOpenData

---@param ID number
---@param checkFunc function
---@param openType UIMainOpenState
function UIMainOpenData:Constructor(ID, checkFunc, openState)
    --模块id，活动用活动id
    self.ID = ID
    --打开界面函数并且返回能否打开
    self.CheckFunc = checkFunc
    --是否是每次回到主界面都打开
    self.OpenState = openState
    --打开次数
    self.OpenTimes = 0
end

--注册界面类型
---@class UIMainOpenType
local UIMainOpenType = {
    --公告
    Notice = 1,
    --签到
    SignIn = 2,
    --星灵
    Pet = 3,
    --8天活动签到
    TempSignIn = 104,
    --伊芙醒山
    YFXS = 10003,
    --绯活动
    FEI = 10004,
    --夏活1
    XIAHUO1 = 10005,
    --夏活2
    XIAHUO2 = 10006,
    --活动N5
    N5 = 10008,-- 
    HOLLOWEEN = 10009,--
    N7 = 10013,-- 
    N8 = 10014,--
    N9 = 10015,--
    N10 = 10016,--
    N11 = 10017,--
    N12 = 10018,--
    N13 = 10019,--
    N14 = 10020,--
    N15 = 10021,--
    N16 = 10022,--
    N17 = 10023,--
    N18 = 10024,--
    N19P5 = 10026,--
    N20 = 10027,--
    N21 = 10029,--
    N22 = 10030,--
    N25 = 10034--
}
_enum("UIMainOpenType", UIMainOpenType)

--界面打开次数
---@class UIMainOpenState
local UIMainOpenState = {
    --一天一次
    DayOnce = 0,
    --一次
    Once = 1,
    --多次
    Times = 99
}
_enum("UIMainOpenState", UIMainOpenState)

--通用活动类型
---@class CommonEventType
local CommonEventType = {
    LimitedTimeRecharge = 1, -- 限时充值返利
}
_enum("CommonEventType", CommonEventType)
