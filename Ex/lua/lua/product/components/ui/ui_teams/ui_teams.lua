---@class UITeams:UIController
_class("UITeams", UIController)
UITeams = UITeams

function UITeams:Constructor()
    self._module = self:GetModule(MissionModule)
    self.ctx = self._module:TeamCtx()

    self._param = self.ctx.param
    self._teamOpenerType = self.ctx.teamOpenerType
    self._teams = self.ctx:Teams()
    self._lastClickTime = 0
end

function UITeams:OnShow(uiParams)
    self:UnLock("DoEnterTeam")

    --连续自动战斗
    self._blockMask = self:GetGameObject("blockMask")
    ---@type SerialAutoFightModule
    local mdSerialFight = GameGlobal.GetModule(SerialAutoFightModule)
    if mdSerialFight:IsRunning() then
        local autoBtnPool = self:GetUIComponent("UISelectObjectPath", "pool")
        self._autoBtn = autoBtnPool:SpawnObject("UIWidgetSerialButton")
        self._blockMask:SetActive(true)
    else
        self._blockMask:SetActive(false)
    end

    self:AttachEvent(GameEventType.CancelSerialAutoFight, self.OnCancelSerialAutoFight)
    local hideHomeBtn = mdSerialFight:IsInited()
    local backCallback = function()
        --region 清理助战信息
        local hpm = self:GetModule(HelpPetModule)
        hpm:UI_ClearHelpPet()
        --清除光灵排序
        self:GetModule(PetModule):ClearAllPetSortInfo()
        --重置连续自动战斗
        mdSerialFight:ResetModuleData()
        --endregion
        local isFightAgain = self.ctx:GetFightAgain() --bool值的拷贝
        -- --在OnHide中关闭再次挑战，否则点击Home退出编队会导致再次挑战信息无法重置 2021.3.9 靳策修改
        -- if isFightAgain then
        --     self.ctx:SetFightAgain(false)
        -- end
        if self.ctx.teamOpenerType == TeamOpenerType.SmallMap then
            self:SwitchState(UIStateType.UIMain)
        elseif self.ctx.teamOpenerType == TeamOpenerType.ResInstance then
            if isFightAgain then
                self:SwitchState(UIStateType.UIResDetailController, self.ctx.param)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Maze then
            if isFightAgain then
                UIMazeController.SetToOpenRoomIndex(self.ctx.param)
                GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.ExtMission then
            if isFightAgain then --再次挑战，需打开当前番外关卡的详情界�?
                local extraMissionID = self.ctx.param[1]
                local stageId = self.ctx.param[2]
                self:SwitchState(UIStateType.UIExtraMissionStage, extraMissionID, stageId)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Stage then
            if isFightAgain then --再次挑战，需打开当前关卡详情界面
                DiscoveryData.EnterStateUIDiscovery(3, self.ctx.param)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Tower then
            if isFightAgain then
                local element = self.ctx:GetTowerElement()
                self:SwitchState(UIStateType.UITowerLayer, element)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Main then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Trail then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Sailing then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Vampire then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Campaign then
            if isFightAgain then
                local match = GameGlobal.GetModule(MatchModule)
                ---@type MatchEnterData
                local enterData = match:GetMatchEnterData()
                ---@type CampaignMissionCreateInfo
                local campaignMissionInfo = enterData:GetCampaignMissionInfo()
                ---@type CampaignModule
                local campaignModule = GameGlobal.GetModule(CampaignModule)
                campaignModule:ExitBattle(campaignMissionInfo)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.LostLand then
            if isFightAgain then
                local misisonid = self.ctx.param
                self:SwitchState(UIStateType.UILostLandStage, misisonid)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Conquest then
            if isFightAgain then
                self:SwitchState(UIStateType.UIActivityN5BattleField)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.WorldBoss then
            if isFightAgain then
                self:SwitchState(UIStateType.UIWorldBoss)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.N21CC then
            if isFightAgain then
                local match = GameGlobal.GetModule(MatchModule)
                ---@type MatchEnterData
                local enterData = match:GetMatchEnterData()
                ---@type CampaignMissionCreateInfo
                local campaignMissionInfo = enterData:GetCampaignMissionInfo()
                ---@type CampaignModule
                local campaignModule = GameGlobal.GetModule(CampaignModule)
                campaignModule:ExitBattle(campaignMissionInfo)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Diff then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.BlackFist then
            if isFightAgain then
                local info = GameGlobal.GetModule(MatchModule):GetMatchEnterData():GetBlackFistInfo()
                GameGlobal.GetModule(CampaignModule):ExitBattle(info)
            else
                self:CloseDialog()
            end
        elseif self.ctx.teamOpenerType == TeamOpenerType.Air then
            --不能再次挑战
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Camp_Diff then
            self:CloseDialog()
        elseif self.ctx.teamOpenerType == TeamOpenerType.Season then
            if isFightAgain then
                --GameGlobal.GetUIModule(SeasonModule):EnterCurrentSeasonMainUI()
                local matchModule = self:GetModule(MatchModule)
                local enterData = matchModule:GetMatchEnterData()
                ---@type SeasonMissionCreateInfo
                local seasonMissionInfo = enterData:GetSeasonMissionInfo()
                ---@type SeasonModule
                local seasonModule = GameGlobal.GetModule(SeasonModule)
                local rt = nil
                seasonModule:ExitBattle(seasonMissionInfo)
            else
                self:CloseDialog()
            end
        else
            self:SwitchState(UIStateType.UIMain)
        end
    end

    ---@type UISelectObjectPath
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    ---@type UICommonTopButton
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        backCallback,
        nil,
        function()
            --点Home键返回主界面，需要清理清理助战，资源关卡无法使用助战
            local hpm = self:GetModule(HelpPetModule)
            hpm:UI_ClearHelpPet()

            --如果是战术模拟器，离开风船释放资源
            if self.ctx.teamOpenerType == TeamOpenerType.Air then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftLeaveAircraft)
                GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Exit, "UI")
            else
                UICommonHelper:GetInstance():SwitchToUIMain()
            end
        end,
        hideHomeBtn
    )

    --编队滑动
    self._leftTglGroupArrow = self:GetGameObject("leftArrow")
    self._rightTglGroupArrow = self:GetGameObject("rightArrow")
    self._tglGoupTrans = self:GetUIComponent("RectTransform", "hlgTgls")
    self._tglScrollViewTrans = self:GetUIComponent("RectTransform", "TglScrollView")
    self._tglScrollView = self:GetUIComponent("ScrollRect", "TglScrollView")
    self._fightBtnTrans = self:GetUIComponent("RectTransform", "btnFight")
    self._viewPointTrans = self:GetUIComponent("RectTransform", "TglViewport")
    self._safeArea = self:GetUIComponent("RectTransform", "SafeArea")
    self._canvas = self._safeArea.parent:GetComponent("RectTransform")
    self._tglGroupOriginPosX = self._tglGoupTrans.anchoredPosition.x - 1 --滑动offset
    self._leftTglGroupArrow:SetActive(false)
    self._rightTglGroupArrow:SetActive(false)
    local height = self._tglScrollViewTrans.sizeDelta.y
    if self._teamOpenerType ~= TeamOpenerType.Main and self._teamOpenerType ~= TeamOpenerType.SmallMap then
        local height = self._tglScrollViewTrans.sizeDelta.y
        self._tglScrollViewTrans.sizeDelta =
            Vector2(self._safeArea.rect.size.x - self._fightBtnTrans.sizeDelta.x + 70, height)
    else
        self._tglScrollViewTrans.sizeDelta = Vector2(self._safeArea.rect.size.x, height)
    end

    if
        self._teamOpenerType == TeamOpenerType.WorldBoss or self._teamOpenerType == TeamOpenerType.Diff or
        self._teamOpenerType == TeamOpenerType.N21CC or
        self._teamOpenerType == TeamOpenerType.Sailing or
        self.ctx.teamOpenerType == TeamOpenerType.Vampire or
        self.ctx.teamOpenerType == TeamOpenerType.Camp_Diff
    then  --self._teamOpenerType ~= TeamOpenerType.Tower and
    else
        ---@type UnityEngine.UI.ToggleGroup
        self._tglGroup = self:GetUIComponent("ToggleGroup", "hlgTgls")
        local hlgTgls = self:GetUIComponent("UISelectObjectPath", "hlgTgls")
        hlgTgls:SpawnObjects("UITeamsSelectItem", self.ctx:GetTeamCount())
        ---@type UITeamsSelectItem[]
        self._hlgTglsSpawns = hlgTgls:GetAllSpawnList()
        for i, v in ipairs(self._hlgTglsSpawns) do
            v:Init(i, self, self._tglGroup, self._tglScrollView)
        end
        self._tglScrollView.onValueChanged:AddListener(
            function()
                self._maxScrollDis = self._tglGoupTrans.sizeDelta.x - self._viewPointTrans.rect.width
                if self._maxScrollDis < 0 then
                    self._rightTglGroupArrow:SetActive(
                        self._tglGoupTrans.anchoredPosition.x > 0 and
                        math.abs(self._tglGoupTrans.anchoredPosition.x) > math.abs(self._maxScrollDis)
                    )
                else
                    self._rightTglGroupArrow:SetActive(
                        math.abs(self._tglGoupTrans.anchoredPosition.x) < math.abs(self._maxScrollDis)
                    )
                end
                self._leftTglGroupArrow:SetActive(self._tglGoupTrans.anchoredPosition.x < self._tglGroupOriginPosX)
            end
        )
    end

    ---@type UnityEngine.RectTransform
    self.tranHlg = self:GetUIComponent("RectTransform", "hlg")
    self.hlg = self:GetUIComponent("UISelectObjectPath", "hlg")
    local goFight = self:GetGameObject("btnFight")
    goFight:SetActive(self._teamOpenerType ~= TeamOpenerType.Main and self._teamOpenerType ~= TeamOpenerType.SmallMap)
    --队长标记
    ---@type UICustomWidgetPool
    local leader = self:GetUIComponent("UISelectObjectPath", "leader")
    ---@type UITeamsLeader
    self._uiTeamsLeader = leader:SpawnObject("UITeamsLeader")

    self._replaceGo = self:GetGameObject("replace")
    ---@type UnityEngine.RectTransform
    self._replaceTran = self:GetUIComponent("RectTransform", "replace")
    self._replaceGo:SetActive(false)
    self._isLongPressing = false
    ---@type UnityEngine.Canvas

    self._btnTxt = self:GetUIComponent("UILocalizationText", "Text")

    self._mazeTeamTips = self:GetGameObject("mazeTips")
    self._mazeTeamTipsText = self:GetUIComponent("UILocalizationText", "Tips")

    self._airTeamTips = self:GetGameObject("airTips")
    self._airTeamTips:SetActive(self.ctx.teamOpenerType == TeamOpenerType.Air)

    self._seasonTeamTips = self:GetGameObject("seasonTips")
    self._seasonTeamTipsText = self:GetUIComponent("UILocalizationText", "SeasonTipsText")

    self:_CheckTeamTips()
    self:AttachEvent(GameEventType.DiscoveryChangeTeamData, self.FlushTeam)
    self:AttachEvent(GameEventType.TeamItemLongPress, self.TeamItemLongPress)
    self:AttachEvent(GameEventType.TeamUpdateReplaceCardPos, self.UpdateReplaceCardPos)

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(goFight),
        UIEvent.Press,
        function(go)
            self._isDown = true
            self._btnTxt.color = Color(1, 1, 1, 1)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(goFight),
        UIEvent.Hovered,
        function(go)
            if self._isDown then
                self._btnTxt.color = Color(1, 1, 1, 1)
            end
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(goFight),
        UIEvent.Unhovered,
        function(go)
            self._btnTxt.color = Color(51 / 255, 51 / 255, 51 / 255, 1)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(goFight),
        UIEvent.Release,
        function(go)
            self._isDown = false
        end
    )
    local teamid = self.ctx:GetCurrTeamId()
    self:FlushTeam(teamid)

    if self.ctx.teamOpenerType == TeamOpenerType.Maze then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenTeamUI, self.ctx.teamOpenerType, -1)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenTeamUI, self.ctx.teamOpenerType, self.ctx.param)
    end
    self:TglBtnPosReset()
