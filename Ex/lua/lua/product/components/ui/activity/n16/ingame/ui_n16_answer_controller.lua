---@class UIN16AnswerController : UIController
_class("UIN16AnswerController", UIController)
UIN16AnswerController = UIN16AnswerController
function UIN16AnswerController:Constructor()
    self._lastBGMResName = AudioHelperController.GetCurrentBgm()
end
-- 答题状态枚举
--- @class UIN16AnswerType
local UIN16AnswerType = {
    OnReady = 1,
    OnAnswer = 2,
    OnOver  = 3,
    OnPause = 5,
}
_enum("UIN16AnswerType", UIN16AnswerType)


function UIN16AnswerController:LoadDataOnEnter(TT, res, uiParams) 
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N16,
        ECampaignN16ComponentID.ECAMPAIGN_N16_ANSWER_GAME
    )
end
function UIN16AnswerController:OnShow(uiParams)
    self:InitWidget()
    
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    self._grad = uiParams[1]
    self._ingameDatas = UIN16ImGameData:New(uiParams[1])
    self._gameType = uiParams[1]:GetLevelType()
    self._gradData =  uiParams[2] or {}
    self._scrollViewInited = false
    self._questionIndex = 0
    self._updateTimer = nil
    self._perCount = 2 
    self._items = {}
    self._faultTolerantItems = {}
    self._pressing = false
    self:EnterState(UIN16AnswerType.OnReady)
end
function UIN16AnswerController:InitWidget()
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
    self.titleText = self:GetUIComponent("UILocalizedTMP", "TitleText")
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
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDown0"), self:GetUIComponent("Image", "ReadyCountDown0")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDown1"), self:GetUIComponent("Image", "ReadyCountDown1")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDown2"), self:GetUIComponent("Image", "ReadyCountDown2")})
    table.insert(self.numAniObgs,{self:GetGameObject("ReadyCountDown3"), self:GetUIComponent("Image", "ReadyCountDown3")})

    self.onReadyAnim = self:GetUIComponent("Animation", "OnReady")
    self.onAnswerAnim = self:GetUIComponent("Animation", "OnAnswer")
    self.countDownAnim = self:GetUIComponent("Animation", "CountDown")
    self.arrAnim = self:GetUIComponent("Animation", "Arr")
    self:AttachEvent(GameEventType.OnN16PauseClick, self.OnN16PauseClick)
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityClose)
    self:SetFontMat(self.titleText,"uieff_n16_ingame_detial1.mat") 
    --generated end--
end

function UIN16AnswerController:OnHide()

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
    self:DetachEvent(GameEventType.OnN16PauseClick, self.OnN16PauseClick)
    self:DetachEvent(GameEventType.ActivityCloseEvent, self.OnActivityClose)
    AudioHelperController.PlayBGM(self._lastBGMResName, AudioConstValue.BGMCrossFadeTime)
end

function UIN16AnswerController:PauseButtonOnClick(go)
    self:EnterState(UIN16AnswerType.OnPause)
end
function UIN16AnswerController:NextButtonOnClick(go)
  
end

function UIN16AnswerController:QuitButtonOnClick(go)

end
function UIN16AnswerController:_ChangeState()
    self._curTypeEnum = self._curTypeEnum + 1 
end 

--进入 对应状态
function UIN16AnswerController:EnterState(nState)
    if self._close then 
       return 
    end 
    self._curTypeEnum = nState
     
    self:_ShowState() 

    if self._curTypeEnum == UIN16AnswerType.OnReady or self._curTypeEnum == UIN16AnswerType.OnAnswer then
        if self._updateTimer then
            self._updateTimer = nil
        end
        local interTime =  self._ingameDatas:GetTimeInter(nState)
        self.countDownTime =  interTime
        self:ShowTime()
        if self._curTypeEnum == UIN16AnswerType.OnReady then
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1GameStart)
        end
        -- 匹配动画显示
        interTime = self._curTypeEnum == UIN16AnswerType.OnReady and interTime or interTime + 1
        self._updateTimer = UpdatTimer:New(interTime,1,function () self:ShowTime() end )
        self._updateTimer:SetEndEvent(function () self:OnStateOver() end )
    end

    if self._curTypeEnum == UIN16AnswerType.OnOver then 
        if self._updateTimer then 
            self._updateTimer = nil
            return 
        end 
    end 
    
    if self._curTypeEnum == UIN16AnswerType.OnPause then 
        if self._updateTimer then 
            self._updateTimer:SetPause(true) 
        end 
    end 
