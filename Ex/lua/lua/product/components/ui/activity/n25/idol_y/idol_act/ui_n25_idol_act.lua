---@class UIN25IdolAct:UIController
_class("UIN25IdolAct", UIController)
UIN25IdolAct = UIN25IdolAct
function UIN25IdolAct:Constructor()
end
function UIN25IdolAct:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign.New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N25,
        ECampaignN25ComponentID.ECAMPAIGN_N25_IDOL
    )

    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(
            res.m_result,
            function()
            end,
            function()
                self:SwitchState(UIStateType.UIMain)
            end
        )
    end
    ---@type IdolMiniGameComponent
    self.component = self._campaign:GetComponent(ECampaignN25ComponentID.ECAMPAIGN_N25_IDOL)
end
function UIN25IdolAct:OnShow(uiParams)
    self.forcePop = uiParams[1] or false
    
    self:GetComponents()
    
    self:OnValue()
end

function UIN25IdolAct:CreateData()
    --当前的三维
    local info = self.component:GetComponentInfo()
    local break_info = info.break_info
    local train_data = break_info.train_data
    self.singValue = train_data[IdolTrainType.IdolTrainType_Music] or 0
    self.danceValue = train_data[IdolTrainType.IdolTrainType_Dance] or 0
    self.performValue = train_data[IdolTrainType.IdolTrainType_Perform] or 0

    --获取配置偶像活动
    self.list = self.component:UI_GetWeekIdolAct()
end
function UIN25IdolAct:GetComponents()
    self.anim = self:GetUIComponent("Animation","SafeArea")

    self.tex = self:GetUIComponent("UILocalizationText","tex")

    self.nextWeek = self:GetGameObject("NextWeek")
    self.backBtnGo = self:GetGameObject("backBtn")

    self.widgetPools = {}
    self.pool1 = self:GetUIComponent("UISelectObjectPath","pool1")
    self.pool2 = self:GetUIComponent("UISelectObjectPath","pool2")
    self.pool3 = self:GetUIComponent("UISelectObjectPath","pool3")
    table.insert(self.widgetPools,self.pool1)
    table.insert(self.widgetPools,self.pool2)
    table.insert(self.widgetPools,self.pool3)
    
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtn")
    ---@type UICommonTopButton
    self.backBtns = backBtns:SpawnObject("UICommonTopButton")
    self.backBtns:SetData(
        function()
            self:CloseDialogAnim()
        end,nil,nil,true
    )
end
function UIN25IdolAct:OnValue()
    self:CreateData()

    self.nextWeek:SetActive(self.forcePop)
    self.backBtnGo:SetActive(not self.forcePop)
    local tex
    if self.forcePop then
        tex = StringTable.Get("str_n25_idol_y_act_title3")
    else
        tex = StringTable.Get("str_n25_idol_y_act_title2")
    end
    self.tex:SetText(tex)

    self:InitPool()
    self:PlayAnim()
end
function UIN25IdolAct:PlayAnim()
    CutsceneManager.ExcuteCutsceneOut()
    
    self:Lock("UIN25IdolAct:PlayAnim")

    self.anim:Play("uieff_UIN25IdolAct_in")
    GameGlobal.Timer():AddEvent(600,function()
        self:UnLock("UIN25IdolAct:PlayAnim")
    end)

    -- GameGlobal.Timer():AddEvent(500,function()
    --     self.anim:Play("uieff_UIN25IdolAct_in")
    --     GameGlobal.Timer():AddEvent(600,function()
    --         self:UnLock("UIN25IdolAct:PlayAnim")
    --     end)
    -- end)
end
function UIN25IdolAct:OnHide()
    self:UnLock("UIN25IdolAct:CloseDialogAnim")
    self:UnLock("UIN25IdolAct:PlayAnim")
end
function UIN25IdolAct:Refresh()
    self:OnValue()
end
function UIN25IdolAct:InitPool()
    local count = #self.list
    count = math.min(count, 3)

    for i = 1, count do
        local widget = self.widgetPools[i]
        local cfg = self.list[i]
        local status = self:GetStatus(cfg)

        ---@type UIN25IdolActItem
        local item = widget:SpawnObject("UIN25IdolActItem")
        item:SetData(self.component, cfg, status, function(id, status)
            self:FinishActivity(id, status)
        end)
    end
end
function UIN25IdolAct:GetStatus(cfg)
    local status
    local id = cfg.ActId
    local finish = self.component:UI_GetActFinishStatus(id)
    if finish then
        status = UIIdolStatus.Finish
    else
        status = UIIdolStatus.GoTo

        for trainType = IdolTrainType.IdolTrainType_Music, IdolTrainType.IdolTrainType_Perform do
            if not self.component:UI_CheckActLimit(cfg, trainType) then
                status = UIIdolStatus.Not
                break
            end
        end
    end
    return status
end
--开启一下周
function UIN25IdolAct:JumpBtnOnClick(go)
    --检测qa
    if self.list then
        for key, cfg in pairs(self.list) do
            local status = self:GetStatus(cfg)
            if status == UIIdolStatus.GoTo then
                local tips =StringTable.Get("str_n25_idol_y_act_open_next_not_tips")
                ToastManager.ShowToast(tips)
                return
            end
        end
    end

    --lxs idol todo
    --回到主界面
    --开启下一回合
    self:CloseDialogAnim()
end
function UIN25IdolAct:CloseDialogAnim()
    self:Lock("UIN25IdolAct:CloseDialogAnim")

    self.anim:Play("uieff_UIN25IdolAct_out")
    GameGlobal.Timer():AddEvent(333,function()
        self:UnLock("UIN25IdolAct:CloseDialogAnim")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.N25IdolGameNextDay,false,true)
        self:CloseDialog()
    end)    
end
function UIN25IdolAct:FinishActivity(id,status)
    if self.component then
        if status == UIIdolStatus.GoTo then
            self.finishID = id
            GameGlobal.TaskManager():StartTask(self.OnFinishActivity,self)
        end 
    end
end
function UIN25IdolAct:OnFinishActivity(TT)
    self:Lock("UIN25IdolAct:OnFinishActivity")
    local res = AsyncRequestRes:New()
    self.component:HandleIdolCompleteActivity(TT,res,self.finishID)
    self:UnLock("UIN25IdolAct:OnFinishActivity")
    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN25FansChange)
        self:ShowDialog("UIN25IdolActResult",self.finishID,function()
            self:Refresh()
        end)
    else
        local result = res:GetResult()
        Log.fatal("###[UIN25IdolAct] IdolCompleteActivityReq fail ! result --> ",result)
    end
end