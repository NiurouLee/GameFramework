--默认调度器，顺序获取下一个阶段
_class("SkillPhaseDirectorBase", Object)
SkillPhaseDirectorBase = SkillPhaseDirectorBase

function SkillPhaseDirectorBase:Constructor(world)
    self._world = world
    self._phaseIndex = 0
    self._delayInfo = {}
    -- self._eventCallback = {}
    -- self._eventCallbackOnce = {}
end

---@param casterEntity 施法者
function SkillPhaseDirectorBase:NextPhaseIndex(casterEntity, skillPhaseArray)
    if self._phaseIndex < #skillPhaseArray then
        self._phaseIndex = self._phaseIndex + 1
        return self._phaseIndex
    end
end

function SkillPhaseDirectorBase:CurPhaseIndex()
    return self._phaseIndex
end

function SkillPhaseDirectorBase:CreateDelayInfo(index)
    self._delayInfo[index] = SkillPhaseTaskRunData:New()
    return self._delayInfo[index]
end

---@param funcDic table<int, PlaySkillPhaseBase>
function SkillPhaseDirectorBase:DoPlaySkillPhase(TT, casterEntity, skillPhaseArray, funcDic)
    local phaseTaskIDArray = {}
    local oldpos = casterEntity:GridLocation().Position
    local olddir = casterEntity:GridLocation().Direction
    local revert_pos_dir = false

    ---技能表现播放前的准备工作
    for phaseIndex = 1, #skillPhaseArray do
        ---@type SkillPhaseData
        local phaseData = skillPhaseArray[phaseIndex]
        local phaseParam = phaseData:GetPhaseParam()
        local phaseType = phaseParam:GetPhaseType()
        local func = funcDic[phaseType]
        func:PrepareToPlay(TT, casterEntity, phaseParam)
    end

    while self:NextPhaseIndex(casterEntity, skillPhaseArray) do
        local phaseIndex = self:CurPhaseIndex()
        ---@type SkillPhaseData
        local phaseData = skillPhaseArray[phaseIndex]
        if phaseData == nil then
            Log.fatal("phase end ---------- phaseIndex= " .. phaseIndex)
            break
        end

        while not self:_CheckPhaseCanStart(skillPhaseArray, phaseIndex) do
            YIELD(TT)
        end

        local runData = self:CreateDelayInfo(phaseIndex)

        ---@type SkillPhaseData
        local phaseData = skillPhaseArray[phaseIndex]
        local posdirParam = phaseData:GetPosDirParam()
        local phaseParam = phaseData:GetPhaseParam()
        local phaseType = phaseParam:GetPhaseType()
        local func = funcDic[phaseType]
        Log.notice("entity " .. casterEntity:GetID() .. " start skill phase " .. phaseIndex,' phaseType=',GetEnumKey('SkillViewPhaseType',phaseType))

        if posdirParam then
            revert_pos_dir=true 
            local pos = posdirParam:GetPos()
            local dir = posdirParam:GetDir()
	        casterEntity:SetLocation(pos, dir)
            --casterEntity:SetGridLocation(pos, dir)
        end

        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                func:BeginPlay(TT, casterEntity, phaseParam)
                func:PlayFlight(TT, casterEntity, phaseParam, phaseIndex)
                func:EndPlay(TT, casterEntity, phaseParam)
                runData.EndTick = GameGlobal:GetInstance():GetCurrentTime()
            end
        )
        table.insert(phaseTaskIDArray, taskID)

    end

    --等待启动的所有协程都结束
    while not TaskHelper:GetInstance():IsAllTaskFinished(phaseTaskIDArray) do
        YIELD(TT)
    end
    
    if revert_pos_dir then
        -- local newPos = casterEntity:GridLocation().Position
	    casterEntity:SetLocation(oldpos, olddir)
        --casterEntity:SetGridLocation(oldpos, olddir)
    end
end

function SkillPhaseDirectorBase:_CheckPhaseCanStart(skillPhaseArray, phaseIndex)
    local runndata = self._delayInfo[phaseIndex]
    if (runndata ~= nil) then
        return false
    end
    ---@type SkillPhaseData
    local phaseData = skillPhaseArray[phaseIndex]
    local delayfromPhase = phaseData:GetDelayFromPhase() or 0
    local delayTime = phaseData:GetDelayMS()
    local delayType = phaseData:GetDelayType()
    local curTick = GameGlobal:GetInstance():GetCurrentTime()
    if delayfromPhase <= 0 then
        return true
    end

    if (delayfromPhase == phaseIndex) then
        error("[skill] delayfromPhase == phaseIndex " .. phaseIndex)
    end
    ---@type SkillPhaseTaskRunData
    local prePhaseRundata = self._delayInfo[delayfromPhase]
    if (prePhaseRundata == nil) then
        return false
    end
    if (delayType == SkillDelayType.Delay_AfterStart) then
        if (curTick - prePhaseRundata.StartTick >= delayTime) then
            return true
        else
            return false
        end
    elseif (delayType == SkillDelayType.Delay_AfterEnd) then
        if (prePhaseRundata.EndTick > 0 and curTick - prePhaseRundata.EndTick >= delayTime) then
            return true
        else
            return false
        end
    elseif delayType == SkillDelayType.Delay_AfterEvent then
        if (curTick - prePhaseRundata.StartTick >= delayTime) then
            return true
        else
            return false
        end
    else
        Log.error("[skill] error delaytype")
    end
end

-- function SkillPhaseDirectorBase:On(event, callback)
--     if not self._eventCallback[event] then
--         self._eventCallback[event] = {}
--     end
--     table.insert(self._eventCallback[event], callback)
-- end

-- function SkillPhaseDirectorBase:Off(event, callback)
--     if not self._eventCallback[event] then
--         return
--     end
--     table.removev(self._eventCallback[event], callback)
-- end

-- function SkillPhaseDirectorBase:Once(event, callback)
--     if not self._eventCallbackOnce[event] then
--         self._eventCallbackOnce[event] = {}
--     end
--     table.insert(self._eventCallbackOnce[event], callback)
-- end

-- function SkillPhaseDirectorBase:DoEventCallback(TT, event)
--     if self._eventCallback[event] then
--         local cbs = table.shallowcopy(self._eventCallback[event])
--         if cbs then
--             for cb in ipairs(cbs) do
--                 cb(TT)
--             end
--         end
--     end

--     if self._eventCallbackOnce[event] then
--         for cb in ipairs(self._eventCallbackOnce[event]) do
--             cb(TT)
--         end
--         table.clear(self._eventCallbackOnce[event])
--     end
-- end