end

function UIN16AnswerController:OnStateOver()
    if self._updateTimer then
        self._updateTimer = nil
        self._pressing = false
    end
    if self._curTypeEnum == UIN16AnswerType.OnAnswer then 
        self:_OnNoSelectAnswer() 
    elseif self._curTypeEnum == UIN16AnswerType.OnReady then
        self:_ChangeState()
        self:EnterState(self._curTypeEnum)
    end 
end 
-- 展示时间信息
function UIN16AnswerController:ShowTime() 
    if self.countDownTime >= 0  then 
        self.countDownTime = self.countDownTime - 1 
        local showCount = self.countDownTime + 2
        for i,v in pairs(self.numAniObgs) do 
            v[2].gameObject:SetActive( i == showCount)
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

        if self._curTypeEnum == UIN16AnswerType.OnReady then
           -- self.readyCountDownText:SetText(showCount)
            self.titleText:SetText(StringTable.Get("str_activity_n16_onready"))
        end
        if self._curTypeEnum == UIN16AnswerType.OnAnswer then
            self.countDownText:SetText(showCount)
        end 
    end 
end 

function UIN16AnswerController:StateIsChanged(nState) 
   return self._curTypeEnum == nState
end 

function UIN16AnswerController:_ShowState() 
    self.onReady:SetActive(self._curTypeEnum  == UIN16AnswerType.OnReady)
    self.letfRoot:SetActive(self._curTypeEnum  ~= UIN16AnswerType.OnReady)
    self.onAnswer:SetActive(self._curTypeEnum  ~= UIN16AnswerType.OnReady)
    self.onPause:SetActive(false)

    if self._curTypeEnum == UIN16AnswerType.OnReady then
        self:_ShowOnReady() 
     
    elseif self._curTypeEnum == UIN16AnswerType.OnAnswer then
        self:_ShowOnAnswer() 

    elseif self._curTypeEnum == UIN16AnswerType.OnPause then
        self:ShowDialog("UIN16AnswerOnPauseController")

    elseif self._curTypeEnum == UIN16AnswerType.OnOver then
        self:_ShowOnOver() 

    end 
end 
-- 帧更新逻辑
function UIN16AnswerController:OnUpdate(deltaTimeMS) 
    if self._updateTimer  then 
        if  (not self._pressing) and  self._updateTimer:GetLastTime() <= 5 and self._curTypeEnum == UIN16AnswerType.OnAnswer then 
            self:_LoadSpine(4)
            self._pressing = true
        end 
        self._updateTimer:OnUpdateEvent(deltaTimeMS* 0.001)
    end 
end

function UIN16AnswerController:_ShowOnReady() 
    self:_CreateFaultTolerants()
end 


function UIN16AnswerController:_ShowOnPause() 
  
end 

function UIN16AnswerController:_ShowOnAnswer() 
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

function UIN16AnswerController:_ShowOnOver()
    self:Lock("UIN16AnswerController")
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UIN16AnswerController")
            self:ShowDialog("UIN16ResultController",self._grad,self._ingameDatas,self._gradData)
        end,
        self
    )
end 
function UIN16AnswerController:_InitQuests() 
    local quest =  self._ingameDatas:GetOneQuestion()
    if not quest then return  end 
    self._questionIndex = self._questionIndex + 1 
    self.questionTipText:SetText(StringTable.Get("str_activity_n16_questiontitle",self._questionIndex)) 
    self.questionText:SetText(quest:GetDes()) 
    self.questionTipTexProcess:SetText(StringTable.Get("str_activity_n16_questiontip",self._questionIndex,self._ingameDatas:GetTotalCount())) 
end 

function UIN16AnswerController:CalcPetScrollViewCount()
    self._listShowItemCount = math.ceil(self._ingameDatas:GetAnswerCount() / self._perCount)
    return self._listShowItemCount
end

