--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    可停止任务相关接口
**********************************************************************************************
]]--------------------------------------------------------------------------------------------

---停止协程(危险接口，谨慎调用)
---注意：禁止在需要停止的任务里调用框架的异步api,如请求服务器，资源异步加载等
---@public
---@param ST StoppableTaskToken 可停止协程函数标识
---@param id int 协程ID
---@param stoppedFunc function 停止协程后的清理回调
function STOP_ST_UNSAFE(ST, id, stoppedFunc, ...)
    if TaskManager:GetInstance():StopTaskUnSafe(ST, id) then
        if stoppedFunc then
            stoppedFunc(...)
        end
    end
end

---等一帧
---@public
---@param ST StoppableTaskToken 可停止协程函数标识
---@param ms int 等多久,nil时等一帧
function YIELD_ST(ST, ms)
    YieldInternal(ST, ms)
end

---挂起当前协程
---@public
---@param ST StoppableTaskToken 可停止协程函数标识
function SUSPEND_ST(ST)
    SuspendInternal(ST)
end

---重启协程
---@public
---@return bool
---@param ST StoppableTaskToken 可停止协程函数标识
---@param id int 协程id
function RESUME_ST(ST, id)
    return ResumeInternal(id)
end

---等待child协程执行完毕
---@public
---@param ST StoppableTaskToken 可停止协程函数标识
---@param child 需要等待的协程id
function JOIN_ST(ST, child)
    JoinInternal(child)
end
