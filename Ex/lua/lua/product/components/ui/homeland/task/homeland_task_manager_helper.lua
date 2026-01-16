_class( "HomelandTaskManagerHelper", Object )
---@class HomelandTaskManagerHelper: Object
HomelandTaskManagerHelper = HomelandTaskManagerHelper

function HomelandTaskManagerHelper:Constructor() 
    self._taskGroups = Cfg.cfg_homeland_task_group{}
    self._taskLibrary = Cfg.cfg_homeland_task{}
    self._taskConditionCfg = Cfg.cfg_homeland_task_finish_conditions{}
    -- 新增剧情任务
    self._storyTaskConditionCfg = Cfg.cfg_homeland_story_task{}
    --self._tasknpcCfg = Cfg.cfg_homeland_task_npc{}
end

function HomelandTaskManagerHelper:Init(homelandTaskManager)
    ---@type HomelandClient
    self._homelandTaskManager = homelandTaskManager
    
end

function HomelandTaskManagerHelper:Dispose()
    self._taskGroups = nil
    self._taskLibrary = nil
end

function HomelandTaskManagerHelper:GetTaskGroupCfg(groupId) 
    return  self._taskGroups[groupId] 
end 

function HomelandTaskManagerHelper:GetSortedTaskItems(groupId)  
    local items = Cfg.cfg_homeland_task{GroupID = groupId}
    local firstTaskItemId 
    for key, value in pairs(items) do
        if  not value.PriorQuestId then 
            firstTaskItemId = value.ID
            break
        end  
    end
    if not firstTaskItemId then 
       Log.error(groupId .. " :groupId not set first taskitem ")
       return 
    end
    local sortedlist = {}
    table.insert(sortedlist,   self._taskLibrary[firstTaskItemId])
    for i = 1, #items   do
        for k = 1, #items  do 
            if items[k].PriorQuestId and items[k].PriorQuestId[1] == firstTaskItemId then 
                firstTaskItemId =  items[k].ID
                table.insert(sortedlist,self._taskLibrary[firstTaskItemId])
                break
            end 
        end 
    end
    return sortedlist
end

function HomelandTaskManagerHelper:GetTaskItemCfg(taskId) 
   return  self._taskLibrary[taskId] 
end 


function HomelandTaskManagerHelper:GetTaskConditionCfg(conditionId) 
    return  self._taskConditionCfg[conditionId] 
end

function HomelandTaskManagerHelper:GetStoryTaskCfg(stroyTaskId) 
    return  self._storyTaskConditionCfg[stroyTaskId] 
end 

function HomelandTaskManagerHelper:GetStoryTaskAllCfg() 
    return  self._storyTaskConditionCfg 
end 

function HomelandTaskManagerHelper:CheckTaskGroupInTime(taskGroupId) 
    local confg = self:GetTaskGroupCfg(taskGroupId) 
    if  not (confg.StartTime and confg.EndTime) then 
       return
    end 
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local loginModule = GameGlobal.GetModule(LoginModule)
    local beginTime = loginModule:GetTimeStampByTimeStr(confg.StartTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
    --local endTime = loginModule:GetTimeStampByTimeStr(confg.EndTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
    -- and curTime < endTime
    if beginTime <= curTime  then
        return true
    end
    return false
end 











 
 



