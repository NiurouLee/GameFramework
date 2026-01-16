--
---@class UISeasonDaily : UICustomWidget
_class("UISeasonDaily", UICustomWidget)
UISeasonDaily = UISeasonDaily

function UISeasonDaily:OnShow(uiParams)
    self:_GetComponents()
    self:AttachEvent(GameEventType.OnEventPointProgressChange, self._DailyGuide)
end

function UISeasonDaily:_GetComponents()
    self._root = self:GetGameObject("Root")
    ---@type UILocalizedTMP
    self._title = self:GetUIComponent("UILocalizedTMP", "Title")
    ---@type UILocalizationText
    self._content = self:GetUIComponent("UILocalizationText", "Content")
end

function UISeasonDaily:SetData(check)
    ---@type SeasonMissionComponent
    self._component = self:GetModule(SeasonModule):GetCurSeasonObj():GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._component:GetComponentInfo()
    ---@type UISeasonModule
    self._uiSeasonModule = self:GetUIModule(SeasonModule)
    self._daily = self._uiSeasonModule:SeasonManager():SeasonMapManager():Daily()
    self:_RefreshUI()
    self:_DailyGuide()
    self:_DailyReset(check)
end

function UISeasonDaily:_RefreshUI()
    ---@type SeasonDailyState
    local state = self._daily:GetState()
    local cfg = self._daily:ComponentCfg()
    if state == SeasonDailyState.Lock or state == SeasonDailyState.Time or state == SeasonDailyState.MaxReward then
        self._root:SetActive(false)
    elseif state == SeasonDailyState.Mission then
        self._title:SetText(StringTable.Get(cfg.LockTitle))
        self._content:SetText(StringTable.Get(cfg.LockContent))
        self._root:SetActive(true)
    elseif state == SeasonDailyState.Unlock then
        self._title:SetText(StringTable.Get(cfg.UnlockTitle))
        self._content:SetText(StringTable.Get(cfg.UnlockContent, self._componentInfo.m_daily_info.m_progress - 1, cfg.MaxReward))
        self._root:SetActive(true)
    else
        self._root:SetActive(false)
    end
end

function UISeasonDaily:DailyBtnOnClick(go)
    if self._uiSeasonModule:SeasonManager():LockUI() then
        return
    end
    self._daily:MoveToEventPoint()
end

function UISeasonDaily:_DailyGuide()
    ---@type SeasonDailyState
    local state = self._daily:GetState()
    if state == SeasonDailyState.Unlock then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.SeasonDaily)
    end
end

function UISeasonDaily:_DailyReset(check)
    if check then
        ---@type SeasonDailyState
        local state = self._daily:GetState()
        if state == SeasonDailyState.Unlock then
            if self._daily:GetServerInfoEmpty() then
                local record = SeasonTool:GetInstance():GetLocalDBFloat("SeasonDailyReset", 0)
                if record > 0 then
                    local cfg = self._daily:ComponentCfg()
                    ToastManager.ShowToast(StringTable.Get(cfg.RefreshText))
                else
                    SeasonTool:GetInstance():SetLocalDBFloat("SeasonDailyReset", 1)
                end
            end
        end
    end
end