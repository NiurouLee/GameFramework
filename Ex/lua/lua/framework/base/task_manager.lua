--region Task定义
---@class TaskState
local TaskState = {
    Running = 1,
    Suspend = 2,
    Stop = 3
}

_enum("TaskState", TaskState)

---@class Task:Object
_class("Task", Object)
Task = Task

---@private
function Task:Constructor(id, func, token)
    self.id = id
    self.co = coroutine.create(func)
    self.state = TaskState.Running
    self.token = token
end

---等待协程执行完毕
---不要直接使用这个函数，请使用全局的JOIN函数，未来这个函数会改成"_Join"
---@param id int 协程id
function Task:Join(id)
    local task = TaskManager:GetInstance():FindTask(id)
    if not task then
        return
    end
    if not task.joinTasks then
        task.joinTasks = {}
    end
    task.joinTasks[self.id] = 1

    self.joinedTaskID = id
    TaskManager:GetInstance():SuspendTask(self.id)
end

---@public
function Task:Update(...)
    local lastTask = TaskManager:GetInstance().curTask
    TaskManager:GetInstance().curTask = self
    --Log.debug("resume frame ", GameGlobal:GetInstance():GetCurrentFrameCount()," time ",GameGlobal:GetInstance():GetCurrentTime());
    local ret, msg = coroutine.resume(self.co, ...)
    TaskManager:GetInstance().curTask = lastTask
    if ret then
        if coroutine.status(self.co) == "dead" then
            if self.finishCallback then
                self.finishCallback(self.data, self.id)
            end
            if self.joinTasks then
                for id, _ in next, self.joinTasks do
                    TaskManager:GetInstance():ResumeTask(id)
                end
            end
            self.state = TaskState.Stop
            return false
        end
        return true
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.TaskError)
    GameGlobal.GameRecorder():StopRecord()
    msg = debug.traceback(self.co, msg)
    Log.exception(msg)
    return false
end
--endregion

--region协程管理器
---@class TaskManager:Singleton
---@field GetInstance TaskManager
_class("TaskManager", Singleton)
TaskManager = TaskManager
local unpack = table.unpack

--region 初始化/销毁
---@private
function TaskManager:Constructor()
    ---@type Task[]
    self.tasks = {}
    ---@type int[]
    self.runnings = {}
    ---@type int[]
    self.newRunnings = {}
    self.seq = 0
    self.TT = TaskToken:New()
    self.ST = StoppableTaskToken:New()

    ---@type table<int, H3DTimerEvent>
    self.yieldEvents = {}

    --局内任务
    self._coreGameTaskIDs = {}
    self._lastLogTaskListTick = 0

    ---@type H3DTimer
    self._timer = nil

    ---@type Task
    self.curTask = nil
end

---更新
---@public
function TaskManager:Update()
    if #self.runnings > 0 then
        local i = 1
        while i <= #self.runnings do
            local id = self.runnings[i]
            local task = self.tasks[id]
            if task then
                local ret = task:Update(task.token)
                self.curTask = nil
                if not ret then --执行完了
                    self.tasks[id] = nil
                    --Log.debug("[task] remove task ", id)
                    table.removev(self.runnings, id)
                    table.removev(self._coreGameTaskIDs, id)
                    i = i - 1
                elseif task.state == TaskState.Suspend then
                    i = i - 1
                end
            else --task已经找不到了
                table.removev(self.runnings, id)
                i = i - 1
            end
            i = i + 1
        end
    end
    local total = #self.newRunnings
    if total > 0 then
        for i = 1, total do
            table.insert(self.runnings, self.newRunnings[i])
        end
        self.newRunnings = {}
    end
end

---得到制定id的协程
---@public
---@param id int 协程id
---@return Task
function TaskManager:FindTask(id)
    return self.tasks[id]
end

---开始协程
---@public
---@param func function 函数
---@param ... any 各种参数
---@return id
function TaskManager:StartTask(func, ...)
    return self:StartTaskInternal(func, self.TT, ...)
end

---开始可停止的协程
---@public
---@param func function 函数
---@param ... any 各种参数
---@return id
function TaskManager:StartStoppableTask(func, ...)
    return self:StartTaskInternal(func, self.ST, ...)
end

