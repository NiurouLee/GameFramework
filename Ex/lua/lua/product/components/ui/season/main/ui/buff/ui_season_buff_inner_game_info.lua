---@class UISeasonBuffInnerGameInfo:UIController
_class("UISeasonBuffInnerGameInfo", UIController)
UISeasonBuffInnerGameInfo = UISeasonBuffInnerGameInfo

function UISeasonBuffInnerGameInfo:LoadDataOnEnter(TT, res, uiParams)
    local serialautofightmodule = self:GetModule(SerialAutoFightModule)
    local running = serialautofightmodule:IsRunning()
    if running then
        res:SetSucc(false)
    else
        res:SetSucc(true)
    end
end

function UISeasonBuffInnerGameInfo:OnShow(uiParams)
    ---@type UILocalizationText
    self._detailLevelText = self:GetUIComponent("UILocalizationText", "DetailLevel")
    ---@type UILocalizationText
    self._detailContentText = self:GetUIComponent("UILocalizationText", "DetailContent")

    ---@type SeasonModule
    local seasonModule = self:GetModule(SeasonModule)
    local seasonObj = seasonModule:GetCurSeasonObj()
    if seasonObj then
        local componentID = seasonObj:GetSeasonMissionComponentCfgID()
        local curLevel,curProgress,maxLevel,isMaxLevel = UISeasonHelper.CalcBuffLevel(componentID)
        self._detailLevelText:SetText(StringTable.Get("str_season_buff_level",tostring(curLevel)))
        local cfgGroup = Cfg.cfg_component_season_wordbuff{ComponentID=componentID,Lv=curLevel}
        if cfgGroup and #cfgGroup > 0 then
            local cfg = cfgGroup[1]
            local desc = cfg.Desc
            self._detailContentText:SetText(StringTable.Get(desc))
        else
            self._detailContentText:SetText("")
        end
    end
end

function UISeasonBuffInnerGameInfo:FullScreenBtnOnClick(go)
        self:CloseDialog()
end
