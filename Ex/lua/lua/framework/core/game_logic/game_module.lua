---@class GameModule:Object
_class("GameModule", Object)
GameModule = GameModule

function GameModule:Constructor()
    self.logic = nil
    ---@type NetCaller
    self.caller = nil
    self.autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())
end
function GameModule:AttachEvent(gameEventType, func)
    self.autoBinder:BindEvent(gameEventType, self, func)
end

function GameModule:DetachEvent(gameEventType)
    self.autoBinder:UnBindEvent(gameEventType)
end

---释放所有+过的事件
function GameModule:Init()
end

function GameModule:Dispose()
    ---@type NetCaller
    --self.caller = nil
end
function GameModule:DetachAllEvents()
    self.autoBinder:UnBindAllEvents()
end
---@param cur_tick int
function GameModule:Update(cur_tick)
end

---@generic T : GameModule
---@param type T 模块类型
---@return T 模块
function GameModule:GetModule(type)
    return self.logic:GetModule(type)
end

---@generic T:GameModule, K:UIModule
---@param type T
---@return K
function GameModule:GetUIModule(type)
    if type == nil then
        type = self
    end
    return GameGlobal.GetUIModule(type)
end

---@public
---@param TT TT 协程函数标识
---@param request CCallRequestEvent 请求发送的协议
---@param sync bool true: 同步（默认）; false: 异步
---@param timeout uint 超时时间（ms），10s：同步（默认）；15s：异步（默认）
---@return ReplyInfo 返回信息
function GameModule:Call(TT, request, sync, timeout)
    local guideModule = GameGlobal.GetModule(GuideModule)
    if guideModule then
        local lastGuideid = guideModule:GetLastCompleteGuide()
        if (lastGuideid ~= 0) then
            request.flag = lastGuideid
            guideModule:ReportCompleteGuide(lastGuideid)
        end
    end
    sync = sync == nil and true or sync
    timeout = timeout == nil and (sync and 10 * 1000 or 15 * 1000) or timeout
    return self.caller:Call(TT, request, sync, timeout) or ReplyInfo:New()
end

---@public
---@param msg CMatchPushEvent 请求发送的协议
function GameModule:Push(msg)
    self.caller:Push(msg)
end