---@private
function TaskManager:StartTaskInternal(func, token, ...)
    local id = self.seq + 1
    if id < 0 then
        id = 1
    end

    self.seq = id
    local task = Task:New(id, func, token)
    local args = {}
    local index = 1

    local hasParam = true
    if not ... then
        hasParam = false
    end

    ---闭包一般都不会传参数。Token需要加到参数列表里，有些地方还是会判断TT是否为nil
    if not hasParam then
        args[index] = token
        index = index + 1
    end

    ---传入闭包时，第一个参数是token
    ---传入普通函数时，第一个参数是self，第二个参数是token
    for i = 1, select("#", ...) do
        args[index] = select(i, ...)
        index = index + 1
        if hasParam and i == 1 then
            args[index] = token
            index = index + 1
        end
    end
    table.insert(self.newRunnings, id)
    self.tasks[id] = task
    local ret = task:Update(unpack(args, 1, table.maxn(args)))
    if not ret then
        table.removev(self.newRunnings, id)
        self.tasks[id] = nil
        --Log.debug("[task] StartTask remove task ", id)
        return -1
    end

    if EDITOR then
    --local functionInfo = debug.getinfo(2)
    --local desc = functionInfo.short_src .. ":" .. functionInfo.currentline .. Log.traceback()
    --Log.debug("[task] StartTask ", desc, " ", id)
    end

    return id
end

function TaskManager:CoreGameStartTask(func, ...)
    local id = self:StartTask(func, ...)
    if id > 0 then
        --添加局内任务
        table.insert(self._coreGameTaskIDs, id)
    --Log.notice("CoreGameStartTask id=", id)
    end

    return id
end

function TaskManager:IsAnyCoreGameTask()
    return next(self._coreGameTaskIDs)
end

function TaskManager:KillCoreGameTasks()
    for _, taskid in ipairs(self._coreGameTaskIDs) do
        table.removev(self.runnings, taskid)
        table.removev(self.newRunnings, taskid)
        self.tasks[taskid] = nil
    end
    self._coreGameTaskIDs = {}
    Log.debug("KillCoreGameTasks Finished!!")
end

function TaskManager:KillTask(taskid)
    table.removev(self.runnings, taskid)
    table.removev(self.newRunnings, taskid)
    self.tasks[taskid] = nil

    local found = false
    for id, yieldEvent in pairs(self.yieldEvents) do
        if id == taskid then
            found = true
            GameGlobal.Timer():CancelEvent(yieldEvent)
            break
        end
    end

    if found then
        self.yieldEvents[taskid] = nil
    end
end

function TaskManager:KillAllTasks()
    for _, taskid in ipairs(self.tasks) do
        table.removev(self.runnings, taskid)
        table.removev(self.newRunnings, taskid)
        self.tasks[taskid] = nil
    end
    for id, yieldEvent in pairs(self.yieldEvents) do
        if yieldEvent then
            GameGlobal.Timer():CancelEvent(yieldEvent)
        end
    end
    self.yieldEvents = {}
    self._coreGameTaskIDs = {}
end