function UIN16AnswerController:_InitScrollView()
    self.answerList:InitListView(
        self:CalcPetScrollViewCount(),
        function(scrollView, index)
            return self:_OnGetUIN16AnswerItem(scrollView, index)
        end,
        self:GetScrollViewParam()
    )
    self._scrollViewInited = true 
end

function UIN16AnswerController:GetScrollViewParam()
    local param = UIDynamicScrollViewInitParam:New()
    param.mItemDefaultWithPaddingSize = 50
    return param
end

function UIN16AnswerController:_OnGetUIN16AnswerItem(scrollView, index)
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    rowPool:SpawnObjects("UIN16AnswerItem", self._perCount)
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

function UIN16AnswerController:_GetAnswerData(index)
    local data = self._ingameDatas:GetCurQuestion():GetOptions()
    return data[index]
end 
function UIN16AnswerController:_RefreshAnswerItemInfo(itemWidget, index)
    -- index 从1开始
    itemWidget:SetData(index,function(index) self:OnSelectAnswer(index) end )
    itemWidget:Refresh( self:_GetAnswerData(index))
end
function UIN16AnswerController:_OnNoSelectAnswer() 
    self:OnSelectAnswer(0) 
end 

function UIN16AnswerController:OnSelectAnswer(nIndex) 
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
            self:Lock("UIN16AnswerController:OnSelectAnswer")
            YIELD(TT, timer)
            
            self:_ChangeState()
            if self._curTypeEnum ==  UIN16AnswerType.OnOver and self._ingameDatas:GetLastCount() > 0 then 
                self._curTypeEnum = UIN16AnswerType.OnAnswer      
            end 
            self:EnterState(self._curTypeEnum)
            self:UnLock("UIN16AnswerController:OnSelectAnswer")
        end
    )
end
-- 处理选择后逻辑
function UIN16AnswerController:_SetSelectData(nIndex) 
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

function UIN16AnswerController:_ShowFaultTolerant() 
   -- self.lasttimes:SetText(self._ingameDatas:GetFaultTolerantCount())
   self:_RefreshFaultTolerantItem()
end 

function UIN16AnswerController:_ShowRightAnswer(rightIndex,seletIndex) 
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN16SelectClick,rightIndex,seletIndex)
end 
function UIN16AnswerController:_ShowAnswerAnimation() 
    -- self.lastDataAni 
 end
 
function UIN16AnswerController:_SwitchBg() 
    -- self.answerbg:LoadImage("n6_home_bg1_kv2")
end    

function UIN16AnswerController:_CreateFaultTolerants() 
    local rowPool  = self:GetUIComponent("UISelectObjectPath", "Group")
    rowPool:SpawnObjects("UIN16FaultTolerantItem", self._ingameDatas:GetDefultFaultTolerantCount())
    local rowList = rowPool:GetAllSpawnList()
    self._faultTolerantItems = rowList
    for i = 1,#rowList do
        rowList[i]:SetData(i)
        rowList[i]:Refresh()
    end
end    


function UIN16AnswerController:_RefreshFaultTolerantItem()
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
-- 1 思考 2 正确 3 错误
function UIN16AnswerController:_LoadSpine(nState)
    local spineName = "jiaersi_n16_spine_idle"
    local aniName = "Story_norm"
    if nState == 1 then 
        aniName = "Story_norm"
    elseif nState == 2  then 
        aniName = "Story_smile"
    elseif nState == 3  then 
        aniName = "Story_snicker"
    elseif nState == 4  then 
        aniName = "Story_watchful"
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

function UIN16AnswerController:OnN16PauseClick(goAhead) 
    if goAhead then 
        if self._curTypeEnum == UIN16AnswerType.OnPause then 
            self._curTypeEnum = UIN16AnswerType.OnAnswer
            if self._updateTimer then 
                self._updateTimer:SetPause(false)
            end 
        end 
    else 
        if self._updateTimer then
            self._updateTimer = nil
        end
        self._curTypeEnum = UIN16AnswerType.OnOver
        self:EnterState(self._curTypeEnum)
    end 
end 

function UIN16AnswerController:SetFontMat(lable,resname) 

    local res = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    if not res  then 
       return 
    end 
    self._mat = res
    local obj  = res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end 

function UIN16AnswerController:OnActivityClose(id) 
    if self._campaign._id == id  then
        self._close = true
    end
end 

