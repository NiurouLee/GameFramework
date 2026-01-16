--拍电影准备阶段主界面
---@class UIHomelandMoviePrepareMainController : UIController
_class("UIHomelandMoviePrepareMainController", UIController)
UIHomelandMoviePrepareMainController = UIHomelandMoviePrepareMainController

--构造
function UIHomelandMoviePrepareMainController:Constructor()
    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
    ---@type HomelandClient
    self.homelandClient = self.mUIHomeland:GetClient()
    ---@type HomeBuildManager
    self.homeBuildManager = self.homelandClient:BuildManager()

    ---@type UIHomelandMoviePrepareFurniture
    self.furnitureWidget = nil;
    ---@type UIHomelandMoviePrepareBase
    self.otherWidget = nil;

    ---@type MoviePrepareType
    self.curPrepareType = nil

    ---@type PrepareStageItem
    self.curPrepareStageItem = nil 

    self.stagesConfig = {
        {prepareType = MoviePrepareType.PT_Scene, name = "str_movie_scene"},
        {prepareType = MoviePrepareType.PT_Furniture, name = "str_movie_free"},
        {prepareType = MoviePrepareType.PT_Prop, name = "str_movie_prop"},
        {prepareType = MoviePrepareType.PT_Actor, name = "str_movie_actor"}
    }

    ---@type {} <MoviePrepareType,PrepareStageItem>
    self.stageItems = {}

    self.fatherBuilding = nil

    self.nextColorEnable = Color(35/255,173/255,244/255)
    self.nextColorDisable = Color(105/255,104/255,104/255)
end

--初始化
function UIHomelandMoviePrepareMainController:OnShow(uiParams)
    self:InitWidget()
    self:_OnValue()
    self:AttachEvent(GameEventType.HomeBuildOnSelectBuilding, self.HomeBuildOnSelectBuilding)
    self:AttachEvent(GameEventType.UIHomelandMoviePrepareActorSelected, self.OnNextBtnStateChange)
end

function UIHomelandMoviePrepareMainController:OnHide()
    self:DetachEvent(GameEventType.HomeBuildOnSelectBuilding, self.HomeBuildOnSelectBuilding)
    self:DetachEvent(GameEventType.UIHomelandMoviePrepareActorSelected, self.OnNextBtnStateChange)
end

--获取ui组件
function UIHomelandMoviePrepareMainController:InitWidget()
    ---@type UnityEngine.GameObject
    self.topBtn = self:GetGameObject("topBtn")
    ---@type UICustomWidgetPool
    self.stages = self:GetUIComponent("UISelectObjectPath", "stages")
    ---@type UnityEngine.GameObject
    self.stageOperate = self:GetGameObject("stageOperate")
    ---@type UnityEngine.GameObject
    self.stageContent = self:GetGameObject("stageContent")
    ---@type UnityEngine.RectTransform
    self.arrowBtn = self:GetUIComponent("RectTransform", "arrowBtn")
    ---@type UICustomWidgetPool
    self.freeStagePool = self:GetUIComponent("UISelectObjectPath", "freeStagePool")
    ---@type UICustomWidgetPool
    self.otherStagePool = self:GetUIComponent("UISelectObjectPath", "otherStagePool")

    ---@type UnityEngine.GameObject
    self.prepareGo = self:GetGameObject("prepare")

    ---@type UnityEngine.GameObject
    self.mobileControlGo = self:GetGameObject("mobileBuildControl")

    ---@type UnityEngine.GameObject
    self.operateGo = self:GetGameObject("operate")

    ---@type UICustomWidgetPool
    local mobilePool = self:GetUIComponent("UISelectObjectPath", "mobileBuildControl")
    ---@type UIWidgetHomelandBuildController
    self.mobileControl = mobilePool:SpawnObject("UIWidgetHomelandBuildController")
    ---@type UICustomWidgetPool
    local operatePool = self:GetUIComponent("UISelectObjectPath", "operate")
    ---@type UIHomelandBuildEditOperate
    self.operate = operatePool:SpawnObject("UIHomelandBuildEditOperate")

    ---@type UILocalizationText
    self.txtNext = self:GetUIComponent("UILocalizationText", "txtNext")

    ---@type UISelectObjectPath
    self._phasePanel = self:GetUIComponent("UISelectObjectPath","phasePanel")
    self._phasePanelGo = self:GetGameObject("phasePanel")
    self._phasePanelRect = self:GetUIComponent("RectTransform","phasePanel")

    ---@type Animation
    self._animation = self:GetUIComponent("Animation", "animation")
end

