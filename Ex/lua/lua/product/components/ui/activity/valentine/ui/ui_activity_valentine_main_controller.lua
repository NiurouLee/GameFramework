---@class UIActivityValentineMainController:UIController
_class("UIActivityValentineMainController", UIController)
UIActivityValentineMainController = UIActivityValentineMainController

function UIActivityValentineMainController:Constructor()
end

function UIActivityValentineMainController:LoadDataOnEnter(TT, res, uiParams)
    res:SetSucc(true)
    ---@type ActivityValentineData
    self._activityData = ActivityValentineData:New()
    self._activityData:LoadData(TT, res)
end

function UIActivityValentineMainController:OnShow()
    self._allTaskDone = false
    self._curWidget = nil
    self._rewardWidgets = {}
    self:_GetComponent()
    self:_SetCampainTime()
    self:SetHeadList()
end

function UIActivityValentineMainController:OnHide()
    self:StartTask(self._CloseAnim,self)
end

function UIActivityValentineMainController:_CloseAnim(TT)
    self:Lock("UIActivityValentineMainController_Close")
    self._anim:Play("uieff_N27_UIActivityValentine_blur_out")
    YIELD(TT,500)
    self:UnLock("UIActivityValentineMainController_Close")
end

function UIActivityValentineMainController:OnUpdate()
    self:CheckMailRed()
end

function UIActivityValentineMainController:_GetComponent()
    self._headContent = self:GetUIComponent("UISelectObjectPath","headContent")
    self._foodName = self:GetUIComponent("UILocalizationText","foodName")
    self._foodImage = self:GetUIComponent("RawImageLoader","foodImage")
    self._flavorList = self:GetUIComponent("UISelectObjectPath","flavorList")
    self._flavorListObj = self:GetGameObject("flavorList")
    self._taskArea = self:GetUIComponent("UISelectObjectPath","taskArea")
    self._taskAreaObj = self:GetGameObject("taskArea")
    self._methodFindingObj = self:GetGameObject("methodFinding")
    self._petImg = self:GetUIComponent("RawImageLoader","petImg")
    self._petImgNew = self:GetUIComponent("RawImageLoader","petImg_new")
    self._rewardContent = self:GetUIComponent("UISelectObjectPath","awardContent")
    self._redObj = self:GetGameObject("red")
    self._scrollRect = self:GetUIComponent("ScrollRect","Scroll View")
    self._sendTxt = self:GetUIComponent("UILocalizationText","sendTxt")
    self._replyAreaObj = self:GetGameObject("replyArea")
    self._taskAreaParentObj = self:GetGameObject("taskAreaParent")
    self._replyTxt = self:GetUIComponent("UILocalizationText","replyTxt")
    self._replyRemainingTimePoolObj = self:GetGameObject("replyRemainingTimePool")
    self._sendBtnMask = self:GetGameObject("sendBtnMask")
    self._sendBtnObj = self:GetGameObject("sendBtn")
    self._flavorTitle = self:GetUIComponent("UILocalizationText","flavorTitle")
    self._flavorTitleOld = self:GetUIComponent("UILocalizationText","flavorTitleLock")
    self._headParentRect = self:GetUIComponent("RectTransform","headContent")
    self._selectInfoPool = self:GetUIComponent("UISelectObjectPath", "selectInfoPool")
    self._foodBgObj = self:GetGameObject("foodBg")
    self._foodNameNew = self:GetUIComponent("UILocalizationText","foodNameNew")

    self._anim = self:GetUIComponent("Animation","anim")
    self._foodAnim = self:GetUIComponent("Animation","foodAnim")
    self._flavorAreaAnim = self:GetUIComponent("Animation","flavorAreaAnim")
end

