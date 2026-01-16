---@class UIBattleQuit : UIController
_class("UIBattleQuit", UIController)
UIBattleQuit = UIBattleQuit

function UIBattleQuit:OnShow(uiParams)
    self._tip = self:GetUIComponent("UILocalizationText", "descText")
    self._hasQuit = false

    local match = self:GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    local bIsFirst = 0
    local nNeedPower = 0
    local nCostPower = 0
    --每个分支自己决定文本提示
    local text = ""
    self._matchType = enterData._match_type
    if MatchType.MT_Mission == enterData._match_type then
        local mission = self:GetModule(MissionModule)
        local missionID = enterData:GetMissionCreateInfo().mission_id
        ---是否首次
        bIsFirst = not mission:IsAlreadyReturnPower(missionID)
        ---扣除值的配置ID
        local costConfigID = 1
        ---体力配置
        nNeedPower = Cfg.cfg_mission[missionID].NeedPower
        nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
        --主线体力默认是棱镜
        local prism = StringTable.Get(Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint].Name)
        if nNeedPower == 0 then
            text = StringTable.Get("str_battle_quit_content_description_zero", nNeedPower, prism)
        else
            if bIsFirst then
                text = StringTable.Get("str_battle_quit_content_description_first", nNeedPower, prism)
            else
                text =
                StringTable.Get(
                        "str_battle_quit_content_description_not_first",
                        nNeedPower - nCostPower,
                        prism,
                        nCostPower
                    )
            end
        end
    elseif MatchType.MT_Campaign == enterData._match_type then
        local noTip = false
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local campId, comId, comType = campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo()
            .CampaignMissionParams)
        local campConfig = Cfg.cfg_campaign[campId]
        if campConfig then
            local campType = campConfig.CampaignType
            if campType == ECampaignType.CAMPAIGN_TYPE_SUMMER_II then --夏活2
                if comType == CampaignComType.E_CAMPAIGN_COM_SUM_II_MISSION then
                    noTip = true
                end
            elseif campType == ECampaignType.CAMPAIGN_TYPE_N12 then --N12
                noTip = true
            end
        end

        local isTactic = self:GetModule(AircraftModule):IsAircraftCartridgeMission(enterData:GetCampaignMissionInfo()
            .nMissionComId)
        if noTip then
            --不花费体力,不显示任何文本
        elseif isTactic then
            --风船战术模拟器
            text = StringTable.Get("str_aircraft_tactic_battle_exit_tip")
        else
            local module = self:GetModule(MissionModule)
            local missionID = enterData:GetCampaignMissionInfo().nCampaignMissionId
            ---是否首次
            bIsFirst = not module:IsAlreadyReturnPowerCamMission(missionID)
            ---扣除值的配置ID
            local costConfigID = 1
            local missionCfg = Cfg.cfg_campaign_mission[missionID]
            if missionCfg.NeedAP then
                --体力是行动点
                local id = missionCfg.NeedAP[1]
                local count = missionCfg.NeedAP[2]
                local name = StringTable.Get(Cfg.cfg_item[id].Name)
                text = StringTable.Get("str_battle_quit_content_description_zero", count, name)
            else
                --体力是棱镜
                local prism = StringTable.Get(Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint].Name)
                nNeedPower = missionCfg.NeedPower
                nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
                if nNeedPower == 0 then
                    text = StringTable.Get("str_battle_quit_content_description_zero", nNeedPower, prism)
                else
                    if bIsFirst then
                        text = StringTable.Get("str_battle_quit_content_description_first", nNeedPower, prism)
                    else
                        text =
                        StringTable.Get(
                                "str_battle_quit_content_description_not_first",
                                nNeedPower - nCostPower,
                                prism,
                                nCostPower
                            )
                    end
                end
            end
        end
    elseif MatchType.MT_ExtMission == enterData._match_type then
        local createData = enterData:GetMissionCreateInfo()
        local workModule = self:GetModule(ExtMissionModule)
        bIsFirst = workModule:UI_IsFirstFail(createData.m_nExtMissionID, createData.m_nExtTaskID)
        local cfgExtTask = Cfg.cfg_extra_mission_task[createData.m_nExtTaskID]
        nNeedPower = cfgExtTask.ExpendPower
        nCostPower = cfgExtTask.MinCostPower
        --体力默认是棱镜
        local prism = StringTable.Get(Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint].Name)
        if nNeedPower == 0 then
            text = StringTable.Get("str_battle_quit_content_description_zero", nNeedPower, prism)
        else
            if bIsFirst then
                text = StringTable.Get("str_battle_quit_content_description_first", nNeedPower, prism)
            else
                text =
                StringTable.Get(
                        "str_battle_quit_content_description_not_first",
                        nNeedPower - nCostPower,
                        prism,
                        nCostPower
                    )
            end
        end
    elseif MatchType.MT_ResDungeon == enterData._match_type then
        local createData = enterData:GetResDungeonInfo()
        local module = self:GetModule(ResDungeonModule)
        bIsFirst = module:AlreadyReturnedPower(createData.res_dungeon_id)
        local cfgExtTask = Cfg.cfg_res_instance_detail[createData.res_dungeon_id]
        nNeedPower = cfgExtTask.NeedPower
        nCostPower = cfgExtTask.MinCostPower
        if module:IsOpenDoubleRes() then
            nNeedPower = nNeedPower * 3
        end
        --体力默认是棱镜
        local prism = StringTable.Get(Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint].Name)
        if nNeedPower == 0 then
            text = StringTable.Get("str_battle_quit_content_description_zero", nNeedPower, prism)
        else
            if bIsFirst then
                text = StringTable.Get("str_battle_quit_content_description_first", nNeedPower, prism)
            else
                text =
                StringTable.Get(
                        "str_battle_quit_content_description_not_first",
                        nNeedPower - nCostPower,
                        prism,
                        nCostPower
                    )
            end
        end
    elseif MatchType.MT_Maze == enterData._match_type then
        text = StringTable.Get("str_maze_tip_battle_quit")
    elseif MatchType.MT_Tower == enterData._match_type then
        text = StringTable.Get("str_tower_quit_battle_tip")
    elseif MatchType.MT_DifficultyMission == enterData._match_type then
        text = StringTable.Get("str_tower_quit_battle_tip")
    elseif MatchType.MT_Conquest == enterData._match_type then
        text = StringTable.Get("str_n5_record_militaryexploit")
    elseif MatchType.MT_WorldBoss == enterData._match_type then
        text = StringTable.Get("str_world_boss_record_damage")
    elseif MatchType.MT_SailingMission == enterData._match_type then
        text = StringTable.Get("str_sailing_mission_quit_battle_tip")
    elseif MatchType.MT_MiniMaze == enterData._match_type then
        text = StringTable.Get("str_n25_quit_battle_tip")
    elseif MatchType.MT_PopStar == enterData._match_type then
        ---@type PopStarMissionCreateInfo
        local createInfo = enterData:GetMissionCreateInfo()
        if createInfo.is_challenge then
            self._isPopStarChallengeMission = true
            text = StringTable.Get("str_n31_popstar_quit_battle_tip")
        end
    elseif MatchType.MT_Season == enterData._match_type then
        local noTip = false
        local module = self:GetModule(MissionModule)
        local missionID = enterData:GetSeasonMissionInfo().mission_id
        ---是否首次
        bIsFirst = false --not module:IsAlreadyReturnPowerCamMission(missionID)
        ---扣除值的配置ID
        local costConfigID = 1
        local missionCfg = Cfg.cfg_season_mission[missionID]
        if missionCfg.NeedAP then
            --体力是行动点
            local id = missionCfg.NeedAP[1]
            local count = missionCfg.NeedAP[2]
            local name = StringTable.Get(Cfg.cfg_item[id].Name)
            text = StringTable.Get("str_battle_quit_content_description_zero", count, name)
        else
            local isDaily = missionCfg.IsDailylevel == 1 --日常关
            --体力是棱镜
            local prism = StringTable.Get(Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint].Name)
            nNeedPower = missionCfg.NeedPower
            nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
            if nNeedPower == 0 then
                if isDaily then
                    text = "" --赛季日常关退局不给提示
                else
                    text = StringTable.Get("str_battle_quit_content_description_zero", nNeedPower, prism)
                end
            else
                if bIsFirst then
                    text = StringTable.Get("str_battle_quit_content_description_first", nNeedPower, prism)
                else
                    text =
                        StringTable.Get(
                            "str_battle_quit_content_description_not_first",
                            nNeedPower - nCostPower,
                            prism,
                            nCostPower
                        )
                end
            end
        end
    end
    self._tip:SetText(text)
end

function UIBattleQuit:CancelBtnOnClick(go)
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattleQuit", input = "CancelBtnOnClick", args = {} }
    )
    self:CloseDialog()
    --播放取消按钮音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundCancel)
end

function UIBattleQuit:OKBtnOnClick(go)
    if self._hasQuit then
        Log.warn("**********repeat click quit button***********")
        return
    end

    --清理助战信息
    local hpm = self:GetModule(HelpPetModule)
    hpm:UI_ClearHelpPet()
    --清理助战信息
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattleQuit", input = "OKBtnOnClick", args = {} }
    )
    Log.notice("----------- quit battle -----------")

    if self._matchType == MatchType.MT_Conquest or
        self._matchType == MatchType.MT_WorldBoss or
        self._matchType == MatchType.MT_MiniMaze or
        self._isPopStarChallengeMission then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SpecialMissionQuitGame)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.MatchClosed)
    end

    self._hasQuit = true
end

function UIBattleQuit:SwitchUI(type, param)
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Battle_Exit, "UI", type, param)
end
