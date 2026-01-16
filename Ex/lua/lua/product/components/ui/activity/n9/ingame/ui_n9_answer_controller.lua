---@class UIN9AnswerController : UIController
_class("UIN9AnswerController", UIController)
UIN9AnswerController = UIN9AnswerController
function UIN9AnswerController:Constructor()
    self._lastBGMResName = AudioHelperController.GetCurrentBgm()
end
-- 答题状态枚举
--- @class UIN9AnswerType
local UIN9AnswerType = {
    OnReady = 1,
    OnAnswer = 2,
    OnOver  = 3,
    OnPause = 5,
}
_enum("UIN9AnswerType", UIN9AnswerType)
function UIN9AnswerController:OnShow(uiParams)
    self:InitWidget()
    
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    self._grad = uiParams[1]
    self._ingameDatas = UIN9ImGameData:New(uiParams[1])
    self._gameType = uiParams[1]:GetLevelType()
    self._gradData =  uiParams[2] or {}
    self._scrollViewInited = false
    self._questionIndex = 0
    self._updateTimer = nil
    self._perCount = 2 
    self._items = {}
    self._faultTolerantItems = {}
    self._pressing = false
    self:EnterState(UIN9AnswerType.OnReady)
end
function UIN9AnswerController:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.countDownText = self:GetUIComponent("UILocalizationText", "CountDownText")
    ---@type UIDynamicScrollView
    self.answerList = self:GetUIComponent("UIDynamicScrollView", "AnswerList")
    ---@type UICustomWidgetPool
    self.itemInfo = self:GetUIComponent("UISelectObjectPath", "ItemInfo")
    ---@type RawImageLoader
    self.bg = self:GetUIComponent("RawImageLoader", "Bg")
    ---@type UILocalizationText
    self.questionTipText = self:GetUIComponent("UILocalizationText", "QuestionTipText")
    ---@type UILocalizationText
    self.questionText = self:GetUIComponent("UILocalizationText", "QuestionText")
    ---@type UILocalizationText
    self.titleText = self:GetUIComponent("UILocalizationText", "TitleText")
    ---@type UILocalizationText
    self.readyCountDownText = self:GetUIComponent("UILocalizationText", "ReadyCountDownText")
    ---@type RawImageLoader
    self.lastDataAni = self:GetUIComponent("RawImageLoader", "LastDataAni")
    ---@type UILocalizationText
    self.lasttimes = self:GetUIComponent("UILocalizationText", "Lasttimes")
    ---@type UnityEngine.UI.Image
    self.pauseButton = self:GetUIComponent("Image", "PauseButton")
    ---@type UnityEngine.GameObject
    self.onReady = self:GetGameObject("OnReady")
    ---@type UnityEngine.GameObject
    self.letfRoot = self:GetGameObject("LetfRoot")
    ---@type UnityEngine.GameObject
    self.answerListGo = self:GetGameObject("AnswerList")
    ---@type UnityEngine.GameObject
    self.onPause = self:GetGameObject("OnPause")
    ---@type RawImageLoader
    self.answerbg = self:GetUIComponent("RawImageLoader", "Answerbg")
    ---@type UnityEngine.GameObject
    self.onAnswer = self:GetGameObject("OnAnswer")
    ---@type UnityEngine.GameObject
    self.group = self:GetGameObject("Group")
    ---@type UnityEngine.GameObject
    self.spine = self:GetGameObject("Spine")
    ---@type UILocalizationText
    self.questionTipTexProcess = self:GetUIComponent("UILocalizationText", "QuestionTipTexProcess")
    
    -- 动画相关
    self.numAniObgs = {}
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDownText"), self:GetUIComponent("UILocalizationText", "ReadyCountDownText")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDownText (1)"), self:GetUIComponent("UILocalizationText", "ReadyCountDownText (1)")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDownText (2)"), self:GetUIComponent("UILocalizationText", "ReadyCountDownText (2)")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDownText (3)"), self:GetUIComponent("UILocalizationText", "ReadyCountDownText (3)")})

    self.onReadyAnim = self:GetUIComponent("Animation", "OnReady")
    self.onAnswerAnim = self:GetUIComponent("Animation", "OnAnswer")
    self.countDownAnim = self:GetUIComponent("Animation", "CountDown")
    self.arrAnim = self:GetUIComponent("Animation", "Arr")
    self:AttachEvent(GameEventType.OnN9PauseClick, self.OnN9PauseClick)
    --generated end--
end