end

--注释
function UITeams:TglBtnPosReset()
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._tglGoupTrans)
    local select = self.ctx:GetCurrTeamId()
    if self.ctx:GetTeamCount() > 1 then
        local seletbtn = self._hlgTglsSpawns[select]
        local btnRectTrans = seletbtn.view:GetComponent("RectTransform")
        local anchoredPosX = btnRectTrans.anchoredPosition.x --按钮中心点坐标
        --如果中心点坐标在viewpoint外，则item移动到屏幕中心
        if anchoredPosX > self._viewPointTrans.rect.width / 2 then
            local maxMove = self._tglGoupTrans.sizeDelta.x - self._viewPointTrans.rect.width
            local move = anchoredPosX - self._viewPointTrans.rect.width / 2
            if move > maxMove then
                move = maxMove
            end
            local originY = self._tglGoupTrans.anchoredPosition.y
            self._tglGoupTrans.anchoredPosition = Vector2(-move, originY)
        end
    end
end

function UITeams:OnHide()
    self._backBtns = nil

    self:DetachEvent(GameEventType.DiscoveryChangeTeamData, self.FlushTeam)
    self:DetachEvent(GameEventType.TeamItemLongPress, self.TeamItemLongPress)
    self:DetachEvent(GameEventType.TeamUpdateReplaceCardPos, self.UpdateReplaceCardPos)
    local isFightAgain = self.ctx:GetFightAgain()
    if isFightAgain then
        self.ctx:SetFightAgain(false)
    end
    if self.ctx:IsFastSelect() then
        self.ctx:ClearFastSelect()
    end

    --点Home键返回主界面，需要清理清理助战，资源关卡无法使用助战
    local hpm = self:GetModule(HelpPetModule)
    hpm:UI_ClearHelpPet()
    --清除光灵排序
    self:GetModule(PetModule):ClearAllPetSortInfo()
