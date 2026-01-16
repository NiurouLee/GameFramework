--[[
    新手引导工具类
]]
---@class GuideHelper: Object
_class("GuideHelper", Object)
GuideHelper = GuideHelper

--------------------------------跳转相关----------------------------
---cfg_guide showOpenUI字段
function GuideHelper.Goto(showOpenUI)
    local uiName
    local type = showOpenUI[1]
    if type == GuideGotoType.FromAircraftTo then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.AircraftJumpOutTo,
            function()
                table.remove(showOpenUI, 1)
                uiName = GuideHelper._Goto(showOpenUI)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.OpenUI)
            end
        )
    else
        uiName = GuideHelper._Goto(showOpenUI)
    end
    return uiName
end

function GuideHelper._Goto(showOpenUI)
    local uiName
    local controllerType = showOpenUI[1]
    if controllerType == GuideGotoType.UIDiscovery then --  关卡界面
        local missionId = showOpenUI[2]
        if missionId then
            ---@type MissionModule
            local module = GameGlobal.GetModule(MissionModule)
            ---@type DiscoveryData
            local data = module:GetDiscoveryData()
            data:UpdatePosByEnter(3, missionId)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery, true)
        else
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIDiscovery, true)
        end
        uiName = "UIDiscovery"
    elseif controllerType == GuideGotoType.UIPlayer then --  角色界面
        local petTempId = showOpenUI[2]
        if petTempId then
            local showTrain = showOpenUI[3]
            if showTrain == 1 then
                local pets = GameGlobal.GetModule(PetModule):GetPets()
                local petPsdId
                for key, v in pairs(pets) do
                    if v:GetTemplateID() == petTempId then
                        petPsdId = key
                        break
                    end
                end
                if petPsdId then
                    -- 培养
                    uiName = "UIUpLevelInterfaceController"
                    GameGlobal.UIStateManager():ShowDialog(uiName, petPsdId)
                end
            else
                uiName = "UISpiritDetailGroupController"
                -- 人物详情
                GameGlobal.UIStateManager():ShowDialog(uiName, petTempId)
            end
        else
            uiName = "UIHeartSpiritController"
            GameGlobal.UIStateManager():ShowDialog(uiName)
        end
    elseif controllerType == GuideGotoType.UICard then --  抽卡界面
        uiName = "UIDrawCardController"
        GameGlobal.UIStateManager():ShowDialog("UIDrawCardController")
    elseif controllerType == GuideGotoType.UIQuest then --  任务界面
        uiName = "UIQuestController"
        GameGlobal.UIStateManager():ShowDialog(uiName)
    elseif controllerType == GuideGotoType.UIMain then --  主界面
        uiName = "UIMainLobbyController"
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
    elseif controllerType == GuideGotoType.UITeam then --  编队界面
        local missionId = showOpenUI[2]
        if missionId then
            local module = GameGlobal.GetModule(MissionModule)
            ---@type DiscoveryData
            local data = module:GetDiscoveryData()
            data:UpdatePosByEnter(5, missionId)
            ---@type TeamsContext
            local ctx = module:TeamCtx()
            ctx:Init(TeamOpenerType.Stage, missionId)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UITeams)
            uiName = "UITeams"
        end
    elseif controllerType == GuideGotoType.UIHelp then --  帮助说明
        local helpEnum = showOpenUI[2]
        local cfg = Cfg.cfg_help {Enum = helpEnum}[1]
        if cfg then
            GameGlobal.UIStateManager():ShowDialog("UIHelpController", cfg.ID)
        end
        uiName = "UIHelpController"
    elseif controllerType == GuideGotoType.UIAircraft then --  风船
        local controller = GameGlobal.UIStateManager():GetController("UIAircraftController")
        if controller then
            -- main:CheckBackToMain()
            local module = GameGlobal.GetModule(AircraftModule)
            local main = module:GetClientMain()
            main:MoveCameraToFar(
                function()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.OpenUI)
                end
            )
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)
        else
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Enter, "fc_ui")
        end
        uiName = "UIAircraftController"
    elseif controllerType == GuideGotoType.CloseCurUI then --  关当前UI 非state 算是直接完成步骤
        local stateManager = GameGlobal.UIStateManager()
        local visibleUIList = stateManager.uiControllerManager:VisibleUIList()
        for i = 1, visibleUIList:Size() do
            local name = visibleUIList:GetAt(i)
            if stateManager:IsTopUI(name) then
                stateManager:CloseDialog(name)
                break
            end
        end
        uiName = ""
        GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.OpenUI)
    end
    return uiName
end
---------------------------------判断条件------------------
---不显示三星条件的关卡
function GuideHelper.DontShowThreeMission()
    if not GuideHelper._dontShowThreeMissions then
        GuideHelper._dontShowThreeMissions = Cfg.cfg_guide_const["guide_no_threestar_missions"].ArrayValue
    end
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    if enterData._match_type == MatchType.MT_Mission then --主线
        local missionID = enterData:GetMissionCreateInfo().mission_id
        return table.icontains(GuideHelper._dontShowThreeMissions, missionID)
    else
        return false
    end
end

---不显示主动技相关的关卡
function GuideHelper.DontShowMainSkillMission()
    if not GuideHelper._dontShowMainSkillMissions then
        GuideHelper._dontShowMainSkillMissions = Cfg.cfg_guide_const["guide_no_active_skill_missions"].ArrayValue
    end
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    if enterData._match_type == MatchType.MT_Mission then --主线
        local missionID = enterData:GetMissionCreateInfo().mission_id
        return table.icontains(GuideHelper._dontShowMainSkillMissions, missionID)
    else
        return false
    end
end

function GuideHelper.GuideLoadLock(lock, mark)
    Log.debug("GuideHelper.GuideLoadLock", lock, mark, debug.traceback())
    if lock then
        GameGlobal.UIStateManager():Lock("GuideLoadLock")
    else
        if GameGlobal.UIStateManager().uiControllerManager.lockManager:HasLock("GuideLoadLock") then
            GameGlobal.UIStateManager():UnLock("GuideLoadLock")
        end
    end
end

-- 按钮引导是否显示
function GuideHelper.IsUIGuideShow()
    return GameGlobal.GuideMessageBoxMng():IsGuideBoxShowing()
end

function GuideHelper.GuideInProgress()
    local guideModule = GameGlobal.GetModule(GuideModule)
    return guideModule:GuideInProgress()
end

function GuideHelper.IsUIGuideFailedComplete(TT)
    ---等待对话框创建
    local uiGuideFailedShow = GameGlobal.UIStateManager():IsShow("UIGuideFailedController")
    while uiGuideFailedShow == false do
        uiGuideFailedShow = GameGlobal.UIStateManager():IsShow("UIGuideFailedController")
        YIELD(TT)
        if not GameGlobal:GetInstance():IsCoreGameRunning() then
            return
        end
    end

    while uiGuideFailedShow == true do
        uiGuideFailedShow = GameGlobal.UIStateManager():IsShow("UIGuideFailedController")
        YIELD(TT)
        if not GameGlobal:GetInstance():IsCoreGameRunning() then
            return
        end
    end
end
