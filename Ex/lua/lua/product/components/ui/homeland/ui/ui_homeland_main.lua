---@class UIHomelandMain:UIController
_class("UIHomelandMain", UIController)
UIHomelandMain = UIHomelandMain

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIHomelandMain:LoadDataOnEnter(TT, res, uiParams)
    --拉取最新活动数据更新主界面活动信息
    self.mCampaign = self:GetModule(CampaignModule)
    self._latestCampObj = self.mCampaign:GetLatestCampaignObj(TT)

    local homelandModule = self:GetModule(HomelandModule)
    homelandModule:HomelandStoryTaskAutoTraceReq(TT)
end

function UIHomelandMain:OnShow(uiParams)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self._uiHomelandModule = self._homelandModule:GetUIModule()
    ---@type HomelandClient
    self._homelandClient = self._uiHomelandModule:GetClient()
    self._isVisit = self._homelandClient:IsVisit()

    -- self._isVisit = true

    ---@type UnityEngine.GameObject
    self._mobileMoveControlGO = self:GetGameObject("MobileMoveControl")
    ---@type UICustomWidgetPool
    self._mobileMoveConWidgetPool = self:GetUIComponent("UISelectObjectPath", "MobileMoveControl")
    self._controllerPanel = self:GetGameObject("ControllerPanel")

    self:GetUIComponent("UISelectObjectPath", "Minmap"):SpawnObject("UIHomelandMinimap")
    self._minimapGo = self:GetGameObject("Minmap")

    --星灵交互时隐藏
    self._uiRoot = self:GetGameObject("FullscreenAnchor")
    ---@type UnityEngine.GameObject
    self._safeArea = self:GetGameObject("SafeArea")
    ---@type UnityEngine.GameObject
    self._hideMask = self:GetGameObject("HideMask")

    self:GetUIComponent("UISelectObjectPath", "eventTips"):SpawnObject("UIHomelandMainEventTips") --通用提示
    self.btnsObj = self:GetGameObject("btns")
    local mainBtns = self:GetUIComponent("UISelectObjectPath", "btns"):SpawnObject("UIHomelandMainBtns") --各种按钮
    mainBtns:SetCampaignEnter(self._latestCampObj)
    if not self._isVisit then
        self:GetUIComponent("UISelectObjectPath", "fishing"):SpawnObject("UIHomelandFishing") --钓鱼
        self:GetUIComponent("UISelectObjectPath", "felling"):SpawnObject("UIHomelandFelling") --伐木
        self:GetUIComponent("UISelectObjectPath", "mining"):SpawnObject("UIHomelandMining") --挖矿
        self.homeLandTaskInfo = self:GetUIComponent("UISelectObjectPath", "homeLandTaskInfo") -- 任务
    end

    ---@type UIInteractPointController
    self._uiInteractPointController = self:GetUIComponent("UISelectObjectPath", "Interact"):SpawnObject("UIInteractPointController")
    self._uiInteractGo = self:GetGameObject("Interact")
    self:Init()
    self:AddListener()

    if not self._isVisit then
        local eventMgr = self._homelandClient:HomeEventManager()
        local finishStory = eventMgr:GetFinishStoryID()
        if finishStory then
            CutsceneManager.ExcuteCutsceneOut()
            --如果是从剧情界面回来要检查领奖
            self:Lock("UIHomelandMainGetStoryAwards")
            GameGlobal.TaskManager():StartTask(self.GetStoryAwards, self, finishStory)

            --如果是从剧情界面回来执行完成事件
            eventMgr:InvokeFinishStoryEvent()
        end
    end

    ---region 测试功能
    if EngineGameHelper.IsDevelopmentBuild() or HelperProxy:GetInstance():GetConfig("EnableTestFunc", "false") == "true" then
        ---@type UIMainLobbyTestFunc
        self._testFunc = UIWidgetHelper.SpawnObject(self, "TestFunc", "UIHomelandTestFunc")
    end
    ---region end 测试功能

    self._homelandClient:AfterHomelandUIShow()
    self:_CheckGuide()
    self:ShowTaskInfo()

end

function UIHomelandMain:OnHide()
    if self.homeLandTaskInfoObj then
        self.homeLandTaskInfoObj:Hide()
    end
end