end

---@public
---@param teamId int 队伍ID
function UITeams:FlushTeam(teamId)
    self._teams = self.ctx:Teams() --用于解决爬塔换人后self._teams还是旧数据的问题TODO所有获取队伍信息应该现用现取，以避免这种缓存数据没有更新导致的问题
    local team = self._teams:Get(teamId)
    if not team then
        return
    end
    if self._hlgTglsSpawns then
        for i, v in ipairs(self._hlgTglsSpawns) do
            local info = self._teams:Get(i)
            if info then
                v:FlushName(info.id)
            end
        end
    end
    self.ctx:SetCurrTeamId(teamId)
    self._replaceTran.sizeDelta = Vector2(self.tranHlg.rect.width / team.teamSlotCount, self.tranHlg.rect.height)
    self.hlg:SpawnObjects("UITeamItem", team.teamSlotCount)
    ---@type UITeamItem[]
    self._uiSlots = self.hlg:GetAllSpawnList()
    for i, v in ipairs(self._uiSlots) do
        v:FlushTeamMember(i, teamId)
        v:Flush(team.pets[i])
        v:FlushCallback(
            function()
                self:OpenTeamMemberSelect(i)
            end
        )
        local state = self:GetHelpPetState()
        v:FlushHelpPetState(state == 1)
    end
    self._uiTeamsLeader:Flush(team.pets[1])
    --toggle按钮高亮
    if self._hlgTglsSpawns then
        for i, v in ipairs(self._hlgTglsSpawns) do
            if v:GetId() == teamId then
                v:FlushTglIsOn(true)
                break
            end
        end
    end
end

function UITeams:OpenTeamMemberSelect(slot)
    local teamCtx = self._module:TeamCtx()
    teamCtx:InitTeamMemberSelect(slot)

    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick) --播放点击音效

    if self._teamOpenerType == TeamOpenerType.Maze then
        --self:CloseDialog()
        self:ShowDialog("UITeamChangeController")
    elseif self._teamOpenerType == TeamOpenerType.Stage then
        --self:CloseDialog()
        local state = self:GetHelpPetState()
        self:ShowDialog("UITeamChangeController", nil, nil, nil, state)
    elseif self._teamOpenerType == TeamOpenerType.ExtMission then
        --self:CloseDialog()
        local state = self:GetHelpPetState()
        self:ShowDialog("UITeamChangeController", nil, nil, nil, state)
    elseif self._teamOpenerType == TeamOpenerType.Tower then
        --self:CloseDialog()
        self:ShowDialog("UITeamChangeController")
    elseif self._teamOpenerType == TeamOpenerType.Main then
        self:ShowDialog("UITeamChangeController")
    elseif self._teamOpenerType == TeamOpenerType.ResInstance then
        self:ShowDialog("UITeamChangeController")
    elseif self._teamOpenerType == TeamOpenerType.Trail then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, false)
    elseif self._teamOpenerType == TeamOpenerType.Campaign then
        local state = self:GetHelpPetState()
        self:ShowDialog("UITeamChangeController", nil, nil, nil, state)
    elseif self._teamOpenerType == TeamOpenerType.LostLand then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, 0)
    elseif self._teamOpenerType == TeamOpenerType.Conquest then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.BlackFist then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.WorldBoss then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.N21CC then
        local state = self:GetHelpPetState()
        self:ShowDialog("UITeamChangeController", nil, nil, nil, state)
    elseif self._teamOpenerType == TeamOpenerType.Air then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.Diff then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.Sailing then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, false)
    elseif self._teamOpenerType == TeamOpenerType.Vampire then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, false)
    elseif self._teamOpenerType == TeamOpenerType.Camp_Diff then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    elseif self._teamOpenerType == TeamOpenerType.Season then
        self:ShowDialog("UITeamChangeController", nil, nil, nil, self:GetHelpPetState())
    else
        self:SwitchState(UIStateType.UITeamChangeController)
    end
end

function UITeams:GetHelpPetState()
    -- 0是禁�? 1是用
    local enable = 0

    local module = self:GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_HelpPet)
    -- 功能未解锁隐�?
    if isLock then
        return enable
    end

    if self._teamOpenerType == TeamOpenerType.Stage then
        local missionId = self._param
        local mission = Cfg.cfg_mission[missionId]
        if mission then
            local levelId = mission.FightLevel
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.ExtMission then
        local extmissionId = self._param[2]
        local extmission = Cfg.cfg_extra_mission_task[extmissionId]
        if extmission then
            local levelId = extmission.FightLevel
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.Campaign then
        local missionId = self._param[1]
        local mission = Cfg.cfg_campaign_mission[missionId]
        if mission then
            local levelId = mission.FightLevel
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.Conquest then
        local levelId = self._param[5]
        if levelId then
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.BlackFist then
        local missionId = self._param[1]
        local mission = Cfg.cfg_blackfist_mission[missionId]
        if mission then
            local levelId = mission.LevelID
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.WorldBoss then
        local worldBossModule = self:GetModule(WorldBossModule)
        local index = worldBossModule:GetBossLevelDifficultyIndex()
        local missionId = self._param[1]
        self._param[2] = index - 1
        local cfg_world_boss_mission = Cfg.cfg_world_boss_mission[missionId]
        if cfg_world_boss_mission then
            local levelId = cfg_world_boss_mission.FightLevel[index]
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif self._teamOpenerType == TeamOpenerType.N21CC then
        local missionId = self._param[1]
        local mission = Cfg.cfg_campaign_mission[missionId]
        if mission then
            local levelId = mission.FightLevel
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    elseif
        self._teamOpenerType == TeamOpenerType.Diff or self._teamOpenerType == TeamOpenerType.Sailing or
        self._teamOpenerType == TeamOpenerType.Vampire or
        self._teamOpenerType == TeamOpenerType.Camp_Diff
    then
    elseif self._teamOpenerType == TeamOpenerType.Air then
        local isBlackFist = self._param[2] == ECampaignMissionComponentId.ECampaignMissionComponentId_AircraftBlackfist
        if isBlackFist then
            local missionId = self._param[1]
            local mission = Cfg.cfg_blackfist_mission[missionId]
            if mission then
                local levelId = mission.LevelID
                enable = Cfg.cfg_level[levelId].EnableHelpPet
            end
        else
            --战术卡带获取levelid
            local missionid = self._param[1]
            local cfg_campaign_mission = Cfg.cfg_campaign_mission[missionid]
            if not cfg_campaign_mission then
                Log.error("###[UITeams] cfg_campaign_mission is nil ! id --> ", missionid)
            end
            local levelId = cfg_campaign_mission.FightLevel
            if levelId then
                enable = Cfg.cfg_level[levelId].EnableHelpPet
            end
        end
    elseif self._teamOpenerType == TeamOpenerType.Season then
        local missionId = self._param[1]
        local progress = self._param[5]
        local mission = Cfg.cfg_season_mission[missionId]
        if mission then
            local levelId = mission.FightLevel[progress]
            enable = Cfg.cfg_level[levelId].EnableHelpPet
        end
    end
    -- return enable
    -- math.random(0, 2)
    return enable
