---@class UIN22EntrustEventFight : UIN22EntrustEventBase
_class("UIN22EntrustEventFight", UIN22EntrustEventBase)
UIN22EntrustEventFight = UIN22EntrustEventFight

-- 虚函数
function UIN22EntrustEventFight:Refresh()
    self:_SetRoot(true)
    self:_SetCloseBtn()

    local cfg = self:GetCfgCampaignEntrustEvent()
    self._missionid = cfg.MissionID
    self:_SetMissionInfo()

    local pass = self._component:IsEventPass(self._levelId, self._eventId)
    self:_SetPass(pass)
    self:_SetTalkIcon("n22_wt_dfqb_icon01")

    -- 确定按钮
    local str1 = StringTable.Get("str_n22_entrust_event_stage_fight_again")
    local str2 = StringTable.Get("str_n22_entrust_event_stage_fight")
    local txtConfirm = pass and str1 or str2
    self:_SetConfirmBtn(true, txtConfirm, function()
        ---@type MissionModule
        local module = self:GetModule(MissionModule)

        ---@type TeamsContext
        local ctx = module:TeamCtx()
        ctx:Init(
            TeamOpenerType.Campaign,
            {
                self._missionid,
                self._component:GetCampaignMissionComponentId(),
                self._component:GetCampaignMissionParamKeyMap()
            }
        )

        self:Lock("DoEnterTeam")
        ctx:ShowDialogUITeams()
    end)
end

-- 虚函数
function UIN22EntrustEventFight:OnEventFinish(rewards)
    Log.info("UIN22EntrustEventFight:OnEventFinish()")
end

function UIN22EntrustEventFight:_SetMissionInfo()
    local cfg_campaign_mission = Cfg.cfg_campaign_mission[self._missionid]
    if not cfg_campaign_mission then
        Log.error("UIN22EntrustEventFight:_SetMissionInfo() cfg_campaign_mission[", self._missionid, "] is nil!")
        return
    end

    --1普通,2boss,3剧情(不能有)
    local missionType = cfg_campaign_mission.Type

    local recommendAwaken = cfg_campaign_mission.RecommendAwaken
    local recommendLV = cfg_campaign_mission.RecommendLV
    local fightLevel = cfg_campaign_mission.FightLevel

    local isChess = false
    self:_SetStage(isChess, fightLevel, cfg_campaign_mission, recommendAwaken, recommendLV)
end