function UIHomelandMain:AddListener()
    self:AttachEvent(GameEventType.OnHomeInteractClose, self.OnHomeInteractClose)
    self:AttachEvent(GameEventType.OnHomeInteractFollow, self.OnHomeInteractFollow)
    self:AttachEvent(GameEventType.ShowTreasureBoardUI, self.ShowTreasureBoardUI)
    self:AttachEvent(GameEventType.ShowInteractUI, self.ShowInteractUI)
    self:AttachEvent(GameEventType.HideInteractUI, self.HideInteractUI)
    self:AttachEvent(GameEventType.OnHomeMainShowUIRoot, self.OnHomeMainShowUIRoot)
    self:AttachEvent(GameEventType.EnterFindTreasure, self.EnterFindTreasure)
    self:AttachEvent(GameEventType.ExitFindTreasure, self.ExitFindTreasure)
    self:AttachEvent(GameEventType.FindTreasureFailure, self.OnFindTreasureFailure)
    self:AttachEvent(GameEventType.FindTreasureSuccess, self.OnFindTreasureSuccess)
    self:AttachEvent(GameEventType.PlayerControllerUIStatus, self.SetControllerPanelStatus)
    self:AttachEvent(GameEventType.SetMinimapStatus, self.SetMinimapStatus)
    self:AttachEvent(GameEventType.ShowHideHomelandMainUI, self.OnHomeMainShowUIRoot)
    self:AttachEvent(GameEventType.QuestUpdate, self.OnQuestUpdate)
    self:AttachEvent(GameEventType.OnUIHomePetInteract, self.OnUIHomePetInteract)
    self:AttachEvent(GameEventType.FishMatchHideDash, self.FishMatchHideUI)
    self:AttachEvent(GameEventType.FishMatchEnd, self.FishMatchEnd)
end

function UIHomelandMain:GetStoryAwards(TT, finishStory)
    local cfg_event = Cfg.cfg_homeland_event[finishStory]
    if cfg_event == nil then
        Log.error("###[UIHomelandMain] _cfg_event is nil ! id --> ", finishStory)
        self:UnLock("UIHomelandMainGetStoryAwards")
        return
    end

    -- 2, //完成任务立刻触发剧情
    if cfg_event.EventType == 2 then
        self._homelandModule:HandleClientFinishEventReq(TT, finishStory)
        self:UnLock("UIHomelandMainGetStoryAwards")
        return
    end

    --临时处理 如果event对应的petid是0 说明是任务用的剧情 不需要请求服务器领奖
    if cfg_event.PetID == 0 then
        self:UnLock("UIHomelandMainGetStoryAwards")
        return
    end

    local res = self._homelandModule:HandleClientFinishEventReq(TT, finishStory)
    --等黑屏动画播完
    YIELD(TT, 500)
    self:UnLock("UIHomelandMainGetStoryAwards")
    if res:GetSucc() then
        Log.debug("###[UIHomelandMain] HandleClientFinishEventReq succ !")

        -- body
        local awards = cfg_event.Rewards
        if awards then
            Log.debug("###[UIHomelandMain] 获得奖励 ！")
            local roleAssetList = {}
            for i = 1, #awards do
                local roleAsset = RoleAsset:New()
                roleAsset.assetid = awards[i][1]
                roleAsset.count = awards[i][2]
                table.insert(roleAssetList, roleAsset)
            end
            if #roleAssetList > 0 then
                self:ShowDialog("UIHomeShowAwards", roleAssetList, function()
                    if cfg_event then
                        if cfg_event.EndEventTipTex then
                            local face = cfg_event.EndEventTipIcon or "Norm"
                            local petid = cfg_event.PetID
                            local pet = self._homelandClient:PetManager():GetPet(petid)
                            if pet then
                                local pstid = pet:PstID()
                                local icon = HelperProxy:GetInstance():HomeGetBody(pstid, face)
                                local tex = ""
                                tex = StringTable.Get(cfg_event.EndEventTipTex)
                                local param = {}
                                param[1] = icon
                                param[2] = tex
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips,
                                    UIHomeEventTipsType.PetBody, param)
                            end
                        end
                    end
                end)
            end
        end
    else
        Log.error("###[UIHomelandMain] HandleClientFinishEventReq fail !")
    end
end

function UIHomelandMain:SetMinimapStatus(status)
    self._minimapGo:SetActive(status)
end

function UIHomelandMain:EnterFindTreasure()
    self._uiRoot:SetActive(false)
    self._controllerPanel:SetActive(true)
end

