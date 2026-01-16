---@class ActivityValentineData : Object
_class("ActivityValentineData", Object)
ActivityValentineData = ActivityValentineData

function ActivityValentineData:Constructor() 
end

---@param res AsyncRequestRes
function ActivityValentineData:LoadData(TT, res)
    ---@type UIActivityCampaign
    self._campaign =  UIActivityCampaign.New()

    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N27_MINI_GAME,
        ECampaignN27MiniGameComponentID.QUEST,
        ECampaignN27MiniGameComponentID.MINI_MAIL
    )
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function ActivityValentineData:GetCampaign() --获取活动
    return self._campaign
end

---@return CCampaignN27MiniGame
function ActivityValentineData:GetCampaignLocalProgress()
    local campaign = self:GetCampaign()
    if campaign then
        return campaign:GetLocalProcess()
    end
end

function ActivityValentineData:GetCampaignSample()
    local campaign = self:GetCampaign()
    if campaign then
        return campaign:GetSample()
    end
end

function ActivityValentineData:GetCampaignID()
    return ECampaignType.CAMPAIGN_TYPE_N27_MINI_GAME
end

---@return MiniMailComponent
function ActivityValentineData:GetMailComponent()
    local localProcess = self:GetCampaignLocalProgress()
    if localProcess then
        return localProcess:GetComponent(ECampaignN27MiniGameComponentID.MINI_MAIL)
    end
end

---@return MiniMailComponentInfo
function ActivityValentineData:GetMailComponentInfo()
    local localProcess = self:GetCampaignLocalProgress()
    if localProcess then
        return localProcess:GetComponentInfo(ECampaignN27MiniGameComponentID.MINI_MAIL)
    end
end

---@return CampaignQuestComponent
function ActivityValentineData:GetQuestComponent()
    local localProcess = self:GetCampaignLocalProgress()
    if localProcess then
        return localProcess:GetComponent(ECampaignN27MiniGameComponentID.QUEST)
    end
end

---@return CamQuestComponentInfo
function ActivityValentineData:GetQuestComponentInfo()
    local localProcess = self:GetCampaignLocalProgress()
    if localProcess then
        return localProcess:GetComponentInfo(ECampaignN27MiniGameComponentID.QUEST)
    end
end

--入口New
function ActivityValentineData:GetEntryNew()
    local campaign_module = GameGlobal.GetModule(CampaignModule)
    if campaign_module.m_campaign_manager then
        local new = UIActivityHelper.CheckCampaignSampleNewPoint(self._campaign)
        return new
    end

    return false
end

--取消入口new
function ActivityValentineData:CancelEntryNew()
    if self:GetEntryNew() then
        GameGlobal.TaskManager():StartTask(self._CancelEntryNew, self)
    end
end

function ActivityValentineData:_CancelEntryNew(TT)
    self._campaign:ClearCampaignNew(TT)
end

--入口红点 需要持续调用
function ActivityValentineData:GetEntryRed()
    if self:CheckMailIsOver() then
        return false
    end
    local hasTaskRed = self:_CheckTaskGroupRed()
    local hasCompRed = self:GetMailRed()
    return hasCompRed or hasTaskRed
end

--邮件红点
function ActivityValentineData:GetMailRed()
    local component = self:GetMailComponent()
    if component then
        local hasCompRed = component:HaveRedPoint()
        return hasCompRed
    end
end

--检查任务组是否解锁
---@param taskId number
function ActivityValentineData:CheckTaskIsLock(taskId)
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local questInfo = self:GetQuestComponentInfo()
    local openTime = questInfo.m_quest_time_param_map[taskId].m_open_time

    if curTime > openTime then
        return false, openTime
    else
        return true, openTime
    end
end

--检查任务组组件是否结束
function ActivityValentineData:CheckTaskIsOver()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local questInfo = self:GetQuestComponentInfo()
    local closeTime = questInfo.m_close_time

    if curTime > closeTime then
        return true
    else
        return false
    end
end

--检查邮件组件是否结束
function ActivityValentineData:CheckMailIsOver()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local questInfo = self:GetMailComponentInfo()
    local closeTime = questInfo.m_close_time

    if curTime > closeTime then
        return true
    else
        return false
    end
end

--检查送巧克力任务状态
---@return CampaignQuestStatus
function ActivityValentineData:CheckSendTaskIsDone(questId)
    local questModule = GameGlobal.GetModule(QuestModule)
    ---@type Quest
    local quest = questModule:GetQuest(questId)
    if not quest then
        return
    end
    ---@type CampaignQuestComponent
    local questComponent = self:GetQuestComponent()
    ---@type CampaignQuestStatus
    local status = questComponent:CheckCampaignQuestStatus(quest:QuestInfo())

    return status
end

--检查任务组红点
function ActivityValentineData:_CheckTaskGroupRed()
    local cfg = Cfg.cfg_valentine_task_group {}
    for _, v in pairs(cfg) do
        local taskId = v.TaskIDGroup[1]
        local isLock = self:CheckTaskIsLock(taskId)
        if not isLock then
            local localID = self:_GetTaskLocalID(taskId)
            local res = LocalDB.GetInt(localID)
            --如果任务开启且拿不到本地的值 则为有红点
            if res ~= 1 then
                return true
            end
        end

        --检查送巧克力任务是否完成未领取
        local sendTaskStatus = self:CheckSendTaskIsDone(v.TaskIDGroup[4])
        if sendTaskStatus == CampaignQuestStatus.CQS_Completed then
            return true
        end
    end
    return false
end

--清除所有任务组红点
function ActivityValentineData:ClearTaskGroupRed()
    local cfg = Cfg.cfg_valentine_task_group {}
    for _, v in pairs(cfg) do
        local taskId = v.TaskIDGroup[1]
        local isLock = self:CheckTaskIsLock(taskId)
        if not isLock then
            local localID = self:_GetTaskLocalID(taskId)
            LocalDB.SetInt(localID, 1)
        end
    end
end

--获得任务组的本地ID
function ActivityValentineData:_GetTaskLocalID(taskId)
    local roleModule = GameGlobal.GetModule(RoleModule)
    local openID = roleModule:GetPstId()
    local key = "ActivityValentineData" .. openID..taskId
    return key
end