function UIHomelandMoviePrepareMainController:_OnValue()
    self.furnitureWidget = self.freeStagePool:SpawnObject("UIHomelandMoviePrepareFurniture")
    self.otherWidget = self.otherStagePool:SpawnObject("UIHomelandMoviePrepareSelectItem")
    self.otherWidget:SetPhasePanel (self._phasePanel,self._phasePanelRect)

    self.furnitureWidget:SetUIWidgetHomelandBuildController(self.mobileControl)
    
    self.fatherBuilding = MoviePrepareData:GetInstance():GetFatherBuild()

    local len = table.count(self.stagesConfig)
    self.stages:SpawnObjects("PrepareStageItem",len)
    local items = self.stages:GetAllSpawnList()
    for idx, subItem in pairs(items) do
        local subConfig = self.stagesConfig[idx]
        subItem:SetData(subConfig.name, subConfig.prepareType, function (item)
            self:OnStageItemClicked(item)
        end)
        self.stageItems[subConfig.prepareType] = subItem

        if idx == 1 then
            self.curPrepareStageItem = subItem
            self.curPrepareType = self.curPrepareStageItem:GetPrepareType()
            self.curPrepareStageItem:SetSelect(true) -- 默认选中第一个
        else
            subItem:SetSelect(false)
        end
    end
    
    self:ChangeStageContent(nil, self.curPrepareType)
end

---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareMainController:GetPrepareWidget(prepareType)
    if prepareType == MoviePrepareType.PT_Furniture then
        return self.furnitureWidget
    else
        return self.otherWidget
    end
end

function UIHomelandMoviePrepareMainController:OnStageItemClicked(item)
    if item == self.curPrepareStageItem then
        return
    end
    if self.curPrepareStageItem then
        self.curPrepareStageItem:SetSelect(false)
    end
    local lastType = self.curPrepareType
    local newType = item:GetPrepareType()
    item:SetSelect(true)
    self.curPrepareStageItem = item
    self.curPrepareType = newType
    self:ChangeStageContent(lastType, newType)
    self:RefreshNextBtnColor()
end

---@param lastType  MoviePrepareType
---@param curType MoviePrepareType
function UIHomelandMoviePrepareMainController:ChangeStageContent(lastType, curType)
    if lastType then
        if lastType == MoviePrepareType.PT_Furniture then
            self.furnitureWidget:OnExit(lastType)
        else
            self.otherWidget:OnExit(lastType)   
        end  
        self._animation:Play("UIHomelandMoviePrepareMainController_up")
    end

    self.mobileControlGo:SetActive(curType == MoviePrepareType.PT_Furniture)

    if curType == MoviePrepareType.PT_Furniture then
        self.furnitureWidget:GetGameObject():SetActive(true)
        self.otherWidget:GetGameObject():SetActive(false)
        self.furnitureWidget:OnEnter(curType)
        self.homelandClient:SetLockGlobalCamera(nil)
        self.homelandClient:BuildManager():SetBuildEditorMode(BuildEditorMode.MakeMovieFree)
        self._phasePanelGo:SetActive(false)
       -- self._animation:Play("UIHomelandMoviePrepareMainController_star")
    else
        self.furnitureWidget:GetGameObject():SetActive(false)
        self.otherWidget:GetGameObject():SetActive(true)
        self.otherWidget:OnEnter(curType)
        self.homelandClient:SetLockGlobalCamera(true)
        self.homelandClient:BuildManager():SetBuildEditorMode(BuildEditorMode.MakeMovieOther)
        self._camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
        self.otherWidget:SetCamera(self._camera)
        self._phasePanelGo:SetActive(true)
        self.otherWidget:ClearSelectBtns()
    end
    local callBack = function() 
        if curType ~= MoviePrepareType.PT_Furniture then 
           self.otherWidget:RefreshSelectBtns()
        end 
    end 
    if self._hasEnter then
        self.mUIHomeland:FocusPreparePoint(self.fatherBuilding,curType,callBack)
    else
        self._hasEnter = true
        self.mUIHomeland:FocusPreparePointDirect(self.fatherBuilding,curType,callBack)
    end
    self:RefreshArrowPos()
end


--返回按钮点击
function UIHomelandMoviePrepareMainController:BackBtnOnClick(go)
    local Exit = function()
        self:StartTask(self._Exit, self)
    end

    local title = nil
    local desc = StringTable.Get("str_movie_prepare_back_tips")
    local leftBtn = {
        StringTable.Get("str_common_cancel"),
        function(param)
        end
    }

    local rightBtn = {
        StringTable.Get("str_common_ok"),
        function()
            Exit()
        end
    }
    self:ShowDialog("UIHomelandMessageBox", title, desc, leftBtn, rightBtn, true)  
end

function UIHomelandMoviePrepareMainController:_Exit(TT)
    self:Lock("HomeExitBuildMode")
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIHomeMovieStoryController .. "DirectIn",
        function()
            self:SwitchState(UIStateType.UIHomeland)
            -- while GameGlobal.UIStateManager():CurUIStateType() ~= UIStateType.UIHomeland do
            --     YIELD(TT)
            -- end
            
            CutsceneManager.ExcuteCutsceneOut()
            self:UnLock("HomeExitBuildMode")
        end
    )

    self.mUIHomeland:RestoreFreeChildrenInScene(MoviePrepareData:GetInstance():GetFatherBuild())
    self.mUIHomeland:ShowHightLightFreeArea(self.fatherBuilding, false)
    HomelandMoviePrepareManager:GetInstance():ClearAll() 
    HomelandMoviePrepareManager:GetInstance():Dispose()
    self.homelandClient:SetLockGlobalCamera(nil)
    self.homelandClient:FinishBuild(TT)
    AudioHelperController.PlayBGM(CriAudioIDConst.BGMEnterHomeland, AudioConstValue.BGMCrossFadeTime)
