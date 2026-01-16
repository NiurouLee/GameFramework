---@class UIActivityN33DateData : Object
_class("UIActivityN33DateData", Object)
UIActivityN33DateData = UIActivityN33DateData

function UIActivityN33DateData:Constructor(campaign)
    self._campaign = campaign
    ---@type SimulationOperation
    self._comp = self._campaign:GetComponent(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
    ---@type SimulationOperationComponentInfo
    self._compInfo = self._campaign:GetComponentInfo(ECampaignN33ComponentID.ECAMPAIGN_N33_SIMULATION_OPERATION)
end

function UIActivityN33DateData:GetComponent()
    return self._comp
end

--获取约会光灵列表
function UIActivityN33DateData:GetDatePetList()
    local map = {}
    local cfg = Cfg.cfg_component_simulation_operation_story {}
    --按照光灵id分配
    for _,v in pairs(cfg) do
        if map[v.PetId] then
            table.insert(map[v.PetId],v)
        else
            map[v.PetId] = {}
            table.insert(map[v.PetId],v)
        end
    end

    return map
end

--获得手册光灵列表
function UIActivityN33DateData:GetDateManualList()
    local map = self:GetDatePetList()
    local list = {}
    local unReadList = {}   --有约会未读
    local unLockList = {}   --约会未完全解锁
    local allDoneList = {}  --约会全部解锁已读
    local lockedList = {}   --未解锁

    for _, cfgs in pairs(map) do
        local hasRed = false
        local allOver = true
        local isOneOver = false

        for i, v in pairs(cfgs) do
            if i > 2 then
                break
            end
            local isOver = self:CheckStoryConditionIsOver(v.ID)
            local isRead = self:CheckStoryIsRead(v.ID)
            isOneOver = isOneOver or isOver
    
            if isOver then
                if not isRead then
                    hasRed = true
                    allOver = false
                end
            else
                allOver = false
            end
        end
    
        if allOver then
            table.insert(allDoneList,cfgs)
        else
            if not isOneOver then
                table.insert(lockedList,cfgs)
            else
                if hasRed then
                    table.insert(unReadList,cfgs)
                else
                    table.insert(unLockList,cfgs)
                end
            end
        end
    end

    --根据id排序
    table.sort(unReadList,function(a,b)
        return a[1].ID < b[1].ID
    end)
    table.sort(unLockList,function(a,b)
        return a[1].ID < b[1].ID
    end)
    table.sort(allDoneList,function(a,b)
        return a[1].ID < b[1].ID
    end)
    table.sort(lockedList,function(a,b)
        return a[1].ID < b[1].ID
    end)

    --插入list
    for _, v in pairs(unReadList) do
        table.insert(list,v)
    end
    for _, v in pairs(unLockList) do
        table.insert(list,v)
    end
    for _, v in pairs(allDoneList) do
        table.insert(list,v)
    end
    for _, v in pairs(lockedList) do
        table.insert(list,v)
    end

    return list
end

--获得在地图上显示的光灵列表
function UIActivityN33DateData:GetMapShowPetList()
    local res = {}
    local cfgs = Cfg.cfg_component_simulation_operation_story {}
    for _,cfg in pairs(cfgs) do
        local isContain = table.icontains(self._compInfo.story_list,cfg.ID)
        if not isContain then
            --如果没有前置剧情 则是光灵的第一段约会 需要满足条件才能出现在地图上
            --如果是非第一段约会 只需要前段剧情完成
            if cfg.PreStory then
                local isRead = false
                for i, v in pairs(cfg.PreStory) do
                    isRead = self:CheckStoryIsRead(v) or isRead
                end
                if isRead then
                    table.insert(res,cfg)
                end
            else
                local isOver = self:CheckStoryConditionIsOver(cfg.ID)
                if isOver then
                    table.insert(res,cfg)
                end
            end
        end
    end

    return res
end

--检查剧情是否阅读过
function UIActivityN33DateData:CheckStoryIsRead(storyId)
    return table.icontains(self._compInfo.story_list,storyId)
end

--检查建筑是否达到指定等级
function UIActivityN33DateData:CheckBuildGetLevel(buildId,level)
    local isGetTargetLevel = self._compInfo.arch_infos[buildId].level >= level
    return isGetTargetLevel
end


--检查剧情的条件是否完成
function UIActivityN33DateData:CheckStoryConditionIsOver(storyId)
    local cfg = Cfg.cfg_component_simulation_operation_story[storyId]
    local buildConditions = cfg.PreCondition
    local storyConditions = cfg.PreStory
    --判断剧情
    local isStoryOver = true
    if storyConditions then
        for _, v in pairs(storyConditions) do
            local isInvited = table.icontains(self._compInfo.story_list,v)
            if not isInvited then
                isStoryOver = false
                break
            end
        end
    end
    
    --判断建筑
    local isBuildOver = true
    if buildConditions then
        for _, v in pairs(buildConditions) do
            local id = v[1]
            local needLevel = v[2]
            if not self:CheckBuildGetLevel(id,needLevel)  then
                isBuildOver = false
                break
            end
        end
    end
    
    return isStoryOver and isBuildOver
end

---@return ArchInfo[]
function UIActivityN33DateData:GetArchInfos()
    return self._compInfo.arch_infos
end
function UIActivityN33DateData:OneSecondUpdate_GetArchInfos(TT, callFun)
    local res = AsyncRequestRes:New()
    local ret, archInfos = self._comp:HandleGetArchInfos(TT,res)
    if res:GetSucc() and callFun then
        callFun()
    end
end
function UIActivityN33DateData:OneSecondUpdate_PickUpCoin(TT, arch_id, callFun)
    local res = AsyncRequestRes:New()
    local ret = self._comp:HandlePickUpCoin(TT,res, arch_id)
    if res:GetSucc() and callFun then
        callFun()
    end
end
function UIActivityN33DateData:OneSecondUpdate_UpgradeArch(TT, arch_id, callFun)
    local res = AsyncRequestRes:New()
    local ret, rewards = self._comp:HandleUpgradeArch(TT,res, arch_id)
    local sortReward = self:SortReward(rewards)
    if res:GetSucc() and callFun then
        callFun(sortReward)
    end
end

--检查活动组件是否结束
function UIActivityN33DateData:CheckSimulationOperationIsOver()
    local closeTime = self._comp.m_component_info.m_close_time
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime > closeTime then
        return true
    else
        return false
    end
end

--- 是否播放最终剧情
function UIActivityN33DateData:GetIsPlayFinalStory()
    local b = self._compInfo.final_story
    if b == 0 or b == false or b == nil then
        return false
    end
    return true
end

function UIActivityN33DateData:SortReward(data)
    local newList = {}
    if not data then
        return newList
    end
    for key, v in pairs(data) do
        local id = v[1]
        if id == RoleAssetID.RoleAssetSimulationOperationCoin then
            table.insert(newList, v)
        end
    end
    for key, v in pairs(data) do
        local id = v[1]
        if id ~= RoleAssetID.RoleAssetSimulationOperationCoin then
            table.insert(newList, v)
        end
    end
    return newList
end