---@class UIPopStarMainController:UISideEnterCenterContentBase
_class("UIPopStarMainController", UISideEnterCenterContentBase)
UIPopStarMainController = UIPopStarMainController

function UIPopStarMainController:Constructor()
end

function UIPopStarMainController:DoInit(params)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type UIActivityCampaign
    self._campaign = self._data
    --活动结束时间
    local sample = self._campaign:GetSample()
    self._activeEndTime = sample.end_time
    ---@type CCampaignN31Center
    local localProcess = self._campaign:GetLocalProcess()
    ---@type PopStarComponent
    self._popstarCom = localProcess:GetComponent(ECampaignN31CenterComponentID.ECAMPAIGN_N31Center_POPSTAR_MISSION)
    ---@type PopStarComponentInfo
    self._popstarComInfo = localProcess:GetComponentInfo(ECampaignN31CenterComponentID.ECAMPAIGN_N31Center_POPSTAR_MISSION)

    local componentConfigId = self._popstarCom:GetComponentCfgId()
    local cfgs = Cfg.cfg_component_popstar_mission{ ComponentID = componentConfigId }
    local sortCfgs = {}
    for k, v in pairs(cfgs) do
        sortCfgs[#sortCfgs + 1] = v
    end
    table.sort(sortCfgs, function(a, b)
        return a.SortId < b.SortId
    end)
    
    self._levelDatas = {}
    self._lastIndex = 1
    for i = 1, #sortCfgs do
        local levelData = UIActivityPopStarLevelData:New(sortCfgs[i], self._campaign, self._popstarCom, self._popstarComInfo)
        self._levelDatas[#self._levelDatas + 1] = levelData
        if levelData:IsOpen() then
            self._lastIndex = i
        end
    end

    self._timeLabel = self:GetUIComponent("UILocalizationText", "Time")
    self._loader = self:GetUIComponent("UISelectObjectPath", "Content")
    self._scrollRect = self:GetUIComponent("ScrollRect", "ScrollView")
end

--显示
function UIPopStarMainController:DoShow()
    self:StartTask(function(TT)
        self._campaign:ClearCampaignNew(TT)
    end)

    self._loader:SpawnObjects("UIPopStarLevelItem", #self._levelDatas)
    local list = self._loader:GetAllSpawnList()
    local isUp = true
    for i = 1, #list do
        ---@type UIPopStarLevelItem
        local item = list[i]
        item:SetData(self._levelDatas[i], isUp, i == #list,
            function(data)
                if data:IsActivityOpen() == false then
                    return
                end
                -- if self:IsActivityEnd() then
                --     ToastManager.ShowToast(StringTable.Get("str_n31_popstar_active_end"))
                --     return
                -- end

                if not data:IsOpen() then
                    ToastManager.ShowToast(StringTable.Get("str_n31_popstar_main_level_unopen"))
                    return
                end
                local levelType = data:GetLevelType()
                if levelType == UIActivityPopStarLevelType.Normal then
                    self:ShowDialog("UIPopStarNormalLevelDetail", data)
                elseif levelType == UIActivityPopStarLevelType.Challenge then
                    self:ShowDialog("UIPopStarChallengeLevelDetail", data)
                end
            end)
        isUp = not isUp
    end

    local width = 557
    local space = 25
    local totalWidth = #self._levelDatas * (width + space)
    if #self._levelDatas >= 1 then
        totalWidth = totalWidth - space
    end
    local go = self:GetGameObject()
    UIHelper.RefreshLayout(go:GetComponent("RectTransform"))
    local viewport = self._scrollRect.viewport
    local widthDelta = totalWidth - viewport.rect.width
    local currentWidth = (self._lastIndex - 1) * (width + space) - viewport.rect.width / 2 + width / 2
    local percent = currentWidth / widthDelta
    if percent < 0 then
        percent = 0
    end
    if percent > 1 then
        percent = 1
    end
    self._scrollRect.horizontalNormalizedPosition = percent

    self:RefreshTimeStr()

    self._timerHandler = GameGlobal.Timer():AddEventTimes(
        0,
        TimerTriggerCount.Infinite,
        function()
            self:RefreshTimeStr()
        end
    )
end

--活动是否开启
function UIPopStarMainController:IsActivityEnd()
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

function UIPopStarMainController:RefreshTimeStr()
    if self:IsActivityEnd() then
        self._timeLabel:SetText(StringTable.Get("str_n31_popstar_active_end"))
        return
    end

    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds < 0 then
        seconds = 0
    end

    local timeStr = UIActivityCustomHelper.GetTimeString(seconds, "str_n31_popstar_day", "str_n31_popstar_hour", "str_n31_popstar_minus", "str_n31_popstar_less_mius")
    self._timeLabel:SetText(StringTable.Get("str_n31_popstar_active_time_remaind", timeStr))
end

--显示其他Tab之前,隐藏
function UIPopStarMainController:DoHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end

--关闭界面,销毁Tab
function UIPopStarMainController:DoDestroy()
end

function UIPopStarMainController:BtnInfoOnClick()
    self:ShowDialog("UIIntroLoader", "UIPopStarIntro", MaskType.MT_BlurMask)
end