end

--剧情介绍按钮点击
function UIHomelandMoviePrepareMainController:IntroduceBtnOnClick(go)
    local movieId = MoviePrepareData:GetInstance():GetMovieId()
    self:ShowDialog("UIHomelandMovieIntroduceController", movieId)
end

--清空按钮点击
function UIHomelandMoviePrepareMainController:ClearBtnOnClick(go)

    local title = nil
    local desc = self:GetClearTipsContent()
    local leftBtn = {
        StringTable.Get("str_common_cancel"),
        function(param)
        end
    }

    local rightBtn = {
        StringTable.Get("str_common_ok"),
        function()
            if self.curPrepareType == MoviePrepareType.PT_Furniture then
                self.furnitureWidget:Clear(self.curPrepareType)
            else
                self.otherWidget:Clear(self.curPrepareType)
                self.otherWidget:RefreshSelectBtns()
            end
        end
    }
    self:ShowDialog("UIHomelandMessageBox", title, desc, leftBtn, rightBtn, true)
end

function UIHomelandMoviePrepareMainController:GetClearTipsContent()
    if self.curPrepareType == MoviePrepareType.PT_Scene then
        return StringTable.Get("str_movie_prepare_clear_scene_tips")
    elseif self.curPrepareType == MoviePrepareType.PT_Prop then
        return StringTable.Get("str_movie_prepare_clear_prop_tips")
    elseif self.curPrepareType == MoviePrepareType.PT_Furniture then
        return StringTable.Get("str_movie_prepare_clear_furniture_tips")
    elseif self.curPrepareType == MoviePrepareType.PT_Actor then
        return StringTable.Get("str_movie_prepare_clear_actor_tips")
    else
        return nil
    end
end

--下一步按钮点击
function UIHomelandMoviePrepareMainController:NextBtnOnClick(go)
    if self.curPrepareType == MoviePrepareType.PT_Actor then
        if self.otherWidget:CheckExit(self.curPrepareType) then
            --最终确认
            self:ShowDialog("UIHomelandMovieActionController")
        else
            --tips
            ToastManager.ShowHomeToast(StringTable.Get("str_movie_prepare_actor_noenough"))
        end
        return
    end
    
    local nextType = self.curPrepareType + 1
    local nextItem = self.stageItems[nextType]
    if nextItem then
        self:OnStageItemClicked(nextItem)
    end
end

function UIHomelandMoviePrepareMainController:RefreshNextBtnColor()
    local enable = true
    if self.curPrepareType == MoviePrepareType.PT_Actor then
        enable = self.otherWidget:CheckExit(self.curPrepareType)
    end
    
    if enable then
        self.txtNext.color = self.nextColorEnable
    else
        self.txtNext.color = self.nextColorDisable
    end
end

function UIHomelandMoviePrepareMainController:OnNextBtnStateChange(state)
    self:RefreshNextBtnColor()
end

--列表箭头按钮点击
function UIHomelandMoviePrepareMainController:ArrowBtnOnClick(go)
    if self.stageContent.activeInHierarchy then
        self.stageContent:SetActive(false)
        self.arrowBtn.anchoredPosition = Vector2(-57, 83)
        self.arrowBtn.localScale = Vector3(1, -1, 1)
    else
        self.stageContent:SetActive(true)
        local h = self:GetArrowTopHeight()
        self.arrowBtn.anchoredPosition = Vector2(-57, h)
        self.arrowBtn.localScale = Vector3.one
    end
end

function UIHomelandMoviePrepareMainController:RefreshArrowPos()
    if self.stageContent.activeInHierarchy then
        local h = self:GetArrowTopHeight()
        self.arrowBtn.anchoredPosition = Vector2(-57, h)
    end
end

function UIHomelandMoviePrepareMainController:GetArrowTopHeight()
    if self.curPrepareType == MoviePrepareType.PT_Furniture then
        return 407
    else
        return 315
    end
end


function UIHomelandMoviePrepareMainController:HomeBuildOnSelectBuilding()
    local homeBuilding = self.homeBuildManager:GetCurrentBuilding()
    if homeBuilding then
        self.prepareGo:SetActive(false)
        self.operateGo:SetActive(true)
        self.operate:FlushOperate()
    else
        self.prepareGo:SetActive(true)
        self.operateGo:SetActive(false)
        self.furnitureWidget:Refresh(self.curPrepareType)
    end
end