function UIN9AnswerController:OnHide()

    self.countDownTime = 0 
    self._svrTimeModule = nil 
    self._ingameDatas = nil 
    self._scrollViewInited = false 

    if self._updateTimer then
        self._updateTimer = nil
    end
    self._items = nil
    self._faultTolerantItems = nil
    self._pressing = false
    self:DetachEvent(GameEventType.OnN9PauseClick, self.OnN9PauseClick)
    AudioHelperController.PlayBGM(self._lastBGMResName, AudioConstValue.BGMCrossFadeTime)
end

function UIN9AnswerController:PauseButtonOnClick(go)
    self:EnterState(UIN9AnswerType.OnPause)
end
function UIN9AnswerController:NextButtonOnClick(go)
  
end

function UIN9AnswerController:QuitButtonOnClick(go)

end
function UIN9AnswerController:_ChangeState()
    self._curTypeEnum = self._curTypeEnum + 1 
end 

--进入 对应状态
function UIN9AnswerController:EnterState(nState)

    self._curTypeEnum = nState

    self:_ShowState() 

    if self._curTypeEnum == UIN9AnswerType.OnReady or self._curTypeEnum == UIN9AnswerType.OnAnswer then
        if self._updateTimer then
            self._updateTimer = nil
        end
        local interTime =  self._ingameDatas:GetTimeInter(nState)
        self.countDownTime =  interTime
        self:ShowTime()
        if self._curTypeEnum == UIN9AnswerType.OnReady then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1GameStart)
        end
        -- 匹配动画显示
        interTime = self._curTypeEnum == UIN9AnswerType.OnReady and interTime or interTime + 1
        self._updateTimer = UpdatTimer:New(interTime,1,function () self:ShowTime() end )
        self._updateTimer:SetEndEvent(function () self:OnStateOver() end )
    end

    if self._curTypeEnum == UIN9AnswerType.OnOver then 
        if self._updateTimer then 
            self._updateTimer = nil
            return 
        end 
    end 
    
    if self._curTypeEnum == UIN9AnswerType.OnPause then 
        if self._updateTimer then 
            self._updateTimer:SetPause(true) 
        end 
    end 
end

function UIN9AnswerController:OnStateOver()
    if self._updateTimer then
        self._updateTimer = nil
        self._pressing = false
    end
    if self._curTypeEnum == UIN9AnswerType.OnAnswer then 
        self:_OnNoSelectAnswer() 
    elseif self._curTypeEnum == UIN9AnswerType.OnReady then
        self:_ChangeState()
        self:EnterState(self._curTypeEnum)
    end 
end 
-- 展示时间信息
function UIN9AnswerController:ShowTime() 
    if self.countDownTime >= 0  then 
        self.countDownTime = self.countDownTime - 1 
        local showCount = self.countDownTime + 1 
        for i,v in pairs(self.numAniObgs) do 
            v[2]:SetText(showCount)
        end

        if showCount > 1 then 
            self.onReadyAnim:Play("uieff_Answer_Ready")
        else
            self.onReadyAnim:Play("uieff_Answer_Start")  
            self:StartTask(
                function(TT)
                    --YIELD(TT, 500)
                    --self.onAnswerAnim:Play("uieff_Answer_Answer_In")
                end,
                self
            )
        end 

        if self._curTypeEnum == UIN9AnswerType.OnReady then
            self.readyCountDownText:SetText(showCount)
            self.titleText:SetText(StringTable.Get("str_activity_n9_onready"))
        end
        if self._curTypeEnum == UIN9AnswerType.OnAnswer then
            self.countDownText:SetText(showCount)
        end 
    end 
end 

function UIN9AnswerController:StateIsChanged(nState) 
   return self._curTypeEnum == nState
end 

function UIN9AnswerController:_ShowState() 
    self.onReady:SetActive(self._curTypeEnum  == UIN9AnswerType.OnReady)
    self.letfRoot:SetActive(self._curTypeEnum  ~= UIN9AnswerType.OnReady)
    self.onAnswer:SetActive(self._curTypeEnum  ~= UIN9AnswerType.OnReady)
    self.onPause:SetActive(false)

    if self._curTypeEnum == UIN9AnswerType.OnReady then
        self:_ShowOnReady() 
     
    elseif self._curTypeEnum == UIN9AnswerType.OnAnswer then
        self:_ShowOnAnswer() 

    elseif self._curTypeEnum == UIN9AnswerType.OnPause then
        self:ShowDialog("UIN9AnswerOnPauseController")

    elseif self._curTypeEnum == UIN9AnswerType.OnOver then
        self:_ShowOnOver() 

    end 
