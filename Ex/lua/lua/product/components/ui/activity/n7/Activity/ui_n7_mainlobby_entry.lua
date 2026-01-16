---@class UIN7MainLobbyEntry : UICustomWidget
_class("UIN7MainLobbyEntry", UICustomWidget)
UIN7MainLobbyEntry = UIN7MainLobbyEntry
function UIN7MainLobbyEntry:Constructor()
    self._campaignModule = self:GetModule(CampaignModule)
end
function UIN7MainLobbyEntry:OnShow(uiParams)
    self:_GetComponents()
    self:_InitNewFlagAndRedPoint()
end
function UIN7MainLobbyEntry:_GetComponents()
    self._redPoint = self:GetGameObject("RedPoint")
    self._newFlag = self:GetGameObject("NewFlag")
end
function UIN7MainLobbyEntry:_InitNewFlagAndRedPoint()
    GameGlobal.TaskManager():StartTask(self.RequestData, self)
end

function UIN7MainLobbyEntry:RequestData(TT)
    self:Lock("UIN7MainLobbyEntry_InitNewFlagAndRedPoint")

    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    local res = AsyncRequestRes:New()
    campaignModule:GetCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_N7)

    local checkList = {}
    checkList[#checkList + 1] = RedDotType.RDT_BLACKFIST_FUNCTION_NEW
    checkList[#checkList + 1] = RedDotType.RDT_ENTRY_REDDOT
    ---@type RedDotModule
    local redDotModule = GameGlobal.GetModule(RedDotModule)
    local results = redDotModule:RequestRedDotStatus(TT, checkList)
    local existNotReadPaper, _ = campaignModule:GetN7BlackFightData():ExistNotReadPaper()
    self:_RefreshNewFlagAndRedPoint(
        results[RedDotType.RDT_BLACKFIST_FUNCTION_NEW] or false,
        results[RedDotType.RDT_ENTRY_REDDOT] or false,
        existNotReadPaper
    )
    self:UnLock("UIN7MainLobbyEntry_InitNewFlagAndRedPoint")
end

function UIN7MainLobbyEntry:EntryBtnOnClick(go)
    GameGlobal.TaskManager():StartTask(self.EntryBtnOnClickCoro, self)
end

function UIN7MainLobbyEntry:EntryBtnOnClickCoro(TT)
    self:Lock("UIN7MainLobbyEntry_EntryBtnOnClickCoro")
    self._campaignModule = GameGlobal.GetModule(CampaignModule)
    self.data = self._campaignModule:GetN7BlackFightData()
    
    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    ---@type AsyncRequestRes
    local ret = self.data:RequestCampaign(TT)
    self._campaign = self.data.activityCampaign
    res:SetResult(ret:GetResult())

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        self:UnLock("UIN7MainLobbyEntry_EntryBtnOnClickCoro")
        return
    end
    if (not self._campaign) or (not self._campaign._id) or self._campaign._id <= 0 then
        Log.warn("### campain not open.")
        self:UnLock("UIN7MainLobbyEntry_EntryBtnOnClickCoro")
        return
    end
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIActivityN7MainController,
        function()
            self:SwitchState(UIStateType.UIActivityN7MainController, true)
        end
    )
    self:UnLock("UIN7MainLobbyEntry_EntryBtnOnClickCoro")
end

function UIN7MainLobbyEntry:_RefreshNewFlagAndRedPoint(isShowNew, isShowRed, existNotReadPaper)
    self._newFlag:SetActive(isShowNew)
    if isShowNew then
        self._redPoint:SetActive(false)
    else
        self._redPoint:SetActive(isShowRed or existNotReadPaper)
    end
end