function TaskManager:WaitCoreGameTaskFinish(onfinish, ...)
    if #self._coreGameTaskIDs == 0 then
        onfinish(...)
        return -1
    end
    local args = {}
    local index = 1
    for i = 1, select("#", ...) do
        args[index] = select(i, ...)
        index = index + 1
        if i == 1 then
            args[index] = self.TT
            index = index + 1
        end
    end
    return self:StartTask(
        function(TT)
            local wait_tick = 10 * 1000
            local start_tick = GameGlobal:GetInstance():GetCurrentTime()

            while next(self._coreGameTaskIDs) do
                Log.debug("WaitCoreGameTaskFinish tasks: ", table.concat(self._coreGameTaskIDs, " "))
                YIELD(TT)

                if (GameGlobal:GetInstance():GetCurrentTime() - start_tick >= wait_tick) then
                    break
                end
            end
            if #self._coreGameTaskIDs ~= 0 then
                self:KillCoreGameTasks()
            end
            --Log.debug("core game task count = ", #self._coreGameTasks)

            if onfinish then
                onfinish(unpack(args))
            end
        end
    )
end

---挂起协程
---@private
function TaskManager:SuspendTask(id)
    local task = self.tasks[id]
    if task then
        table.removev(self.runnings, id)
        table.removev(self.newRunnings, id)
        task.state = TaskState.Suspend
        YIELD()
    --如果task是nil，不阻塞
    end
end

---重启协程
---@private
---@return bool 是否已执行（一次）
function TaskManager:ResumeTask(id)
    local yieldEvent = self.yieldEvents[id]
    if yieldEvent then
        GameGlobal.Timer():CancelEvent(yieldEvent)
        self.yieldEvents[id] = nil
    end
    local task = self.tasks[id]
    if not task then
        Log.fatal(
            "TaskManager Resume Error!!! cannot find task with id=",
            id,
            ", Please Check if called STOP_ST_UNSAFE,",
            debug.traceback()
        )
    end
    if task and not table.ikey(self.runnings, id) then
        if table.ikey(self.newRunnings) then
            return
        end
        table.insert(self.newRunnings, id)
        task.state = TaskState.Running
        -- 异步下帧执行
        -- return true

        -- 同步当帧执行（一次）
        local ret = task:Update(task.token)
        if not ret then --若执行完成
            self.tasks[id] = nil
            table.removev(self._coreGameTaskIDs, id)
            table.removev(self.newRunnings, id)
            return false
        end
    end
    return false
end

---@private
function TaskManager:ExpirationYield(token, id, ms)
    --local start_tick = GameGlobal:GetInstance():GetCurrentTime()
    --Log.debug("[task] ExpirationYield start ",ms," ",GameGlobal:GetInstance():GetCurrentTime())
    if (ms > 15) then
        ms = ms - 15
    end

    local event =
        GameGlobal.Timer():AddEvent(
        ms,
        function()
            self.yieldEvents[id] = nil
            --local end_tick = GameGlobal:GetInstance():GetCurrentTime()
            --Log.debug("[task] ExpirationYield RESUME ",ms," use ",end_tick-start_tick)
            ResumeInternal(id)
        end
    )
    if not self.yieldEvents[id] then
        self.yieldEvents[id] = event
    else
        Log.fatal("TaskManager:ExpirationYield Error, Expiration Yield When Suspend")
    end
    SuspendInternal()
end

---@private
---@param ST StoppableTaskToken 可停止协程函数标识
---@param id int 协程ID
---@return bool 是否停止成功
function TaskManager:StopTaskUnSafe(ST, id)
    local task = self.tasks[id]
    if not task then
        Log.fatal("StopTaskUnSafe Error, cannot find task,", id, ",", debug.traceback())
        return false
    end

    --检查下task token
    if task.token then
        local className = task.token._className
        if className ~= "StoppableTaskToken" then
            Log.fatal("StopTaskUnSafe Error, token is not StoppableTaskToken,", className, ",", debug.traceback())
            return false
        end
    end

    local yieldEvent = self.yieldEvents[id]
    if yieldEvent then
        GameGlobal.Timer():CancelEvent(yieldEvent)
        self.yieldEvents[id] = nil
    end

    --从join的task里移除
    local joinedTask = self.tasks[task.joinedTaskID]
    if joinedTask then
        joinedTask.joinTasks[id] = nil
    end

    task.state = TaskState.Stop
    self.tasks[id] = nil

    table.removev(self.newRunnings, id)
    return true
end
--endregion

--region全局方法

---得到当前协程
---@public
---@return Task
function GetCurTask()
    return TaskManager:GetInstance().curTask
end

---得到当前协程id
---@public
---@return id
function GetCurTaskId()
    local task = TaskManager:GetInstance().curTask
    return task and task.id or nil
end

---等一帧
---@public
---@param TT TaskToken 协程函数标识
---@param ms int 等多久,nil时等一帧
function YIELD(TT, ms)
    --TODO 局内和局外用两个task
    --[[
    if TT then
        local className = TT._className
        if className ~= "TaskToken" then
            Log.fatal("YIELD Error, token is not TaskToken,",className,",",debug.traceback())
            return
        end
    end
    ]]
    YieldInternal(TT, ms)
end

function YIELD_FRAME(TT, frame)
    for i = 0, frame do
        YieldInternal(TT)
    end
end

---挂起当前协程
---@public
---@param TT TaskToken 协程函数标识
function SUSPEND(TT)
    --[[
    if TT then
        local className = TT._className
        if className ~= "TaskToken" then
            Log.fatal("SUSPEND Error, token is not TaskToken,",className,",",debug.traceback())
            return
        end
    end
    ]]
    SuspendInternal()
end

---重启协程
---@public
---@return bool
---@param TT TaskToken 协程函数标识
---@param id int 协程id
function RESUME(TT, id)
    --[[
    if TT then
        local className = TT._className
        if className ~= "TaskToken" then
            Log.fatal("RESUME Error, token is not TaskToken,",className,",",debug.traceback())
            return
        end
    end
    ]]
    return ResumeInternal(id)
end

---等待child协程执行完毕
---@public
---@param TT TaskToken 协程函数标识
---@param child 需要等待的协程id
function JOIN(TT, child)
    --[[
    if TT then
        local className = TT._className
        if className ~= "TaskToken" then
            Log.fatal("JOIN Error, token is not TaskToken,",className,",",debug.traceback())
            return
        end
    end
    ]]
    JoinInternal(child)
end

--region Private
---@private
function YieldInternal(token, ms)
    if not ms then
        coroutine.yield()
    else
        local id = GetCurTaskId()
        if id then
            TaskManager:GetInstance():ExpirationYield(token, id, ms)
        else
            Log.fatal("YIELD Error, current task id is nil")
        end
    end
end

---@private
function SuspendInternal()
    local id = GetCurTaskId()
    TaskManager:GetInstance():SuspendTask(id)
end

---@private
function ResumeInternal(id)
    return TaskManager:GetInstance():ResumeTask(id)
end

---@private
function JoinInternal(child)
    local task = TaskManager:GetInstance().curTask
    task:Join(child)
end
--endregion
--endregion

function JOIN_TASK_ARRAY(TT, childArray)
    while not TaskHelper:GetInstance():IsAllTaskFinished(childArray) do
        YIELD(TT)
    end
end