function UIHomelandMain:ExitFindTreasure()
    self._uiRoot:SetActive(true)
    self._controllerPanel:SetActive(true)
end

function UIHomelandMain:OnFindTreasureFailure()
    self._controllerPanel:SetActive(false)
end

function UIHomelandMain:OnFindTreasureSuccess()
    self._controllerPanel:SetActive(false)
end

function UIHomelandMain:SetControllerPanelStatus(status)
    self._controllerPanel:SetActive(status)
end

function UIHomelandMain:OnHomeMainShowUIRoot(show, keepCamRotation)
    self._uiRoot:SetActive(show)
    self._minimapGo:SetActive(show)
    if show then
        self._controllerPanel:SetActive(show)
        self._homelandMoveController:HideExceptCameraRotation(not show)
    else
        if keepCamRotation then
            self._homelandMoveController:HideExceptCameraRotation(not show)
        else
            self._controllerPanel:SetActive(show)
        end
    end
end

--跟随
function UIHomelandMain:OnHomeInteractFollow(follow, pet)
    self._homelandClient:PetManager():OnHomeInteractFollow(follow, pet)
end

function UIHomelandMain:OnHomeInteractClose(active)
    self._homelandClient:InputManager():GetControllerChar():SetActive(true)
end

function UIHomelandMain:Init()
    self._mobileMoveControlGO:SetActive(true)
    ---@type UIWidgetHomelandMoveController
    self._homelandMoveController = self._mobileMoveConWidgetPool:SpawnObject("UIWidgetHomelandMoveController")
end

function UIHomelandMain:ShowTreasureBoardUI(tipsid)
    self:ShowDialog("UITreasureBoard", tipsid)
end

function UIHomelandMain:ShowInteractUI()
    self._uiInteractPointController:SetStatus(true)
end

function UIHomelandMain:HideInteractUI()
    self._uiInteractPointController:SetStatus(false, true)
end

function UIHomelandMain:SetShowHide(show)
    self._safeArea:SetActive(show)
    self._hideMask:SetActive(not show)
end

function UIHomelandMain:HideMaskOnClick()
    self:SetShowHide(true)
end

function UIHomelandMain:ShowHideAllUI(show)
    self._safeArea:SetActive(show)
end

--N17
function UIHomelandMain:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIHomelandMain)
end

function UIHomelandMain:OnQuestUpdate(quests)
    if quests then
        if #quests > 1 then
            table.sort(quests, function(a, b)
                    return a:QuestInfo().status > b:QuestInfo().status
                end)
        end
        for _, quest in pairs(quests) do
            GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideTaskState, quest:QuestInfo().quest_id,
                quest:QuestInfo().status)
        end
    end
end

function UIHomelandMain:ShowTaskInfo()
    if not self.homeLandTaskInfo then
        return
    end

    self.homeLandTaskInfoObj = self.homeLandTaskInfo:SpawnObject("UIHomeLandTaskInfo")
    if self.homeLandTaskInfoObj then
        local taskGroup = self.homeLandTaskInfoObj:_GetRunningTaskGroup()
        self.homeLandTaskInfoObj:SetShow(taskGroup ~= nil)
    end
end

function UIHomelandMain:OnUIHomePetInteract(bShow)
    if self.homeLandTaskInfoObj and self._homelandClient then
        self.homeLandTaskInfoObj:SetShow(not bShow)
    end
end

--N17 交互按钮引导
function UIHomelandMain:GetInteractBtn(param)
    return self._uiInteractPointController:GetInteractBtn(param)
end

--准备开始钓鱼比赛
function UIHomelandMain:FishMatchHideUI()
    self.btnsObj:SetActive(false)
    self._minimapGo:SetActive(false)
    self:HideInteractUI()
    self._uiInteractGo:SetActive(false)
    self:OnUIHomePetInteract(true)
end

--结束钓鱼比赛
function UIHomelandMain:FishMatchEnd(res)
    if res == FishMatchEndType.MATCHEND_CLOSE then
        self.btnsObj:SetActive(true)
        self._minimapGo:SetActive(true)
        self:ShowInteractUI()
        self._uiInteractGo:SetActive(true)
        self:OnUIHomePetInteract(false)
    end
end

function UIHomelandMain:OnUpdate(deltaTimeMS)
    if self._uiInteractPointController then
        self._uiInteractPointController:OnUpdate(deltaTimeMS)
    end
end