--设置头像列表
function UIActivityValentineMainController:SetHeadList()
    self._headCfg = Cfg.cfg_valentine_main {}
    self._headWidgets = self._headContent:SpawnObjects("UIActivityValentineMainHeadItem",#self._headCfg)
    for i, v in pairs(self._headWidgets) do
        local cfg = self._headCfg[i]
        local taskId = Cfg.cfg_valentine_task_group[cfg.TaskGroupID].TaskIDGroup[1]
        local isLock = self._activityData:CheckTaskIsLock(taskId)

        v:SetData(cfg, isLock, function(widget)
            self:HeadClickCallback(widget)
        end)
    end

    self:_SetPrimeHeadList()
end

--选择初始头像
function UIActivityValentineMainController:_SetPrimeHeadList()
    local widget = self._headWidgets[1]
    for _, v in pairs(self._headWidgets) do
        ---@type QuestStatus
        local status = v:GetSendTaskStatus()
        local isLock = v:GetIsLock()
        if status < QuestStatus.QUEST_Taken and not isLock then
            v:HeadBtnOnClick()
            return
        elseif status == QuestStatus.QUEST_Taken then
            widget = v
        else
            if not self._curWidget then
                widget = v
            end
        end
    end

    widget:HeadBtnOnClick()
end

--检查信箱红点
function UIActivityValentineMainController:CheckMailRed()
    local haveRed = self._activityData:GetMailRed()
    if haveRed then
        self._redObj:SetActive(true)
    else
        self._redObj:SetActive(false)
    end
end

function UIActivityValentineMainController:HeadClickCallback(widget)
    if widget == self._curWidget then
        return
    end
    local oldWidget = nil
    if self._curWidget then
        self._curWidget:SetSelecte(false)
        oldWidget = self._curWidget
    end
    self._curWidget = widget
    self:SetInfo(oldWidget,widget)

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._headParentRect)
end

function UIActivityValentineMainController:SetInfo(oldWidget,widget)
    local cfg = widget:GetCfg()

    local petName = StringTable.Get(Cfg.cfg_pet[cfg.PetID].Name)
    self._foodNameNew:SetText(petName)
    if oldWidget then
        local oldCfg = oldWidget:GetCfg()
        local oldName = StringTable.Get(Cfg.cfg_pet[oldCfg.PetID].Name)
        self._foodName:SetText(oldName)
        self:_CheckTaskIsLock(cfg,oldCfg)
    else
        self._foodImage:LoadImage(cfg.FoodImg)
        self:_CheckTaskIsLock(cfg,nil)
    end
    self._anim:Play("uieff_UIActivityValentineMainController_CenterArea")

    self:StartTask(self._PlayAnimation,self,oldWidget,widget)
end

function UIActivityValentineMainController:_PlayAnimation(TT,oldWidget,widget)
    local cfg = widget:GetCfg()
    self:Lock("UIActivityValentineMainController_taskArea")
    self._petImgNew:LoadImage(cfg.PetImg)
    if oldWidget then
        local oldCfg = oldWidget:GetCfg()
        local oldName = StringTable.Get(Cfg.cfg_pet[oldCfg.PetID].Name)
        self._foodName:SetText(oldName)
        self._petImg:LoadImage(oldCfg.PetImg)

        --播放退出动画
        self._foodAnim:Play("uieff_UIActivityValentineMainController_area_out")
        YIELD(TT,200)
        self._methodFindingObj:SetActive(false)
        self._replyAreaObj:SetActive(false)
        self._taskAreaParentObj:SetActive(false)
    end
    self:InitAward(cfg)
    self:InitFlavor(cfg)
    self:InitTask(cfg)
    --播放进入动画
    local taskGroup = Cfg.cfg_valentine_task_group[cfg.TaskGroupID].TaskIDGroup
    local taskId = taskGroup[1]
    local isLock, openTime = self._activityData:CheckTaskIsLock(taskId)
    if isLock then
        self._taskAreaObj:SetActive(false)
        self._foodAnim:Play("uieff_UIActivityValentineMainController_methodFinding_in")
        self._taskAreaParentObj:SetActive(true)
        self._methodFindingObj:SetActive(true)
    else
        self._taskAreaObj:SetActive(true)
        self._foodAnim:Play("uieff_UIActivityValentineMainController_area_in")
        local isDone = widget:GetSendTaskStatus() == QuestStatus.QUEST_Taken
        if isDone then
            self._replyAreaObj:SetActive(true)
        else
            self._taskAreaParentObj:SetActive(true)
        end
    end

    YIELD(TT,200)
    self:UnLock("UIActivityValentineMainController_taskArea")
end