end

function UITeams:btnClearOnClick(go)
    local teamid = self.ctx:GetCurrTeamId()
    local team = self._teams:Get(teamid)
    if not team:HasPet() then
        return
    end
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_discovery_clear_all_pet_or_not"),
        function(param)
            self:StartTask(
                function(TT)
                    --清空助战信息
                    local hpm = self:GetModule(HelpPetModule)
                    hpm:UI_ClearHelpPet()
                    --清空助战信息
                    if self.ctx.teamOpenerType == TeamOpenerType.Tower then
                        local curTeamId = self.ctx:GetCurrTeamId()
                        local team = self._teams:Get(curTeamId):Clone()
                        team:ClearPet()
                        ---@type TowerModule
                        local module = self:GetModule(TowerModule)
                        self:Lock("module:UpdateMainFormationInfo")
                        local res, mul_formations = self.ctx:ReqTowerChangeMulFormationInfo(TT, team)
                        self:UnLock("module:UpdateMainFormationInfo")
                        if res:GetSucc() then
                            self.ctx:InitTowerTeam(mul_formations)
                            self._teams = self.ctx:GetTowerTeam()
                            local element = self.ctx:GetTowerElement()
                            local teams = self.ctx:RawGetTowerTeam(element)
                            teams:UpdateTeam(team)
                            self:FlushTeam(curTeamId)
                        else
                            ToastManager.ShowToast(module:GetErrorMsg(res:GetResult()))
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Maze then
                        local team = self._teams:Get(self.ctx.mazeTeamId):Clone()
                        team:ClearPet()
                        local mazeModule = self:GetModule(MazeModule)
                        self:Lock("module:UpdateMainFormationInfo")

                        local res, data = mazeModule:UpdateMazeFormationInfo(TT, team.id, team.name, team.pets)
                        self:UnLock("module:UpdateMainFormationInfo")

                        if res:GetSucc() then
                            self.ctx:InitMazeTeam(data)
                            self._teams = self.ctx:GetMazeTeam()
                            self.ctx:GetMazeTeam():UpdateTeam(team)
                            self:FlushTeam(self.ctx.mazeTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Trail then
                        local team = self._teams:Get(self.ctx.trailTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateMainFormationInfo")
                        ---@type TalePetModule
                        local talePetModule = GameGlobal.GetModule(TalePetModule)
                        local res = talePetModule:UpdateMainFormationInfo(TT, team.id, team.name, team.pets)
                        self:UnLock("module:UpdateMainFormationInfo")
                        if res:GetSucc() then
                            self.ctx.trailTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.trailTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.WorldBoss then
                        local team = self._teams:Get(self.ctx.worldBossTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateWorldBossFormationInfo")
                        ---@type WorldBossModule
                        local worldBossModule = GameGlobal.GetModule(WorldBossModule)
                        local res = worldBossModule:ReqWorldBossChangeFormationInfo(TT, team.pets)
                        self:UnLock("module:UpdateWorldBossFormationInfo")
                        if res:GetSucc() then
                            self.ctx.worldBossTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.worldBossTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.N21CC then
                        local curTeamId = self.ctx:GetCurrTeamId()
                        local team = self._teams:Get(curTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateMainFormationInfo")
                        local result = UIActivityN21CCConst.SaveTeamInfo(TT, team.id, team.name, team.pets)
                        if result then
                            self.ctx.n21CCTeam:UpdateTeam(team)
                            self:FlushTeam(curTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                        self:UnLock("module:UpdateMainFormationInfo")
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Diff then
                        local team = self._teams:Get(self.ctx.diffTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateDiffFormationInfo")
                        ---@type DifficultyMissionModule
                        local diffModule = GameGlobal.GetModule(DifficultyMissionModule)
                        local param = self.ctx.param
                        local nodeid = param[1]
                        local stageid = param[2]
                        local res = diffModule:HandleChangeFormation(TT, nodeid, stageid, team.pets)
                        self:UnLock("module:UpdateDiffFormationInfo")
                        if res:GetSucc() then
                            self.ctx.diffTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.diffTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Sailing then
                        local team = self._teams:Get(self.ctx.sailingTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateDiffFormationInfo")
                        ---@type SailingMissionModule
                        local sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
                        local param = self.ctx.param
                        local layerId = param[1]
                        local missionId = param[2]
                        local res = sailingMissionModule:HandleChangeFormation(TT, layerId, missionId, team.pets)
                        self:UnLock("module:UpdateDiffFormationInfo")
                        if res:GetSucc() then
                            self.ctx.sailingTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.sailingTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Vampire then
                        local curTeamId = self.ctx:GetCurrTeamId()
                        local team = self._teams:Get(curTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateMainFormationInfo")
                        local result, hasExpire = UIN25VampireUtil.SaveTeamInfo(TT, team.pets)
                        if result then
                            self.ctx.vampireTeam:UpdateTeam(team)
                            self:FlushTeam(curTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                        self:UnLock("module:UpdateMainFormationInfo")
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Air then
                        local team = self._teams:Get(self.ctx.airTeamId):Clone()
                        team:ClearPet()
                        local airModule = self:GetModule(AircraftModule)
                        self:Lock("module:UpdateMainFormationInfo")

                        local res, data = airModule:RequestChangeTacticFormationInfo(TT, team.id, team.name, team.pets)
                        self:UnLock("module:UpdateMainFormationInfo")

                        if res:GetSucc() then
                            self.ctx:InitAirTeam(data)
                            self._teams = self.ctx:GetAirTeam()
                            self._teams:UpdateTeam(team)
                            self:FlushTeam(self.ctx.airTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Camp_Diff then
                        local team = self._teams:Get(self.ctx.diffTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateCampDiffFormationInfo")
                        local param = self.ctx.param
                        ---@type DifficultyMissionComponent
                        local diffCpt = param[5]
                        local nodeid = param[1]
                        local stageid = param[2]
                        local res =
                            diffCpt:HandleDifficultyChangeFormation(
                                TT,
                                AsyncRequestRes:New(),
                                nodeid,
                                stageid,
                                team.pets
                            )
                        self:UnLock("module:UpdateCampDiffFormationInfo")
                        if res:GetSucc() then
                            self.ctx.campDiffTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.campDiffTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新活动高难编队失败 ")
                        end
                    elseif self.ctx.teamOpenerType == TeamOpenerType.Season then
                        local team = self._teams:Get(self.ctx.seasonTeamId):Clone()
                        team:ClearPet()
                        ---@type SeasonModule
                        local seasonModule = GameGlobal.GetModule(SeasonModule)
                        self:Lock("module:UpdateMainFormationInfo")
                        local res = seasonModule:ReqSeasonChangeFormationInfo(TT, team.id, team.name, team.pets)
                        self:UnLock("module:UpdateMainFormationInfo")

                        if res:GetSucc() then
                            self.ctx.seasonTeam:UpdateTeam(team)
                            self:FlushTeam(self.ctx.seasonTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    else
                        local curTeamId = self.ctx:GetCurrTeamId()
                        local team = self._teams:Get(curTeamId):Clone()
                        team:ClearPet()
                        self:Lock("module:UpdateMainFormationInfo")
                        local res = self._module:UpdateMainFormationInfo(TT, team.id, team.name, team.pets)
                        self:UnLock("module:UpdateMainFormationInfo")

                        if res:GetSucc() then
                            self.ctx.teams:UpdateTeam(team)
                            self:FlushTeam(curTeamId)
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                        else
                            Log.fatal("### 更新编队失败 ")
                        end
                    end
                end,
                self
            )
        end
    )
end

function UITeams:BtnFastTeamOnClick(go)
    local teamCtx = self._module:TeamCtx()
    teamCtx:InitTeamFastSelect()
    self:ShowDialog("UITeamChangeController")
end

---@param nMatchType MatchType
function UITeams:_MatchStart(TT, nMatchType, teamid, createInfo)
    self._nMatchType = nMatchType
    self._teamid = teamid
    self._createInfo = createInfo
    ---卡带进局前播一�?7秒的动画
    local isTape = false
    if self._teamOpenerType == TeamOpenerType.Campaign then
        if
            self._param[2] == ECampaignMissionComponentId.ECampaignMissionComponentId_SimulatorBlackfist or
            self._param[2] == ECampaignMissionComponentId.ECampaignMissionComponentId_CamSimulator
        then
            isTape = true
        end
    elseif self._teamOpenerType == TeamOpenerType.Air then
        isTape = true
    elseif self._teamOpenerType == TeamOpenerType.Vampire then
        self:Lock("UITeams_MatchStart")
        local curTeamId = self.ctx:GetCurrTeamId()
        local team = self._teams:Get(curTeamId):Clone()
        local result, hasExpire = UIN25VampireUtil.SaveTeamInfo(TT, team.pets)
        if hasExpire then
            ToastManager.ShowToast(StringTable.Get("str_n25_start_battle_error"))
            self.ctx.vampireTeam:UpdateTeam(team)
            self:FlushTeam(curTeamId)
            self:UnLock("UITeams_MatchStart")
            self:UnLock("DoEnterMatch")
            GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
            return
        end
        self:UnLock("UITeams_MatchStart")
    end
    if isTape then
        self:UnLock("DoEnterMatch")
        local pstid = self._param[3][ECampaignMissionParamKey.ECampaignMissionParamKey_CartridgePstId]
        self:ShowDialog(
            "UIAircraftTacticSwitch",
            pstid,
            function()
                self:Lock("DoEnterMatch")
                self:_OnMatchStart()
            end
        )
    else
        self:_OnMatchStart()
    end
end

function UITeams:_OnMatchStart()
    self:StartTask(self.StartMatchTask, self, self._nMatchType, self._teamid, self._createInfo)
end

function UITeams:StartMatchTask(TT, nMatchType, teamid, createInfo)
    ---@type GameMatchModule
    local game = GameGlobal.GetModule(GameMatchModule)
    local res = game:StartMatchTask(TT, nMatchType, teamid, createInfo)
    self:UnLock("DoEnterMatch")
    if not res:GetSucc() then
        if GameGlobal.UIStateManager():IsShow("UIAircraftTacticSwitch") then
            GameGlobal.UIStateManager():CloseDialog("UIAircraftTacticSwitch")
        end
        local result = res:GetResult()
        if result == MatchOpResCode.MATCH_NOT_ENOUGH_PHY_POWER then
            self:ShowDialog("UIGetPhyPointController")
        elseif result == MatchOpResCode.MATCH_CAMPAIGN_MISSIOHN_CROSS_DAY then
            ToastManager.ShowToast(game:GetErrorMsg(result))
            if nMatchType == MatchType.MT_BlackFist then
                self:SwitchState(UIStateType.UIBlackFightMain)
            else
                self:SwitchState(UIStateType.UIActivityN5BattleField)
            end
        elseif result == MatchOpResCode.MATCH_WORLD_BOSS_MISSION_INVALID then
            ToastManager.ShowToast(game:GetErrorMsg(result))
            self:SwitchState(UIStateType.UIWorldBoss)
        elseif result == MatchOpResCode.MATCH_DM_FORMATION_INVALID then
            local tips = StringTable.Get("str_diff_mission_MATCH_DM_FORMATION_INVALID")
            ToastManager.ShowToast(tips)
        else
            ToastManager.ShowToast(game:GetErrorMsg(result)) --各系统根据自己的nMatchType和res:GetResult()去执行不同的UI动作
        end
        return
    end

    --开局成功则启动连续自动战�?
    local serial = GameGlobal.GetModule(SerialAutoFightModule)
    serial:StartSerialFight()
end

-- 资源本开始匹�?
function UITeams:_ResInstanceMatchStart(TT)
    local resDungeonModule = self:GetModule(ResDungeonModule)
    local instanceId = resDungeonModule:GetEnterInstanceId()

    local game = GameGlobal.GetModule(GameMatchModule)
    local curTeamId = self.ctx:GetCurrTeamId()
    local res = resDungeonModule:StartMatchTask(TT, instanceId, curTeamId)
    self:UnLock("DoEnterMatch")
    if not res:GetSucc() then
        ToastManager.ShowToast(game:GetErrorMsg(res:GetResult())) --各系统根据自己的nMatchType和res:GetResult()去执行不同的UI动作
        return
    end
    --开局成功则启动连续自动战�?
    local serial = GameGlobal.GetModule(SerialAutoFightModule)
    serial:StartSerialFight()
end

function UITeams:CheckTeamMemberDuplicate()
    local teamid = self.ctx:GetCurrTeamId()
    local team = self._teams:Get(teamid)
    if not team or not team.pets then
        return false
    end

    ---@type PetModule
    local petModule = self:GetModule(PetModule)
    local dic = {}
    local valueIndexDic = {}
    for index, pstId in pairs(team.pets) do
        if pstId > 0 then
            ---@type Pet
            local petData = petModule:GetPet(pstId)
            if petData then
                local tmpId = petData:GetTemplateID()
                if dic[tmpId] == nil then
                    dic[tmpId] = 0
                end
                dic[tmpId] = dic[tmpId] + 1
                valueIndexDic[tmpId] = index
            end
        end
    end
    ---@type HelpPetModule
    local helpPetModule = GameGlobal.GetModule(HelpPetModule)

    local helpPet = helpPetModule:UI_GetSelectHelpPet()
    if helpPet then
        local helpPetTmpId = helpPet.m_nTemplateID
        local index = valueIndexDic[helpPetTmpId]
        if index and index ~= 5 then
            return false
        end
    end

    for k, v in pairs(dic) do
        if v > 1 then
            return false
        end
    end

    return true
end

---检查编队成员有效�?
function UITeams:CheckTeamValid()
    local teamid = self.ctx:GetCurrTeamId()
    local team = self._teams:Get(teamid)
    if not team or not team.pets then
        return false
    end
    if table.count(team.pets) <= 0 then
        return false
    end
    local leaderId = team.pets[1]
    if not leaderId then
        return false
    end
    if leaderId == 0 then
        return false
    end
    return true, team
end

function UITeams:btnFightOnClick(go)
    local l_curTime = os.time()

    if (l_curTime - self._lastClickTime) < 1 then
        Log.debug("btnFightOnClick repeat")
        return
    end
    self._lastClickTime = l_curTime
    ---@type ProfileCollector
    local pc = GameGlobal:GetInstance():GetCollector("CoreGameLoading")
    pc:ResetCollector()
    pc:Sample("UITeams:btnFightOnClick()")
    --进入战斗音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIBattleStart)

    local bCheckTeamValid, team = self:CheckTeamValid()
    if false == bCheckTeamValid then
        ToastManager.ShowToast(StringTable.Get("str_discovery_no_leader_no_fight"))
        return
    end

    if self:CheckTeamMemberDuplicate() == false then
        ToastManager.ShowToast(StringTable.Get("str_tower_error_8"))
        return
    end

    -- 编队限制 --
    local guide_team_limit = Cfg.cfg_guide_const["guide_team_limit"].StrValue
    local enterBattleLimit = {}
    local limitTips = {}
    local a = string.split(guide_team_limit, "|")
    for _, value1 in ipairs(a) do
        local b = string.split(value1, ";")
        local missionId = tonumber(b[1])
        if not enterBattleLimit[missionId] then
            enterBattleLimit[missionId] = {}
        end
        local petIds = string.split(b[2], ",")
        for index, petId in ipairs(petIds) do
            table.insert(enterBattleLimit[missionId], tonumber(petId))
        end
        local tipId = b[3]
        if not limitTips[missionId] then
            limitTips[missionId] = tipId
        end
    end
    -- enterBattleLimit[4000001] = {1500331}
    -- enterBattleLimit[4000002] = {1500331, 1300221, 1400071}
    -- enterBattleLimit[4000003] = {1500331, 1300221, 1400071}

    -- local limitTips = {}
    -- limitTips[4000001] = "str_mission_limit_4000001"
    -- limitTips[4000002] = "str_mission_limit_4000002"
    -- limitTips[4000003] = "str_mission_limit_4000003"

    local limit = enterBattleLimit[self._param]
    if limit then
        ---@type PetModule
        local petModule = self:GetModule(PetModule)
        for i = 1, #team.pets do
            ---@type Pet
            local petData = petModule:GetPet(team.pets[i])
            if petData then
                local key = table.ikey(limit, petData:GetTemplateID())
                if key then
                    table.remove(limit, key)
                end
            end
        end

        if #limit > 0 then
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                "",
                StringTable.Get(limitTips[self._param])
            )
            return
        end
    end
    self:GetModule(PetModule):ClearAllPetSortInfo()
    --编队队长限制
    -- local enterBattleLeaderLimit = {}
    -- enterBattleLeaderLimit[4000002] = 1500331

    -- local leaderlLimitTips = {}
    -- leaderlLimitTips[4000002] = "str_mission_leader_limit_4000002"

    -- local leaderLimit = enterBattleLeaderLimit[self._param]
    -- if leaderLimit then
    --     ---@type PetModule
    --     local petModule = self:GetModule(PetModule)
    --     local petData = petModule:GetPet(team.pets[1])
    --     if petData then
    --         local tmpID = petData:GetTemplateID()
    --         if tmpID ~= leaderLimit then
    --             PopupManager.Alert(
    --                 "UICommonMessageBox",
    --                 PopupPriority.Normal,
    --                 PopupMsgBoxType.Ok,
    --                 "",
    --                 StringTable.Get(leaderlLimitTips[self._param])
    --             )
    --             return
    --         end
    --     end
    -- end
    --
    self:Lock("DoEnterMatch")
    --进局
    ---@type GameMatchModule
    local game = GameGlobal.GetModule(GameMatchModule)
    ---@type RoleModule
    local role = GameGlobal.GetModule(RoleModule)
    local curTeamId = self.ctx:GetCurrTeamId()
    if self._teamOpenerType == TeamOpenerType.Stage then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_Mission, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_Mission, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.ExtMission then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_ExtMission, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_ExtMission, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Maze then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_Maze, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_Maze, self.ctx.mazeTeamId, createInfo)
        local teams = self.ctx:GetMazeTeam()
        local team = teams:Get(self.ctx.mazeTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
        --迷宫调用编队改成了普通ui，进入局内时会从迷宫的状态UI通过Loading切换到局内，可能会出bug，需要提前通知迷宫停止所有逻辑
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnLeaveMaze)
    elseif self._teamOpenerType == TeamOpenerType.ResInstance then
        self:StartTask(self._ResInstanceMatchStart, self)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Tower then
        local teams = self.ctx:GetTowerTeam()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        local count = 0
        for _, id in ipairs(petsList) do
            if id > 0 then
                count = count + 1
            end
        end
        local towerTeamCeiling = self.ctx:GetTowerTeamCeiling()
        if count < towerTeamCeiling then
            local tips = {
                [ElementType.ElementType_Blue] = "str_tower_pet_count_error_water",
                [ElementType.ElementType_Red] = "str_tower_pet_count_error_fire",
                [ElementType.ElementType_Green] = "str_tower_pet_count_error_wood",
                [ElementType.ElementType_Yellow] = "str_tower_pet_count_error_thunder"
            }
            ToastManager.ShowToast(string.format(StringTable.Get(tips[self.ctx:GetTowerElement()]), towerTeamCeiling))
            self:UnLock("DoEnterMatch")
            return
        end
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_Tower, self.ctx:GetTowerLayerID())
        self:StartTask(self._MatchStart, self, MatchType.MT_Tower, curTeamId, createInfo)
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Trail then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_TalePet, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_TalePet, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Campaign then
        local matchType = MatchType.MT_Campaign
        if self._param[2] == ECampaignMissionComponentId.ECampaignMissionComponentId_SimulatorBlackfist then
            matchType = MatchType.MT_BlackFist
        end

        local createInfo = game:GetMatchCreateInfo(matchType, self._param)
        self:StartTask(self._MatchStart, self, matchType, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.LostLand then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_LostArea, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_LostArea, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Conquest then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_Conquest, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_Conquest, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.WorldBoss then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_WorldBoss, self._param)
        local worldBossModule = self:GetModule(WorldBossModule)
        self:StartTask(
            self._MatchStart,
            self,
            MatchType.MT_WorldBoss,
            worldBossModule:GetCurSelectTeamIndex(),
            createInfo
        )
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.N21CC then
        local matchType = MatchType.MT_Campaign
        local createInfo = game:GetMatchCreateInfo(matchType, self._param)
        self:StartTask(self._MatchStart, self, matchType, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        UIActivityN21CCConst.SetNewFlagStatus("MISSION_ENTER_STATUS" .. createInfo.nCampaignMissionId, false)
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.BlackFist then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_BlackFist, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_BlackFist, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Air then
        local airModule = GameGlobal.GetModule(AircraftModule)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets

        for i = 1, #petsList do
            local pstid = petsList[i]
            if pstid ~= 0 then
                local room = airModule:GetRoomByRoomType(AirRoomType.TacticRoom)
                local switchCount = room:GetPetRemainFightNum(pstid)

                if switchCount <= 0 then
                    local tips = StringTable.Get("str_aircraft_tactic_battle_error_tips")
                    ToastManager.ShowToast(tips)
                    self:UnLock("DoEnterMatch")
                    return
                end
            end
        end

        local matchType = MatchType.MT_Campaign
        if self._param[2] == ECampaignMissionComponentId.ECampaignMissionComponentId_AircraftBlackfist then
            matchType = MatchType.MT_BlackFist
        end

        local createInfo = game:GetMatchCreateInfo(matchType, self._param)
        self:StartTask(self._MatchStart, self, matchType, curTeamId, createInfo)
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Diff then
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_DifficultyMission, self._param)
        local diffModule = self:GetModule(DifficultyMissionModule)
        self:StartTask(self._MatchStart, self, MatchType.MT_DifficultyMission, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Sailing then
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        if petsList == nil or #petsList < 5 then
            self:UnLock("DoEnterMatch")
            local tips = StringTable.Get("str_sailing_mission_team_count_not_enough")
            ToastManager.ShowToast(tips)
            return
        end

        for i = 1, #petsList do
            if petsList[i] <= 0 then
                self:UnLock("DoEnterMatch")
                local tips = StringTable.Get("str_sailing_mission_team_count_not_enough")
                ToastManager.ShowToast(tips)
                return
            end
        end

        ---@type SailingMissionModule
        local sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
        local layerId = self._param[1]
        local missionId = self._param[2]
        if sailingMissionModule:GetChallengeLayerID() == layerId then
            -- 本层未全部通关：最近一次挑战的关卡默认居中
            LocalDB.SetInt(UISailing:ChallengeMissionKey(), missionId)
        end

        local createInfo = game:GetMatchCreateInfo(MatchType.MT_SailingMission, self._param)
        self:StartTask(self._MatchStart, self, MatchType.MT_SailingMission, curTeamId, createInfo)

        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Vampire then
        local matchType = MatchType.MT_MiniMaze
        local createInfo = game:GetMatchCreateInfo(matchType, self._param)
        self:StartTask(self._MatchStart, self, matchType, curTeamId, createInfo)
    elseif self._teamOpenerType == TeamOpenerType.Camp_Diff then
        --活动高难关进局
        local createInfo = game:GetMatchCreateInfo(MatchType.MT_DifficultyMission, self._param)
        local diffModule = self:GetModule(DifficultyMissionModule)
        self:StartTask(self._MatchStart, self, MatchType.MT_DifficultyMission, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    elseif self._teamOpenerType == TeamOpenerType.Season then
        local matchType = MatchType.MT_Season
        local createInfo = game:GetMatchCreateInfo(matchType, self._param)
        self:StartTask(self._MatchStart, self, matchType, curTeamId, createInfo)
        local teams = self.ctx:Teams()
        local team = teams:Get(curTeamId)
        local petsList = team.pets
        role:UpdateMatchPetsList(petsList)
    else
        self:UnLock("DoEnterMatch")
    end
end

--region 长按
---@param isBegin boolean true-长按开始false长按结束
---@param slot number 长按的槽
---@param slot number 长按的宠物Id
---@param screenPos Vector2 屏幕坐标
function UITeams:TeamItemLongPress(isBegin, slot, id)
    if isBegin then
        Log.debug("TeamItemLongPress begin drag")
        self._isLongPressing = true

        if not self._replaceCard then
            local sop = self:GetUIComponent("UISelectObjectPath", "card")
            ---@type UIPetMemberItem
            sop:SpawnObjects("UIPetMemberItem", 1)
            self._replaceCard = sop:GetAllSpawnList()[1]
        end

        self._replaceCard:SetData(id)
    else
        self._isLongPressing = false
        local strUITeamsDrag = "UITeamsDrag"
        for i, v in ipairs(self._uiSlots) do
            local tran = v:GetRectTransform()

            local localPos = tran:InverseTransformPoint(self._replaceTran.position)
            if tran.rect:Contains(localPos) and not v:IsLocked() then
                -- 助战判断 不能把其他位置移到五号位
                if i == 5 then
                    local hpm = self:GetModule(HelpPetModule)
                    local key = hpm:UI_GetHelpPetKey()
                    if key > 0 then
                        self._replaceGo:SetActive(false)
                        ToastManager.ShowToast(StringTable.Get("str_help_pet_weizhi"))
                        return
                    end
                end

                local teamid = self.ctx:GetCurrTeamId()
                local team = self._teams:Get(teamid):Clone()
                team:Swap(slot, i)
                self:StartTask(
                    function(TT)
                        self:Lock(strUITeamsDrag)
                        if self.ctx.teamOpenerType == TeamOpenerType.Tower then
                            local module = self:GetModule(TowerModule)
                            local res, formation_data = self.ctx:ReqTowerChangeMulFormationInfo(TT, team)
                            if res:GetSucc() then
                                self.ctx:InitTowerTeam(formation_data)
                                self._teams = self.ctx:GetTowerTeam()
                                local element = self.ctx:GetTowerElement()
                                local teams = self.ctx:RawGetTowerTeam(element)
                                teams:UpdateTeam(team)
                                self:FlushTeam(team.id)
                            else
                                ToastManager.ShowToast(module:GetErrorMsg(res:GetResult()))
                            end
                            self:UnLock(strUITeamsDrag)
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Maze then
                            ---@type MazeModule
                            local mazeModule = self:GetModule(MazeModule)
                            local res, data = mazeModule:UpdateMazeFormationInfo(self, team.id, team.name, team.pets)
                            if res:GetSucc() then
                                self.ctx:InitMazeTeam(data)
                                self._teams = self.ctx:GetMazeTeam()
                                self.ctx:GetMazeTeam():UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            else
                                ToastManager.ShowToast(self._module:GetErrorMsg(res:GetResult()))
                            end
                            self:UnLock(strUITeamsDrag)
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Trail then
                            ---@type TalePetModule
                            local talePetModule = GameGlobal.GetModule(TalePetModule)
                            local res = talePetModule:UpdateMainFormationInfo(TT, team.id, team.name, team.pets)
                            if res:GetSucc() then
                                self.ctx.trailTeam:UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            end
                            self:UnLock(strUITeamsDrag)
                        elseif self.ctx.teamOpenerType == TeamOpenerType.WorldBoss then
                            ---@type WorldBossModule
                            local worldBossModule = GameGlobal.GetModule(WorldBossModule)
                            local res = worldBossModule:ReqWorldBossChangeFormationInfo(TT, team.pets)
                            if res:GetSucc() then
                                self.ctx.worldBossTeam:UpdateTeam(team)
                                self:FlushTeam(self.ctx.worldBossTeamId)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            end
                            self:UnLock(strUITeamsDrag)
                        elseif self.ctx.teamOpenerType == TeamOpenerType.N21CC then
                            local result = UIActivityN21CCConst.SaveTeamInfo(TT, team.id, team.name, team.pets)
                            if result then
                                self.ctx.n21CCTeam:UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                                self:UnLock(strUITeamsDrag)
                            else
                                self:UnLock(strUITeamsDrag)
                            end
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Diff then
                            ---@type DifficultyMissionModule
                            local diffModule = GameGlobal.GetModule(DifficultyMissionModule)
                            local param = self.ctx.param
                            local nodeid = param[1]
                            local stageid = param[2]
                            local res = diffModule:HandleChangeFormation(TT, nodeid, stageid, team.pets)
                            self:UnLock(strUITeamsDrag)
                            if res:GetSucc() then
                                self.ctx.diffTeam:UpdateTeam(team)
                                self:FlushTeam(self.ctx.diffTeamId)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            else
                                Log.fatal("### 更新编队失败 ")
                            end
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Sailing then
                            ---@type SailingMissionModule
                            local sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
                            local param = self.ctx.param
                            local layerId = param[1]
                            local missionId = param[2]
                            local res = sailingMissionModule:HandleChangeFormation(TT, layerId, missionId, team.pets)
                            self:UnLock(strUITeamsDrag)
                            if res:GetSucc() then
                                self.ctx.sailingTeam:UpdateTeam(team)
                                self:FlushTeam(self.ctx.sailingTeamId)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            else
                                Log.fatal("### 更新编队失败 ")
                            end
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Vampire then
                            local result, hasExpire = UIN25VampireUtil.SaveTeamInfo(TT, team.pets)
                            if result then
                                self.ctx.vampireTeam:UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                                self:UnLock(strUITeamsDrag)
                            else
                                self:UnLock(strUITeamsDrag)
                            end
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Air then
                            local airModule = GameGlobal.GetModule(AircraftModule)
                            local res, data =
                                airModule:RequestChangeTacticFormationInfo(TT, team.id, team.name, team.pets)
                            if res:GetSucc() then
                                self.ctx:InitAirTeam(data)
                                self.ctx.airTeam:UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                                self:UnLock(strUITeamsDrag)
                            end
                            self:UnLock(strUITeamsDrag)
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Camp_Diff then
                            local param = self.ctx.param
                            ---@type DifficultyMissionComponent
                            local diffCpt = param[5]
                            local nodeid = param[1]
                            local stageid = param[2]
                            local res =
                                diffCpt:HandleDifficultyChangeFormation(
                                    TT,
                                    AsyncRequestRes:New(),
                                    nodeid,
                                    stageid,
                                    team.pets
                                )
                            self:UnLock(strUITeamsDrag)
                            if res:GetSucc() then
                                self.ctx.campDiffTeam:UpdateTeam(team)
                                self:FlushTeam(self.ctx.campDiffTeamId)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            else
                                Log.fatal("### 更新活动高难编队失败 ")
                            end
                        elseif self.ctx.teamOpenerType == TeamOpenerType.Season then
                            ---@type SeasonModule
                            local seasonModule = GameGlobal.GetModule(SeasonModule)
                            local res = seasonModule:ReqSeasonChangeFormationInfo(TT, team.id, team.name, team.pets)
                            if res:GetSucc() then
                                self.ctx.seasonTeam:UpdateTeam(team)
                                self:FlushTeam(self.ctx.seasonTeamId)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                            else
                                Log.fatal("### 更新编队失败 ")
                            end
                            self:UnLock(strUITeamsDrag)
                        else
                            local res, data = self._module:UpdateMainFormationInfo(self, team.id, team.name, team.pets)
                            if res:GetSucc() then
                                self.ctx.teams:UpdateTeam(team)
                                self:FlushTeam(team.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamMemberChanged)
                                self:UnLock(strUITeamsDrag)
                            else
                                self:UnLock(strUITeamsDrag)
                            end
                        end
                    end,
                    self
                )
                break
            end
        end
    end
    self._replaceGo:SetActive(self._isLongPressing)
end

function UITeams:UpdateReplaceCardPos(screenPos)
    if self._replaceTran then
        local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
        local pos = UIHelper.ScreenPointToWorldPointInRectangle(self._replaceTran.parent, screenPos, camera)
        self._replaceTran.position = pos
    end
end

function UITeams:GetTeamItem(index)
    if self._uiSlots[index] then
        return self._uiSlots[index]:GetGB()
    else
        return nil
    end
end

function UITeams:GetTeamItemHelpPetIcon(index)
    if self._uiSlots[index] then
        return self._uiSlots[index]:GetHelpPetIcon()
    else
        return nil
    end
end

--endregion

function UITeams:OnCancelSerialAutoFight()
    self._blockMask:SetActive(false)
    if self._autoBtn then
        self._autoBtn:Hide()
    end
end

function UITeams:blockMaskOnClick()
    ToastManager.ShowToast(StringTable.Get("str_battle_cannot_use"))
end

function UITeams:_CheckTeamTips()
    local active = false
    local text = nil
    if self.ctx.teamOpenerType == TeamOpenerType.Maze then
        active = true
        text = StringTable.Get("str_maze_teams_tips")
    elseif self.ctx.teamOpenerType == TeamOpenerType.Vampire then
        active = true
        text = StringTable.Get("str_n25_teams_tips")
    end
    self._mazeTeamTips:SetActive(active)
    self._mazeTeamTipsText:SetText(text)

    self:_CheckSeasonTeamTips()
end

function UITeams:_CheckSeasonTeamTips()
    local active = false
    local text = nil
    if self.ctx.teamOpenerType == TeamOpenerType.Season then
        local missionId = self._param[1]
        if missionId then
            local missionCfg = Cfg.cfg_season_mission[missionId]
            if missionCfg and missionCfg.IsDailylevel ~= 1 then
                active = true
                text = StringTable.Get("str_season_pet_enhance_title"
                , missionCfg.PetGrade
                , missionCfg.PetLv
                , missionCfg.PetAwakening
                , missionCfg.PetEquip
                )
            end
        end
    end
    if self._seasonTeamTips then
        self._seasonTeamTips:SetActive(active)
        if active then
            self._seasonTeamTipsText:SetText(text)
        end
    end
end
