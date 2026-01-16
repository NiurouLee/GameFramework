---@class SeasonEnterLoadingHandler:LoadingHandler
_class("SeasonEnterLoadingHandler", LoadingHandler)
SeasonEnterLoadingHandler = SeasonEnterLoadingHandler

function SeasonEnterLoadingHandler:Constructor()
    GameGlobal.UIStateManager():Lock("SeasonEnterLoadingHandler")
end

function SeasonEnterLoadingHandler:PreLoadBeforeLoadLevel()
end

function SeasonEnterLoadingHandler:PreLoadAfterLoadLevel(TT, ...)
    local loadingParams = { ... }
    local seasonModule = GameGlobal.GetModule(SeasonModule)
    if seasonModule:GetCurSeasonID() > 0 then
        LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)
        seasonModule:ForceRequestCurSeasonData(TT)
        self:Verify(TT, seasonModule)
        YIELD(TT)
    end
end

function SeasonEnterLoadingHandler:OnLoadingFinish(...)
    local seasonModule = GameGlobal.GetModule(SeasonModule)
    if seasonModule:GetCurSeasonID() > 0 then
        local loadingParams = { ... }
        ---@type UISeasonModule
        local uimodule = GameGlobal.GetUIModule(SeasonModule)
        uimodule:EnterSeasonGame(loadingParams)
        GameGlobal.UIStateManager():SwitchState(UIStateType.UISeason)
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    end
    GameGlobal.UIStateManager():UnLock("SeasonEnterLoadingHandler")
end

--根据关卡通关信息和事件点的进度信息进行反推校验(主要是防止退局杀进程的时候事件点的进度未来得及同步的情况)
---@param seasonModule SeasonModule
function SeasonEnterLoadingHandler:Verify(TT, seasonModule)
    local errorInfo = {}
    if not seasonModule:GetLevelExpress() then
        ---@type SeasonMissionComponentInfo
        local componentInfo = seasonModule:GetCurSeasonObj():GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
        local pass = componentInfo.m_pass_mission_info
        local map = componentInfo.m_stage_info
        if pass and table.count(pass) then
            for id, _ in pairs(pass) do
                local cfgMission = Cfg.cfg_season_mission[id]
                if cfgMission and cfgMission.IsFightLevel then
                    local missionID = cfgMission.ID
                    local progress = map[missionID]
                    local cfgEventPoint = Cfg.cfg_season_map_eventpoint[missionID]
                    if cfgEventPoint then
                        if progress then --有进度记录但是记录的进度中没有关卡表现
                            local firstProgress = SeasonTool:GetInstance():GetProgressByExpressType(cfgEventPoint,
                                SeasonExpressType.Level)
                            if firstProgress and progress < firstProgress then
                                local t = {}
                                t.id = missionID
                                t.progress = firstProgress
                                table.insert(errorInfo, t)
                            end
                        else --通关过但是没有进度记录
                            local firstProgress = SeasonTool:GetInstance():GetProgressByExpressType(cfgEventPoint,
                                SeasonExpressType.Level)
                            if firstProgress then
                                local t = {}
                                t.id = missionID
                                t.progress = firstProgress
                                table.insert(errorInfo, t)
                            end
                        end
                    end
                end
            end
        end
        local count = #errorInfo
        if count > 0 then
            for _, value in pairs(errorInfo) do
                Log.debug("Season Verify !", value.id, value.progress)
                seasonModule:HandleSeasonClientStageData(TT, value.id, value.progress)
            end
        end
    end
end
