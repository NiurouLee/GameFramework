---@class SeasonMapExpressLevel:SeasonMapExpressBase
_class("SeasonMapExpressLevel", SeasonMapExpressBase)
SeasonMapExpressLevel = SeasonMapExpressLevel

function SeasonMapExpressLevel:Constructor(cfg, eventPoint)
    self._content = self._cfg.MissionID
    self._autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())
    self._autoBinder:BindEvent(GameEventType.UISeasonOnLevelDiffChanged, self, self.RefreshRecord)
end

function SeasonMapExpressLevel:Update(deltaTime)
    
end

function SeasonMapExpressLevel:Dispose()
    self._autoBinder:UnBindAllEvents()
end

--播放表现内容
function SeasonMapExpressLevel:Play(param)
    SeasonMapExpressLevel.super.Play(self, param)
    if self._param == true then --局内退出之后继续之前的播放流程
        self._state = SeasonExpressState.Over
        self:_Next(param)
    else
        if self._content then
            ---@type SeasonModule
            local module = GameGlobal.GetModule(SeasonModule)
            ---@type UISeasonModule
            local uiModule = GameGlobal.GetUIModule(SeasonModule)
            local curDiff = uiModule:GetCurrentSeasonLevelDiff()
            local missionID = self._content
            local cfg = Cfg.cfg_season_mission[self._content]
            if cfg then
                if cfg.OrderID ~= curDiff then
                    local cfgs = Cfg.cfg_season_mission{GroupID = cfg.GroupID, OrderID = curDiff}
                    if cfgs then
                        missionID = cfgs[1].ID
                    end
                end
            end
            UISeasonHelper.TriggerMissionNode(missionID, module:GetCurSeasonObj())
            uiModule:SeasonManager():SeasonPlayerManager():GetPlayer():PlayAnimation(SeasonPlayerAnimation.Click2)
            self._state = SeasonExpressState.Playing
            module:RecordLevelExpress(missionID, self._eventPoint:GroupID(), SeasonExpressType.Level)
        end
    end
end

--关卡详情界面切换难度的时候刷新记录的数据
---@param diff UISeasonLevelDiff
function SeasonMapExpressLevel:RefreshRecord(diff)
    if self._state == SeasonExpressState.Playing then
        ---@type SeasonModule
        local module = GameGlobal.GetModule(SeasonModule)
        local info = module:GetLevelExpress()
        if info and info.groupID == self._eventPoint:GroupID() then
            local cfg = Cfg.cfg_season_mission{GroupID = info.groupID, OrderID = diff}
            if cfg then
                module:RecordLevelExpress(cfg[1].ID, info.groupID, SeasonExpressType.Level)
            end
        end
    end
end