end 
-- 帧更新逻辑
function UIN9AnswerController:OnUpdate(deltaTimeMS) 
    if self._updateTimer  then 
        if  (not self._pressing) and  self._updateTimer:GetLastTime() <= 5 and self._curTypeEnum == UIN9AnswerType.OnAnswer then 
            self:_LoadSpine(4)
            self._pressing = true
        end 
        self._updateTimer:OnUpdateEvent(deltaTimeMS* 0.001)
    end 
end

function UIN9AnswerController:_ShowOnReady() 
    self:_CreateFaultTolerants()
end 


function UIN9AnswerController:_ShowOnPause() 
  
end 

function UIN9AnswerController:_ShowOnAnswer() 
    --self.onAnswerAnim:Play("uieff_Answer_Answer_Switch1")
    self.countDownAnim:Stop()
    self.countDownAnim:Play("uieff_CountDown")
   -- self.arrAnim:Play("uieff_Arr")
    self:StartTask(
        function(TT)
            YIELD(TT, 100)
            self:_InitQuests()
            if not  self._scrollViewInited then 
                self:_InitScrollView()
            else  
                self.answerList:RefreshAllShownItem()
            end 
        
            self:_ShowFaultTolerant()
            self.onAnswerAnim:Play("uieff_Answer_Answer_Switch2")
        end,
        self
    )
  
    self:_LoadSpine(1)
end 

function UIN9AnswerController:_ShowOnOver()
    self:Lock("UIN9AnswerController")
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UIN9AnswerController")
            self:ShowDialog("UIN9ResultController",self._grad,self._ingameDatas,self._gradData)
        end,
        self
    )
end 
function UIN9AnswerController:_InitQuests() 
    local quest =  self._ingameDatas:GetOneQuestion()
    if not quest then return  end 
    self._questionIndex = self._questionIndex + 1 
    self.questionTipText:SetText(StringTable.Get("str_activity_n9_questiontitle",self._questionIndex)) 
    self.questionText:SetText(quest:GetDes()) 
    self.questionTipTexProcess:SetText(StringTable.Get("str_activity_n9_questiontip",self._questionIndex,self._ingameDatas:GetTotalCount())) 
end 

function UIN9AnswerController:CalcPetScrollViewCount()
    self._listShowItemCount = math.ceil(self._ingameDatas:GetAnswerCount() / self._perCount)
    return self._listShowItemCount
end

function UIN9AnswerController:_InitScrollView()
    self.answerList:InitListView(
        self:CalcPetScrollViewCount(),
        function(scrollView, index)
            return self:_OnGetUIN9AnswerItem(scrollView, index)
        end,
        self:GetScrollViewParam()
    )
    self._scrollViewInited = true 
end

function UIN9AnswerController:GetScrollViewParam()
    local param = UIDynamicScrollViewInitParam:New()
    param.mItemDefaultWithPaddingSize = 50
    return param
end

function UIN9AnswerController:_OnGetUIN9AnswerItem(scrollView, index)
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    rowPool:SpawnObjects("UIN9AnswerItem", self._perCount)
    local rowList = rowPool:GetAllSpawnList()
     for i = 1, self._perCount do
        local itemWidget = rowList[i]
        local itemIndex = index * self._perCount + i
        if itemIndex > self._ingameDatas:GetAnswerCount() then
            itemWidget:GetGameObject():SetActive(false)
        else
            self:_RefreshAnswerItemInfo(itemWidget, itemIndex)
            self._items[itemIndex] = itemWidget
        end
    end
    UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end

function UIN9AnswerController:_GetAnswerData(index)
    local data = self._ingameDatas:GetCurQuestion():GetOptions()
    return data[index]
end 
function UIN9AnswerController:_RefreshAnswerItemInfo(itemWidget, index)
    -- index 从1开始
    itemWidget:SetData(index,function(index) self:OnSelectAnswer(index) end )
    itemWidget:Refresh( self:_GetAnswerData(index))
end
function UIN9AnswerController:_OnNoSelectAnswer() 
    self:OnSelectAnswer(0) 
end 

function UIN9AnswerController:OnSelectAnswer(nIndex) 
    local bSelet,rightAnswerIndex = self:_SetSelectData(nIndex) 
    self:_LoadSpine(bSelet == 1 and 2 or 3)
    if self._updateTimer then
        self._updateTimer = nil
    end
    local timer = 1000
    if bSelet == 0 then
        timer = 1500
    else 
        timer = 1500
    end 
    self:StartTask(
        function(TT)
            self:Lock("UIN9AnswerController:OnSelectAnswer")
            YIELD(TT, timer)
            
            self:_ChangeState()
            if self._curTypeEnum ==  UIN9AnswerType.OnOver and self._ingameDatas:GetLastCount() > 0 then 
                self._curTypeEnum = UIN9AnswerType.OnAnswer      
            end 
            self:EnterState(self._curTypeEnum)
            self:UnLock("UIN9AnswerController:OnSelectAnswer")
        end
    )