--初始化奖励列表
function UIActivityValentineMainController:InitAward(cfg)
    local rewards = cfg.AwardID
    self._rewardWidgets = self._rewardContent:SpawnObjects("UIActivityValentineMainReward",#rewards)
    local isDone = self._curWidget:GetSendTaskStatus() == QuestStatus.QUEST_Taken
    for i, rewardWidget in pairs(self._rewardWidgets) do
        local rew = {}
        rew.assetid = rewards[i][1]
        rew.count = rewards[i][2]
        rewardWidget:Flush(rew,function(id, pos)
            self:OnItemSelect(id, pos)
        end)
        rewardWidget:SetIsGet(isDone)
    end
end

--初始化口味列表
function UIActivityValentineMainController:InitFlavor(cfg)
    local flavorIDs = cfg.Flavor
    local flavorWidgets = self._flavorList:SpawnObjects("UIActivityValentineMainFlavorItem",#flavorIDs)
    for i, v in pairs(flavorWidgets) do
        local id = flavorIDs[i]
        local isDone = self._curWidget:GetSendTaskStatus() == QuestStatus.QUEST_Taken
        v:SetData(Cfg.cfg_valentine_flavor[id],isDone)
    end
end

--初始化任务列表
function UIActivityValentineMainController:InitTask(cfg)
    local taskIDs = Cfg.cfg_valentine_task_group[cfg.TaskGroupID].TaskIDGroup
    local taskWidgets = self._taskArea:SpawnObjects("UIActivityValentineMainTaskItem",#taskIDs - 1)
    for i = 1, 3 do
        local id = taskIDs[i]
        taskWidgets[i]:SetData(Cfg.cfg_quest[id],i,self._activityData)
    end
end

--检查任务组是否解锁 任务是否完成
function UIActivityValentineMainController:_CheckTaskIsLock(cfg,oldCfg)
    local taskGroup = Cfg.cfg_valentine_task_group[cfg.TaskGroupID].TaskIDGroup
    local taskId = taskGroup[1]
    local isLock, openTime = self._activityData:CheckTaskIsLock(taskId)
    local isOldLock = false
    if oldCfg then
        local oldTaskId = Cfg.cfg_valentine_task_group[oldCfg.TaskGroupID].TaskIDGroup[1]
        isOldLock = self._activityData:CheckTaskIsLock(oldTaskId)
        self:StartTask(self._ShowFoodAnim,self,isLock,isOldLock)
    end
    
    if isLock then
        self._flavorTitleOld:SetText(StringTable.Get("str_n27_valentine_y_lock_flavor"))
        self._flavorTitle:SetText(StringTable.Get("str_n27_valentine_y_lock_flavor"))
        self._sendBtnObj:SetActive(false)
        self._anim:Play("uieff_UIActivityValentineMainController_methodFinding_in")

        self:_SetTaskLockTime(openTime)
        return
    end
    --任务组已经解锁
    --设置头像也解锁
    self._curWidget:SetHeadUnLock()
    self._flavorTitleOld:SetText(StringTable.Get("str_n27_valentine_y_nameTitle"))
    self._flavorTitle:SetText(StringTable.Get("str_n27_valentine_y_nameTitle"))
    self._sendBtnObj:SetActive(true)
    self:StartTask(self._ShowFoodAnim,self,isLock,isOldLock)

    local isDone = self._curWidget:GetSendTaskStatus() == QuestStatus.QUEST_Taken
    if isDone then
        --送巧克力任务已经完成
        self._allTaskDone = true
        self._sendBtnMask:SetActive(true)
        self._taskAreaParentObj:SetActive(false)
        self._sendTxt:SetText(StringTable.Get("str_n27_valentine_y_sendTxt_done"))
        self:_CheckReply()
        return
    end

    --检查任务是否完成
    self._allTaskDone = false
    local questModule = GameGlobal.GetModule(QuestModule)
    for i=1, 3 do
        ---@type Quest
        local task = questModule:GetQuest(taskGroup[i])
        local status = task:Status()
        if status < QuestStatus.QUEST_Completed then
            self._sendBtnMask:SetActive(true)
            self._sendTxt:SetText(StringTable.Get("str_n27_valentine_y_sendTxt_undone"))
            return
        end
    end
    --所有任务都完成
    self._allTaskDone = true

    --送巧克力任务未完成
    self._sendBtnMask:SetActive(false)
    self._sendTxt:SetText(StringTable.Get("str_n27_valentine_y_sendTxt_undone"))
    self._replyAreaObj:SetActive(false)
end

function UIActivityValentineMainController:_ShowFoodAnim(TT,isLock,isOldLock)
    self:Lock("UIActivityValentineMainController_FoodAnim")
    if isLock and isOldLock then    --都锁 不用动画
    elseif isLock and not isOldLock then    --老的不锁新的锁 消失动画
        self._flavorAreaAnim:Play("uieff_UIActivityValentineMainController_flavorArea_out")
        YIELD(TT,100)
    elseif not isLock and isOldLock then    --老的锁新的不锁  出现动画
        self._flavorAreaAnim:Play("uieff_UIActivityValentineMainController_flavorArea_in")
        YIELD(TT,100)
    elseif not isLock and not isOldLock then    --老的不锁新的也不锁 消失动画接出现动画
        self._flavorAreaAnim:Play("uieff_UIActivityValentineMainController_flavorArea_out")
        YIELD(TT,100)
        local cfg = self._curWidget:GetCfg()
        self._foodImage:LoadImage(cfg.FoodImg)
        self._flavorAreaAnim:Play("uieff_UIActivityValentineMainController_flavorArea_in")
        YIELD(TT,100)
    end
    self:UnLock("UIActivityValentineMainController_FoodAnim")
end

--设置任务组解锁时间
function UIActivityValentineMainController:_SetTaskLockTime(openTime)
    local descId = "str_n27_valentine_y_task_cowndown"
    local timeStr = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_common_less_minute"
    }
    self:_SetRemainingTime("taskRemainingTimePool", descId, openTime, timeStr)
end
--设置活动结束时间
function UIActivityValentineMainController:_SetCampainTime()
    local questCompInfo = self._activityData:GetQuestComponentInfo()
    local endTime = questCompInfo.m_close_time
    local descId = "str_n27_valentine_y_campaign_cowndown"
    local timeStr = {
            ["day"] = "str_activity_common_day",
            ["hour"] = "str_activity_common_hour",
            ["min"] = "str_activity_common_minute",
            ["zero"] = "str_activity_common_less_minute",
            ["over"] = "str_activity_common_less_minute"
        }
    self:_SetRemainingTime("remainingTimePool", descId, endTime, timeStr)
end

function UIActivityValentineMainController:_SetRemainingTime(widgetName, descId, endTime, timeStr,stopCallback)
    ---@type UICustomWidgetPool
    local sop = self:GetUIComponent("UISelectObjectPath", widgetName)
    ---@type UIActivityCommonRemainingTime
    local obj = sop:SpawnObject("UIActivityCommonRemainingTime")

    -- 设置自定义时间文字
    obj:SetCustomTimeStr(timeStr)
    obj:SetExtraRollingText()
    obj:SetAdvanceText(descId)
    obj:SetData(endTime, nil, stopCallback)
end

--送出巧克力
function UIActivityValentineMainController:_SendFunc(TT,questId)
    self:Lock("UIActivityValentineMainController_SendBtn")
    self._anim:Play("uieff_UIActivityValentineMainController_SendBtn")
    YIELD(TT,500)
    self:UnLock("UIActivityValentineMainController_SendBtn")

    local res = AsyncRequestRes:New()
    ---@type CampaignQuestComponent
    local questComponent = self._activityData:GetQuestComponent()
    local code,rewards = questComponent:HandleQuestTake(TT,res,questId)
    self:UnLock("UIQuestGet")
    if res:GetSucc() then
        if #rewards > 0 then
            --播放送巧克力Spine动画
            self:ShowDialog("UIActivityValentineSendLetterController",function()
                self:ShowDialog(
                    "UIActivityValentineGetController",
                    rewards,
                    function()
                        --任务奖励领取完回调
                        self._sendBtnMask:SetActive(true)
                        self._sendTxt:SetText(StringTable.Get("str_n27_valentine_y_sendTxt_done"))
                        self._taskAreaParentObj:SetActive(false)
                        self._replyAreaObj:SetActive(true)
                        --显示时间
                        self:_CheckReply()
                        --设置头像为完成
                        self._curWidget:SetHeadFinish()
                        for i,rewardWidget in pairs(self._rewardWidgets) do
                            rewardWidget:PlayGetAnim()
                        end
                    end
                )
            end)
        end
    else
        Log.fatal("送出巧克力任务完成失败：",code)
    end
end

--检查回信状态
function UIActivityValentineMainController:_CheckReply()
    --查看回信时间
    local cfg = self._curWidget:GetCfg()
    local letterId = cfg.LetterID

    self._replyTxt:SetText(StringTable.Get(cfg.ReplyTxt))
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    ---@type MiniMailComponentInfo
    local mailCompInfo = self._activityData:GetMailComponent()
    ---@type table<MiniMailItemInfo>
    local infos = mailCompInfo.m_component_info.infos
    local letter = nil
    for i,v in pairs(infos) do
        if v.id == letterId then
            letter = v
            break
        end
    end

    if letter then
        local unLockTime = letter.unlock_time
        if curTime > unLockTime then
            --已解锁
            self._replyRemainingTimePoolObj:SetActive(false)
        else
            --未解锁
            self._replyRemainingTimePoolObj:SetActive(true)
            local descId = "str_n27_valentine_y_letter_cowndown"
            local timeStr = {
                ["day"] = "str_activity_common_day",
                ["hour"] = "str_activity_common_hour",
                ["min"] = "str_activity_common_minute",
                ["zero"] = "str_activity_common_less_minute",
                ["over"] = "str_activity_common_less_minute"
            }
            self:_SetRemainingTime("replyRemainingTimePool", descId, unLockTime, timeStr,function()
                self._replyRemainingTimePoolObj:SetActive(false)
            end)
        end
    else
        self._replyRemainingTimePoolObj:SetActive(false)
    end
end
---------------OnClick-------------------
function UIActivityValentineMainController:MailBoxBtnOnClick()
    self:StartTask(self._MailBtnClick,self)
end

function UIActivityValentineMainController:_MailBtnClick(TT)
    self:Lock("uieff_UIActivityValentineMainController_mailBoxBtn")
    self._anim:Play("uieff_UIActivityValentineMainController_mailBoxBtn")
    YIELD(TT,100)
    self:UnLock("uieff_UIActivityValentineMainController_mailBoxBtn")
    self:ShowDialog("UIActivityValentineMailboxController")
end

function UIActivityValentineMainController:SendBtnOnClick()
    -- local rewards = {}
    -- local reward1 = RoleAsset:New()
    -- reward1.assetid = 3000003
    -- reward1.count = 50
    -- rewards[1] = reward1
    --  self:ShowDialog(
    --     --"UIGetItemController",
    --     "UIActivityValentineGetController",
    --     rewards,
    --     function()
            
    --     end
    -- )

    -- self:Lock("UIActivityValentineMainController_SendBtn")
    -- self._anim:Play("uieff_UIActivityValentineMainController_SendBtn")
    -- self:UnLock("UIActivityValentineMainController_SendBtn")

    -- self:ShowDialog("UIActivityValentineSendLetterController",function()
    --     self:ShowDialog("UIActivityValentineGetController",rewards)
    -- end)

    if self._activityData:CheckTaskIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_offline"))
        return
    end

    if self._allTaskDone then
        local sendQuestId = self._curWidget:GetSendTaskId()
        local status = self._activityData:CheckSendTaskIsDone(sendQuestId)
        if status == CampaignQuestStatus.CQS_Completed then
            self:Lock("UIQuestGet")
            local questId = self._curWidget:GetSendTaskId()
            self:StartTask(self._SendFunc,self,questId)
        elseif status >= CampaignQuestStatus.CQS_Taken then
            ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_send_done"))
        else
            Log.fatal("不允许送巧克力，任务状态：",status)
        end
    else
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_task_undone"))
        return
    end
end

function UIActivityValentineMainController:IntroBtnOnClick()
    self:StartTask(self._IntroBtnOnClick,self)
end

function UIActivityValentineMainController:_IntroBtnOnClick(TT)
    self:Lock("IntroBtnOnClick")
    self._anim:Play("uieff_UIActivityValentineMainController_introBtn")
    YIELD(TT,200)
    self:UnLock("IntroBtnOnClick")
    self:ShowDialog("UIIntroLoader", "UIActivityValentineIntro", MaskType.MT_BlurMask)
end

function UIActivityValentineMainController:BackBtnOnClick()
    self:CloseDialog()
end

---@param index number
function UIActivityValentineMainController:OnItemSelect(id, pos)
    if not self._selectInfo then
        self._selectInfo = self._selectInfoPool:SpawnObject("UISelectInfo")
    end

    self._selectInfo:SetData(id, pos)
end