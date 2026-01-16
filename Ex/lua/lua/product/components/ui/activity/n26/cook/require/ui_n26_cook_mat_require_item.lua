---@class UIN26CookMatRequireItem : UICustomWidget
_class("UIN26CookMatRequireItem", UICustomWidget)
UIN26CookMatRequireItem = UIN26CookMatRequireItem

function UIN26CookMatRequireItem:Constructor()
    ---@type NewYearDinner_Task
    self._task = nil
    self._callback = nil
    self._component = nil
    self._delayTime = 50
end

--初始化
function UIN26CookMatRequireItem:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIN26CookMatRequireItem:_GetComponents()
    self._rewardContent = self:GetUIComponent("UISelectObjectPath","rewardContent")
    self._slider = self:GetUIComponent("Slider","taskInfoSlider")
    self._percentParent = self:GetUIComponent("RectTransform","percentParent")
    self._percent1 = self:GetUIComponent("UILocalizationText","percent1")
    self._taskTitle = self:GetUIComponent("UILocalizationText","taskInfoTitle")
    self._taskBtnObj = self:GetGameObject("taskBtn")
    self._taskBtnUnFishedObj = self:GetGameObject("taskBtn-unFinish")
    self._taskBtnReceivedObj = self:GetGameObject("taskBtn-received")
end

---@param task NewYearDinner_Task
---@param component NewYearDinnerMiniGameComponent
function UIN26CookMatRequireItem:SetData(task,component,index,callback,itemClickCall)
    self._itemClickCall = itemClickCall
    self._task = task
    self._component = component
    self._index = index
    self._taskCfg = Cfg.cfg_component_newyear_dinner_task[self._task.task_id]
    self._callback = callback
    local delayTime = (index-1) * self._delayTime
    self:_SetAnimation(delayTime)
    self:_InitData()
end

--初始化数据
function UIN26CookMatRequireItem:_InitData()
    --生成奖励图标
    local reward = self._rewardContent:SpawnObject("UIN26CookRewardItem")
    local id = self._taskCfg.Reward[1][1]
    local num = self._taskCfg.Reward[1][2]
    reward:SetData(id,num,function (tplId, pos)
        if self._itemClickCall then
            self._itemClickCall(tplId, pos)
        end
    end)
    --进度
    self._percent1:SetText(self._task.cur_progress.."/"..self._task.total_progress)
    self._slider.value = self._task.cur_progress / self._task.total_progress

    --标题
    self._taskTitle:SetText(StringTable.Get(self._taskCfg.Sescribe))

    self._taskBtnObj:SetActive(false)
    self._taskBtnUnFishedObj:SetActive(false)
    self._taskBtnReceivedObj:SetActive(false)
    if self._task.status == NewYearDinner_Status.E_NewYearDinner_Status_LOCK then  --未解锁
    elseif self._task.status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then --未完成
        self._taskBtnUnFishedObj:SetActive(true)
    elseif self._task.status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then  --可领取
        self._taskBtnObj:SetActive(true)
    elseif self._task.status == NewYearDinner_Status.E_NewYearDinner_Status_RECVED then  --已领取
        self._taskBtnReceivedObj:SetActive(true)
    end

    --不知道为啥要刷新两下才能正常
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._percentParent)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._percentParent)
end

--领取
function UIN26CookMatRequireItem:TaskBtnOnClick()
   if self._task.status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
        self:StartTask(self._TaskBtnClick,self)
    else
        Log.fatal("不可领取：",self._task.status)
   end
end

function UIN26CookMatRequireItem:_TaskBtnClick(TT)
    local res = AsyncRequestRes:New()
    local result, rewards = self._component:HandleNewYearDinnerReward(TT,
        res,
        NewYearDinner_Reward_Type.E_NewYearDinner_Reward_Task,
        self._task.task_id
    )
    if res and res:GetSucc() then
        self:ShowDialog("UIGetItemController", rewards)
        self._taskBtnObj:SetActive(false)
        self._taskBtnReceivedObj:SetActive(true)

        if self._callback then
            self._callback()
        end
    else
        Log.fatal("美食活动任务领取失败：",res:GetResult())
    end
 end

 function UIN26CookMatRequireItem:_SetAnimation(delay)
    UIWidgetHelper.PlayAnimationInSequence(self,
        "anim",
        "anim",
        "uieff_N26_CookMatRequireItem",
        delay,
        500,
        nil)
end