end
-- 处理选择后逻辑
function UIN9AnswerController:_SetSelectData(nIndex) 
    local nState = self._ingameDatas:GetAnswerState(nIndex)
    local rightAnswerIndex = self._ingameDatas:GetCurQuestion():GetAnswerIndex()
    local bSelet = 0
    local isRight = 0
    if nState == 1  then 
        bSelet = 1 
        isRight = 1
        self._ingameDatas:SetTrueRight(self._questionIndex ,bSelet)
    elseif nState == 2  then 
        bSelet = 1 
    else 
        self:_ChangeState()
        self:EnterState(self._curTypeEnum)
    end 
    self:_ShowFaultTolerant() 
    self:_ShowRightAnswer(rightAnswerIndex,nIndex) 
    self._ingameDatas:SetSelects(self._questionIndex ,bSelet)
    return isRight,rightAnswerIndex
end 

function UIN9AnswerController:_ShowFaultTolerant() 
   -- self.lasttimes:SetText(self._ingameDatas:GetFaultTolerantCount())
   self:_RefreshFaultTolerantItem()
end 

function UIN9AnswerController:_ShowRightAnswer(rightIndex,seletIndex) 
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN9SelectClick,rightIndex,seletIndex)
end 
function UIN9AnswerController:_ShowAnswerAnimation() 
    -- self.lastDataAni 
 end
 
function UIN9AnswerController:_SwitchBg() 
    -- self.answerbg:LoadImage("n6_home_bg1_kv2")
end    

function UIN9AnswerController:_CreateFaultTolerants() 
    local rowPool  = self:GetUIComponent("UISelectObjectPath", "Group")
    rowPool:SpawnObjects("UIN9FaultTolerantItem", self._ingameDatas:GetDefultFaultTolerantCount())
    local rowList = rowPool:GetAllSpawnList()
    self._faultTolerantItems = rowList
    for i = 1,#rowList do
        rowList[i]:SetData(i)
        rowList[i]:Refresh()
    end
end    


function UIN9AnswerController:_RefreshFaultTolerantItem()
    if not  self._faultTolerantItems then  return end 
    local count = self._ingameDatas:GetDefultFaultTolerantCount()
    local usedCount = count - self._ingameDatas:GetFaultTolerantCount()
    for i = 1,count do
        if i <= usedCount then 
            local itemWidget = self._faultTolerantItems[i]
            itemWidget:SetUsed(true )
            if usedCount == i then
                itemWidget:PlayeAni()
            end 
        end 
    end
end    

function UIN9AnswerController:SetFontMat(lable,resname) 
    local res = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    if not res  then return end 
    local obj  = res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end 
-- 1 思考 2 正确 3 错误
function UIN9AnswerController:_LoadSpine(nState)
    local spineName = "nuoweiya_n9_spine_idle"
    local aniName = "Story_norm"
    if nState == 1 then 
        aniName = "Story_norm"
    elseif nState == 2  then 
        aniName = "Story_happy"
    elseif nState == 3  then 
        aniName = "Story_sad"
    elseif nState == 4  then 
        aniName = "Story_press"
    end 
    if string.isnullorempty(spineName) then
        return
    end
    self._spine = self:GetUIComponent("SpineLoader", "Spine")
    if not self._spineSke then 
        self._spine:LoadSpine(spineName)
    end 
    if self._spine then
        self._spineSke = self._spine.CurrentSkeleton
        if not self._spineSke then
            self._spineSke = self._spine.CurrentMultiSkeleton
        end
        if self._spineSke then
            self._spineSke.AnimationState:SetAnimation(0, aniName, true)
        end
    end
end

function UIN9AnswerController:OnN9PauseClick(goAhead) 
    if goAhead then 
        if self._curTypeEnum == UIN9AnswerType.OnPause then 
            self._curTypeEnum = UIN9AnswerType.OnAnswer
            if self._updateTimer then 
                self._updateTimer:SetPause(false)
            end 
        end 
    else 
        if self._updateTimer then
            self._updateTimer = nil
        end
        self._curTypeEnum = UIN9AnswerType.OnOver
        self:EnterState(self._curTypeEnum)
    end 
end 
 
